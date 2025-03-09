# List all available commands
default:
    @just --list

# Install dependencies
install:
    npm install

# Run development server
dev:
    npm run dev

# Run production server
start:
    npm start

# Run tests
test:
    npm test

# Run specific test
test-one NAME:
    npm run test -- -t "{{NAME}}"

# Run linter
lint:
    npm run lint

# Run manual scrape
scrape:
    npm run scrape

# Build Docker image
docker-build:
    docker build -t ihoje:latest .

# Run application in Docker
docker-run:
    docker run -p 3000:3000 --env-file .env ihoje:latest

# Run Puppeteer hello world test
test-puppeteer:
    node tests/puppeteer-test.js

# Setup project (copy env file, create directories)
setup:
    cp -n .env.example .env || true
    mkdir -p logs/history images
    @echo "Setup complete. Don't forget to update your .env file with your Supabase credentials."

# Clean log files
clean-logs:
    rm -rf logs/*.log logs/history/*.json

# Generate example scraper template
generate-scraper NAME:
    #!/bin/bash
    cat > src/scrapers/{{NAME}}.js << 'EOL'
    const BaseScraper = require('./base');
    const logger = require('../utils/logger');
    const { saveEvent, findExistingEvent } = require('../models/event');
    const { saveVenue, findVenueByName } = require('../models/venue');
    const { savePrices } = require('../models/price');

    class {{NAME}}Scraper extends BaseScraper {
      constructor() {
        super({
          name: '{{NAME}}',
          baseUrl: 'https://example.com',
        });
        
        this.selectors = {
          eventList: '.event-item',
          eventLink: 'a.event-link',
          eventName: '.event-title',
          eventDate: '.event-date',
          eventVenue: '.event-venue',
          eventPrice: '.event-price'
        };
      }
      
      async scrape() {
        try {
          logger.info(`Starting scrape for ${this.name}`);
          await this.init();
          
          // Implement your scraping logic here
          
          return [];
        } catch (error) {
          logger.error(`Error during scraping: ${error.message}`);
          throw error;
        } finally {
          await this.close();
        }
      }
    }

    module.exports = {{NAME}}Scraper;
    EOL
    @echo "Created new scraper: src/scrapers/{{NAME}}.js"