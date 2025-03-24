# iHoje

An event ticket aggregator service that scrapes and aggregates ticket information from various websites.

## Project Overview

iHoje monitors event websites, retrieves ticket information, and stores it in a structured database. It allows users to compare prices and availability across different sources.

## Project Structure

```
ihoje/
├── .env.example           # Environment variables template
├── images/                # Downloaded event images
├── logs/                  # Application logs
│   └── history/           # Scraper execution history
├── package.json           # Node.js dependencies
├── src/                   # Source code
│   ├── app.js             # Main application entry point
│   ├── config/            # Configuration files
│   │   ├── database.js    # Supabase database connection
│   │   └── scraper.js     # Scraper configuration
│   ├── models/            # Database models
│   │   ├── event.js       # Event data model
│   │   ├── price.js       # Price data model
│   │   └── venue.js       # Venue data model
│   ├── scrapers/          # Web scrapers
│   │   ├── base.js        # Base scraper class
│   │   └── example-site.js # Example site implementation
│   ├── services/          # Business logic services
│   │   └── scheduler.js   # Scraper scheduling service
│   └── utils/             # Utility functions
│       ├── helpers.js     # Helper functions
│       └── logger.js      # Logging utility
├── supabase-schema.sql    # Database schema for Supabase
└── tests/                 # Test files
```

## Prerequisites

- Node.js >= 22.0.0
- Supabase account (for database)
- Docker (optional, for containerization)
- Just command runner (optional, for simplified commands)

## Setup

### 1. Clone the repository

```bash
git clone https://github.com/yourusername/ihoje.git
cd ihoje
```

### 2. Install dependencies

```bash
npm install
```

### 3. Configure environment variables

```bash
cp .env.example .env
```

Edit the `.env` file with your configuration:

```
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
PROXY_LIST=http://username:password@proxy1.example.com:8080

# Scheduling
SCHEDULE_CRON_EXPRESSION=0 0 * * *  # Run daily at midnight

# Logging
LOG_LEVEL=info
```

### 4. Setup Supabase

1. Create a new Supabase project
2. Execute the SQL script in `supabase-schema.sql` in the Supabase SQL editor
3. Create a storage bucket named `event-images`
4. Update your `.env` file with the Supabase URL and anon key
5. Populate the database with fake data for testing and frontend development:
   ```bash
   npm run seed
   ```
   This will create test venues, events, and pricing data with realistic Brazilian location information.

### 5. Hello World Test for Puppeteer

Create a test file in the `tests` directory:

```bash
mkdir -p tests
```

Create a file `tests/puppeteer-test.js`:

```javascript
const puppeteer = require('puppeteer');
const logger = require('../src/utils/logger');

async function testPuppeteer() {
  logger.info('Starting Puppeteer test');
  
  const browser = await puppeteer.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });
  
  try {
    const page = await browser.newPage();
    
    // Set viewport
    await page.setViewport({ width: 1920, height: 1080 });
    
    // Navigate to a test site
    logger.info('Navigating to example.com');
    await page.goto('https://example.com', { waitUntil: 'networkidle2' });
    
    // Take a screenshot
    await page.screenshot({ path: 'tests/screenshot.png' });
    
    // Get page title
    const title = await page.title();
    logger.info(`Page title: ${title}`);
    
    // Get some content
    const content = await page.$eval('h1', el => el.textContent);
    logger.info(`Page content: ${content}`);
    
    logger.info('Puppeteer test completed successfully');
    return { success: true, title, content };
  } catch (error) {
    logger.error(`Puppeteer test failed: ${error.message}`);
    return { success: false, error: error.message };
  } finally {
    await browser.close();
  }
}

// Run the test if this file is executed directly
if (require.main === module) {
  testPuppeteer()
    .then(result => {
      console.log('Test result:', result);
      process.exit(result.success ? 0 : 1);
    })
    .catch(error => {
      console.error('Error running test:', error);
      process.exit(1);
    });
}

module.exports = testPuppeteer;
```

## Database Seeding

The project includes a script to populate the database with fake data for development and testing purposes.

### Running the Seed Script

```bash
npm run seed
```

This script will:
1. Clear any existing data in the Supabase database
2. Create 20 fake venues with realistic Brazilian addresses
3. Create 100 fake events with various properties (multi-day events, different location types, etc.)
4. Add pricing information for each event (full, half, and VIP prices)
5. Generate random images for the events using picsum.photos

The seeding process helps frontend developers build and test UI components with realistic data structures.

### Configuration

You can modify the seeding parameters in `src/scripts/populate-db.js`:
- `NUM_VENUES`: Number of venues to create
- `NUM_EVENTS`: Number of events to create
- `BATCH_SIZE`: Number of events to process in each batch

## Available Commands

### NPM Commands

```bash
# Start the application
npm start

# Start with nodemon for development (auto-restart on file changes)
npm run dev

# Run tests
npm test

# Run a specific test
npm run test -- -t "test name"

# Run ESLint
npm run lint

# Run manual scraper
npm run scrape

# Populate database with fake data
npm run seed
```

### Creating a Dockerfile

Create a `Dockerfile` in the project root:

```dockerfile
FROM node:18-slim

# Install dependencies for Puppeteer
RUN apt-get update && apt-get install -y \
    ca-certificates \
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libc6 \
    libcairo2 \
    libcups2 \
    libdbus-1-3 \
    libexpat1 \
    libfontconfig1 \
    libgbm1 \
    libgcc1 \
    libglib2.0-0 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libstdc++6 \
    libx11-6 \
    libx11-xcb1 \
    libxcb1 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxi6 \
    libxrandr2 \
    libxrender1 \
    libxss1 \
    libxtst6 \
    lsb-release \
    wget \
    xdg-utils \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy the rest of the application
COPY . .

# Create necessary directories
RUN mkdir -p logs/history images

# Expose the port the app runs on
EXPOSE 3000

# Command to run the application
CMD ["npm", "start"]
```

### Justfile

Create a `justfile` in the project root for command aggregation:

```makefile
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
```

## Troubleshooting

### Common Issues with Puppeteer

1. **Browser Launch Fails**:
   - Ensure all dependencies are installed
   - Try running with `--no-sandbox` flag (included in the Docker setup)

2. **Proxy Issues**:
   - Check that your proxy URL is correctly formatted
   - Verify proxy credentials and accessibility

3. **Element Selection Fails**:
   - Use `page.waitForSelector()` to ensure elements are loaded
   - Check that your CSS selectors are correct
   - Use tools like DevTools to verify selectors

### Supabase Connection Issues

1. **Authentication Fails**:
   - Verify your Supabase URL and anon key in the `.env` file
   - Check that your IP is not blocked by Supabase

2. **Schema Errors**:
   - Ensure you've run the complete SQL script in `supabase-schema.sql`
   - Check for any errors in the Supabase SQL editor

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.