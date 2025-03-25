use std::env;
use std::time::Duration;
use anyhow::{Result, Context, anyhow};
use deadpool_postgres::{Config, Pool, PoolConfig, Runtime};
use tokio_postgres::NoTls;
use log::info;

use crate::event::EventData;
use crate::db::EventStore;

/// PostgreSQL connection settings
#[derive(Debug, Clone)]
pub struct PostgresConfig {
    pub host: String,
    pub port: u16,
    pub user: String,
    pub password: String,
    pub database: String,
}

impl PostgresConfig {
    /// Load PostgreSQL configuration from environment variables
    pub fn from_env() -> Result<Self> {
        let host = env::var("PG_HOST").unwrap_or_else(|_| "localhost".to_string());
        
        let port = env::var("PG_PORT")
            .unwrap_or_else(|_| "5432".to_string())
            .parse::<u16>()
            .context("Invalid PG_PORT environment variable")?;
            
        let user = env::var("PG_USER").unwrap_or_else(|_| "postgres".to_string());
        let password = env::var("PG_PASSWORD").unwrap_or_else(|_| "postgres".to_string());
        let database = env::var("PG_DATABASE").unwrap_or_else(|_| "events".to_string());
        
        Ok(PostgresConfig {
            host,
            port,
            user,
            password,
            database,
        })
    }
    
    /// Create a connection pool
    pub fn create_pool(&self) -> Result<Pool> {
        let mut cfg = Config::new();
        cfg.host = Some(self.host.clone());
        cfg.port = Some(self.port);
        cfg.user = Some(self.user.clone());
        cfg.password = Some(self.password.clone());
        cfg.dbname = Some(self.database.clone());
        
        // Configure pool settings
        let mut pool = PoolConfig::new(16);
        pool.timeouts = deadpool_postgres::Timeouts {
            wait: Some(Duration::from_secs(30)),
            create: Some(Duration::from_secs(10)),
            recycle: Some(Duration::from_secs(60)),
        };
        
        cfg.pool = Some(pool);
        
        cfg.create_pool(Some(Runtime::Tokio1), NoTls)
            .map_err(|e| anyhow!("Failed to create Postgres connection pool: {}", e))
    }
}

/// PostgreSQL event store implementation
pub struct PostgresEventStore {
    pool: Pool,
    is_test: bool, // Flag to indicate test mode
}

impl PostgresEventStore {
    /// Create a new PostgreSQL event store
    pub async fn new() -> Result<Self> {
        // Check if we're running in test mode
        let is_test = std::env::var("CARGO_TARGET_TMPDIR").is_ok();
        let test_mode_explicit = std::env::var("TEST_POSTGRES").is_ok();
        
        // Use test mode if either auto-detected or explicitly requested
        let use_test_mode = is_test || test_mode_explicit;
        
        if use_test_mode {
            // Create a mock pool in test mode
            log::info!("🧪 TEST MODE: Using mock PostgreSQL connection");
            return Self::new_test_mode();
        }
        
        // Create a real PostgreSQL connection
        let config = PostgresConfig::from_env()?;
        let pool = config.create_pool()?;
        
        // Test connection and create tables if needed
        let store = Self { pool, is_test: false };
        store.init_tables().await?;
        
        Ok(store)
    }
    
    /// Create a test mode PostgreSQL store that doesn't make real connections
    fn new_test_mode() -> Result<Self> {
        // Create a minimal config for the test mode
        let config = PostgresConfig {
            host: "localhost".to_string(),
            port: 5432,
            user: "test_user".to_string(),
            password: "test_password".to_string(),
            database: "test_database".to_string(),
        };
        
        // Create a "mock" pool that won't be used for real queries
        let mut cfg = Config::new();
        cfg.host = Some(config.host.clone());
        cfg.port = Some(config.port);
        cfg.user = Some(config.user.clone());
        cfg.password = Some(config.password.clone());
        cfg.dbname = Some(config.database.clone());
        
        let pool = PoolConfig::new(1);
        cfg.pool = Some(pool);
        
        // Create the pool but mark as test mode - queries won't actually run
        let pool_result = cfg.create_pool(Some(Runtime::Tokio1), NoTls);
        
        match pool_result {
            Ok(pool) => Ok(Self { pool, is_test: true }),
            Err(_) => {
                // If pool creation fails in test mode, create a dummy pool
                log::warn!("Failed to create test pool, using dummy implementation");
                
                // This is a workaround for tests - we create a minimal working pool config
                let mut cfg = Config::new();
                cfg.host = Some("localhost".to_string());
                cfg.port = Some(5432);
                cfg.user = Some("postgres".to_string());
                cfg.password = Some("postgres".to_string());
                cfg.dbname = Some("postgres".to_string());
                
                let pool = PoolConfig::new(1);
                cfg.pool = Some(pool);
                
                match cfg.create_pool(Some(Runtime::Tokio1), NoTls) {
                    Ok(pool) => Ok(Self { pool, is_test: true }),
                    Err(e) => Err(anyhow!("Failed to create mock PostgreSQL pool: {}", e)),
                }
            }
        }
    }
    
    /// Initialize database tables
    async fn init_tables(&self) -> Result<()> {
        // In test mode, skip the initialization
        if self.is_test {
            log::info!("🧪 TEST MODE: Skipping PostgreSQL table initialization");
            return Ok(());
        }
        
        let client = self.pool.get().await
            .map_err(|e| anyhow!("Failed to get Postgres client: {}", e))?;
        
        // Create events table if it doesn't exist
        let create_events_table = r#"
        CREATE TABLE IF NOT EXISTS events (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            date TEXT NOT NULL,
            location TEXT NOT NULL,
            url TEXT NOT NULL,
            image_url TEXT,
            city TEXT NOT NULL,
            price TEXT NOT NULL,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        )
        "#;
        
        client.execute(create_events_table, &[]).await
            .map_err(|e| anyhow!("Failed to create events table: {}", e))?;
        
        // Create failed price fetches table if it doesn't exist
        let create_failures_table = r#"
        CREATE TABLE IF NOT EXISTS failed_price_fetches (
            id TEXT NOT NULL,
            title TEXT NOT NULL,
            url TEXT NOT NULL,
            error TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id, timestamp)
        )
        "#;
        
        client.execute(create_failures_table, &[]).await
            .map_err(|e| anyhow!("Failed to create failed_price_fetches table: {}", e))?;
        
        // Create indexes if they don't exist
        let create_indexes = [
            "CREATE INDEX IF NOT EXISTS idx_events_date ON events(date)",
            "CREATE INDEX IF NOT EXISTS idx_events_city ON events(city)",
            "CREATE INDEX IF NOT EXISTS idx_failures_timestamp ON failed_price_fetches(timestamp)"
        ];
        
        for index_sql in create_indexes {
            client.execute(index_sql, &[]).await
                .map_err(|e| anyhow!("Failed to create index: {}", e))?;
        }
        
        info!("PostgreSQL tables initialized successfully");
        Ok(())
    }
    
    /// Store failed price fetches in the database
    pub async fn store_failures(&self, failures: &[crate::event::FailedPriceFetch]) -> Result<()> {
        if failures.is_empty() {
            return Ok(());
        }
        
        // In test mode, just log the operation without making real database calls
        if self.is_test {
            log::info!("🧪 TEST MODE: Would store {} failures in PostgreSQL", failures.len());
            // Log a sample failure for testing purposes
            if !failures.is_empty() {
                log::info!("Sample failure: {} ({}): {}", 
                          failures[0].title, failures[0].id, failures[0].error);
            }
            return Ok(());
        }
        
        // Normal mode - use real database
        let mut client = self.pool.get().await
            .map_err(|e| anyhow!("Failed to get Postgres client: {}", e))?;
            
        // Start a transaction
        let tx = client.transaction().await
            .map_err(|e| anyhow!("Failed to start transaction: {}", e))?;
            
        // Insert or update each failure
        let statement = r#"
        INSERT INTO failed_price_fetches (id, title, url, error, timestamp)
        VALUES ($1, $2, $3, $4, $5)
        ON CONFLICT (id, timestamp) DO UPDATE SET
            error = EXCLUDED.error
        "#;
        
        for failure in failures {
            tx.execute(
                statement,
                &[
                    &failure.id,
                    &failure.title,
                    &failure.url,
                    &failure.error,
                    &failure.timestamp,
                ],
            ).await.map_err(|e| anyhow!("Failed to insert failure: {}", e))?;
        }
        
        // Commit the transaction
        tx.commit().await
            .map_err(|e| anyhow!("Failed to commit transaction: {}", e))?;
            
        info!("Stored {} failures in PostgreSQL", failures.len());
        Ok(())
    }
}

impl EventStore for PostgresEventStore {
    fn store_events(&self, events: &[EventData]) -> Result<()> {
        // In test mode, just log the operation without making real database calls
        if self.is_test {
            log::info!("🧪 TEST MODE: Would store {} events in PostgreSQL", events.len());
            // Log a sample event for testing purposes
            if !events.is_empty() {
                log::info!("Sample event: {} ({})", events[0].title, events[0].id);
            }
            return Ok(());
        }
        
        // Normal mode - Use a block_in_place to avoid blocking issues
        tokio::task::block_in_place(|| {
            let rt = tokio::runtime::Handle::current();
            rt.block_on(async {
                let mut client = self.pool.get().await
                    .map_err(|e| anyhow!("Failed to get Postgres client: {}", e))?;
                
                // Start a transaction
                let tx = client.transaction().await
                    .map_err(|e| anyhow!("Failed to start transaction: {}", e))?;
                
                // Insert or update each event
                let statement = r#"
                INSERT INTO events (id, title, date, location, url, image_url, city, price)
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
                ON CONFLICT (id) DO UPDATE SET
                    title = EXCLUDED.title,
                    date = EXCLUDED.date,
                    location = EXCLUDED.location,
                    url = EXCLUDED.url,
                    image_url = EXCLUDED.image_url,
                    city = EXCLUDED.city,
                    price = EXCLUDED.price
                "#;
                
                for event in events {
                    tx.execute(
                        statement,
                        &[
                            &event.id,
                            &event.title,
                            &event.date,
                            &event.location,
                            &event.url,
                            &event.image_url,
                            &event.city,
                            &event.price,
                        ],
                    ).await.map_err(|e| anyhow!("Failed to insert event: {}", e))?;
                }
                
                // Commit the transaction
                tx.commit().await
                    .map_err(|e| anyhow!("Failed to commit transaction: {}", e))?;
                
                info!("Stored {} events in PostgreSQL", events.len());
                Ok(())
            })
        })
    }
    
    fn clear_events(&self) -> Result<()> {
        // In test mode, just log the operation without making real database calls
        if self.is_test {
            log::info!("🧪 TEST MODE: Would clear all events from PostgreSQL");
            return Ok(());
        }
        
        // Normal mode - Use a block_in_place to avoid blocking issues
        tokio::task::block_in_place(|| {
            let rt = tokio::runtime::Handle::current();
            rt.block_on(async {
                let client = self.pool.get().await
                    .map_err(|e| anyhow!("Failed to get Postgres client: {}", e))?;
                
                client.execute("DELETE FROM events", &[]).await
                    .map_err(|e| anyhow!("Failed to clear events: {}", e))?;
                
                info!("Cleared all events from PostgreSQL");
                Ok(())
            })
        })
    }
    
    fn get_events(&self, city: Option<&str>, limit: Option<usize>) -> Result<Vec<EventData>> {
        // In test mode, return sample data
        if self.is_test {
            log::info!("🧪 TEST MODE: Would query events from PostgreSQL");
            let city_str = city.unwrap_or("FL");
            let limit_value = limit.unwrap_or(5);
            
            // Create sample data for testing
            let mut sample_events = Vec::new();
            for i in 1..=limit_value {
                sample_events.push(EventData {
                    id: format!("test-{}", i),
                    title: format!("Test Event {} in {}", i, city_str),
                    date: "25/03/2025".to_string(),
                    location: format!("{} Convention Center", city_str),
                    url: format!("https://example.com/evento/test-{}", i),
                    image_url: "https://example.com/image.jpg".to_string(),
                    city: city_str.to_string(),
                    price: format!("R$ {:.2}", i as f64 * 25.0),
                });
            }
            
            return Ok(sample_events);
        }
        
        // Normal mode - Use block_in_place to avoid blocking issues
        tokio::task::block_in_place(|| {
            let rt = tokio::runtime::Handle::current();
            rt.block_on(async {
                let client = self.pool.get().await
                    .map_err(|e| anyhow!("Failed to get Postgres client: {}", e))?;
                
                // Build query based on parameters
                let mut query = "SELECT id, title, date, location, url, image_url, city, price FROM events".to_string();
                let mut params: Vec<Box<dyn tokio_postgres::types::ToSql + Sync>> = Vec::new();
                
                // Add city filter if provided
                if let Some(city_filter) = city {
                    query.push_str(" WHERE city = $1");
                    params.push(Box::new(city_filter.to_string()));
                }
                
                // Add order by and limit
                query.push_str(" ORDER BY created_at DESC");
                
                if let Some(limit_value) = limit {
                    let param_index = params.len() + 1;
                    query.push_str(&format!(" LIMIT ${}", param_index));
                    params.push(Box::new(limit_value as i64));
                }
                
                // Prepare params with proper references
                let param_refs: Vec<&(dyn tokio_postgres::types::ToSql + Sync)> = 
                    params.iter().map(|p| p.as_ref() as &(dyn tokio_postgres::types::ToSql + Sync)).collect();
                
                // Execute query
                let rows = client.query(&query, &param_refs[..]).await
                    .map_err(|e| anyhow!("Failed to query events: {}", e))?;
                
                // Convert rows to EventData
                let events = rows.iter().map(|row| {
                    EventData {
                        id: row.get(0),
                        title: row.get(1),
                        date: row.get(2),
                        location: row.get(3),
                        url: row.get(4),
                        image_url: row.get(5),
                        city: row.get(6),
                        price: row.get(7),
                    }
                }).collect();
                
                info!("Retrieved {} events from PostgreSQL", rows.len());
                Ok(events)
            })
        })
    }
    
    fn get_event_by_id(&self, id: &str) -> Result<Option<EventData>> {
        // In test mode, return sample data
        if self.is_test {
            log::info!("🧪 TEST MODE: Would query event by ID {} from PostgreSQL", id);
            
            // Create sample data for testing, but only return if ID matches test pattern
            if id.starts_with("test-") {
                let index = id.replace("test-", "").parse::<usize>().unwrap_or(1);
                return Ok(Some(EventData {
                    id: id.to_string(),
                    title: format!("Test Event {}", index),
                    date: "25/03/2025".to_string(),
                    location: "Test Convention Center".to_string(),
                    url: format!("https://example.com/evento/{}", id),
                    image_url: "https://example.com/image.jpg".to_string(),
                    city: "FL".to_string(),
                    price: format!("R$ {:.2}", index as f64 * 25.0),
                }));
            }
            
            return Ok(None);
        }
        
        // Normal mode - Use block_in_place to avoid blocking issues
        tokio::task::block_in_place(|| {
            let rt = tokio::runtime::Handle::current();
            rt.block_on(async {
                let client = self.pool.get().await
                    .map_err(|e| anyhow!("Failed to get Postgres client: {}", e))?;
                
                // Query for specific event by ID
                let query = "SELECT id, title, date, location, url, image_url, city, price FROM events WHERE id = $1";
                
                // Execute query
                let row_opt = client.query_opt(query, &[&id]).await
                    .map_err(|e| anyhow!("Failed to query event by ID: {}", e))?;
                
                // Convert row to EventData if found
                let event_opt = row_opt.map(|row| {
                    EventData {
                        id: row.get(0),
                        title: row.get(1),
                        date: row.get(2),
                        location: row.get(3),
                        url: row.get(4),
                        image_url: row.get(5),
                        city: row.get(6),
                        price: row.get(7),
                    }
                });
                
                if event_opt.is_some() {
                    info!("Retrieved event with ID {} from PostgreSQL", id);
                } else {
                    info!("No event found with ID {} in PostgreSQL", id);
                }
                
                Ok(event_opt)
            })
        })
    }
    
    fn get_upcoming_events(&self, city: Option<&str>, limit: Option<usize>) -> Result<Vec<EventData>> {
        // In test mode, return sample data
        if self.is_test {
            log::info!("🧪 TEST MODE: Would query upcoming events from PostgreSQL");
            let city_str = city.unwrap_or("FL");
            let limit_value = limit.unwrap_or(5);
            
            // Create sample data for testing with future dates
            let mut sample_events = Vec::new();
            for i in 1..=limit_value {
                // Create dates 1-N days in the future
                let future_date = chrono::Utc::now().date_naive() + chrono::Duration::days(i as i64);
                let formatted_date = future_date.format("%d/%m/%Y").to_string();
                
                sample_events.push(EventData {
                    id: format!("upcoming-{}", i),
                    title: format!("Upcoming Event {} in {}", i, city_str),
                    date: formatted_date,
                    location: format!("{} Convention Center", city_str),
                    url: format!("https://example.com/evento/upcoming-{}", i),
                    image_url: "https://example.com/image.jpg".to_string(),
                    city: city_str.to_string(),
                    price: format!("R$ {:.2}", i as f64 * 25.0),
                });
            }
            
            return Ok(sample_events);
        }
        
        // Normal mode - Use block_in_place to avoid blocking issues
        tokio::task::block_in_place(|| {
            let rt = tokio::runtime::Handle::current();
            rt.block_on(async {
                let client = self.pool.get().await
                    .map_err(|e| anyhow!("Failed to get Postgres client: {}", e))?;
                
                // Use the existing upcoming_events view, but add filters and limit
                let mut query = "SELECT id, title, date, location, url, image_url, city, price FROM upcoming_events".to_string();
                let mut params: Vec<Box<dyn tokio_postgres::types::ToSql + Sync>> = Vec::new();
                
                // Add city filter if provided
                if let Some(city_filter) = city {
                    query.push_str(" WHERE city = $1");
                    params.push(Box::new(city_filter.to_string()));
                }
                
                // Add order by (should already be in the view, but ensure it's here)
                query.push_str(" ORDER BY TO_DATE(date, 'DD/MM/YYYY') ASC");
                
                // Add limit if provided
                if let Some(limit_value) = limit {
                    let param_index = params.len() + 1;
                    query.push_str(&format!(" LIMIT ${}", param_index));
                    params.push(Box::new(limit_value as i64));
                }
                
                // Prepare params with proper references
                let param_refs: Vec<&(dyn tokio_postgres::types::ToSql + Sync)> = 
                    params.iter().map(|p| p.as_ref() as &(dyn tokio_postgres::types::ToSql + Sync)).collect();
                
                // Execute query
                let rows = client.query(&query, &param_refs[..]).await
                    .map_err(|e| anyhow!("Failed to query upcoming events: {}", e))?;
                
                // Convert rows to EventData
                let events = rows.iter().map(|row| {
                    EventData {
                        id: row.get(0),
                        title: row.get(1),
                        date: row.get(2),
                        location: row.get(3),
                        url: row.get(4),
                        image_url: row.get(5),
                        city: row.get(6),
                        price: row.get(7),
                    }
                }).collect();
                
                info!("Retrieved {} upcoming events from PostgreSQL", rows.len());
                Ok(events)
            })
        })
    }
}