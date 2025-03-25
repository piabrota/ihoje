pub mod csv;

use anyhow::Result;
use crate::event::EventData;
use crate::event::FailedPriceFetch;

/// Trait for data exporting
pub trait Exporter {
    /// Export event data
    fn export_events(&self, events: &[EventData], timestamp: &str) -> Result<String>;
    
    /// Export failed price fetches
    fn export_failures(&self, failures: &[FailedPriceFetch], timestamp: &str) -> Result<String>;
}