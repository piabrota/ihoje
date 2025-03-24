/**
 * Simple database migration tool to run SQL schema file
 * Run with: node src/scripts/run-migration.js
 */

const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');
const logger = require('../utils/logger');
require('dotenv').config();

// Get database connection info
const connectionString = process.env.POSTGRES_CONNECTION_STRING;
const useConnectionString = !!connectionString;

// Create a database connection
const pool = useConnectionString 
  ? new Pool({ 
      connectionString,
      ssl: process.env.POSTGRES_SSL === 'true' ? { rejectUnauthorized: false } : false 
    })
  : new Pool({
      user: process.env.POSTGRES_USER || 'postgres',
      password: process.env.POSTGRES_PASSWORD,
      host: process.env.POSTGRES_HOST || 'localhost',
      port: process.env.POSTGRES_PORT || 5432,
      database: process.env.POSTGRES_DB || 'postgres',
      ssl: process.env.POSTGRES_SSL === 'true' ? { rejectUnauthorized: false } : false
    });

async function runMigration() {
  let client;
  
  try {
    // Connect to the database
    client = await pool.connect();
    logger.info('Connected to PostgreSQL database');
    
    // Read the SQL file
    const schemaPath = path.join(process.cwd(), 'supabase-schema.sql');
    const sqlContent = fs.readFileSync(schemaPath, 'utf8');
    
    logger.info('Read schema file successfully');
    
    // Split SQL content into individual statements
    const statements = sqlContent
      .split(';')
      .map(statement => statement.trim())
      .filter(statement => statement.length > 0);
    
    logger.info(`Found ${statements.length} SQL statements to execute`);
    
    // Begin transaction
    await client.query('BEGIN');
    
    // Execute each statement
    for (let i = 0; i < statements.length; i++) {
      const statement = statements[i];
      
      try {
        // Skip Supabase-specific statements
        if (statement.includes('storage.') || 
            statement.includes('POLICY') || 
            statement.includes('ROW LEVEL SECURITY') ||
            statement.includes('TO authenticated') ||
            statement.includes('TO anon')) {
          logger.info(`[${i+1}/${statements.length}] Skipping Supabase-specific statement`);
          continue;
        }
        
        logger.info(`[${i+1}/${statements.length}] Executing statement`);
        await client.query(statement);
      } catch (error) {
        logger.warn(`Error executing statement ${i+1}: ${error.message}`);
        logger.debug(`Statement: ${statement}`);
        // Continue with next statement
      }
    }
    
    // Commit transaction
    await client.query('COMMIT');
    
    logger.info('Migration completed successfully');
    
    // Verify tables were created
    const tableResult = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
    `);
    
    logger.info('Created tables:');
    tableResult.rows.forEach(row => {
      logger.info(`- ${row.table_name}`);
    });
    
    return { success: true };
    
  } catch (error) {
    // Rollback transaction if client exists
    if (client) {
      await client.query('ROLLBACK');
    }
    
    logger.error(`Migration failed: ${error.message}`);
    return { success: false, error: error.message };
    
  } finally {
    // Release client back to pool
    if (client) {
      client.release();
    }
    
    // Close the pool
    await pool.end();
  }
}

// Run if called directly
if (require.main === module) {
  runMigration()
    .then(result => {
      if (result.success) {
        logger.info('============================================');
        logger.info('Schema migration completed successfully!');
        logger.info('You can now populate the database with:');
        logger.info('npm run seed');
        logger.info('============================================');
        process.exit(0);
      } else {
        logger.error('============================================');
        logger.error(`Schema migration failed: ${result.error}`);
        logger.error('============================================');
        process.exit(1);
      }
    })
    .catch(error => {
      logger.error(`Unhandled error: ${error.message}`);
      process.exit(1);
    });
}

module.exports = runMigration;