//! Module template showing best practices for a standard Rust module.
//!
//! This module demonstrates the recommended structure, documentation style,
//! error handling patterns, and code organization practices for Rust modules.

// Standard library imports
use std::collections::HashMap;
use std::fmt;
use std::fs;
use std::io::{self, Read};
use std::path::Path;

// External crate imports (alphabetical order)
use anyhow::{Context, Result};
use log::{debug, error, info, warn};
use serde::{Deserialize, Serialize};
use thiserror::Error;

// Internal crate imports
use crate::config::Config;
use crate::util::helpers;

// -----------------------------------------------------------------------------
// Public Types
// -----------------------------------------------------------------------------

/// A high-level description of what this type represents.
///
/// More detailed explanation of the type's purpose, behavior, and usage.
///
/// # Examples
///
/// ```
/// use crate::module_name::ExampleType;
///
/// let example = ExampleType::new("example");
/// assert_eq!(example.name(), "example");
/// ```
#[derive(Debug, Clone, PartialEq, Eq, Deserialize, Serialize)]
pub struct ExampleType {
    /// The name of the example (public field with documentation)
    pub name: String,
    
    // Private fields don't need doc comments but should have regular comments
    data: HashMap<String, u32>,
    status: Status,
}

/// Represents the status of an `ExampleType`.
///
/// This enum is used to track the lifecycle state of an example.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Deserialize, Serialize)]
pub enum Status {
    /// Item is being initialized
    Initializing,
    /// Item is active and ready for use
    Active,
    /// Item has been deactivated
    Inactive,
    /// Item has been marked for deletion
    PendingDeletion,
}

/// Custom error type for this module.
///
/// This pattern centralizes all possible errors from this module in one type,
/// making error handling more consistent and maintainable.
#[derive(Error, Debug)]
pub enum ModuleError {
    /// Used when a requested resource is not found
    #[error("Resource not found: {0}")]
    NotFound(String),
    
    /// Used for invalid input situations
    #[error("Invalid input: {0}")]
    InvalidInput(String),
    
    /// Used when an IO error occurs, wrapping the original error
    #[error("IO error: {0}")]
    IoError(#[from] io::Error),
    
    /// Catch-all for other errors
    #[error("Unexpected error: {0}")]
    Other(String),
}

// -----------------------------------------------------------------------------
// Public Interface
// -----------------------------------------------------------------------------

impl ExampleType {
    /// Creates a new instance with the given name.
    ///
    /// # Arguments
    ///
    /// * `name` - The name to assign to this instance
    ///
    /// # Returns
    ///
    /// A new `ExampleType` instance with the provided name.
    pub fn new(name: &str) -> Self {
        Self {
            name: name.to_string(),
            data: HashMap::new(),
            status: Status::Initializing,
        }
    }
    
    /// Returns the name of this instance.
    pub fn name(&self) -> &str {
        &self.name
    }
    
    /// Activates this instance.
    ///
    /// # Errors
    ///
    /// Returns a `ModuleError::InvalidInput` if the instance is in 
    /// `Status::PendingDeletion` state.
    pub fn activate(&mut self) -> Result<(), ModuleError> {
        if self.status == Status::PendingDeletion {
            return Err(ModuleError::InvalidInput(
                "Cannot activate an instance pending deletion".to_string()
            ));
        }
        
        debug!("Activating instance: {}", self.name);
        self.status = Status::Active;
        Ok(())
    }
    
    /// Loads data from a file into this instance.
    ///
    /// # Arguments
    ///
    /// * `path` - Path to the file to load
    ///
    /// # Errors
    ///
    /// Returns various errors if loading fails.
    pub fn load_from_file<P: AsRef<Path>>(&mut self, path: P) -> Result<()> {
        // Example of using anyhow for error context
        let data = fs::read_to_string(&path)
            .with_context(|| format!("Failed to read file: {}", path.as_ref().display()))?;
        
        // Process the data...
        info!("Loaded data from {}", path.as_ref().display());
        
        Ok(())
    }
}

// Default implementation (if appropriate)
impl Default for ExampleType {
    fn default() -> Self {
        Self::new("default")
    }
}

// Display implementation for user-friendly output
impl fmt::Display for ExampleType {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "ExampleType(name={}, status={:?})", self.name, self.status)
    }
}

// -----------------------------------------------------------------------------
// Private Helpers
// -----------------------------------------------------------------------------

// Private helper functions don't need doc comments but should have 
// regular comments describing their purpose
fn process_data(input: &str) -> Result<HashMap<String, u32>, ModuleError> {
    let mut result = HashMap::new();
    
    // Example processing logic
    for (i, line) in input.lines().enumerate() {
        let parts: Vec<&str> = line.split(',').collect();
        if parts.len() != 2 {
            return Err(ModuleError::InvalidInput(
                format!("Invalid format on line {}: expected 2 parts", i + 1)
            ));
        }
        
        let key = parts[0].trim().to_string();
        let value = parts[1].trim().parse::<u32>()
            .map_err(|_| ModuleError::InvalidInput(
                format!("Invalid number on line {}", i + 1)
            ))?;
        
        result.insert(key, value);
    }
    
    Ok(result)
}

// -----------------------------------------------------------------------------
// Tests
// -----------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_example_new() {
        let example = ExampleType::new("test");
        assert_eq!(example.name, "test");
        assert_eq!(example.status, Status::Initializing);
        assert!(example.data.is_empty());
    }
    
    #[test]
    fn test_example_activate() {
        let mut example = ExampleType::new("test");
        assert_eq!(example.status, Status::Initializing);
        
        example.activate().unwrap();
        assert_eq!(example.status, Status::Active);
    }
    
    #[test]
    fn test_example_activate_pending_deletion() {
        let mut example = ExampleType::new("test");
        example.status = Status::PendingDeletion;
        
        let result = example.activate();
        assert!(result.is_err());
        if let Err(ModuleError::InvalidInput(msg)) = result {
            assert!(msg.contains("pending deletion"));
        } else {
            panic!("Expected InvalidInput error");
        }
    }
    
    #[test]
    fn test_process_data_valid() {
        let input = "key1, 123\nkey2, 456";
        let result = process_data(input).unwrap();
        
        assert_eq!(result.len(), 2);
        assert_eq!(result.get("key1"), Some(&123));
        assert_eq!(result.get("key2"), Some(&456));
    }
    
    #[test]
    fn test_process_data_invalid_format() {
        let input = "key1, 123, extra\nkey2, 456";
        let result = process_data(input);
        
        assert!(result.is_err());
        if let Err(ModuleError::InvalidInput(msg)) = result {
            assert!(msg.contains("Invalid format on line 1"));
        } else {
            panic!("Expected InvalidInput error");
        }
    }
    
    #[test]
    fn test_process_data_invalid_number() {
        let input = "key1, 123\nkey2, not_a_number";
        let result = process_data(input);
        
        assert!(result.is_err());
        if let Err(ModuleError::InvalidInput(msg)) = result {
            assert!(msg.contains("Invalid number on line 2"));
        } else {
            panic!("Expected InvalidInput error");
        }
    }
}