# Config.rs Implementation Plan

## Current State
The current `config.rs` file has:
- Basic environment variable loading
- Configuration structures (AppConfig, CityConfig, DateRange, DatabaseConfig)
- Simple validation methods
- Basic tests

## Improvements Based on Template

### 1. Custom Error Type
- Add `ConfigError` enum for better error handling
- Implement thiserror for more descriptive errors
- Replace anyhow errors with custom error types

### 2. Builder Pattern
- Add `ConfigBuilder` struct for fluent API
- Implement all builder methods similar to template
- Move validation to builder

### 3. Enhanced Validation
- Better validation for API keys
- Better validation for provider values
- Better validation for export format

### 4. Loading Options
- Implement JSON file loading method
- Add fallback loading mechanism (env or file)

### 5. Helper Methods
- Add connection string helper method
- Add timeout duration method

### 6. Improved Documentation
- Add module-level documentation
- Improve struct-level documentation
- Add examples

## Implementation Steps

1. Create Custom Error Type:
```rust
#[derive(Error, Debug)]
pub enum ConfigError {
    #[error("Invalid configuration value: {0}")]
    InvalidValue(String),
    
    #[error("Missing required configuration: {0}")]
    MissingValue(String),
    
    #[error("Environment error: {0}")]
    EnvError(#[from] env::VarError),
    
    // Other error types...
}
```

2. Implement Builder Pattern:
```rust
pub struct ConfigBuilder {
    config: AppConfig,
}

impl ConfigBuilder {
    pub fn new() -> Self {
        Self {
            config: AppConfig::default(),
        }
    }
    
    pub fn city(mut self, city: impl Into<String>) -> Self {
        self.config.city = city.into();
        self
    }
    
    // Other builder methods...
    
    pub fn build(self) -> Result<AppConfig, ConfigError> {
        // Validation logic here
        Ok(self.config)
    }
}
```

3. Add Default Implementation for AppConfig:
```rust
impl Default for AppConfig {
    fn default() -> Self {
        Self {
            city: "FL".to_string(),
            city_config: CityConfig {
                name: "Florianópolis".to_string(),
                path: "florianopolis-sc".to_string(),
            },
            // Set other defaults...
        }
    }
}
```

4. Implement Methods for Loading Configuration:
```rust
impl AppConfig {
    pub fn from_env() -> Result<Self, ConfigError> {
        // Logic to load from environment
    }
    
    pub fn from_json_file<P: AsRef<Path>>(path: P) -> Result<Self, ConfigError> {
        // Logic to load from JSON file
    }
    
    pub fn from_env_or_file<P: AsRef<Path>>(path: P) -> Result<Self, anyhow::Error> {
        // Logic to load from env or fall back to file
    }
}
```

5. Update Tests for New Functionality:
```rust
#[test]
fn test_config_builder() {
    let config = ConfigBuilder::new()
        .city("RJ")
        .api_key("test-key")
        .build()
        .unwrap();
        
    assert_eq!(config.city, "RJ");
    assert_eq!(config.api_key, "test-key");
}
```

## Migration Strategy

1. Add the new types and implementations without removing existing code
2. Update the tests to verify new functionality
3. Gradually replace the direct loading with the builder pattern
4. Add serde support for file loading
5. Clean up and remove any redundant code