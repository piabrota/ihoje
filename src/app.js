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
