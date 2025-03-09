#!/bin/bash

# Create project directory structure
mkdir -p ihoje/{src/{scrapers,models,utils,services,config},logs,tests}

echo "Creating project structure..."

# Create package.json
cat > ihoje/package.json << 'EOL'
{
  "name": "ihoje",
  "version": "1.0.0",
  "description": "Event ticket aggregator service",
  "main": "src/app.js",
  "scripts": {
    "start": "node src/app.js",
    "dev": "nodemon src/app.js",
    "test": "jest",
    "lint": "eslint src/**/*.js",
    "scrape": "node src/scripts/manual-scrape.js"
  },
  "dependencies": {
    "@supabase/supabase-js": "^2.38.0",
    "axios": "^1.5.0",
    "cheerio": "^1.0.0-rc.12",
    "cron": "^2.4.3",
    "date-fns": "^2.30.0",
    "dotenv": "^16.3.1",
    "express": "^4.18.2",
    "node-cron": "^3.0.2",
    "node-html-parser": "^6.1.10",
    "pino": "^8.15.1",
    "puppeteer": "^21.3.6",
    "uuid": "^9.0.1",
    "winston": "^3.10.0"
  },
  "devDependencies": {
    "eslint": "^8.50.0",
    "jest": "^29.7.0",
    "nodemon": "^3.0.1"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
EOL

# Create .env.example
cat > ihoje/.env.example << 'EOL'
# Supabase Configuration
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_KEY=your-supabase-anon-key

# Scraper Configuration
SCRAPER_USER_AGENT=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36
SCRAPER_CONCURRENCY=2
SCRAPER_DELAY_MIN=2000
SCRAPER_DELAY_MAX=5000

# Proxy Configuration (optional)
USE_PROXIES=false
PROXY_LIST=http://username:password@proxy1.example.com:8080,http://username:password@proxy2.example.com:8080

# Scheduling
SCHEDULE_CRON_EXPRESSION=0 0 * * *  # Run daily at midnight

# Logging
LOG_LEVEL=info
EOL

# Create .gitignore
cat > ihoje/.gitignore << 'EOL'
# Logs
logs
*.log
npm-debug.log*

# Runtime data
pids
*.pid
*.seed
*.pid.lock

# Dependency directories
node_modules/

# Environment variables
.env

# Images directory
images/

# Build files
dist/
build/

# Coverage directory
coverage/

# OS specific files
.DS_Store
Thumbs.db
EOL

# Create database.js
cat > ihoje/src/config/database.js << 'EOL'
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_KEY;

if (!supabaseUrl || !supabaseKey) {
  throw new Error('Missing Supabase credentials. Please check your .env file.');
}

// Initialize Supabase client
const supabase = createClient(supabaseUrl, supabaseKey);

// Test the connection
async function testConnection() {
  try {
    const { data, error } = await supabase.from('events').select('count').limit(1);
    
    if (error) throw error;
    
    console.log('Successfully connected to Supabase');
    return true;
  } catch (error) {
    console.error('Failed to connect to Supabase:', error.message);
    return false;
  }
}

module.exports = {
  supabase,
  testConnection
};
EOL

# Create scraper.js
cat > ihoje/src/config/scraper.js << 'EOL'
require('dotenv').config();

// Default scraper configuration
const scraperConfig = {
  userAgent: process.env.SCRAPER_USER_AGENT || 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
  concurrency: parseInt(process.env.SCRAPER_CONCURRENCY || '2'),
  delayMin: parseInt(process.env.SCRAPER_DELAY_MIN || '2000'),
  delayMax: parseInt(process.env.SCRAPER_DELAY_MAX || '5000'),
  useProxies: process.env.USE_PROXIES === 'true',
  proxyList: (process.env.PROXY_LIST || '').split(',').filter(p => p)
};

module.exports = scraperConfig;
EOL

# Create base.js
cat > ihoje/src/scrapers/base.js << 'EOL'
const puppeteer = require('puppeteer');
const fs = require('fs').promises;
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const logger = require('../utils/logger');
require('dotenv').config();

/**
 * Base Scraper class to be extended by specific website scrapers
 */
class BaseScraper {
  constructor(config = {}) {
    this.name = config.name || 'base-scraper';
    this.baseUrl = config.baseUrl || '';
    this.userAgent = config.userAgent || process.env.SCRAPER_USER_AGENT;
    this.minDelay = config.minDelay || parseInt(process.env.SCRAPER_DELAY_MIN || 2000);
    this.maxDelay = config.maxDelay || parseInt(process.env.SCRAPER_DELAY_MAX || 5000);
    this.browser = null;
    this.context = null;
    this.page = null;
    this.proxyList = (process.env.PROXY_LIST || '').split(',').filter(p => p);
    this.useProxies = process.env.USE_PROXIES === 'true' && this.proxyList.length > 0;
  }

  /**
   * Initialize browser and page
   */
  async init() {
    logger.info(`Initializing ${this.name} scraper`);
    
    const launchOptions = {
      headless: true,
      args: ['--no-sandbox', '--disable-setuid-sandbox']
    };
    
    // Add proxy if enabled
    if (this.useProxies) {
      // Select a random proxy from the list
      const proxy = this.proxyList[Math.floor(Math.random() * this.proxyList.length)];
      if (proxy) {
        launchOptions.args.push(`--proxy-server=${proxy}`);
        logger.info(`Using proxy: ${proxy.split('@')[1] || proxy}`); // Hide credentials in logs
      }
    }
    
    this.browser = await puppeteer.launch(launchOptions);
    this.page = await this.browser.newPage();
    
    // Set user agent
    await this.page.setUserAgent(this.userAgent);
    
    // Set viewport
    await this.page.setViewport({ 
      width: 1920, 
      height: 1080 
    });
    
    // Set default timeout
    this.page.setDefaultTimeout(30000);
    
    // Add basic error handling
    this.page.on('console', msg => {
      if (msg.type() === 'error') {
        logger.error(`Page error: ${msg.text()}`);
      }
    });
    
    return this;
  }

  /**
   * Close browser
   */
  async close() {
    if (this.browser) {
      await this.browser.close();
      this.browser = null;
      this.page = null;
      logger.info(`Closed ${this.name} scraper`);
    }
  }

  /**
   * Add random delay between requests
   */
  async randomDelay() {
    const delay = Math.floor(Math.random() * (this.maxDelay - this.minDelay + 1)) + this.minDelay;
    logger.debug(`Waiting for ${delay}ms`);
    await new Promise(resolve => setTimeout(resolve, delay));
  }

  /**
   * Navigate to URL with retry mechanism
   */
  async navigateTo(url, retries = 3) {
    let attempt = 0;
    let lastError = null;
    
    while (attempt < retries) {
      try {
        logger.info(`Navigating to ${url} (attempt ${attempt + 1}/${retries})`);
        await this.page.goto(url, { waitUntil: 'domcontentloaded' });
        await this.randomDelay();
        return true;
      } catch (error) {
        lastError = error;
        logger.error(`Failed to navigate to ${url}: ${error.message}`);
        attempt++;
        
        if (attempt < retries) {
          const backoffDelay = this.minDelay * 2 * attempt;
          logger.info(`Retrying in ${backoffDelay}ms...`);
          await new Promise(resolve => setTimeout(resolve, backoffDelay));
        }
      }
    }
    
    logger.error(`All navigation attempts to ${url} failed`);
    throw lastError;
  }

  /**
   * Download and save image from URL
   * @param {string} imageUrl - URL of the image to download
   * @returns {Promise<string>} - Path to the downloaded image
   */
  async downloadImage(imageUrl) {
    if (!imageUrl) return null;
    
    try {
      logger.debug(`Downloading image from ${imageUrl}`);
      
      // Create a new page for downloading the image
      const imagePage = await this.browser.newPage();
      
      // Navigate to the image URL
      const response = await imagePage.goto(imageUrl, { 
        waitUntil: 'networkidle2',
        timeout: 30000
      });
      
      if (!response || response.status() !== 200) {
        throw new Error(`Failed to download image: ${response ? response.status() : 'No response'}`);
      }
      
      // Get the buffer
      const imageBuffer = await response.buffer();
      
      // Generate a unique filename
      const fileExt = path.extname(imageUrl).split('?')[0] || '.jpg';
      const fileName = `${uuidv4()}${fileExt}`;
      
      // Ensure the images directory exists
      const imagesDir = path.join(__dirname, '../../images');
      await fs.mkdir(imagesDir, { recursive: true });
      
      // Save the image to the file system
      const filePath = path.join(imagesDir, fileName);
      await fs.writeFile(filePath, imageBuffer);
      
      // Close the image page
      await imagePage.close();
      
      logger.info(`Image downloaded to ${filePath}`);
      
      return {
        path: filePath,
        fileName,
        originalUrl: imageUrl
      };
    } catch (error) {
      logger.error(`Error downloading image from ${imageUrl}: ${error.message}`);
      return null;
    }
  }

  /**
   * Main scraping method to be implemented by child classes
   */
  async scrape() {
    throw new Error('Method scrape() must be implemented by child classes');
  }

  /**
   * Extract data from a single event page
   */
  async extractEventData() {
    throw new Error('Method extractEventData() must be implemented by child classes');
  }

  /**
   * Process scraped events
   * @param {Array} events - Array of scraped events
   */
  async processEvents(events) {
    logger.info(`Processing ${events.length} events from ${this.name}`);
    // To be implemented in child classes or in a processing service
    return events;
  }
}

module.exports = BaseScraper;
EOL

# Create example-site.js
cat > ihoje/src/scrapers/example-site.js << 'EOL'
const BaseScraper = require('./base');
const logger = require('../utils/logger');
const { extractDateFromText, cleanText } = require('../utils/helpers');
const { saveEvent, findExistingEvent } = require('../models/event');
const { saveVenue, findVenueByName } = require('../models/venue');
const { savePrices } = require('../models/price');
const { supabase } = require('../config/database');

/**
 * Example site scraper - replace with actual implementation for your target site
 */
class ExampleSiteScraper extends BaseScraper {
  constructor() {
    super({
      name: 'example-site',
      baseUrl: 'https://www.example-events-site.com',
    });
    
    // Site-specific selectors
    this.selectors = {
      eventList: '.event-list .event-item',
      eventLink: 'a.event-title',
      eventName: '.event-page .event-title',
      eventDate: '.event-page .event-date',
      eventVenue: '.event-page .event-venue',
      eventDescription: '.event-page .event-description',
      eventImage: '.event-page .event-image img',
      priceList: '.event-page .price-list .price-item',
      priceType: '.price-type',
      priceValue: '.price-value',
      priceAvailability: '.availability'
    };
  }

  /**
   * Main scraping method
   */
  async scrape() {
    try {
      logger.info(`Starting scrape for ${this.name}`);
      
      await this.init();
      
      // Navigate to events page
      await this.navigateTo(`${this.baseUrl}/events`);
      
      // Get all event links
      const eventLinks = await this.page.$$eval(this.selectors.eventList, (items, selector) => {
        return items.map(item => {
          const link = item.querySelector(selector);
          return link ? link.href : null;
        });
      }, this.selectors.eventLink);
      
      logger.info(`Found ${eventLinks.length} events to scrape`);
      
      const scrapedEvents = [];
      
      // Process each event (limit for testing purposes)
      const maxEvents = 5;
      for (let i = 0; i < Math.min(eventLinks.length, maxEvents); i++) {
        const eventUrl = eventLinks[i];
        if (!eventUrl) continue;
        
        try {
          logger.info(`Scraping event ${i + 1}/${Math.min(eventLinks.length, maxEvents)}: ${eventUrl}`);
          
          await this.navigateTo(eventUrl);
          const eventData = await this.extractEventData();
          
          if (eventData) {
            eventData.source = this.name;
            eventData.sourceUrl = eventUrl;
            scrapedEvents.push(eventData);
          }
          
          await this.randomDelay();
        } catch (error) {
          logger.error(`Error scraping event at ${eventUrl}: ${error.message}`);
        }
      }
      
      logger.info(`Successfully scraped ${scrapedEvents.length} events`);
      
      // Process and save the events
      await this.processEvents(scrapedEvents);
      
      return scrapedEvents;
    } catch (error) {
      logger.error(`Error during scraping: ${error.message}`);
      throw error;
    } finally {
      await this.close();
    }
  }

  /**
   * Extract data from a single event page
   */
  async extractEventData() {
    try {
      // Extract event name
      const name = await this.page.$eval(this.selectors.eventName, el => el.textContent.trim())
        .catch(() => null);
      
      if (!name) {
        logger.warn('Could not extract event name, skipping event');
        return null;
      }
      
      // Extract event date
      const dateText = await this.page.$eval(this.selectors.eventDate, el => el.textContent.trim())
        .catch(() => null);
      const date = dateText ? extractDateFromText(dateText) : null;
      
      // Extract venue information
      const venueText = await this.page.$eval(this.selectors.eventVenue, el => el.textContent.trim())
        .catch(() => null);
      
      // Parse venue (in a real implementation, you would parse address, city, etc.)
      const venueParts = venueText ? venueText.split(',').map(part => part.trim()) : [];
      const venue = {
        name: venueParts[0] || 'Unknown Venue',
        address: venueParts.slice(1).join(', '),
        city: venueParts[1] || '',
        state: venueParts[2] || '',
        country: venueParts[3] || 'Unknown Country'
      };
      
      // Extract description
      const description = await this.page.$eval(this.selectors.eventDescription, el => el.textContent.trim())
        .catch(() => '');
      
      // Extract image
      const imageUrl = await this.page.$eval(this.selectors.eventImage, img => img.src)
        .catch(() => null);
      
      let imageDetails = null;
      if (imageUrl) {
        imageDetails = await this.downloadImage(imageUrl);
      }
      
      // Extract prices
      const prices = await this.page.$$eval(this.selectors.priceList, (items, selectors) => {
        return items.map(item => {
          const type = item.querySelector(selectors.priceType)?.textContent.trim() || 'Standard';
          const valueText = item.querySelector(selectors.priceValue)?.textContent.trim() || '';
          const value = parseFloat(valueText.replace(/[^0-9.]/g, '')) || 0;
          const currency = valueText.match(/[^0-9.]/g)?.[0] || '$';
          const availabilityText = item.querySelector(selectors.priceAvailability)?.textContent.trim() || '';
          
          return {
            price_type: type,
            price_value: value,
            currency,
            availability: availabilityText.toLowerCase().includes('sold out') ? 'Sold Out' : 'Available'
          };
        });
      }, this.selectors);
      
      return {
        name,
        date,
        venue,
        description: cleanText(description),
        image: imageDetails,
        prices
      };
    } catch (error) {
      logger.error(`Error extracting event data: ${error.message}`);
      return null;
    }
  }

  /**
   * Process and save scraped events
   */
  async processEvents(events) {
    logger.info(`Processing ${events.length} events from ${this.name}`);
    
    const results = {
      created: 0,
      updated: 0,
      skipped: 0,
      errors: 0
    };
    
    for (const eventData of events) {
      try {
        // Check if event already exists based on name, date and venue
        const existingEvent = await findExistingEvent({
          name: eventData.name,
          date: eventData.date,
          venue_name: eventData.venue.name
        });
        
        let eventId;
        
        if (existingEvent) {
          logger.info(`Event already exists: ${eventData.name}`);
          eventId = existingEvent.id;
          results.updated++;
          
          // Update event if needed
          // (Add logic for updating existing events)
        } else {
          // Find or create venue
          let venueId = null;
          const existingVenue = await findVenueByName(eventData.venue.name);
          
          if (existingVenue) {
            venueId = existingVenue.id;
          } else {
            const newVenue = await saveVenue(eventData.venue);
            venueId = newVenue.id;
          }
          
          // Upload image to Supabase storage
          let imageUrl = null;
          if (eventData.image) {
            const { path, fileName } = eventData.image;
            const fileBuffer = await require('fs').promises.readFile(path);
            
            const { data, error } = await supabase.storage
              .from('event-images')
              .upload(`images/${fileName}`, fileBuffer, {
                contentType: 'image/jpeg',
                upsert: false
              });
            
            if (error) {
              logger.error(`Error uploading image: ${error.message}`);
            } else {
              const { data: urlData } = supabase.storage
                .from('event-images')
                .getPublicUrl(`images/${fileName}`);
              
              imageUrl = urlData.publicUrl;
            }
          }
          
          // Save event
          const savedEvent = await saveEvent({
            name: eventData.name,
            date: eventData.date,
            venue_id: venueId,
            description: eventData.description,
            image_url: imageUrl,
            source: eventData.source,
            source_url: eventData.sourceUrl
          });
          
          eventId = savedEvent.id;
          
          // Save prices
          if (eventData.prices && eventData.prices.length > 0) {
            for (const price of eventData.prices) {
              await savePrices({
                event_id: eventId,
                price_type: price.price_type,
                price_value: price.price_value,
                currency: price.currency,
                availability: price.availability
              });
            }
          }
          
          results.created++;
          logger.info(`Created new event: ${eventData.name} (${eventId})`);
        }
      } catch (error) {
        logger.error(`Error processing event ${eventData.name}: ${error.message}`);
        results.errors++;
      }
    }
    
    logger.info(`Processing complete: Created ${results.created}, Updated ${results.updated}, ` +
      `Skipped ${results.skipped}, Errors ${results.errors}`);
    
    return results;
  }
}

module.exports = ExampleSiteScraper;
EOL

# Create venue.js
cat > ihoje/src/models/venue.js << 'EOL'
const { supabase } = require('../config/database');
const logger = require('../utils/logger');

/**
 * Save a new venue to the database
 * @param {Object} venueData - Venue data
 * @returns {Promise<Object>} - Saved venue object
 */
async function saveVenue(venueData) {
  try {
    // Normalize venue data
    const normalizedVenue = {
      name: venueData.name || 'Unknown Venue',
      address: venueData.address || '',
      city: venueData.city || '',
      state: venueData.state || '',
      country: venueData.country || '',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };
    
    // Insert venue into database
    const { data, error } = await supabase
      .from('venues')
      .insert(normalizedVenue)
      .select()
      .single();
    
    if (error) {
      throw error;
    }
    
    logger.info(`Saved venue: ${normalizedVenue.name} (${data.id})`);
    return data;
  } catch (error) {
    logger.error(`Error saving venue: ${error.message}`);
    throw error;
  }
}

/**
 * Find venue by name
 * @param {string} name - Venue name
 * @returns {Promise<Object|null>} - Venue object or null if not found
 */
async function findVenueByName(name) {
  try {
    if (!name) return null;
    
    const { data, error } = await supabase
      .from('venues')
      .select('*')
      .ilike('name', name)
      .limit(1)
      .single();
    
    if (error && error.code !== 'PGRST116') {
      throw error;
    }
    
    return data || null;
  } catch (error) {
    logger.error(`Error finding venue by name: ${error.message}`);
    return null;
  }
}

/**
 * Find venue by ID
 * @param {string|number} id - Venue ID
 * @returns {Promise<Object|null>} - Venue object or null if not found
 */
async function findVenueById(id) {
  try {
    if (!id) return null;
    
    const { data, error } = await supabase
      .from('venues')
      .select('*')
      .eq('id', id)
      .single();
    
    if (error) {
      throw error;
    }
    
    return data || null;
  } catch (error) {
    logger.error(`Error finding venue by ID: ${error.message}`);
    return null;
  }
}

/**
 * Update an existing venue
 * @param {number} id - Venue ID
 * @param {Object} venueData - Updated venue data
 * @returns {Promise<Object>} - Updated venue object
 */
async function updateVenue(id, venueData) {
  try {
    if (!id) throw new Error('Venue ID is required');
    
    // Add update timestamp
    venueData.updated_at = new Date().toISOString();
    
    const { data, error } = await supabase
      .from('venues')
      .update(venueData)
      .eq('id', id)
      .select()
      .single();
    
    if (error) {
      throw error;
    }
    
    logger.info(`Updated venue: ${venueData.name || 'Unknown'} (${id})`);
    return data;
  } catch (error) {
    logger.error(`Error updating venue: ${error.message}`);
    throw error;
  }
}

/**
 * List all venues with optional filtering
 * @param {Object} options - Query options (limit, offset, filters)
 * @returns {Promise<Array>} - Array of venue objects
 */
async function listVenues(options = {}) {
  try {
    const { limit = 100, offset = 0, city, country } = options;
    
    let query = supabase
      .from('venues')
      .select('*')
      .order('name', { ascending: true })
      .range(offset, offset + limit - 1);
    
    // Apply filters if provided
    if (city) {
      query = query.ilike('city', `%${city}%`);
    }
    
    if (country) {
      query = query.ilike('country', `%${country}%`);
    }
    
    const { data, error } = await query;
    
    if (error) {
      throw error;
    }
    
    return data || [];
  } catch (error) {
    logger.error(`Error listing venues: ${error.message}`);
    return [];
  }
}

module.exports = {
  saveVenue,
  findVenueByName,
  findVenueById,
  updateVenue,
  listVenues
};
EOL

# Create event.js
cat > ihoje/src/models/event.js << 'EOL'
const { supabase } = require('../config/database');
const logger = require('../utils/logger');
const { v4: uuidv4 } = require('uuid');

/**
 * Save a new event to the database
 * @param {Object} eventData - Event data
 * @returns {Promise<Object>} - Saved event object
 */
async function saveEvent(eventData) {
  try {
    // Normalize event data
    const normalizedEvent = {
      name: eventData.name,
      date: eventData.date ? new Date(eventData.date).toISOString() : null,
      venue_id: eventData.venue_id,
      description: eventData.description || '',
      image_url: eventData.image_url || null,
      source: eventData.source || 'manual',
      source_url: eventData.source_url || null,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };
    
    // Insert event into database
    const { data, error } = await supabase
      .from('events')
      .insert(normalizedEvent)
      .select()
      .single();
    
    if (error) {
      throw error;
    }
    
    logger.info(`Saved event: ${normalizedEvent.name} (${data.id})`);
    return data;
  } catch (error) {
    logger.error(`Error saving event: ${error.message}`);
    throw error;
  }
}

/**
 * Find an existing event by name, date and venue
 * @param {Object} criteria - Search criteria
 * @returns {Promise<Object|null>} - Event object or null if not found
 */
async function findExistingEvent(criteria) {
  try {
    const { name, date, venue_name } = criteria;
    
    if (!name) return null;
    
    // First query for events with matching name
    let query = supabase
      .from('events')
      .select(`
        *,
        venue:venues(*)
      `)
      .ilike('name', name);
    
    // Add date filter if provided
    if (date) {
      // Consider events on the same day (ignoring time)
      const dateStr = new Date(date).toISOString().split('T')[0];
      query = query.filter('date', 'gte', `${dateStr}T00:00:00Z`);
      query = query.filter('date', 'lte', `${dateStr}T23:59:59Z`);
    }
    
    const { data, error } = await query;
    
    if (error) {
      throw error;
    }
    
    if (!data || data.length === 0) {
      return null;
    }
    
    // If venue name is provided, filter results further
    if (venue_name) {
      const match = data.find(event => 
        event.venue && 
        event.venue.name.toLowerCase() === venue_name.toLowerCase()
      );
      
      return match || null;
    }
    
    // If no venue specified, return the first match
    return data[0];
  } catch (error) {
    logger.error(`Error finding existing event: ${error.message}`);
    return null;
  }
}

/**
 * Find event by ID
 * @param {string|number} id - Event ID
 * @returns {Promise<Object|null>} - Event object or null if not found
 */
async function findEventById(id) {
  try {
    if (!id) return null;
    
    const { data, error } = await supabase
      .from('events')
      .select(`
        *,
        venue:venues(*),
        prices:prices(*)
      `)
      .eq('id', id)
      .single();
    
    if (error) {
      throw error;
    }
    
    return data || null;
  } catch (error) {
    logger.error(`Error finding event by ID: ${error.message}`);
    return null;
  }
}

/**
 * Update an existing event
 * @param {number} id - Event ID
 * @param {Object} eventData - Updated event data
 * @returns {Promise<Object>} - Updated event object
 */
async function updateEvent(id, eventData) {
  try {
    if (!id) throw new Error('Event ID is required');
    
    // Add update timestamp
    eventData.updated_at = new Date().toISOString();
    
    // Handle date format if provided
    if (eventData.date) {
      eventData.date = new Date(eventData.date).toISOString();
    }
    
    const { data, error } = await supabase
      .from('events')
      .update(eventData)
      .eq('id', id)
      .select()
      .single();
    
    if (error) {
      throw error;
    }
    
    logger.info(`Updated event: ${eventData.name || 'Unknown'} (${id})`);
    return data;
  } catch (error) {
    logger.error(`Error updating event: ${error.message}`);
    throw error;
  }
}

/**
 * List events with various filtering options
 * @param {Object} options - Query options
 * @returns {Promise<Array>} - Array of event objects
 */
async function listEvents(options = {}) {
  try {
    const { 
      limit = 100, 
      offset = 0, 
      venueId,
      fromDate,
      toDate,
      keyword,
      orderBy = 'date',
      orderDirection = 'asc' 
    } = options;
    
    let query = supabase
      .from('events')
      .select(`
        *,
        venue:venues(*),
        prices:prices(*)
      `);
    
    // Apply filters
    if (venueId) {
      query = query.eq('venue_id', venueId);
    }
    
    if (fromDate) {
      query = query.gte('date', new Date(fromDate).toISOString());
    }
    
    if (toDate) {
      query = query.lte('date', new Date(toDate).toISOString());
    }
    
    if (keyword) {
      query = query.or(`name.ilike.%${keyword}%,description.ilike.%${keyword}%`);
    }
    
    // Apply ordering
    query = query.order(orderBy, { ascending: orderDirection === 'asc' });
    
    // Apply pagination
    query = query.range(offset, offset + limit - 1);
    
    const { data, error } = await query;
    
    if (error) {
      throw error;
    }
    
    return data || [];
  } catch (error) {
    logger.error(`Error listing events: ${error.message}`);
    return [];
  }
}

/**
 * Delete an event and its related data
 * @param {number} id - Event ID
 * @returns {Promise<boolean>} - Success status
 */
async function deleteEvent(id) {
  try {
    if (!id) throw new Error('Event ID is required');
    
    // Delete related prices first
    const { error: pricesError } = await supabase
      .from('prices')
      .delete()
      .eq('event_id', id);
    
    if (pricesError) {
      throw pricesError;
    }
    
    // Delete the event
    const { error } = await supabase
      .from('events')
      .delete()
      .eq('id', id);
    
    if (error) {
      throw error;
    }
    
    logger.info(`Deleted event with ID: ${id}`);
    return true;
  } catch (error) {
    logger.error(`Error deleting event: ${error.message}`);
    return false;
  }
}

module.exports = {
  saveEvent,
  findExistingEvent,
  findEventById,
  updateEvent,
  listEvents,
  deleteEvent
};
EOL

# Create price.js
cat > ihoje/src/models/price.js << 'EOL'
const { supabase } = require('../config/database');
const logger = require('../utils/logger');

/**
 * Save new price information for an event
 * @param {Object} priceData - Price data
 * @returns {Promise<Object>} - Saved price object
 */
async function savePrices(priceData) {
  try {
    // Normalize price data
    const normalizedPrice = {
      event_id: priceData.event_id,
      price_type: priceData.price_type || 'Standard',
      price_value: priceData.price_value || 0,
      currency: priceData.currency || '$',
      availability: priceData.availability || 'Available',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };
    
    // Insert price into database
    const { data, error } = await supabase
      .from('prices')
      .insert(normalizedPrice)
      .select()
      .single();
    
    if (error) {
      throw error;
    }
    
    logger.info(`Saved price for event ID ${priceData.event_id}: ${priceData.price_type} - ${priceData.price_value} ${priceData.currency}`);
    return data;
  } catch (error) {
    logger.error(`Error saving price: ${error.message}`);
    throw error;
  }
}

/**
 * Update an existing price
 * @param {number} id - Price ID
 * @param {Object} priceData - Updated price data
 * @returns {Promise<Object>} - Updated price object
 */
async function updatePrice(id, priceData) {
  try {
    if (!id) throw new Error('Price ID is required');
    
    // Add update timestamp
    priceData.updated_at = new Date().toISOString();
    
    const { data, error } = await supabase
      .from('prices')
      .update(priceData)
      .eq('id', id)
      .select()
      .single();
    
    if (error) {
      throw error;
    }
    
    logger.info(`Updated price: ID ${id}`);
    return data;
  } catch (error) {
    logger.error(`Error updating price: ${error.message}`);
    throw error;
  }
}

/**
 * Get all prices for an event
 * @param {number} eventId - Event ID
 * @returns {Promise<Array>} - Array of price objects
 */
async function getPricesForEvent(eventId) {
  try {
    if (!eventId) throw new Error('Event ID is required');
    
    const { data, error } = await supabase
      .from('prices')
      .select('*')
      .eq('event_id', eventId)
      .order('price_value', { ascending: true });
    
    if (error) {
      throw error;
    }
    
    return data || [];
  } catch (error) {
    logger.error(`Error getting prices for event: ${error.message}`);
    return [];
  }
}

/**
 * Delete a price
 * @param {number} id - Price ID
 * @returns {Promise<boolean>} - Success status
 */
async function deletePrice(id) {
  try {
    if (!id) throw new Error('Price ID is required');
    
    const { error } = await supabase
      .from('prices')
      .delete()
      .eq('id', id);
    
    if (error) {
      throw error;
    }
    
    logger.info(`Deleted price with ID: ${id}`);
    return true;
  } catch (error) {
    logger.error(`Error deleting price: ${error.message}`);
    return false;
  }
}

/**
 * Track price changes for an event
 * @param {number} eventId - Event ID
 * @param {Array} newPrices - New price data
 * @returns {Promise<Object>} - Price change summary
 */
async function trackPriceChanges(eventId, newPrices) {
  try {
    if (!eventId) throw new Error('Event ID is required');
    if (!newPrices || !Array.isArray(newPrices)) throw new Error('New prices must be an array');
    
    // Get existing prices
    const existingPrices = await getPricesForEvent(eventId);
    
    const changes = {
      added: [],
      updated: [],
      removed: [],
      unchanged: []
    };
    
    // Process new prices
    for (const newPrice of newPrices) {
      const existingPrice = existingPrices.find(p => 
        p.price_type === newPrice.price_type && 
        p.currency === newPrice.currency
      );
      
      if (!existingPrice) {
        // New price
        const savedPrice = await savePrices({
          event_id: eventId,
          ...newPrice
        });
        changes.added.push(savedPrice);
      } else if (existingPrice.price_value !== newPrice.price_value || 
                existingPrice.availability !== newPrice.availability) {
        // Updated price
        const updatedPrice = await updatePrice(existingPrice.id, {
          price_value: newPrice.price_value,
          availability: newPrice.availability,
          updated_at: new Date().toISOString()
        });
        changes.updated.push({
          before: existingPrice,
          after: updatedPrice
        });
      } else {
        changes.unchanged.push(existingPrice);
      }
    }
    
    // Find removed prices
    const existingPriceTypes = existingPrices.map(p => `${p.price_type}-${p.currency}`);
    const newPriceTypes = newPrices.map(p => `${p.price_type}-${p.currency}`);
    
    const removedPrices = existingPrices.filter(p => 
      !newPriceTypes.includes(`${p.price_type}-${p.currency}`)
    );
    
    // Mark these as unavailable rather than deleting
    for (const removedPrice of removedPrices) {
      const updatedPrice = await updatePrice(removedPrice.id, {
        availability: 'Unavailable',
        updated_at: new Date().toISOString()
      });
      
      changes.removed.push({
        before: removedPrice,
        after: updatedPrice
      });
    }
    
    // Create a log of price changes for analysis
    if (changes.added.length > 0 || changes.updated.length > 0 || changes.removed.length > 0) {
      await supabase
        .from('price_history')
        .insert({
          event_id: eventId,
          changes: JSON.stringify(changes),
          created_at: new Date().toISOString()
        });
      
      logger.info(`Tracked price changes for event ${eventId}: ${changes.added.length} added, ` +
        `${changes.updated.length} updated, ${changes.removed.length} removed`);
    }
    
    return changes;
  } catch (error) {
    logger.error(`Error tracking price changes: ${error.message}`);
    throw error;
  }
}

module.exports = {
  savePrices,
  updatePrice,
  getPricesForEvent,
  deletePrice,
  trackPriceChanges
};
EOL

# Create logger.js
cat > ihoje/src/utils/logger.js << 'EOL'
const winston = require('winston');
const path = require('path');
require('dotenv').config();

// Define log levels
const levels = {
  error: 0,
  warn: 1,
  info: 2,
  debug: 3
};

// Define log colors
const colors = {
  error: 'red',
  warn: 'yellow',
  info: 'green',
  debug: 'blue'
};

// Add colors to winston
winston.addColors(colors);

// Create the logger
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  levels,
  format: winston.format.combine(
    winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    winston.format.errors({ stack: true }),
    winston.format.splat(),
    winston.format.json()
  ),
  defaultMeta: { service: 'ihoje-scraper' },
  transports: [
    // Console transport
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize({ all: true }),
        winston.format.printf(
          info => `${info.timestamp} ${info.level}: ${info.message}`
        )
      )
    }),
    
    // File transport for errors
    new winston.transports.File({
      filename: path.join(__dirname, '../../logs/error.log'),
      level: 'error',
      format: winston.format.combine(
        winston.format.uncolorize(),
        winston.format.printf(
          info => `${info.timestamp} ${info.level}: ${info.message}${info.stack ? '\n' + info.stack : ''}`
        )
      )
    }),
    
    // File transport for all logs
    new winston.transports.File({
      filename: path.join(__dirname, '../../logs/combined.log'),
      format: winston.format.combine(
        winston.format.uncolorize(),
        winston.format.printf(
          info => `${info.timestamp} ${info.level}: ${info.message}`
        )
      )
    })
  ]
});

// Create a stream object with a write function that will be used by morgan
logger.stream = {
  write: (message) => {
    logger.info(message.trim());
  }
};

module.exports = logger;
EOL

# Create helpers.js
cat > ihoje/src/utils/helpers.js << 'EOL'
const { format, parse, isValid } = require('date-fns');
const logger = require('./logger');

/**
 * Extracts a date from a text string
 * @param {string} text - Text that might contain a date
 * @returns {string|null} - ISO formatted date string or null if not found
 */
function extractDateFromText(text) {
  if (!text) return null;
  
  // Try various date formats
  const patterns = [
    // 2023-09-15
    {
      regex: /(\d{4})[\/\-\.](\d{1,2})[\/\-\.](\d{1,2})/,
      format: '$1-$2-$3'
    },
    // 15/09/2023, 15-09-2023, 15.09.2023
    {
      regex: /(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{4})/,
      format: '$3-$2-$1'
    },
    // September 15, 2023, September 15th, 2023
    {
      regex: /([A-Za-z]+)\s+(\d{1,2})(?:st|nd|rd|th)?,\s+(\d{4})/,
      format: '$3-$1-$2'
    },
    // 15 September 2023, 15th September 2023
    {
      regex: /(\d{1,2})(?:st|nd|rd|th)?\s+([A-Za-z]+)\s+(\d{4})/,
      format: '$3-$2-$1'
    }
  ];
  
  // Try each pattern
  for (const pattern of patterns) {
    const match = text.match(pattern.regex);
    if (match) {
      let dateStr = pattern.format;
      
      // Replace capture groups
      for (let i = 1; i < match.length; i++) {
        dateStr = dateStr.replace(`$${i}`, match[i]);
      }
      
      // Parse the date
      try {
        const date = new Date(dateStr);
        if (isValid(date)) {
          return date.toISOString();
        }
      } catch (error) {
        // Continue to next pattern
      }
    }
  }
  
  // Try to find a date using natural language
  try {
    const monthNames = [
      'january', 'february', 'march', 'april', 'may', 'june',
      'july', 'august', 'september', 'october', 'november', 'december'
    ];
    
    const monthRegex = new RegExp(`(${monthNames.join('|')})`, 'i');
    const monthMatch = text.match(monthRegex);
    
    if (monthMatch) {
      const monthIndex = monthNames.findIndex(m => 
        m.toLowerCase() === monthMatch[1].toLowerCase()
      );
      
      if (monthIndex !== -1) {
        // Try to find a day near the month
        const dayRegex = new RegExp(`\\b(\\d{1,2})(?:st|nd|rd|th)?\\s+${monthMatch[1]}|${monthMatch[1]}\\s+(\\d{1,2})(?:st|nd|rd|th)?\\b`, 'i');
        const dayMatch = text.match(dayRegex);
        
        if (dayMatch) {
          // Get the day number (could be in group 1 or 2)
          const day = dayMatch[1] || dayMatch[2];
          
          // Try to find a year near the month
          const yearRegex = /\b(20\d{2})\b/;
          const yearMatch = text.match(yearRegex);
          const year = yearMatch ? yearMatch[1] : new Date().getFullYear();
          
          const date = new Date(year, monthIndex, parseInt(day));
          if (isValid(date)) {
            return date.toISOString();
          }
        }
      }
    }
  } catch (error) {
    logger.debug(`Error parsing natural language date: ${error.message}`);
  }
  
  // If we still couldn't parse a date, log and return null
  logger.debug(`Could not extract date from text: ${text}`);
  return null;
}

/**
 * Clean text by removing extra whitespace, HTML tags, etc.
 * @param {string} text - Text to clean
 * @returns {string} - Cleaned text
 */
function cleanText(text) {
  if (!text) return '';
  
  return text
    // Remove HTML tags
    .replace(/<[^>]*>/g, ' ')
    // Replace multiple spaces, tabs, newlines with a single space
    .replace(/\s+/g, ' ')
    // Trim leading/trailing whitespace
    .trim();
}

/**
 * Generate a slug from a string
 * @param {string} text - Text to convert to slug
 * @returns {string} - Slug
 */
function slugify(text) {
  if (!text) return '';
  
  return text
    .toString()
    .toLowerCase()
    .replace(/\s+/g, '-')        // Replace spaces with -
    .replace(/[^\w\-]+/g, '')    // Remove all non-word chars
    .replace(/\-\-+/g, '-')      // Replace multiple - with single -
    .replace(/^-+/, '')          // Trim - from start of text
    .replace(/-+$/, '');         // Trim - from end of text
}

/**
 * Generate a random user agent string
 * @returns {string} - User agent string
 */
function getRandomUserAgent() {
  const userAgents = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.1 Safari/605.1.15',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:89.0) Gecko/20100101 Firefox/89.0',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36'
  ];
  
  return userAgents[Math.floor(Math.random() * userAgents.length)];
}

/**
 * Deep compare two objects for equality
 * @param {Object} obj1 - First object
 * @param {Object} obj2 - Second object
 * @returns {boolean} - True if objects are equal
 */
function deepEqual(obj1, obj2) {
  if (obj1 === obj2) return true;
  
  if (typeof obj1 !== 'object' || obj1 === null ||
      typeof obj2 !== 'object' || obj2 === null) {
    return false;
  }
  
  const keys1 = Object.keys(obj1);
  const keys2 = Object.keys(obj2);
  
  if (keys1.length !== keys2.length) return false;
  
  for (const key of keys1) {
    if (!keys2.includes(key)) return false;
    
    if (!deepEqual(obj1[key], obj2[key])) return false;
  }
  
  return true;
}

/**
 * Format a date with optional format string
 * @param {Date|string} date - Date to format
 * @param {string} formatStr - Format pattern (date-fns format)
 * @returns {string} - Formatted date string
 */
function formatDate(date, formatStr = 'yyyy-MM-dd') {
  if (!date) return '';
  
  try {
    const parsedDate = typeof date === 'string' ? new Date(date) : date;
    return format(parsedDate, formatStr);
  } catch (error) {
    logger.error(`Error formatting date: ${error.message}`);
    return '';
  }
}

/**
 * Calculate date difference in days
 * @param {Date|string} date1 - First date
 * @param {Date|string} date2 - Second date
 * @returns {number} - Difference in days
 */
function dateDiffInDays(date1, date2) {
  if (!date1 || !date2) return 0;
  
  try {
    const d1 = typeof date1 === 'string' ? new Date(date1) : date1;
    const d2 = typeof date2 === 'string' ? new Date(date2) : date2;
    
    // Convert to UTC to avoid timezone issues
    const utc1 = Date.UTC(d1.getFullYear(), d1.getMonth(), d1.getDate());
    const utc2 = Date.UTC(d2.getFullYear(), d2.getMonth(), d2.getDate());
    
    return Math.floor((utc2 - utc1) / (1000 * 60 * 60 * 24));
  } catch (error) {
    logger.error(`Error calculating date difference: ${error.message}`);
    return 0;
  }
}

module.exports = {
  extractDateFromText,
  cleanText,
  slugify,
  getRandomUserAgent,
  deepEqual,
  formatDate,
  dateDiffInDays
};
EOL

# Create scheduler.js
cat > ihoje/src/services/scheduler.js << 'EOL'
const cron = require('node-cron');
const path = require('path');
const fs = require('fs');
const logger = require('../utils/logger');
require('dotenv').config();

// Store scheduled tasks
const scheduledTasks = new Map();

/**
 * Schedule a scraper to run on a cron schedule
 * @param {string} scraperId - Unique identifier for the scraper
 * @param {string} cronExpression - Cron expression for schedule
 * @param {Function} scraperFunction - Function to execute
 * @param {Object} options - Additional options
 * @returns {boolean} - Whether scheduling was successful
 */
function scheduleScraper(scraperId, cronExpression, scraperFunction, options = {}) {
  try {
    if (scheduledTasks.has(scraperId)) {
      logger.warn(`Scraper ${scraperId} is already scheduled. Stopping existing schedule.`);
      stopScraper(scraperId);
    }
    
    if (!cron.validate(cronExpression)) {
      logger.error(`Invalid cron expression: ${cronExpression}`);
      return false;
    }
    
    logger.info(`Scheduling scraper ${scraperId} with cron: ${cronExpression}`);
    
    const task = cron.schedule(cronExpression, async () => {
      const startTime = new Date();
      logger.info(`Running scheduled scraper: ${scraperId}`);
      
      try {
        await scraperFunction();
        
        const endTime = new Date();
        const duration = (endTime - startTime) / 1000;
        
        logger.info(`Completed scheduled scraper ${scraperId} in ${duration.toFixed(2)} seconds`);
        
        // Record execution history
        recordExecution(scraperId, {
          startTime,
          endTime,
          duration,
          status: 'success'
        });
      } catch (error) {
        const endTime = new Date();
        const duration = (endTime - startTime) / 1000;
        
        logger.error(`Error in scheduled scraper ${scraperId}: ${error.message}`);
        
        // Record execution history
        recordExecution(scraperId, {
          startTime,
          endTime,
          duration,
          status: 'error',
          error: error.message
        });
        
        // Handle retry if configured
        if (options.retry && options.maxRetries > 0) {
          const retryDelay = options.retryDelay || 60000; // Default 1 minute
          const retryCount = options.retryCount || 0;
          
          if (retryCount < options.maxRetries) {
            logger.info(`Retrying scraper ${scraperId} in ${retryDelay / 1000} seconds (${retryCount + 1}/${options.maxRetries})`);
            
            setTimeout(() => {
              scraperFunction()
                .then(() => {
                  logger.info(`Retry successful for scraper ${scraperId}`);
                  recordExecution(scraperId, {
                    startTime: new Date(),
                    endTime: new Date(),
                    duration: 0,
                    status: 'retry-success',
                    retryCount: retryCount + 1
                  });
                })
                .catch((retryError) => {
                  logger.error(`Retry failed for scraper ${scraperId}: ${retryError.message}`);
                  recordExecution(scraperId, {
                    startTime: new Date(),
                    endTime: new Date(),
                    duration: 0,
                    status: 'retry-failed',
                    retryCount: retryCount + 1,
                    error: retryError.message
                  });
                  
                  // Try again with incremented retry count
                  if (retryCount + 1 < options.maxRetries) {
                    const nextRetryOptions = {
                      ...options,
                      retryCount: retryCount + 1
                    };
                    
                    setTimeout(() => {
                      scraperFunction(nextRetryOptions);
                    }, retryDelay);
                  }
                });
            }, retryDelay);
          }
        }
      }
    }, {
      scheduled: true,
      timezone: options.timezone || 'UTC'
    });
    
    scheduledTasks.set(scraperId, {
      task,
      cronExpression,
      options
    });
    
    logger.info(`Successfully scheduled scraper ${scraperId}`);
    return true;
  } catch (error) {
    logger.error(`Error scheduling scraper ${scraperId}: ${error.message}`);
    return false;
  }
}

/**
 * Stop a scheduled scraper
 * @param {string} scraperId - ID of the scraper to stop
 * @returns {boolean} - Whether stopping was successful
 */
function stopScraper(scraperId) {
  try {
    if (!scheduledTasks.has(scraperId)) {
      logger.warn(`Scraper ${scraperId} is not scheduled.`);
      return false;
    }
    
    const { task } = scheduledTasks.get(scraperId);
    task.stop();
    scheduledTasks.delete(scraperId);
    
    logger.info(`Stopped scheduled scraper ${scraperId}`);
    return true;
  } catch (error) {
    logger.error(`Error stopping scraper ${scraperId}: ${error.message}`);
    return false;
  }
}

/**
 * Get the status of all scheduled scrapers
 * @returns {Array} - Array of scraper status objects
 */
function getScheduleStatus() {
  const status = [];
  
  for (const [scraperId, { cronExpression, options }] of scheduledTasks.entries()) {
    status.push({
      id: scraperId,
      cronExpression,
      timezone: options.timezone || 'UTC',
      active: true
    });
  }
  
  return status;
}

/**
 * Record execution history for a scraper
 * @param {string} scraperId - ID of the scraper
 * @param {Object} executionData - Data about the execution
 */
function recordExecution(scraperId, executionData) {
  try {
    const historyDir = path.join(__dirname, '../../logs/history');
    if (!fs.existsSync(historyDir)) {
      fs.mkdirSync(historyDir, { recursive: true });
    }
    
    const historyFile = path.join(historyDir, `${scraperId}.json`);
    
    let history = [];
    if (fs.existsSync(historyFile)) {
      const historyContent = fs.readFileSync(historyFile, 'utf8');
      history = JSON.parse(historyContent);
    }
    
    // Add the new execution data
    history.push({
      ...executionData,
      timestamp: new Date().toISOString()
    });
    
    // Keep only the last 100 executions
    if (history.length > 100) {
      history = history.slice(history.length - 100);
    }
    
    fs.writeFileSync(historyFile, JSON.stringify(history, null, 2));
  } catch (error) {
    logger.error(`Error recording execution history for ${scraperId}: ${error.message}`);
  }
}

/**
 * Get execution history for a scraper
 * @param {string} scraperId - ID of the scraper
 * @param {number} limit - Maximum number of records to return
 * @returns {Array} - Array of execution history records
 */
function getExecutionHistory(scraperId, limit = 10) {
  try {
    const historyFile = path.join(__dirname, '../../logs/history', `${scraperId}.json`);
    
    if (!fs.existsSync(historyFile)) {
      return [];
    }
    
    const historyContent = fs.readFileSync(historyFile, 'utf8');
    const history = JSON.parse(historyContent);
    
    // Return the most recent records
    return history.slice(-limit).reverse();
  } catch (error) {
    logger.error(`Error getting execution history for ${scraperId}: ${error.message}`);
    return [];
  }
}

/**
 * Initialize all scrapers from the scrapers directory
 * @returns {Promise<Array>} - Array of initialized scrapers
 */
async function initializeScrapers() {
  try {
    logger.info('Initializing scrapers...');
    
    const scrapersDir = path.join(__dirname, '../scrapers');
    const scraperFiles = fs.readdirSync(scrapersDir)
      .filter(file => file !== 'base.js' && file.endsWith('.js'));
    
    const initializedScrapers = [];
    
    for (const file of scraperFiles) {
      try {
        const ScraperClass = require(path.join(scrapersDir, file));
        const scraperId = file.replace('.js', '');
        
        // Create instance
        const scraper = new ScraperClass();
        
        // Schedule using default or environment cron expression
        const cronExpression = process.env.SCHEDULE_CRON_EXPRESSION || '0 0 * * *'; // Default: daily at midnight
        
        scheduleScraper(scraperId, cronExpression, async () => {
          return scraper.scrape();
        }, {
          retry: true,
          maxRetries: 3,
          retryDelay: 300000 // 5 minutes
        });
        
        initializedScrapers.push({
          id: scraperId,
          name: scraper.name,
          cronExpression
        });
        
        logger.info(`Initialized scraper: ${scraperId}`);
      } catch (error) {
        logger.error(`Error initializing scraper ${file}: ${error.message}`);
      }
    }
    
    logger.info(`Initialized ${initializedScrapers.length} scrapers`);
    return initializedScrapers;
  } catch (error) {
    logger.error(`Error initializing scrapers: ${error.message}`);
    return [];
  }
}

module.exports = {
  scheduleScraper,
  stopScraper,
  getScheduleStatus,
  getExecutionHistory,
  initializeScrapers
};
EOL

# Create app.js
cat > ihoje/src/app.js << 'EOL'
const express = require('express');
const path = require('path');
const fs = require('fs');
const { testConnection } = require('./config/database');
const logger = require('./utils/logger');
const { initializeScrapers, getScheduleStatus } = require('./services/scheduler');
require('dotenv').config();

// Create Express application
const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static files from the public directory
app.use(express.static(path.join(__dirname, '../public')));

// Simple API endpoints for status
app.get('/api/status', (req, res) => {
  res.json({
    status: 'ok',
    uptime: process.uptime(),
    timestamp: new Date().toISOString()
  });
});

// Get scrapers status
app.get('/api/scrapers', (req, res) => {
  const scrapers = getScheduleStatus();
  res.json(scrapers);
});

// Manual trigger endpoint for scrapers
app.post('/api/scrapers/:id/run', async (req, res) => {
  const scraperId = req.params.id;
  
  try {
    // Try to dynamically load the scraper
    const scraperPath = path.join(__dirname, 'scrapers', `${scraperId}.js`);
    
    if (!fs.existsSync(scraperPath)) {
      return res.status(404).json({
        status: 'error',
        message: `Scraper ${scraperId} not found`
      });
    }
    
    // Import the scraper class
    const ScraperClass = require(scraperPath);
    const scraper = new ScraperClass();
    
    // Run the scraper
    logger.info(`Manually triggered scraper: ${scraperId}`);
    
    // Run asynchronously to not block the response
    res.json({
      status: 'started',
      message: `Scraper ${scraperId} started`
    });
    
    // Execute the scraper
    try {
      await scraper.scrape();
      logger.info(`Manually triggered scraper ${scraperId} completed successfully`);
    } catch (error) {
      logger.error(`Error in manually triggered scraper ${scraperId}: ${error.message}`);
    }
  } catch (error) {
    logger.error(`Error starting scraper ${scraperId}: ${error.message}`);
    res.status(500).json({
      status: 'error',
      message: `Error starting scraper: ${error.message}`
    });
  }
});

// Start the server
async function startServer() {
  try {
    // Test database connection
    const dbConnected = await testConnection();
    
    if (!dbConnected) {
      logger.error('Failed to connect to database. Please check your credentials.');
      process.exit(1);
    }
    
    // Initialize scrapers
    await initializeScrapers();
    
    // Start the Express server
    app.listen(PORT, () => {
      logger.info(`Server started on port ${PORT}`);
      logger.info(`API available at http://localhost:${PORT}/api/status`);
    });
  } catch (error) {
    logger.error(`Failed to start server: ${error.message}`);
    process.exit(1);
  }
}

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  logger.error(`Uncaught Exception: ${error.message}`);
  logger.error(error.stack);
  process.exit(1);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled Promise Rejection');
  logger.error(reason);
});

// Handle graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM received. Shutting down gracefully...');
  process.exit(0);
});

process.on('SIGINT', () => {
  logger.info('SIGINT received. Shutting down gracefully...');
  process.exit(0);
});

// Start the server
startServer();
EOL

# Create supabase-schema.sql
cat > ihoje/supabase-schema.sql << 'EOL'
-- Create venues table
CREATE TABLE IF NOT EXISTS venues (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  address TEXT,
  city TEXT,
  state TEXT,
  country TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create events table
CREATE TABLE IF NOT EXISTS events (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  date TIMESTAMP WITH TIME ZONE,
  venue_id BIGINT REFERENCES venues(id),
  description TEXT,
  image_url TEXT,
  source TEXT,
  source_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create prices table
CREATE TABLE IF NOT EXISTS prices (
  id BIGSERIAL PRIMARY KEY,
  event_id BIGINT REFERENCES events(id) ON DELETE CASCADE,
  price_type TEXT,
  price_value DECIMAL(10, 2),
  currency TEXT DEFAULT '$',
  availability TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create price_history table for tracking changes
CREATE TABLE IF NOT EXISTS price_history (
  id BIGSERIAL PRIMARY KEY,
  event_id BIGINT REFERENCES events(id) ON DELETE CASCADE,
  changes JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS events_venue_id_idx ON events(venue_id);
CREATE INDEX IF NOT EXISTS events_date_idx ON events(date);
CREATE INDEX IF NOT EXISTS events_name_idx ON events(name);
CREATE INDEX IF NOT EXISTS prices_event_id_idx ON prices(event_id);
CREATE INDEX IF NOT EXISTS venues_name_idx ON venues(name);
CREATE INDEX IF NOT EXISTS venues_city_idx ON venues(city);

-- Create a view for event summaries with venue information
CREATE OR REPLACE VIEW event_summaries AS
SELECT 
  e.id,
  e.name,
  e.date,
  v.name AS venue_name,
  v.city,
  v.state,
  v.country,
  e.image_url,
  MIN(p.price_value) AS min_price,
  MAX(p.price_value) AS max_price,
  p.currency,
  CASE 
    WHEN e.date < CURRENT_TIMESTAMP THEN 'past'
    ELSE 'upcoming'
  END AS event_status
FROM events e
LEFT JOIN venues v ON e.venue_id = v.id
LEFT JOIN prices p ON e.id = p.event_id
GROUP BY e.id, v.id, p.currency;

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = CURRENT_TIMESTAMP;
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for automatic timestamp updates
CREATE TRIGGER update_events_updated_at
BEFORE UPDATE ON events
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_venues_updated_at
BEFORE UPDATE ON venues
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_prices_updated_at
BEFORE UPDATE ON prices
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Create a bucket for event images in storage
INSERT INTO storage.buckets (id, name, public)
VALUES ('event-images', 'Event Images', true)
ON CONFLICT (id) DO NOTHING;

-- Set up policies for the storage bucket to allow public access to images
CREATE POLICY "Public Access for Event Images"
ON storage.objects FOR SELECT
USING (bucket_id = 'event-images');

-- RLS policies for application
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE venues ENABLE ROW LEVEL SECURITY;
ALTER TABLE prices ENABLE ROW LEVEL SECURITY;
ALTER TABLE price_history ENABLE ROW LEVEL SECURITY;

-- Policy for authenticated users to manage events
CREATE POLICY "Authenticated users can manage events"
ON events FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Policy for authenticated users to manage venues
CREATE POLICY "Authenticated users can manage venues"
ON venues FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Policy for authenticated users to manage prices
CREATE POLICY "Authenticated users can manage prices"
ON prices FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Policy for authenticated users to manage price history
CREATE POLICY "Authenticated users can manage price history"
ON price_history FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Allow anonymous users to read events and related data
CREATE POLICY "Anonymous users can read events"
ON events FOR SELECT
TO anon
USING (true);

CREATE POLICY "Anonymous users can read venues"
ON venues FOR SELECT
TO anon
USING (true);

CREATE POLICY "Anonymous users can read prices"
ON prices FOR SELECT
TO anon
USING (true);
EOL

echo "Project setup complete!"
echo "Run the following commands to get started:"
echo "cd ihoje"
echo "npm install"
echo "cp .env.example .env"
echo "# Edit .env with your Supabase credentials"
echo "npm start"
