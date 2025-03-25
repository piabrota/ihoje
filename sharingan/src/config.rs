//! Configuration management for the ihoje event scraper.
//!
//! This module provides a type-safe configuration system with:
//! - Environment variable loading with sensible defaults
//! - Builder pattern for programmatic configuration
//! - Structured error handling
//! - Configuration validation
//! - City-specific settings

use std::env;
use std::fmt;
use std::fs;
use std::path::Path;
use std::str::FromStr;
use std::time::Duration;

use anyhow::{Context, Result as AnyhowResult};
use log::{error, info};
use serde::{Deserialize, Serialize, Deserializer, Serializer};
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
    
    /// Invalid extraction mode
    #[error("Invalid extraction mode: {0}")]
    InvalidExtractionMode(String),
}

// -----------------------------------------------------------------------------
// Extraction Mode Enum
// -----------------------------------------------------------------------------

/// Extraction mode for fetching HTML content
#[derive(Debug, Clone, PartialEq)]
pub enum ExtractionMode {
    /// Use FireCrawl API for fetching HTML content
    FireCrawler,
    /// Use local files from HTTrack extraction
    Static,
}

impl fmt::Display for ExtractionMode {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            ExtractionMode::FireCrawler => write!(f, "firecrawler"),
            ExtractionMode::Static => write!(f, "static"),
        }
    }
}

impl FromStr for ExtractionMode {
    type Err = ConfigError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.to_lowercase().as_str() {
            "firecrawler" => Ok(ExtractionMode::FireCrawler),
            "static" => Ok(ExtractionMode::Static),
            _ => Err(ConfigError::InvalidExtractionMode(format!(
                "Invalid extraction mode: {}. Must be 'firecrawler' or 'static'",
                s
            ))),
        }
    }
}

impl Default for ExtractionMode {
    fn default() -> Self {
        ExtractionMode::FireCrawler
    }
}

// Custom serialization for ExtractionMode
impl Serialize for ExtractionMode {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        serializer.serialize_str(&self.to_string())
    }
}

// Custom deserialization for ExtractionMode
impl<'de> Deserialize<'de> for ExtractionMode {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        let s = String::deserialize(deserializer)?;
        FromStr::from_str(&s).map_err(serde::de::Error::custom)
    }
}

// -----------------------------------------------------------------------------
// Configuration Structures
// -----------------------------------------------------------------------------

/// City configuration with display name and URL path
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CityConfig {
    /// Display name of the city (e.g., "Florianópolis")
    pub name: String,
    /// URL path component for the city (e.g., "florianopolis-sc")
    pub path: String,
}

/// Date range configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DateRange {
    /// Optional start date in the format expected by the provider
    pub start_date: Option<String>,
    /// Optional end date in the format expected by the provider
    pub end_date: Option<String>,
}

/// Database export format setting
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DatabaseConfig {
    /// Format to use for data export (CSV, Postgres, etc.)
    pub export_format: crate::db::ExportFormat,
}

/// Application configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AppConfig {
    /// Target city code (e.g., "FL", "RJ")
    pub city: String,
    /// Detailed city configuration
    pub city_config: CityConfig,
    /// API key for the event service
    pub api_key: String,
    /// Target URL for the API
    pub target_url: String,
    /// Maximum number of events to process
    pub max_events: usize,
    /// Date range for event filtering
    pub date_range: DateRange,
    /// Database configuration
    pub db_config: DatabaseConfig,
    /// Provider name (e.g., "pikachu", "charmander")
    pub provider: String,
    /// Request timeout in seconds (optional)
    #[serde(default = "default_timeout_seconds")]
    pub timeout_seconds: u64,
    /// Extraction mode (firecrawler or static)
    #[serde(default)]
    pub extraction_mode: ExtractionMode,
    /// Path to HTTrack extraction folder
    #[serde(default)]
    pub extraction_folder: Option<String>,
    /// Whether to use FireCrawl for HTTP requests or local files (deprecated, use extraction_mode instead)
    #[serde(default = "default_use_firecrawl", skip_serializing)]
    pub use_firecrawl: bool,
}

fn default_timeout_seconds() -> u64 {
    30
}

fn default_use_firecrawl() -> bool {
    true
}

// -----------------------------------------------------------------------------
// Implementation
// -----------------------------------------------------------------------------

impl DateRange {
    /// Create a new date range with optional start and end dates
    pub fn new(start_date: Option<String>, end_date: Option<String>) -> Self {
        Self {
            start_date,
            end_date,
        }
    }

    /// Check if the date range is specified
    pub fn is_specified(&self) -> bool {
        self.start_date.is_some() || self.end_date.is_some()
    }
}

impl Default for AppConfig {
    fn default() -> Self {
        Self {
            city: "FL".to_string(),
            city_config: CityConfig {
                name: "Florianópolis".to_string(),
                path: "florianopolis-sc".to_string(),
            },
            api_key: String::new(),    // Requires explicit setting
            target_url: String::new(), // Requires explicit setting
            max_events: 10,
            date_range: DateRange::new(None, None),
            db_config: DatabaseConfig {
                export_format: crate::db::ExportFormat::Postgres,
            },
            provider: "pikachu".to_string(),
            timeout_seconds: 30,
            extraction_mode: ExtractionMode::FireCrawler,
            use_firecrawl: true, // For backward compatibility
            extraction_folder: None,
        }
    }
}

// -----------------------------------------------------------------------------
// Builder Pattern
// -----------------------------------------------------------------------------

/// Builder for creating AppConfig instances with a fluent interface
#[derive(Default)]
pub struct ConfigBuilder {
    config: AppConfig,
}

impl ConfigBuilder {
    /// Create a new ConfigBuilder with default values
    pub fn new() -> Self {
        Self {
            config: AppConfig::default(),
        }
    }

    /// Set the target city
    pub fn city(mut self, city: impl Into<String>) -> Self {
        let city_str = city.into();
        self.config.city = city_str.clone();
        self.config.city_config = get_city_config(&city_str);
        self
    }

    /// Set the API key
    pub fn api_key(mut self, key: impl Into<String>) -> Self {
        self.config.api_key = key.into();
        self
    }

    /// Set the provider
    pub fn provider(mut self, provider: impl Into<String>) -> Self {
        self.config.provider = provider.into();
        self
    }

    /// Set the target URL
    pub fn target_url(mut self, url: impl Into<String>) -> Self {
        self.config.target_url = url.into();
        self
    }

    /// Set the maximum number of events
    pub fn max_events(mut self, max: usize) -> Self {
        self.config.max_events = max;
        self
    }

    /// Set the start date
    pub fn start_date(mut self, date: impl Into<String>) -> Self {
        self.config.date_range.start_date = Some(date.into());
        self
    }

    /// Set the end date
    pub fn end_date(mut self, date: impl Into<String>) -> Self {
        self.config.date_range.end_date = Some(date.into());
        self
    }

    /// Set the export format
    pub fn export_format(mut self, format: crate::db::ExportFormat) -> Self {
        self.config.db_config.export_format = format;
        self
    }

    /// Set the timeout in seconds
    pub fn timeout_seconds(mut self, seconds: u64) -> Self {
        self.config.timeout_seconds = seconds;
        self
    }

    /// Set extraction mode (firecrawler or static)
    pub fn extraction_mode(mut self, mode: ExtractionMode) -> Self {
        self.config.extraction_mode = mode.clone();
        // Update use_firecrawl for backward compatibility
        self.config.use_firecrawl = mode == ExtractionMode::FireCrawler;
        self
    }

    /// Set whether to use FireCrawl for HTTP requests (deprecated, use extraction_mode instead)
    pub fn use_firecrawl(mut self, use_firecrawl: bool) -> Self {
        self.config.use_firecrawl = use_firecrawl;
        // Update extraction_mode for consistency
        self.config.extraction_mode = if use_firecrawl {
            ExtractionMode::FireCrawler
        } else {
            ExtractionMode::Static
        };
        self
    }

    /// Set the HTTrack extraction folder path
    pub fn extraction_folder(mut self, path: impl Into<String>) -> Self {
        self.config.extraction_folder = Some(path.into());
        self
    }

    /// Build the config with validation
    pub fn build(self) -> Result<AppConfig, ConfigError> {
        let config = self.config;

        // Validate configuration based on extraction mode
        match config.extraction_mode {
            ExtractionMode::FireCrawler => {
                // When using FireCrawl, we need an API key
                if config.api_key.is_empty() {
                    return Err(ConfigError::MissingValue(
                        "API key is required when extraction mode is 'firecrawler'".to_string()
                    ));
                }
            },
            ExtractionMode::Static => {
                // When using static extraction, we need an extraction folder
                if config.extraction_folder.is_none() || config.extraction_folder.as_ref().unwrap().is_empty() {
                    return Err(ConfigError::MissingValue(
                        "extraction_folder is required when extraction mode is 'static'".to_string(),
                    ));
                }
                
                // Check if the extraction folder exists
                if let Some(folder) = &config.extraction_folder {
                    if !Path::new(folder).exists() {
                        return Err(ConfigError::InvalidValue(
                            format!("Extraction folder '{}' does not exist", folder)
                        ));
                    }
                }
            }
        }

        // Validate target URL
        if config.target_url.is_empty() {
            return Err(ConfigError::MissingValue(
                "Target URL is required".to_string(),
            ));
        }

        // Validate provider
        match config.provider.as_str() {
            "pikachu" | "charmander" => {}
            _ => {
                return Err(ConfigError::InvalidValue(format!(
                    "Invalid provider: {}. Must be 'pikachu' or 'charmander'",
                    config.provider
                )))
            }
        }

        // Validate max_events
        if config.max_events == 0 {
            return Err(ConfigError::InvalidValue(
                "max_events must be greater than 0".to_string(),
            ));
        }

        Ok(config)
    }
}

// -----------------------------------------------------------------------------
// Configuration Loading Methods
// -----------------------------------------------------------------------------

impl AppConfig {
    /// Get request timeout as a Duration
    pub fn timeout(&self) -> Duration {
        Duration::from_secs(self.timeout_seconds)
    }

    /// Load configuration from environment variables
    pub fn from_env() -> Result<Self, ConfigError> {
        // Get extraction mode with appropriate default
        let extraction_mode_str = env::var("EXTRACTION_MODE")
            .unwrap_or_else(|_| "firecrawler".to_string());
        
        let extraction_mode = ExtractionMode::from_str(&extraction_mode_str)?;
        
        // For backward compatibility - check USE_FIRECRAWL if EXTRACTION_MODE not explicitly set
        let use_firecrawl = if env::var("EXTRACTION_MODE").is_err() {
            env::var("USE_FIRECRAWL")
                .unwrap_or_else(|_| "true".to_string())
                .to_lowercase() == "true"
        } else {
            extraction_mode == ExtractionMode::FireCrawler
        };
        
        // Extract folder configuration
        let extraction_folder = env::var("EXTRACTION_FOLDER").ok().filter(|s| !s.is_empty());
        
        // API key - only required when using FireCrawler mode
        let api_key = if extraction_mode == ExtractionMode::FireCrawler {
            env::var("FIRECRAWL_API_KEY").map_err(|_| {
                ConfigError::MissingValue(
                    "FIRECRAWL_API_KEY environment variable is required when EXTRACTION_MODE is 'firecrawler'".to_string(),
                )
            })?
        } else {
            // Empty API key is allowed when using static extraction
            env::var("FIRECRAWL_API_KEY").unwrap_or_default()
        };

        // Get city from environment or use default
        let city = env::var("CITY").unwrap_or_else(|_| "FL".to_string());

        // Map city code to configuration
        let city_config = get_city_config(&city);

        // Get provider
        let provider = env::var("PROVIDER").unwrap_or_else(|_| "pikachu".to_string());

        // Get target URL based on provider
        let target_url = match provider.as_str() {
            "pikachu" => env::var("PIKACHU_API_URL").map_err(|_| {
                ConfigError::MissingValue(
                    "PIKACHU_API_URL environment variable is required for pikachu provider"
                        .to_string(),
                )
            })?,
            "charmander" => env::var("CHARMANDER_API_URL").map_err(|_| {
                ConfigError::MissingValue(
                    "CHARMANDER_API_URL environment variable is required for charmander provider"
                        .to_string(),
                )
            })?,
            _ => {
                return Err(ConfigError::InvalidValue(format!(
                    "Unknown provider: {}",
                    provider
                )))
            }
        };

        if target_url.is_empty() {
            return Err(ConfigError::InvalidValue(format!(
                "{}_API_URL environment variable cannot be empty",
                provider.to_uppercase()
            )));
        }

        // Get max events
        let max_events = env::var("MAX_EVENTS")
            .unwrap_or_else(|_| "10".to_string())
            .parse::<usize>()
            .unwrap_or(10);

        // Get date range parameters
        let start_date = env::var("START_DATE").ok().filter(|s| !s.is_empty());
        let end_date = env::var("END_DATE").ok().filter(|s| !s.is_empty());

        // Create date range object
        let date_range = DateRange::new(start_date, end_date);

        // Get database export format from environment
        let export_format_str =
            env::var("EXPORT_FORMAT").unwrap_or_else(|_| "postgres".to_string());
        let export_format = crate::db::ExportFormat::from(export_format_str);

        // Get timeout seconds if specified
        let timeout_seconds = env::var("TIMEOUT_SECONDS")
            .ok()
            .and_then(|s| s.parse::<u64>().ok())
            .unwrap_or(30);

        // Create database config
        let db_config = DatabaseConfig { export_format };

        // Log the configuration
        info!("Using provider: {}", provider);
        info!("Database export format: {}", export_format);
        info!("Extraction mode: {}", extraction_mode);
        if let Some(folder) = &extraction_folder {
            info!("Extraction folder: {}", folder);
        }

        Ok(AppConfig {
            city,
            city_config,
            api_key,
            target_url,
            max_events,
            date_range,
            db_config,
            provider,
            timeout_seconds,
            extraction_mode,
            use_firecrawl,
            extraction_folder,
        })
    }

    /// Load configuration from a JSON file
    pub fn from_json_file<P: AsRef<Path>>(path: P) -> Result<Self, ConfigError> {
        let file_content = fs::read_to_string(path)?;
        let config: AppConfig = serde_json::from_str(&file_content)?;

        // Validate the loaded config using the builder
        let mut builder = ConfigBuilder::new()
            .city(config.city)
            .provider(config.provider)
            .target_url(config.target_url)
            .max_events(config.max_events)
            .export_format(config.db_config.export_format)
            .timeout_seconds(config.timeout_seconds)
            .use_firecrawl(config.use_firecrawl);
        
        // Add optional parameters
        if !config.api_key.is_empty() {
            builder = builder.api_key(config.api_key);
        }
        
        if let Some(folder) = config.extraction_folder {
            builder = builder.extraction_folder(folder);
        }
        
        builder.build()
    }

    /// Load configuration from environment with fallback to file
    pub fn from_env_or_file<P: AsRef<Path>>(path: P) -> AnyhowResult<Self> {
        match Self::from_env() {
            Ok(config) => Ok(config),
            Err(ConfigError::MissingValue(_)) | Err(ConfigError::EnvError(_)) => {
                // Fall back to file
                Self::from_json_file(&path).with_context(|| {
                    format!("Failed to load config from {}", path.as_ref().display())
                })
            }
            Err(e) => Err(e.into()), // Other errors indicate invalid values, propagate them
        }
    }
}

/// Load application configuration using the current behavior
///
/// This function maintains backward compatibility with the original code
/// while using the new error handling.
pub fn get_config() -> AnyhowResult<AppConfig> {
    match AppConfig::from_env() {
        Ok(config) => Ok(config),
        Err(e) => {
            error!("Configuration error: {}", e);
            Err(e.into())
        }
    }
}

/// Get city configuration for a city code
pub fn get_city_config(city: &str) -> CityConfig {
    match city {
        "FL" => CityConfig {
            name: "Florianópolis".to_string(),
            path: "florianopolis-sc".to_string(),
        },
        "RJ" => CityConfig {
            name: "Rio de Janeiro".to_string(),
            path: "rio-de-janeiro-rj".to_string(),
        },
        "SP" => CityConfig {
            name: "São Paulo".to_string(),
            path: "sao-paulo-sp".to_string(),
        },
        _ => CityConfig {
            name: "Florianópolis".to_string(),
            path: "florianopolis-sc".to_string(),
        },
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::env;

    // Helper to set environment variables for tests
    fn set_test_env() {
        env::set_var("CITY", "RJ");
        env::set_var("FIRECRAWL_API_KEY", "test-api-key");
        env::set_var("PROVIDER", "pikachu");
        env::set_var("PIKACHU_API_URL", "https://example.com");
        env::set_var("MAX_EVENTS", "5");
    }

    // Helper to clear environment variables after tests
    fn clear_test_env() {
        env::remove_var("CITY");
        env::remove_var("FIRECRAWL_API_KEY");
        env::remove_var("PROVIDER");
        env::remove_var("PIKACHU_API_URL");
        env::remove_var("MAX_EVENTS");
        env::remove_var("USE_FIRECRAWL");
        env::remove_var("EXTRACTION_FOLDER");
    }

    #[test]
    fn test_get_city_config() {
        let fl_config = get_city_config("FL");
        assert_eq!(fl_config.name, "Florianópolis");
        assert_eq!(fl_config.path, "florianopolis-sc");

        let rj_config = get_city_config("RJ");
        assert_eq!(rj_config.name, "Rio de Janeiro");
        assert_eq!(rj_config.path, "rio-de-janeiro-rj");

        let sp_config = get_city_config("SP");
        assert_eq!(sp_config.name, "São Paulo");
        assert_eq!(sp_config.path, "sao-paulo-sp");

        let unknown_config = get_city_config("UNKNOWN");
        assert_eq!(unknown_config.name, "Florianópolis");
        assert_eq!(unknown_config.path, "florianopolis-sc");
    }

    #[test]
    fn test_config_with_env_vars() {
        // Set environment variables for testing
        set_test_env();

        let config = get_config().unwrap();

        assert_eq!(config.city, "RJ");
        assert_eq!(config.city_config.name, "Rio de Janeiro");
        assert_eq!(config.city_config.path, "rio-de-janeiro-rj");
        assert_eq!(config.api_key, "test-api-key");
        assert_eq!(config.target_url, "https://example.com");
        assert_eq!(config.max_events, 5);
        assert_eq!(config.provider, "pikachu");
        assert_eq!(config.use_firecrawl, true);
        assert_eq!(config.extraction_folder, None);

        // Reset environment variables
        clear_test_env();
    }

    #[test]
    fn test_config_with_static_extraction() {
        // Set environment variables for testing
        env::set_var("CITY", "FL");
        env::set_var("PROVIDER", "pikachu");
        env::set_var("PIKACHU_API_URL", "https://example.com");
        env::set_var("USE_FIRECRAWL", "false");
        env::set_var("EXTRACTION_FOLDER", "./tests/httrack");

        // Create the test folder
        let test_folder = Path::new("./tests/httrack");
        if !test_folder.exists() {
            fs::create_dir_all(test_folder).unwrap();
        }

        let config = get_config().unwrap();

        assert_eq!(config.city, "FL");
        assert_eq!(config.use_firecrawl, false);
        assert_eq!(config.extraction_folder, Some("./tests/httrack".to_string()));

        // Remove the test folder
        fs::remove_dir_all(test_folder).ok();

        // Reset environment variables
        clear_test_env();
    }

    #[test]
    fn test_config_with_charmander_provider() {
        // Set environment variables for testing
        env::set_var("PROVIDER", "charmander");
        env::set_var("FIRECRAWL_API_KEY", "test-api-key");
        env::set_var("CHARMANDER_API_URL", "https://example.com/events");

        let config = get_config().unwrap();

        assert_eq!(config.provider, "charmander");
        assert_eq!(config.target_url, "https://example.com/events");

        // Reset environment variables
        env::remove_var("PROVIDER");
        env::remove_var("FIRECRAWL_API_KEY");
        env::remove_var("CHARMANDER_API_URL");
    }

    #[test]
    fn test_config_builder() {
        let config = ConfigBuilder::new()
            .city("RJ")
            .api_key("test-key")
            .provider("pikachu")
            .target_url("https://example.com")
            .max_events(50)
            .build()
            .unwrap();

        assert_eq!(config.city, "RJ");
        assert_eq!(config.city_config.name, "Rio de Janeiro");
        assert_eq!(config.api_key, "test-key");
        assert_eq!(config.provider, "pikachu");
        assert_eq!(config.target_url, "https://example.com");
        assert_eq!(config.max_events, 50);
        assert_eq!(config.use_firecrawl, true);
    }

    #[test]
    fn test_static_extraction_config() {
        // Create the test folder
        let test_folder = Path::new("./tests/httrack");
        if !test_folder.exists() {
            fs::create_dir_all(test_folder).unwrap();
        }

        let config = ConfigBuilder::new()
            .city("FL")
            .target_url("https://example.com")
            .provider("pikachu")
            .use_firecrawl(false)
            .extraction_folder("./tests/httrack")
            .build()
            .unwrap();

        assert_eq!(config.city, "FL");
        assert_eq!(config.use_firecrawl, false);
        assert_eq!(config.extraction_folder, Some("./tests/httrack".to_string()));

        // Remove the test folder
        fs::remove_dir_all(test_folder).ok();
    }

    #[test]
    fn test_invalid_static_extraction() {
        let result = ConfigBuilder::new()
            .city("FL")
            .target_url("https://example.com")
            .provider("pikachu")
            .use_firecrawl(false)
            .build();

        assert!(result.is_err());
        match result {
            Err(ConfigError::MissingValue(msg)) => {
                assert!(msg.contains("extraction_folder is required"));
            }
            _ => panic!("Expected MissingValue error for extraction_folder"),
        }
    }

    #[test]
    fn test_timeout() {
        let config = ConfigBuilder::new()
            .city("FL")
            .api_key("test-key")
            .target_url("https://example.com")
            .provider("pikachu")
            .timeout_seconds(45)
            .build()
            .unwrap();

        assert_eq!(config.timeout(), Duration::from_secs(45));
    }

    #[test]
    fn test_date_range() {
        let config = ConfigBuilder::new()
            .city("FL")
            .api_key("test-key")
            .target_url("https://example.com")
            .provider("pikachu")
            .start_date("2025-01-01")
            .end_date("2025-12-31")
            .build()
            .unwrap();

        assert_eq!(config.date_range.start_date, Some("2025-01-01".to_string()));
        assert_eq!(config.date_range.end_date, Some("2025-12-31".to_string()));
        assert!(config.date_range.is_specified());
    }
}