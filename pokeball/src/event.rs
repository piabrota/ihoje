use chrono::{NaiveDate, Utc};
use serde::{Deserialize, Serialize};

/// Shared event model used by both tobira and backend
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct Event {
    pub id: String,
    pub title: String,
    pub description: Option<String>,
    pub url: String,
    pub date: NaiveDate,
    pub time: Option<String>,
    pub venue: Option<String>,
    pub city: String,
    pub price: Option<String>,
    pub image_url: Option<String>,
    pub provider: String,
}

impl Event {
    /// Create a new event with default values
    pub fn new(
        id: String,
        title: String,
        url: String,
        date: NaiveDate,
        city: String,
        provider: String,
    ) -> Self {
        Self {
            id,
            title,
            description: None,
            url,
            date,
            time: None,
            venue: None,
            city,
            price: Some("Fetching...".to_string()),
            image_url: None,
            provider,
        }
    }

    /// Determine if this event is free
    pub fn is_free(&self) -> bool {
        if let Some(price) = &self.price {
            price.contains("R$ 0,00")
                || price.to_lowercase().contains("grátis")
                || price.to_lowercase().contains("gratuito")
                || price.to_lowercase().contains("free")
                || price.to_lowercase().contains("$0")
        } else {
            false
        }
    }

    /// Get a formatted date string
    pub fn formatted_date(&self) -> String {
        self.date.format("%d/%m/%Y").to_string()
    }
}

/// Track failed price fetches
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FailedPriceFetch {
    pub id: String,
    pub title: String,
    pub url: String,
    pub error: String,
    pub timestamp: String,
}

impl FailedPriceFetch {
    /// Create a new failed price fetch record
    pub fn new(event: &Event, error: String) -> Self {
        Self {
            id: event.id.clone(),
            title: event.title.clone(),
            url: event.url.clone(),
            error,
            timestamp: Utc::now().to_rfc3339(),
        }
    }

    /// Get a formatted string with error details
    pub fn error_details(&self) -> String {
        format!(
            "Error fetching price for '{}' (ID: {}): {}",
            self.title, self.id, self.error
        )
    }
}
