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
    const historyDir = path.join(__dirname, '../../../logs/history');
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
    const historyDir = path.join(__dirname, '../../../logs/history');
    const historyFile = path.join(historyDir, `${scraperId}.json`);
    
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
