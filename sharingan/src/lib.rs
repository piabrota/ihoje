/*!
# Rust Event Scraper

A simple, efficient scraper for events that respects API rate limits and provides
comprehensive error tracking and logging.

## Architecture

This library implements a modular event scraping system with the following components:

- **config**: Configuration loading and management
- **event**: Event data structures and extraction logic
- **exporter**: CSV and data export utilities
- **logger**: Logging setup and utilities
- **rate_limiter**: API rate limiting implementation
- **sharingan**: Core web scraping functionality with visual pattern recognition
- **db**: Database integration and storage
- **exporters**: Export functionality for various formats
- **providers**: Provider implementations for different event sources

## Usage

See the `main.rs` file for the binary implementation that uses this library.
*/

// Re-export modules for integration testing
pub mod config;
pub mod db;
pub mod event;
pub mod exporter;
pub mod exporters;
pub mod logger;
pub mod providers;
pub mod rate_limiter;
pub mod sharingan;

// Re-export common types
pub use config::{get_config, AppConfig};
pub use db::{EventStore, ExportFormat};
pub use event::{EventData, FailedPriceFetch};
pub use exporters::Exporter;
pub use providers::{get_provider, EventProvider, Provider};
