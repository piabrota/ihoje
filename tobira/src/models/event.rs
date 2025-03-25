use serde::{Deserialize, Serialize};

/// Event model that matches the backend EventData structure
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
}

/// A structure for tracking favorite events
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct Favorite {
    pub event_id: String,
    pub saved_at: String,
}

/// Event filter model for search and filter operations
#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq)]
pub struct EventFilter {
    pub search_term: Option<String>,
    pub city: Option<String>,
    pub date_from: Option<String>,
    pub date_to: Option<String>,
    pub price_free: bool,
}

impl Event {
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
    
    /// Compare this event to search filters
    pub fn matches_filter(&self, filter: &EventFilter) -> bool {
        // Search term filter
        if let Some(term) = &filter.search_term {
            if !term.is_empty() && !self.title.to_lowercase().contains(&term.to_lowercase()) {
                return false;
            }
        }
        
        // City filter
        if let Some(city) = &filter.city {
            if !city.is_empty() && self.city != *city {
                return false;
            }
        }
        
        // Free event filter
        if filter.price_free && !self.is_free() {
            return false;
        }
        
        // Date filter not implemented yet
        // Would require proper date parsing
        
        true
    }
}