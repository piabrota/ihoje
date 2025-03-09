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
