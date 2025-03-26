use crate::models::local::Favorite;
use gloo::storage::{LocalStorage, Storage};
use serde::{de::DeserializeOwned, Serialize};

const FAVORITES_KEY: &str = "ihoje-favorites";

/// Storage utility for favorites and app state
pub struct StorageService;

impl StorageService {
    /// Get all favorites
    pub fn get_favorites() -> Vec<Favorite> {
        LocalStorage::get(FAVORITES_KEY).unwrap_or_else(|_| Vec::new())
    }

    /// Save a favorite
    pub fn add_favorite(event_id: &str) -> Result<(), String> {
        let mut favorites = Self::get_favorites();

        // Check if already favorited
        if favorites.iter().any(|f| f.event_id == event_id) {
            return Ok(());
        }

        // Add new favorite
        let new_favorite = Favorite {
            event_id: event_id.to_string(),
            saved_at: chrono::Utc::now().to_rfc3339(),
        };

        favorites.push(new_favorite);
        Self::save_data(FAVORITES_KEY, &favorites)
    }

    /// Remove a favorite
    pub fn remove_favorite(event_id: &str) -> Result<(), String> {
        let mut favorites = Self::get_favorites();
        favorites.retain(|f| f.event_id != event_id);
        Self::save_data(FAVORITES_KEY, &favorites)
    }

    /// Check if an event is favorited
    pub fn is_favorite(event_id: &str) -> bool {
        Self::get_favorites().iter().any(|f| f.event_id == event_id)
    }

    /// Generic function to save data to storage
    fn save_data<T: Serialize>(key: &str, data: &T) -> Result<(), String> {
        LocalStorage::set(key, data).map_err(|e| format!("Failed to save to local storage: {}", e))
    }

    /// Generic function to load data from storage
    pub fn load_data<T: DeserializeOwned>(key: &str) -> Option<T> {
        LocalStorage::get(key).ok()
    }
}
