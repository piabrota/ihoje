//! Error handling patterns and best practices for Rust.
//!
//! This module demonstrates recommended error handling approaches:
//! 1. Custom error types with thiserror
//! 2. Error context with anyhow
//! 3. Result type propagation
//! 4. Error conversion

// Standard library imports
use std::fmt;
use std::io;
use std::path::PathBuf;

// External crate imports
use thiserror::Error;

// -----------------------------------------------------------------------------
// Custom Error Type Pattern
// -----------------------------------------------------------------------------

/// Errors that can occur in the scraper module.
///
/// This enum provides a structured way to represent different error scenarios
/// that might occur within the scraper module, with meaningful error messages.
#[derive(Error, Debug)]
pub enum ScraperError {
    /// Network error during request
    #[error("Network error: {0}")]
    NetworkError(String),
    
    /// URL parsing error
    #[error("Invalid URL: {0}")]
    InvalidUrl(String),
    
    /// Resource not found (404)
    #[error("Resource not found: {0}")]
    NotFound(String),
    
    /// Rate limiting error
    #[error("Rate limited: retry after {0} seconds")]
    RateLimited(u64),
    
    /// Authentication error
    #[error("Authentication failed: {0}")]
    AuthenticationError(String),
    
    /// Data parsing error
    #[error("Failed to parse data: {0}")]
    ParseError(String),
    
    /// Wraps I/O errors
    #[error("I/O error: {0}")]
    IoError(#[from] io::Error),
    
    /// Wraps URL parsing errors
    #[error("URL parsing error: {0}")]
    UrlParseError(#[from] url::ParseError),
    
    /// Wraps JSON serialization/deserialization errors
    #[error("JSON error: {0}")]
    JsonError(#[from] serde_json::Error),
    
    /// Wraps reqwest HTTP client errors
    #[error("HTTP error: {0}")]
    HttpError(#[from] reqwest::Error),
    
    /// Any other error
    #[error("Other error: {0}")]
    Other(String),
}

// -----------------------------------------------------------------------------
// Error Context with anyhow
// -----------------------------------------------------------------------------

/// Function demonstrating the use of anyhow for context-rich errors.
///
/// This pattern is useful for propagating errors up the call stack
/// while adding context at each level.
pub fn read_config_file(path: &str) -> anyhow::Result<String> {
    // Read file with added context
    let content = std::fs::read_to_string(path)
        .with_context(|| format!("Failed to read config file at '{}'", path))?;
        
    // Parse content with added context
    parse_config(&content)
        .with_context(|| format!("Config file at '{}' has invalid format", path))?;
        
    Ok(content)
}

// Helper function that returns a Result
fn parse_config(content: &str) -> Result<(), ScraperError> {
    // Example validation
    if content.trim().is_empty() {
        return Err(ScraperError::ParseError("Config file is empty".to_string()));
    }
    
    // More parsing logic would go here...
    
    Ok(())
}

// -----------------------------------------------------------------------------
// Result Type Propagation
// -----------------------------------------------------------------------------

/// Function demonstrating the ? operator for error propagation.
///
/// This shows how to chain operations that might fail, leveraging
/// Rust's ? operator to propagate errors up the call stack.
pub fn fetch_and_process_data(url: &str, output_path: &str) -> Result<(), ScraperError> {
    // Fetch data (? propagates errors)
    let data = fetch_data(url)?;
    
    // Process data (? propagates errors)
    let processed_data = process_data(&data)?;
    
    // Save results (? propagates errors)
    save_data(&processed_data, output_path)?;
    
    Ok(())
}

// Example helpers returning Results
fn fetch_data(url: &str) -> Result<String, ScraperError> {
    // Example implementation
    if url.starts_with("https://") {
        Ok("example data".to_string())
    } else {
        Err(ScraperError::InvalidUrl(format!("URL must use HTTPS: {}", url)))
    }
}

fn process_data(data: &str) -> Result<String, ScraperError> {
    // Example implementation
    if data.is_empty() {
        Err(ScraperError::ParseError("Empty data received".to_string()))
    } else {
        Ok(format!("Processed: {}", data))
    }
}

fn save_data(data: &str, path: &str) -> Result<(), ScraperError> {
    // Example implementation
    std::fs::write(path, data)
        .map_err(|e| ScraperError::IoError(e))?;
    Ok(())
}

// -----------------------------------------------------------------------------
// Error Conversion Pattern
// -----------------------------------------------------------------------------

/// Function showing how to convert between different error types.
///
/// This demonstrates how to convert errors from one type to another,
/// either using the From trait or manual conversion.
pub fn load_scraper_config(path: PathBuf) -> Result<ScraperConfig, ScraperError> {
    // Read file with std::io::Error
    let content = std::fs::read_to_string(path)
        .map_err(|e| ScraperError::IoError(e))?; // Using From trait impl
    
    // Parse JSON with serde_json::Error
    let config: ScraperConfig = serde_json::from_str(&content)
        .map_err(|e| ScraperError::JsonError(e))?; // Using From trait impl
    
    // Manual validation with custom error
    if config.timeout == 0 {
        return Err(ScraperError::ParseError("Timeout cannot be zero".to_string()));
    }
    
    Ok(config)
}

/// Example configuration struct.
#[derive(Debug, serde::Deserialize)]
pub struct ScraperConfig {
    pub url: String,
    pub timeout: u64,
    pub retry_count: u32,
}

// -----------------------------------------------------------------------------
// Tests
// -----------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;
    use anyhow::Context;
    
    #[test]
    fn test_fetch_data_valid_url() {
        let result = fetch_data("https://example.com");
        assert!(result.is_ok());
    }
    
    #[test]
    fn test_fetch_data_invalid_url() {
        let result = fetch_data("http://example.com");
        assert!(result.is_err());
        
        match result {
            Err(ScraperError::InvalidUrl(msg)) => {
                assert!(msg.contains("must use HTTPS"));
            }
            _ => panic!("Expected InvalidUrl error"),
        }
    }
    
    #[test]
    fn test_process_data_valid() {
        let result = process_data("some data");
        assert!(result.is_ok());
        assert_eq!(result.unwrap(), "Processed: some data");
    }
    
    #[test]
    fn test_process_data_empty() {
        let result = process_data("");
        assert!(result.is_err());
        
        match result {
            Err(ScraperError::ParseError(msg)) => {
                assert!(msg.contains("Empty data"));
            }
            _ => panic!("Expected ParseError error"),
        }
    }
}