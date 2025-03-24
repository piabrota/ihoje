const fs = require('fs');
const path = require('path');
const logger = require('../utils/logger');
require('dotenv').config();

/**
 * Manual scraper script
 * This script can be used to manually trigger scraping of specific sites
 */
async function runManualScrape() {
  try {
    logger.info('Starting manual scrape process');
    
    // Get the scraper ID from command line arguments
    const scraperId = process.argv[2];
    
    if (!scraperId) {
      logger.info('Available scrapers:');
      
      // Find all scraper files
      const scraperDir = path.join(__dirname, '../scrapers');
      const files = fs.readdirSync(scraperDir)
        .filter(file => file !== 'base.js' && file.endsWith('.js'))
        .map(file => file.replace('.js', ''));
      
      files.forEach(file => {
        logger.info(`- ${file}`);
      });
      
      logger.info('\nUsage: npm run scrape <scraper-id>');
      return;
    }
    
    // Check if scraper exists
    const scraperPath = path.join(__dirname, '../scrapers', `${scraperId}.js`);
    
    if (!fs.existsSync(scraperPath)) {
      logger.error(`Scraper "${scraperId}" not found`);
      return;
    }
    
    // Import and run the scraper
    const ScraperClass = require(scraperPath);
    const scraper = new ScraperClass();
    
    logger.info(`Running scraper: ${scraperId}`);
    
    // Execute the scraper
    const result = await scraper.scrape();
    
    logger.info(`Scraper ${scraperId} completed successfully`);
    logger.info(`Results: ${JSON.stringify(result, null, 2)}`);
    
  } catch (error) {
    logger.error(`Error in manual scrape: ${error.message}`);
    logger.error(error.stack);
    process.exit(1);
  }
}

// Run the manual scrape if this file is executed directly
if (require.main === module) {
  runManualScrape()
    .catch(error => {
      logger.error('Fatal error during manual scrape:', error);
      process.exit(1);
    });
}

module.exports = runManualScrape;