/**
 * Script to test PostgreSQL connectivity and create necessary tables
 * Run with: node src/scripts/test-postgres.js
 */

const db = require('../config/postgres');
const logger = require('../utils/logger');
const fs = require('fs');
const path = require('path');

// Function to read and execute SQL schema
async function createDatabaseSchema() {
  try {
    logger.info('Setting up database schema...');
    
    // Read the schema file
    const schemaPath = path.join(process.cwd(), 'supabase-schema.sql');
    let schema = fs.readFileSync(schemaPath, 'utf8');
    
    // Modify the schema to use CREATE TABLE IF NOT EXISTS
    schema = schema.replace(/CREATE TABLE IF NOT EXISTS/g, 'CREATE TABLE IF NOT EXISTS');
    schema = schema.replace(/CREATE TABLE(?! IF NOT EXISTS)/g, 'CREATE TABLE IF NOT EXISTS');
    
    // Replace index creation to avoid errors if they already exist
    schema = schema.replace(/CREATE INDEX(?! IF NOT EXISTS)/g, 'CREATE INDEX IF NOT EXISTS');
    
    // Replace sequence commands with safer versions
    schema = schema.replace(/CREATE SEQUENCE/g, 'CREATE SEQUENCE IF NOT EXISTS');
    
    // Replace view creation
    schema = schema.replace(/CREATE OR REPLACE VIEW/g, 'CREATE OR REPLACE VIEW');
    
    // Replace function creation
    schema = schema.replace(/CREATE OR REPLACE FUNCTION/g, 'CREATE OR REPLACE FUNCTION');
    
    // Split the schema into separate statements
    const statements = schema
      .split(';')
      .map(statement => statement.trim())
      .filter(statement => statement.length > 0);
    
    // Execute each statement in a transaction
    await db.transaction(async (client) => {
      for (const statement of statements) {
        try {
          // Skip problematic statements related to Supabase-specific features
          if (statement.includes('storage.') || 
              statement.includes('POLICY') || 
              statement.includes('ROW LEVEL SECURITY') ||
              statement.includes('TO authenticated') ||
              statement.includes('TO anon')) {
            logger.info(`Skipping Supabase-specific statement: ${statement.substring(0, 50)}...`);
            continue;
          }
          
          logger.info(`Executing: ${statement.substring(0, 50)}...`);
          await client.query(statement);
        } catch (error) {
          logger.warn(`Error executing statement: ${error.message}`);
          logger.warn(`Statement: ${statement}`);
          // Continue with next statement
        }
      }
    });
    
    logger.info('Database schema setup complete');
    return true;
  } catch (error) {
    logger.error(`Error setting up database schema: ${error.message}`);
    return false;
  }
}

// Function to test simple query
async function testQuery() {
  try {
    logger.info('Testing simple query...');
    
    // Test a simple SELECT query
    const result = await db.query('SELECT NOW() as current_time');
    logger.info(`Current database time: ${result.rows[0].current_time}`);
    
    // Test venues table
    const venuesResult = await db.query('SELECT COUNT(*) FROM venues');
    logger.info(`Number of venues in database: ${venuesResult.rows[0].count}`);
    
    // Test events table
    const eventsResult = await db.query('SELECT COUNT(*) FROM events');
    logger.info(`Number of events in database: ${eventsResult.rows[0].count}`);
    
    // Test prices table
    const pricesResult = await db.query('SELECT COUNT(*) FROM prices');
    logger.info(`Number of prices in database: ${pricesResult.rows[0].count}`);
    
    return true;
  } catch (error) {
    logger.error(`Error testing query: ${error.message}`);
    return false;
  }
}

// Main function
async function testDatabase() {
  try {
    logger.info('Starting PostgreSQL connection test...');
    
    // Test connection
    const connected = await db.testConnection();
    if (!connected) {
      throw new Error('Failed to connect to PostgreSQL database');
    }
    
    // Create schema
    const schemaCreated = await createDatabaseSchema();
    if (!schemaCreated) {
      throw new Error('Failed to create database schema');
    }
    
    // Test query
    const querySuccess = await testQuery();
    if (!querySuccess) {
      throw new Error('Failed to execute test query');
    }
    
    logger.info('===============================================');
    logger.info('PostgreSQL connectivity test SUCCESSFUL!');
    logger.info('Database schema is properly set up.');
    logger.info('===============================================');
    logger.info('You can now populate the database with:');
    logger.info('npm run seed');
    logger.info('===============================================');
    
    return { success: true };
  } catch (error) {
    logger.error('===============================================');
    logger.error(`PostgreSQL connectivity test FAILED: ${error.message}`);
    logger.error('===============================================');
    logger.error('Please check your .env file settings:');
    logger.error('POSTGRES_CONNECTION_STRING or individual parameters');
    logger.error('===============================================');
    return { success: false, error: error.message };
  } finally {
    // Close pool
    db.pool.end();
  }
}

// Run if called directly
if (require.main === module) {
  testDatabase()
    .then(result => {
      process.exit(result.success ? 0 : 1);
    })
    .catch(error => {
      logger.error(`Unhandled error: ${error.message}`);
      process.exit(1);
    });
}

module.exports = testDatabase;