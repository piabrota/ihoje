const puppeteer = require('puppeteer');
const fs = require('fs').promises;
const path = require('path');
const { v4 } = require('uuid');
const uuidv4 = v4; // For backward compatibility
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
      headless: 'new',
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
      const imagesDir = path.join(__dirname, '../../../images');
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
