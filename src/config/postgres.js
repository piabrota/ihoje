const { Pool } = require('pg');
const logger = require('../utils/logger');
require('dotenv').config();

// PostgreSQL connection config
let pool;

// If connection string is provided, use it
if (process.env.POSTGRES_CONNECTION_STRING) {
  logger.info('Using PostgreSQL connection string');
  pool = new Pool({
    connectionString: process.env.POSTGRES_CONNECTION_STRING,
    ssl: process.env.POSTGRES_SSL === 'true' ? 
      { rejectUnauthorized: false } : 
      false
  });
} else {
  // Otherwise use individual parameters
  logger.info('Using individual PostgreSQL connection parameters');
  pool = new Pool({
    user: process.env.POSTGRES_USER || 'postgres',
    password: process.env.POSTGRES_PASSWORD,
    host: process.env.POSTGRES_HOST || 'localhost',
    port: process.env.POSTGRES_PORT || 5432,
    database: process.env.POSTGRES_DB || 'postgres',
    ssl: process.env.POSTGRES_SSL === 'true' ? 
      { rejectUnauthorized: false } : 
      false
  });
}

// Test the database connection
async function testConnection() {
  let client;
  try {
    client = await pool.connect();
    const result = await client.query('SELECT NOW() as now');
    logger.info(`Successfully connected to PostgreSQL database: ${result.rows[0].now}`);
    return true;
  } catch (error) {
    logger.error(`Failed to connect to PostgreSQL database: ${error.message}`);
    return false;
  } finally {
    if (client) client.release();
  }
}

// Helper function to execute queries
async function query(text, params = []) {
  let client;
  try {
    client = await pool.connect();
    const start = Date.now();
    const result = await client.query(text, params);
    const duration = Date.now() - start;

    if (duration > 500) {
      // Log slow queries
      logger.warn(`Slow query (${duration}ms): ${text}`);
    }

    return { rows: result.rows, rowCount: result.rowCount };
  } catch (error) {
    logger.error(`Database query error: ${error.message}`);
    logger.error(`Query: ${text}`);
    logger.error(`Params: ${JSON.stringify(params)}`);
    throw error;
  } finally {
    if (client) client.release();
  }
}

// Transaction helper
async function transaction(callback) {
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    const result = await callback(client);
    await client.query('COMMIT');
    return result;
  } catch (error) {
    await client.query('ROLLBACK');
    logger.error(`Transaction error: ${error.message}`);
    throw error;
  } finally {
    client.release();
  }
}

module.exports = {
  pool,
  query,
  transaction,
  testConnection
};