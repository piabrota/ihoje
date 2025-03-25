//! Database module for persistence
//!
//! This module provides database operations for storing and retrieving events.

pub mod postgres;
pub mod gcp;

use anyhow::Result;
use crate::event::EventData;
use serde::{Deserialize, Serialize};
use std::fmt;

/// Format for data export
#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize, clap::ValueEnum)]
#[serde(rename_all = "lowercase")]
pub enum ExportFormat {
    /// Export to GCP (Google Cloud Storage) bucket
    Gcp,
    /// Export to PostgreSQL database (preferred)
    Postgres,
    /// Export to PostgreSQL with GCP fallback
    PgWithGcpFallback,
    /// Export to both PostgreSQL and GCP
    Both,
}

impl fmt::Display for ExportFormat {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            ExportFormat::Gcp => write!(f, "gcp"),
            ExportFormat::Postgres => write!(f, "postgres"),
            ExportFormat::PgWithGcpFallback => write!(f, "pg_with_gcp_fallback"),
            ExportFormat::Both => write!(f, "both"),
        }
    }
}

impl From<String> for ExportFormat {
    fn from(s: String) -> Self {
        match s.to_lowercase().as_str() {
            "gcp" => ExportFormat::Gcp,
            "pg_with_gcp_fallback" | "pgwithgcpfallback" | "fallback" => ExportFormat::PgWithGcpFallback,
            "both" => ExportFormat::Both,
            _ => ExportFormat::Postgres, // Default to Postgres for any unrecognized format
        }
    }
}

/// Trait for database operations
pub trait EventStore {
    /// Store multiple events
    fn store_events(&self, events: &[EventData]) -> Result<()>;
    
    /// Clear all events (for testing/cleanup)
    fn clear_events(&self) -> Result<()>;
    
    /// Get all events with optional filters
    fn get_events(&self, city: Option<&str>, limit: Option<usize>) -> Result<Vec<EventData>>;
    
    /// Get a specific event by its ID
    fn get_event_by_id(&self, id: &str) -> Result<Option<EventData>>;
    
    /// Get upcoming events (future dates)
    fn get_upcoming_events(&self, city: Option<&str>, limit: Option<usize>) -> Result<Vec<EventData>>;
}