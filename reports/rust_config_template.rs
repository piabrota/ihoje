//! Configuration handling best practices for Rust applications.
//!
//! This module demonstrates recommended patterns for configuration:
//! 1. Environment-based configuration with fallbacks
//! 2. Strongly typed config with validation
//! 3. Builder pattern for flexible config creation
//! 4. Proper error handling for config issues

use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::time::Duration;

use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use thiserror::Error;

// -----------------------------------------------------------------------------
// Configuration Error Type
// -----------------------------------------------------------------------------

/// Errors that can occur during configuration loading and validation.
#[derive(Error, Debug)]
pub enum ConfigError {
    /// Invalid configuration value
    #[error("Invalid configuration value: {0}")]
    InvalidValue(String),
    
    /// Missing required configuration
    #[error("Missing required configuration: {0}")]
    MissingValue(String),
    
    /// Environment variable error
    #[error("Environment error: {0}")]
    EnvError(#[from] env::VarError),
    
    /// File system error
    #[error("File system error: {0}")]
    FileError(#[from] std::io::Error),
    
    /// JSON parsing error
    #[error("JSON parsing error: {0}")]
    JsonError(#[from] serde_json::Error),
    
    /// TOML parsing error
    #[error("TOML parsing error: {0}")]
    TomlError(String),
}

// -----------------------------------------------------------------------------
// Configuration Structure
// -----------------------------------------------------------------------------

/// Application configuration with strongly typed fields and defaults.
///
/// This struct represents the application's configuration, with proper
/// type safety and documentation for each field.
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct Config {
    /// API provider to use (e.g., "pikachu", "charmander")
    pub provider: String,
    
    /// Target city code (e.g., "FL", "RJ")
    pub city: String,
    
    /// Start date for event range in YYYY-MM-DD format
    pub start_date: Option<String>,
    
    /// End date for event range in YYYY-MM-DD format
    pub end_date: Option<String>,
    
    /// Maximum number of events to process
    pub max_events: usize,
    
    /// API key for the event service
    pub api_key: String,
    
    /// Base URL for the API
    pub api_url: String,
    
    /// Request timeout in seconds
    pub timeout_seconds: u64,
    
    /// Format for exporting data ("csv", "postgres", or "both")
    pub export_format: ExportFormat,
    
    /// Database configuration if using postgres
    pub database: Option<DatabaseConfig>,
    
    /// Rate limiting configuration
    pub rate_limit: RateLimitConfig,
    
    /// Log level ("error", "warn", "info", "debug", "trace")
    pub log_level: String,
    
    /// Output directory for exported files
    pub output_dir: PathBuf,
}

/// Format options for exporting data.
#[derive(Debug, Clone, Deserialize, Serialize, PartialEq)]
#[serde(rename_all = "lowercase")]
pub enum ExportFormat {
    /// Export to CSV files only
    Csv,
    /// Export to PostgreSQL database only
    Postgres,
    /// Export to both CSV and PostgreSQL
    Both,
}

/// Database connection configuration.
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct DatabaseConfig {
    /// Database host (default: "localhost")
    pub host: String,
    /// Database port (default: 5432)
    pub port: u16,
    /// Database username
    pub username: String,
    /// Database password
    pub password: String,
    /// Database name
    pub database: String,
}

/// Rate limiting configuration.
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct RateLimitConfig {
    /// Maximum requests per window
    pub requests: u32,
    /// Time window in milliseconds
    pub window_ms: u64,
}

// -----------------------------------------------------------------------------
// Default Implementation
// -----------------------------------------------------------------------------

impl Default for Config {
    fn default() -> Self {
        Self {
            provider: "pikachu".to_string(),
            city: "FL".to_string(),
            start_date: None,
            end_date: None,
            max_events: 100,
            api_key: String::new(), // Requires explicit setting
            api_url: "https://api.example.com".to_string(),
            timeout_seconds: 30,
            export_format: ExportFormat::Csv,
            database: None,
            rate_limit: RateLimitConfig {
                requests: 10,
                window_ms: 1000,
            },
            log_level: "info".to_string(),
            output_dir: PathBuf::from("./output"),
        }
    }
}

// -----------------------------------------------------------------------------
// Builder Pattern for Config
// -----------------------------------------------------------------------------

/// Builder for creating Config instances with a fluent interface.
#[derive(Default)]
pub struct ConfigBuilder {
    config: Config,
}

impl ConfigBuilder {
    /// Create a new ConfigBuilder with default values.
    pub fn new() -> Self {
        Self {
            config: Config::default(),
        }
    }
    
    /// Set the API provider.
    pub fn provider(mut self, provider: impl Into<String>) -> Self {
        self.config.provider = provider.into();
        self
    }
    
    /// Set the target city.
    pub fn city(mut self, city: impl Into<String>) -> Self {
        self.config.city = city.into();
        self
    }
    
    /// Set the start date for event range.
    pub fn start_date(mut self, date: impl Into<String>) -> Self {
        self.config.start_date = Some(date.into());
        self
    }
    
    /// Set the end date for event range.
    pub fn end_date(mut self, date: impl Into<String>) -> Self {
        self.config.end_date = Some(date.into());
        self
    }
    
    /// Set the maximum number of events.
    pub fn max_events(mut self, max: usize) -> Self {
        self.config.max_events = max;
        self
    }
    
    /// Set the API key.
    pub fn api_key(mut self, key: impl Into<String>) -> Self {
        self.config.api_key = key.into();
        self
    }
    
    /// Set the API URL.
    pub fn api_url(mut self, url: impl Into<String>) -> Self {
        self.config.api_url = url.into();
        self
    }
    
    /// Set request timeout in seconds.
    pub fn timeout_seconds(mut self, seconds: u64) -> Self {
        self.config.timeout_seconds = seconds;
        self
    }
    
    /// Set the export format.
    pub fn export_format(mut self, format: ExportFormat) -> Self {
        self.config.export_format = format;
        self
    }
    
    /// Set the database configuration.
    pub fn database(mut self, db_config: DatabaseConfig) -> Self {
        self.config.database = Some(db_config);
        self
    }
    
    /// Set rate limiting configuration.
    pub fn rate_limit(mut self, requests: u32, window_ms: u64) -> Self {
        self.config.rate_limit = RateLimitConfig {
            requests,
            window_ms,
        };
        self
    }
    
    /// Set the log level.
    pub fn log_level(mut self, level: impl Into<String>) -> Self {
        self.config.log_level = level.into();
        self
    }
    
    /// Set the output directory.
    pub fn output_dir(mut self, dir: impl Into<PathBuf>) -> Self {
        self.config.output_dir = dir.into();
        self
    }
    
    /// Build the Config with validation.
    pub fn build(self) -> Result<Config, ConfigError> {
        let config = self.config;
        
        // Validate required fields
        if config.api_key.is_empty() {
            return Err(ConfigError::MissingValue("api_key".to_string()));
        }
        
        // Validate provider
        match config.provider.as_str() {
            "pikachu" | "charmander" => {}
            _ => return Err(ConfigError::InvalidValue(format!(
                "Invalid provider: {}. Must be 'pikachu' or 'charmander'", 
                config.provider
            ))),
        }
        
        // Validate export format requires database config when needed
        if (config.export_format == ExportFormat::Postgres || 
            config.export_format == ExportFormat::Both) && 
            config.database.is_none() {
            return Err(ConfigError::MissingValue(
                "Database configuration required for PostgreSQL export".to_string()
            ));
        }
        
        // Validate rate limit settings
        if config.rate_limit.requests == 0 {
            return Err(ConfigError::InvalidValue(
                "Rate limit requests must be greater than 0".to_string()
            ));
        }
        
        if config.rate_limit.window_ms == 0 {
            return Err(ConfigError::InvalidValue(
                "Rate limit window must be greater than 0 ms".to_string()
            ));
        }
        
        Ok(config)
    }
}

// -----------------------------------------------------------------------------
// Config Loading Methods
// -----------------------------------------------------------------------------

impl Config {
    /// Load configuration from environment variables.
    ///
    /// This method creates a Config by reading from environment variables,
    /// falling back to defaults when values are not provided.
    pub fn from_env() -> Result<Self, ConfigError> {
        let builder = ConfigBuilder::new()
            .provider(env::var("PROVIDER").unwrap_or_else(|_| "pikachu".to_string()))
            .city(env::var("CITY").unwrap_or_else(|_| "FL".to_string()))
            .max_events(env::var("MAX_EVENTS")
                .ok()
                .and_then(|v| v.parse().ok())
                .unwrap_or(100))
            .api_key(env::var("API_KEY")?)
            .api_url(env::var("API_URL").unwrap_or_else(|_| "https://api.example.com".to_string()));
        
        // Optional date range
        let builder = if let Ok(start) = env::var("START_DATE") {
            builder.start_date(start)
        } else {
            builder
        };
        
        let builder = if let Ok(end) = env::var("END_DATE") {
            builder.end_date(end)
        } else {
            builder
        };
        
        // Export format
        let builder = match env::var("EXPORT_FORMAT").ok().as_deref() {
            Some("csv") => builder.export_format(ExportFormat::Csv),
            Some("postgres") => builder.export_format(ExportFormat::Postgres),
            Some("both") => builder.export_format(ExportFormat::Both),
            _ => builder, // Default is CSV
        };
        
        // Database config if needed
        let builder = if let (Ok(host), Ok(user), Ok(pass), Ok(db)) = (
            env::var("PG_HOST"),
            env::var("PG_USER"),
            env::var("PG_PASSWORD"),
            env::var("PG_DATABASE"),
        ) {
            let port = env::var("PG_PORT")
                .ok()
                .and_then(|p| p.parse().ok())
                .unwrap_or(5432);
                
            builder.database(DatabaseConfig {
                host,
                port,
                username: user,
                password: pass,
                database: db,
            })
        } else {
            builder
        };
        
        // Rate limiting
        let builder = if let (Ok(req), Ok(window)) = (
            env::var("RATE_LIMIT_REQUESTS"),
            env::var("RATE_LIMIT_WINDOW_MS"),
        ) {
            let reqs = req.parse().map_err(|_| 
                ConfigError::InvalidValue("Invalid RATE_LIMIT_REQUESTS".to_string())
            )?;
            
            let window_ms = window.parse().map_err(|_| 
                ConfigError::InvalidValue("Invalid RATE_LIMIT_WINDOW_MS".to_string())
            )?;
            
            builder.rate_limit(reqs, window_ms)
        } else {
            builder
        };
        
        // Build with validation
        builder.build()
    }
    
    /// Load configuration from a JSON file.
    pub fn from_json_file<P: AsRef<Path>>(path: P) -> Result<Self, ConfigError> {
        let file_content = fs::read_to_string(path)?;
        let config: Config = serde_json::from_str(&file_content)?;
        
        // Validate the loaded config
        ConfigBuilder::new()
            .provider(config.provider)
            .city(config.city)
            .api_key(config.api_key)
            .api_url(config.api_url)
            .max_events(config.max_events)
            // ... other fields
            .build()
    }
    
    /// Load configuration from environment with fallback to file.
    ///
    /// This method tries to load from environment variables first, and
    /// falls back to loading from a file if a required value is missing.
    pub fn from_env_or_file<P: AsRef<Path>>(path: P) -> Result<Self, anyhow::Error> {
        match Self::from_env() {
            Ok(config) => Ok(config),
            Err(ConfigError::MissingValue(_)) | Err(ConfigError::EnvError(_)) => {
                // Fall back to file
                Self::from_json_file(&path)
                    .with_context(|| format!("Failed to load config from {}", path.as_ref().display()))
            }
            Err(e) => Err(e.into()), // Other errors indicate invalid values, propagate them
        }
    }
    
    /// Get request timeout as a Duration.
    pub fn timeout(&self) -> Duration {
        Duration::from_secs(self.timeout_seconds)
    }
    
    /// Get connection string for PostgreSQL.
    ///
    /// Returns None if database configuration is not present.
    pub fn postgres_connection_string(&self) -> Option<String> {
        self.database.as_ref().map(|db| {
            format!(
                "postgresql://{}:{}@{}:{}/{}",
                db.username, db.password, db.host, db.port, db.database
            )
        })
    }
}

// -----------------------------------------------------------------------------
// Tests
// -----------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;
    use std::env;
    
    // Helper to set environment variables for tests
    fn set_test_env() {
        env::set_var("PROVIDER", "pikachu");
        env::set_var("CITY", "NY");
        env::set_var("MAX_EVENTS", "50");
        env::set_var("API_KEY", "test-api-key");
        env::set_var("API_URL", "https://test.example.com");
        env::set_var("EXPORT_FORMAT", "csv");
    }
    
    // Helper to clear environment variables after tests
    fn clear_test_env() {
        env::remove_var("PROVIDER");
        env::remove_var("CITY");
        env::remove_var("MAX_EVENTS");
        env::remove_var("API_KEY");
        env::remove_var("API_URL");
        env::remove_var("EXPORT_FORMAT");
    }
    
    #[test]
    fn test_default_config() {
        let config = Config::default();
        
        assert_eq!(config.provider, "pikachu");
        assert_eq!(config.city, "FL");
        assert_eq!(config.max_events, 100);
        assert_eq!(config.export_format, ExportFormat::Csv);
        assert!(config.database.is_none());
    }
    
    #[test]
    fn test_config_builder() {
        let config = ConfigBuilder::new()
            .provider("charmander")
            .city("NY")
            .max_events(50)
            .api_key("test-key")
            .api_url("https://test.example.com")
            .export_format(ExportFormat::Csv)
            .build()
            .unwrap();
        
        assert_eq!(config.provider, "charmander");
        assert_eq!(config.city, "NY");
        assert_eq!(config.max_events, 50);
        assert_eq!(config.api_key, "test-key");
        assert_eq!(config.api_url, "https://test.example.com");
    }
    
    #[test]
    fn test_missing_api_key() {
        let result = ConfigBuilder::new()
            .provider("pikachu")
            .city("FL")
            // Missing api_key
            .build();
        
        assert!(result.is_err());
        match result {
            Err(ConfigError::MissingValue(field)) => {
                assert_eq!(field, "api_key");
            }
            _ => panic!("Expected MissingValue error for api_key"),
        }
    }
    
    #[test]
    fn test_invalid_provider() {
        let result = ConfigBuilder::new()
            .provider("invalid")
            .api_key("test-key")
            .build();
        
        assert!(result.is_err());
        match result {
            Err(ConfigError::InvalidValue(msg)) => {
                assert!(msg.contains("Invalid provider"));
            }
            _ => panic!("Expected InvalidValue error for provider"),
        }
    }
    
    #[test]
    fn test_postgres_without_db_config() {
        let result = ConfigBuilder::new()
            .provider("pikachu")
            .api_key("test-key")
            .export_format(ExportFormat::Postgres)
            // Missing database config
            .build();
        
        assert!(result.is_err());
        match result {
            Err(ConfigError::MissingValue(msg)) => {
                assert!(msg.contains("Database configuration required"));
            }
            _ => panic!("Expected MissingValue error for database"),
        }
    }
    
    #[test]
    fn test_from_env() {
        set_test_env();
        
        let config = Config::from_env().unwrap();
        
        assert_eq!(config.provider, "pikachu");
        assert_eq!(config.city, "NY");
        assert_eq!(config.max_events, 50);
        assert_eq!(config.api_key, "test-api-key");
        assert_eq!(config.api_url, "https://test.example.com");
        
        clear_test_env();
    }
    
    #[test]
    fn test_timeout_duration() {
        let config = ConfigBuilder::new()
            .provider("pikachu")
            .api_key("test-key")
            .timeout_seconds(45)
            .build()
            .unwrap();
        
        assert_eq!(config.timeout(), Duration::from_secs(45));
    }
    
    #[test]
    fn test_postgres_connection_string() {
        let config = ConfigBuilder::new()
            .provider("pikachu")
            .api_key("test-key")
            .export_format(ExportFormat::Postgres)
            .database(DatabaseConfig {
                host: "localhost".to_string(),
                port: 5432,
                username: "user".to_string(),
                password: "pass".to_string(),
                database: "testdb".to_string(),
            })
            .build()
            .unwrap();
        
        let conn_string = config.postgres_connection_string().unwrap();
        assert_eq!(conn_string, "postgresql://user:pass@localhost:5432/testdb");
    }
}