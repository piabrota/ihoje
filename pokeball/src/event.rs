use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};

/// Shared event model used by both tobira and backend
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct Event {
    pub id: String,
    pub title: String,
    pub date: String,
    pub location: String,
    pub url: String,
    pub image_url: String,
    pub city: String,
    pub price: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub created_at: Option<DateTime<Utc>>,
}

impl Event {
    /// Create a new event with default "Fetching..." price
    pub fn new(
        id: String,
        title: String,
        date: String,
        location: String,
        url: String,
        image_url: String,
        city: String,
    ) -> Self {
        Self {
            id,
            title,
            date,
            location,
            url,
            image_url,
            city,
            price: "Fetching...".to_string(),
            created_at: Some(Utc::now()),
        }
    }
    
    /// Determine if this event is free
    pub fn is_free(&self) -> bool {
        self.price.contains("R$ 0,00") || 
        self.price.to_lowercase().contains("grátis") ||
        self.price.to_lowercase().contains("gratuito")
    }
    
    /// Get a formatted date string 
    pub fn formatted_date(&self) -> String {
        // Simple passthrough for now, could be enhanced with date formatting
        self.date.clone()
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
        format!("Error fetching price for '{}' (ID: {}): {}", 
                self.title, self.id, self.error)
    }
}