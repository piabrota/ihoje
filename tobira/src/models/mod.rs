// Export shared models from the pokeball crate
pub use pokeball::{Event, EventQuery};

// Export user models
pub use self::user::{User, UserRole, AuthState};

// Local models that are specific to the tobira
pub mod local {
    // Import shared event model
    use pokeball::Event;
    use serde::{Deserialize, Serialize};
    
    /// A structure for tracking favorite events
    #[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
    pub struct Favorite {
        pub event_id: String,
        pub saved_at: String,
    }
    
    /// Helper functions for Event model
    pub trait EventHelpers {
        fn is_free(&self) -> bool;
        fn formatted_date(&self) -> String;
    }
    
    impl EventHelpers for Event {
        /// Determine if this event is free
        fn is_free(&self) -> bool {
            self.price.contains("R$ 0,00") || 
            self.price.to_lowercase().contains("grátis") ||
            self.price.to_lowercase().contains("gratuito")
        }
        
        /// Get a formatted date string 
        fn formatted_date(&self) -> String {
            // Simple passthrough for now, could be enhanced with date formatting
            self.date.clone()
        }
    }
}