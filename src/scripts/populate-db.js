/**
 * Script to populate the database with fake data
 * Run with: node src/scripts/populate-db.js
 */

const db = require('../config/postgres');
const logger = require('../utils/logger');
const fs = require('fs');
const { faker } = require('@faker-js/faker/locale/pt_BR');
const { v4: uuidv4 } = require('uuid');

// Configuration
const NUM_VENUES = 20;
const NUM_EVENTS = 100;
const BATCH_SIZE = 10;

// Arrays to hold Brazilian states and cities
const BRAZILIAN_STATES = [
  'SP', 'RJ', 'MG', 'RS', 'PR', 'BA', 'SC', 'PE', 'CE', 'GO'
];

const BRAZILIAN_CITIES = {
  'SP': ['São Paulo', 'Campinas', 'Santos', 'Ribeirão Preto', 'São José dos Campos'],
  'RJ': ['Rio de Janeiro', 'Niterói', 'Petrópolis', 'Volta Redonda', 'Campos dos Goytacazes'],
  'MG': ['Belo Horizonte', 'Uberlândia', 'Contagem', 'Juiz de Fora', 'Betim'],
  'RS': ['Porto Alegre', 'Caxias do Sul', 'Pelotas', 'Canoas', 'Santa Maria'],
  'PR': ['Curitiba', 'Londrina', 'Maringá', 'Ponta Grossa', 'Cascavel'],
  'BA': ['Salvador', 'Feira de Santana', 'Vitória da Conquista', 'Camaçari', 'Juazeiro'],
  'SC': ['Florianópolis', 'Joinville', 'Blumenau', 'São José', 'Criciúma'],
  'PE': ['Recife', 'Jaboatão dos Guararapes', 'Olinda', 'Caruaru', 'Petrolina'],
  'CE': ['Fortaleza', 'Caucaia', 'Juazeiro do Norte', 'Maracanaú', 'Sobral'],
  'GO': ['Goiânia', 'Aparecida de Goiânia', 'Anápolis', 'Rio Verde', 'Luziânia']
};

// Event categories
const EVENT_CATEGORIES = [
  'Show', 'Festival', 'Teatro', 'Esporte', 'Exposição', 
  'Conferência', 'Workshop', 'Standup', 'Cinema', 'Gastronomia'
];

// Venue types
const VENUE_TYPES = [
  'Arena', 'Teatro', 'Casa de Shows', 'Estádio', 'Centro de Convenções',
  'Clube', 'Bar', 'Restaurante', 'Museu', 'Galeria', 'Parque'
];

// Event producers
const EVENT_PRODUCERS = [
  'Live Nation', 'T4F', 'Eventim', 'Ingresse', 'Sympla',
  'Ticket360', 'Pixelti', 'Mega Eventos', 'Brasil Shows', 'Festival Produções'
];

// Function to get a random item from an array
const getRandomItem = (array) => array[Math.floor(Math.random() * array.length)];

// Function to get a random future date
const getRandomFutureDate = (daysOffset = 0) => {
  const date = new Date();
  date.setDate(date.getDate() + daysOffset + Math.floor(Math.random() * 180));
  return date;
};

// Function to get a random price
const getRandomPrice = (min = 5000, max = 50000) => {
  return Math.floor(Math.random() * (max - min + 1)) + min;
};

// Function to clear existing data
async function clearData() {
  logger.info('Clearing existing data...');

  try {
    // Use a transaction to ensure all deletions are atomic
    await db.transaction(async (client) => {
      // Delete all prices first (due to foreign key constraints)
      await client.query('DELETE FROM prices WHERE id > 0');
      
      // Delete all events
      await client.query('DELETE FROM events WHERE id > 0');
      
      // Delete all venues
      await client.query('DELETE FROM venues WHERE id > 0');
      
      // Reset sequences
      await client.query('ALTER SEQUENCE prices_id_seq RESTART WITH 1');
      await client.query('ALTER SEQUENCE events_id_seq RESTART WITH 1');
      await client.query('ALTER SEQUENCE venues_id_seq RESTART WITH 1');
    });

    logger.info('All existing data cleared');
  } catch (error) {
    logger.error(`Error clearing data: ${error.message}`);
    throw error;
  }
}

// Function to create fake venues
async function createVenues() {
  logger.info(`Creating ${NUM_VENUES} fake venues...`);
  const venues = [];

  try {
    for (let i = 0; i < NUM_VENUES; i++) {
      const state = getRandomItem(BRAZILIAN_STATES);
      const city = getRandomItem(BRAZILIAN_CITIES[state]);
      const venueType = getRandomItem(VENUE_TYPES);
      
      const venue = {
        name: `${venueType} ${faker.company.name()}`,
        address: `${faker.location.street()}, ${faker.number.int({min: 1, max: 9999})}`,
        city,
        state,
        country: 'Brasil',
        created_at: new Date(),
        updated_at: new Date()
      };
      
      const query = {
        text: `
          INSERT INTO venues (name, address, city, state, country, created_at, updated_at)
          VALUES ($1, $2, $3, $4, $5, $6, $7)
          RETURNING *
        `,
        values: [
          venue.name, 
          venue.address, 
          venue.city,
          venue.state,
          venue.country,
          venue.created_at,
          venue.updated_at
        ]
      };
      
      const result = await db.query(query.text, query.values);
      const newVenue = result.rows[0];
      venues.push(newVenue);
      
      logger.info(`Created venue: ${venue.name} (${newVenue.id})`);
    }
    
    return venues;
  } catch (error) {
    logger.error(`Error creating venues: ${error.message}`);
    throw error;
  }
}

// Function to create fake events
async function createEvents(venues) {
  logger.info(`Creating ${NUM_EVENTS} fake events...`);
  const events = [];

  try {
    for (let i = 0; i < NUM_EVENTS; i++) {
      // Determine if it's a multi-day event (20% chance)
      const isMultiDay = Math.random() < 0.2;
      const startDate = getRandomFutureDate();
      
      // For multi-day events, end date is 1-3 days after start date
      const endDate = isMultiDay ? 
        new Date(startDate.getTime() + (Math.floor(Math.random() * 3) + 1) * 24 * 60 * 60 * 1000) : 
        null;
      
      // Select a random venue
      const venue = getRandomItem(venues);
      
      // Location type - 70% onsite, 20% remote, 10% hybrid
      const locationType = Math.random() < 0.7 ? 'onsite' : (Math.random() < 0.67 ? 'remote' : 'hybrid');
      
      // Determine state and city (may be different from venue for remote events)
      const state = locationType === 'onsite' ? venue.state : getRandomItem(BRAZILIAN_STATES);
      const city = locationType === 'onsite' ? venue.city : getRandomItem(BRAZILIAN_CITIES[state]);
      
      // Set up pricing
      const basePrice = getRandomPrice();
      const feePercentage = Math.random() * 0.15; // 0% to 15% fee
      const fee = Math.floor(basePrice * feePercentage);
      const startPrice = basePrice;
      
      // Generate event data
      const category = getRandomItem(EVENT_CATEGORIES);
      const hasHalf = Math.random() < 0.7; // 70% chance of having half-price tickets
      const isSoldout = Math.random() < 0.1; // 10% chance of being sold out
      const batch = Math.floor(Math.random() * 5) + 1; // Batch 1-5
      
      const query = {
        text: `
          INSERT INTO events (
            name, date, date_end, venue_id, description, 
            image_url, source, source_url, location_type, 
            state, city, start_price, price, fee, 
            batch, has_half, is_soldout, producer, share_link,
            created_at, updated_at
          )
          VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21)
          RETURNING *
        `,
        values: [
          `${category} - ${faker.lorem.words(3)}`, // name
          startDate, // date
          endDate, // date_end
          venue.id, // venue_id
          faker.lorem.paragraphs(2), // description
          `https://picsum.photos/seed/${uuidv4().slice(0, 8)}/800/600`, // image_url
          'seed', // source
          null, // source_url
          locationType, // location_type
          state, // state
          city, // city
          startPrice, // start_price
          basePrice, // price
          fee, // fee
          batch, // batch
          hasHalf, // has_half
          isSoldout, // is_soldout
          getRandomItem(EVENT_PRODUCERS), // producer
          `https://ihoje.com/event/${uuidv4().slice(0, 8)}`, // share_link
          new Date(), // created_at
          new Date() // updated_at
        ]
      };
      
      const result = await db.query(query.text, query.values);
      const newEvent = result.rows[0];
      events.push(newEvent);
      
      // Create prices for the event
      await createPrices(newEvent.id, basePrice, hasHalf);
      
      logger.info(`Created event: ${newEvent.name} (${newEvent.id})`);
      
      // Process in batches to avoid overwhelming the database
      if (i > 0 && i % BATCH_SIZE === 0) {
        logger.info(`Processed ${i} events so far...`);
        await new Promise(resolve => setTimeout(resolve, 1000)); // Small delay
      }
    }
    
    return events;
  } catch (error) {
    logger.error(`Error creating events: ${error.message}`);
    throw error;
  }
}

// Function to create prices for an event
async function createPrices(eventId, basePrice, hasHalf) {
  try {
    // Full price
    const fullPriceQuery = {
      text: `
        INSERT INTO prices (event_id, price_type, price_value, currency, availability, created_at, updated_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        RETURNING id
      `,
      values: [
        eventId,
        'FULL',
        basePrice / 100, // Convert from cents to currency units
        'BRL',
        'AVAILABLE',
        new Date(),
        new Date()
      ]
    };
    
    await db.query(fullPriceQuery.text, fullPriceQuery.values);
    
    // Half price if applicable
    if (hasHalf) {
      const halfPriceQuery = {
        text: `
          INSERT INTO prices (event_id, price_type, price_value, currency, availability, created_at, updated_at)
          VALUES ($1, $2, $3, $4, $5, $6, $7)
          RETURNING id
        `,
        values: [
          eventId,
          'HALF',
          (basePrice / 2) / 100, // Convert from cents to currency units
          'BRL',
          'AVAILABLE',
          new Date(),
          new Date()
        ]
      };
      
      await db.query(halfPriceQuery.text, halfPriceQuery.values);
    }
    
    // Add VIP price for some events (30% chance)
    if (Math.random() < 0.3) {
      const vipPrice = basePrice * (1.5 + Math.random());
      const vipPriceQuery = {
        text: `
          INSERT INTO prices (event_id, price_type, price_value, currency, availability, created_at, updated_at)
          VALUES ($1, $2, $3, $4, $5, $6, $7)
          RETURNING id
        `,
        values: [
          eventId,
          'VIP',
          vipPrice / 100, // Convert from cents to currency units
          'BRL',
          'LIMITED',
          new Date(),
          new Date()
        ]
      };
      
      await db.query(vipPriceQuery.text, vipPriceQuery.values);
    }
    
  } catch (error) {
    logger.error(`Error creating prices for event ${eventId}: ${error.message}`);
    throw error;
  }
}

// Main function to run the seeding
async function seedDatabase() {
  try {
    logger.info('Starting database seeding...');
    
    // Create necessary directories
    const dirs = ['logs', 'logs/history', 'images'];
    dirs.forEach(dir => {
      const path = `${process.cwd()}/${dir}`;
      if (!fs.existsSync(path)) {
        logger.info(`Creating directory: ${path}`);
        fs.mkdirSync(path, { recursive: true });
      }
    });
    
    // Clear existing data
    await clearData();
    
    // Create venues
    const venues = await createVenues();
    
    // Create events
    const events = await createEvents(venues);
    
    logger.info(`Database seeding completed. Created ${venues.length} venues and ${events.length} events.`);
    logger.info('You can now check the database to see the generated data.');
    
    return { success: true, venues: venues.length, events: events.length };
  } catch (error) {
    logger.error(`Database seeding failed: ${error.message}`);
    return { success: false, error: error.message };
  }
}

// Function to test database connection
async function testDatabaseConnection() {
  try {
    logger.info('Testing PostgreSQL database connection...');
    const isConnected = await db.testConnection();
    
    if (!isConnected) {
      throw new Error('Database connection test failed');
    }
    
    return true;
  } catch (error) {
    logger.error(`Database connection failed: ${error.message}`);
    logger.info('Please check your .env file for correct PostgreSQL credentials:');
    logger.info('POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_HOST, POSTGRES_PORT, POSTGRES_DB');
    return false;
  }
}

// Run the seed function if this file is executed directly
if (require.main === module) {
  // First test the database connection
  testDatabaseConnection()
    .then(connectionSuccessful => {
      if (!connectionSuccessful) {
        logger.error('Aborting seeding due to database connection failure');
        process.exit(1);
      }
      
      // If connection is successful, proceed with seeding
      return seedDatabase();
    })
    .then(result => {
      if (result && result.success) {
        logger.info(`Successfully seeded database with ${result.venues} venues and ${result.events} events.`);
      } else {
        logger.error(`Failed to seed database: ${result?.error || 'Unknown error'}`);
      }
      
      // Close the database pool
      db.pool.end();
      
      // Keep the process running for a moment to ensure logs are written
      setTimeout(() => process.exit(result && result.success ? 0 : 1), 1000);
    })
    .catch(error => {
      logger.error(`Unhandled error during seeding: ${error.message}`);
      // Close the database pool
      db.pool.end();
      process.exit(1);
    });
}

module.exports = seedDatabase;