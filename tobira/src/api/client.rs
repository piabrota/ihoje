use reqwasm::http::{Request, Response};
use serde::de::DeserializeOwned;
use pokeball::{Event, EventQuery};
use log;
use web_sys::AbortController;
use gloo::timers::callback::Timeout;
use wasm_bindgen::JsCast;
use gloo_storage::{LocalStorage, Storage as GlooStorage};
use yew_router::prelude::*;

use crate::utils::mock_data::{generate_fake_events, is_mock_data_enabled};
use crate::utils::config::get_config;
use crate::models::User;
use crate::router::Route;
use super::error::{ApiError, ApiResult};

// Key for storing the auth session in local storage
const AUTH_STORAGE_KEY: &str = "ihoje_auth";

/// API client for interacting with the backend
#[derive(Debug, Clone, Default)]
pub struct ApiClient {
    base_url: String,
    auth_token: Option<String>,
}

impl ApiClient {
    /// Create a new API client with default base URL from configuration
    pub fn new() -> Self {
        // Try to get auth token from storage
        let auth_token = Self::get_auth_token_from_storage();
        
        Self {
            base_url: get_config().api_base_url.clone(),
            auth_token,
        }
    }
    
    /// Create a new API client with a custom base URL
    pub fn with_base_url(base_url: impl Into<String>) -> Self {
        // Try to get auth token from storage
        let auth_token = Self::get_auth_token_from_storage();
        
        Self {
            base_url: base_url.into(),
            auth_token,
        }
    }
    
    /// Create a new API client with an auth token
    pub fn with_auth_token(token: impl Into<String>) -> Self {
        Self {
            base_url: get_config().api_base_url.clone(),
            auth_token: Some(token.into()),
        }
    }
    
    /// Set the auth token for this client
    pub fn set_auth_token(&mut self, token: impl Into<String>) {
        self.auth_token = Some(token.into());
    }
    
    /// Clear the auth token for this client
    pub fn clear_auth_token(&mut self) {
        self.auth_token = None;
    }
    
    /// Get the configured API timeout
    fn timeout_ms(&self) -> u32 {
        get_config().api_timeout_seconds * 1000
    }
    
    /// Try to get auth token from local storage
    fn get_auth_token_from_storage() -> Option<String> {
        match LocalStorage::get::<String>(AUTH_STORAGE_KEY) {
            Ok(json) => {
                // Parse the user JSON and extract the token
                match serde_json::from_str::<User>(&json) {
                    Ok(user) => user.access_token,
                    Err(e) => {
                        log::warn!("Failed to parse user from storage: {}", e);
                        None
                    }
                }
            }
            Err(_) => None,
        }
    }
    
    /// Fetch events with query parameters
    pub async fn fetch_events(&self, query: EventQuery) -> ApiResult<Vec<Event>> {
        // Check if mock data mode is enabled
        if is_mock_data_enabled() {
            log::info!("Using mock data for events");
            return Ok(self.apply_query_to_mock_events(query));
        }
        
        let query_string = self.build_query_string(&query);
        let url = format!("{}/events{}", self.base_url, query_string);
        
        self.get(&url).await
    }
    
    /// Fetch a single event by ID
    pub async fn fetch_event(&self, id: &str) -> ApiResult<Event> {
        // Check if mock data mode is enabled
        if is_mock_data_enabled() {
            log::info!("Using mock data for event details: {}", id);
            return self.get_mock_event(id);
        }
        
        let url = format!("{}/events/{}", self.base_url, id);
        self.get(&url).await
    }
    
    /// Fetch available cities
    pub async fn fetch_cities(&self) -> ApiResult<Vec<String>> {
        // Check if mock data mode is enabled
        if is_mock_data_enabled() {
            log::info!("Using mock data for cities");
            return Ok(vec!["FL".to_string(), "SP".to_string(), "RJ".to_string()]);
        }
        
        let url = format!("{}/cities", self.base_url);
        self.get(&url).await
    }
    
    // ======= Admin API Methods =======
    
    /// Fetch all events with full details (admin only)
    pub async fn fetch_events_admin(&self) -> ApiResult<Vec<Event>> {
        // Check if mock data mode is enabled
        if is_mock_data_enabled() {
            log::info!("Using mock data for admin events");
            return Ok(self.apply_query_to_mock_events(Default::default()));
        }
        
        let url = format!("{}/admin/events", self.base_url);
        self.get(&url).await
    }
    
    /// Create a new event (admin only)
    pub async fn create_event(&self, event: &Event) -> ApiResult<Event> {
        // Check if mock data mode is enabled
        if is_mock_data_enabled() {
            log::info!("Using mock data for create event");
            return Ok(event.clone());
        }
        
        let url = format!("{}/admin/events", self.base_url);
        self.post(&url, event).await
    }
    
    /// Update an existing event (admin only)
    pub async fn update_event(&self, event: &Event) -> ApiResult<Event> {
        // Check if mock data mode is enabled
        if is_mock_data_enabled() {
            log::info!("Using mock data for update event");
            return Ok(event.clone());
        }
        
        let url = format!("{}/admin/events/{}", self.base_url, event.id);
        self.put(&url, event).await
    }
    
    /// Delete an event (admin only)
    pub async fn delete_event(&self, id: &str) -> ApiResult<()> {
        // Check if mock data mode is enabled
        if is_mock_data_enabled() {
            log::info!("Using mock data for delete event");
            return Ok(());
        }
        
        let url = format!("{}/admin/events/{}", self.base_url, id);
        self.delete(&url).await
    }
    
    /// Check server status and redirect to appropriate error pages if needed
    pub async fn check_server_status(&self) -> ApiResult<bool> {
        // Health check endpoint (typically /health or /api/health)
        let health_url = format!("{}/health", self.base_url);
        
        // Simple health check with short timeout
        let abort_controller = AbortController::new().map_err(|_| {
            ApiError::NetworkError("Failed to create abort controller".to_string())
        })?;
        let abort_signal = abort_controller.signal();
        
        // Shorter timeout for health check
        let abort_controller_clone = abort_controller.clone();
        let timeout = Timeout::new(5000, move || {
            log::warn!("Health check timed out");
            abort_controller_clone.abort();
        });
        
        let result = Request::get(&health_url)
            .header("Content-Type", "application/json")
            .abort_signal(Some(&abort_signal))
            .send()
            .await;
            
        // Cancel the timeout
        timeout.cancel();
        
        match result {
            Ok(response) => {
                let status = response.status();
                
                // Handle various status codes
                match status {
                    // Healthy
                    200 => Ok(true),
                    
                    // Maintenance mode
                    503 => {
                        if let Some(navigator) = use_navigator() {
                            navigator.push(&Route::Maintenance);
                        }
                        Ok(false)
                    },
                    
                    // Other errors redirect to error page
                    _ => {
                        if let Some(navigator) = use_navigator() {
                            navigator.push(&Route::ServerError);
                        }
                        Ok(false)
                    }
                }
            },
            Err(_) => {
                // Network error or timeout, redirect to error page
                if let Some(navigator) = use_navigator() {
                    navigator.push(&Route::ServerError);
                }
                Ok(false)
            }
        }
    }
    
    /// Generic GET request method with improved security
    async fn get<T: DeserializeOwned>(&self, url: &str) -> ApiResult<T> {
        log::info!("GET request to {}", url);
        
        // Create an abort controller for the timeout
        let abort_controller = AbortController::new().map_err(|_| {
            ApiError::NetworkError("Failed to create abort controller".to_string())
        })?;
        let abort_signal = abort_controller.signal();
        
        // Set up a timeout 
        let timeout_ms = self.timeout_ms();
        let abort_controller_clone = abort_controller.clone();
        let timeout = Timeout::new(timeout_ms as u32, move || {
            log::warn!("Request timed out after {}ms", timeout_ms);
            abort_controller_clone.abort();
        });
        
        // Build the request with security headers
        let mut req = Request::get(url)
            .header("Content-Type", "application/json")
            .header("X-Requested-With", "XMLHttpRequest") // CSRF protection
            .header("Accept", "application/json");
            
        // Add authorization header if available
        if let Some(token) = &self.auth_token {
            req = req.header("Authorization", &format!("Bearer {}", token));
        }
        
        // Send the request
        let response = req
            .abort_signal(Some(&abort_signal))
            .send()
            .await
            .map_err(|e| {
                // Cancel the timeout
                timeout.cancel();
                ApiError::from_reqwasm_error(e)
            })?;
        
        // Cancel the timeout as request completed
        timeout.cancel();
        
        // Process the response
        self.process_response(response).await
    }
    
    /// Generic POST request method
    async fn post<T: DeserializeOwned, B: serde::Serialize>(&self, url: &str, body: &B) -> ApiResult<T> {
        log::info!("POST request to {}", url);
        
        // Create an abort controller for the timeout
        let abort_controller = AbortController::new().map_err(|_| {
            ApiError::NetworkError("Failed to create abort controller".to_string())
        })?;
        let abort_signal = abort_controller.signal();
        
        // Set up a timeout 
        let timeout_ms = self.timeout_ms();
        let abort_controller_clone = abort_controller.clone();
        let timeout = Timeout::new(timeout_ms as u32, move || {
            log::warn!("Request timed out after {}ms", timeout_ms);
            abort_controller_clone.abort();
        });
        
        // Serialize body
        let body_json = serde_json::to_string(body)
            .map_err(|e| ApiError::ParseError(format!("Failed to serialize request body: {}", e)))?;
        
        // Build the request with security headers
        let mut req = Request::post(url)
            .header("Content-Type", "application/json")
            .header("X-Requested-With", "XMLHttpRequest") // CSRF protection
            .header("Accept", "application/json");
            
        // Add authorization header if available
        if let Some(token) = &self.auth_token {
            req = req.header("Authorization", &format!("Bearer {}", token));
        }
        
        // Send the request
        let response = req
            .abort_signal(Some(&abort_signal))
            .body(body_json)
            .send()
            .await
            .map_err(|e| {
                // Cancel the timeout
                timeout.cancel();
                ApiError::from_reqwasm_error(e)
            })?;
        
        // Cancel the timeout as request completed
        timeout.cancel();
        
        // Process the response
        self.process_response(response).await
    }
    
    /// Generic PUT request method
    async fn put<T: DeserializeOwned, B: serde::Serialize>(&self, url: &str, body: &B) -> ApiResult<T> {
        log::info!("PUT request to {}", url);
        
        // Create an abort controller for the timeout
        let abort_controller = AbortController::new().map_err(|_| {
            ApiError::NetworkError("Failed to create abort controller".to_string())
        })?;
        let abort_signal = abort_controller.signal();
        
        // Set up a timeout 
        let timeout_ms = self.timeout_ms();
        let abort_controller_clone = abort_controller.clone();
        let timeout = Timeout::new(timeout_ms as u32, move || {
            log::warn!("Request timed out after {}ms", timeout_ms);
            abort_controller_clone.abort();
        });
        
        // Serialize body
        let body_json = serde_json::to_string(body)
            .map_err(|e| ApiError::ParseError(format!("Failed to serialize request body: {}", e)))?;
        
        // Build the request with security headers
        let mut req = Request::put(url)
            .header("Content-Type", "application/json")
            .header("X-Requested-With", "XMLHttpRequest") // CSRF protection
            .header("Accept", "application/json");
            
        // Add authorization header if available
        if let Some(token) = &self.auth_token {
            req = req.header("Authorization", &format!("Bearer {}", token));
        }
        
        // Send the request
        let response = req
            .abort_signal(Some(&abort_signal))
            .body(body_json)
            .send()
            .await
            .map_err(|e| {
                // Cancel the timeout
                timeout.cancel();
                ApiError::from_reqwasm_error(e)
            })?;
        
        // Cancel the timeout as request completed
        timeout.cancel();
        
        // Process the response
        self.process_response(response).await
    }
    
    /// Generic DELETE request method
    async fn delete<T: DeserializeOwned>(&self, url: &str) -> ApiResult<T> {
        log::info!("DELETE request to {}", url);
        
        // Create an abort controller for the timeout
        let abort_controller = AbortController::new().map_err(|_| {
            ApiError::NetworkError("Failed to create abort controller".to_string())
        })?;
        let abort_signal = abort_controller.signal();
        
        // Set up a timeout 
        let timeout_ms = self.timeout_ms();
        let abort_controller_clone = abort_controller.clone();
        let timeout = Timeout::new(timeout_ms as u32, move || {
            log::warn!("Request timed out after {}ms", timeout_ms);
            abort_controller_clone.abort();
        });
        
        // Build the request with security headers
        let mut req = Request::delete(url)
            .header("Content-Type", "application/json")
            .header("X-Requested-With", "XMLHttpRequest") // CSRF protection
            .header("Accept", "application/json");
            
        // Add authorization header if available
        if let Some(token) = &self.auth_token {
            req = req.header("Authorization", &format!("Bearer {}", token));
        }
        
        // Send the request
        let response = req
            .abort_signal(Some(&abort_signal))
            .send()
            .await
            .map_err(|e| {
                // Cancel the timeout
                timeout.cancel();
                ApiError::from_reqwasm_error(e)
            })?;
        
        // Cancel the timeout as request completed
        timeout.cancel();
        
        // Process the response
        self.process_response(response).await
    }
    
    /// Process an HTTP response
    async fn process_response<T: DeserializeOwned>(&self, response: Response) -> ApiResult<T> {
        let status = response.status();
        
        if !(200..300).contains(&status) {
            // Try to parse error message from response
            let error_message = match response.text().await {
                Ok(text) if !text.is_empty() => text,
                _ => format!("Request failed with status: {}", status),
            };
            
            // Handle specific status codes and redirect if necessary
            match status {
                // Authentication errors
                401 => {
                    // Redirect to login for unauthorized access
                    if let Some(navigator) = use_navigator() {
                        navigator.push(&Route::Login);
                    }
                    return Err(ApiError::AuthError(format!("Authentication required: {}", error_message)));
                },
                // Authorization errors
                403 => {
                    return Err(ApiError::AuthorizationError(format!("Access denied: {}", error_message)));
                },
                // Maintenance mode
                503 => {
                    // Redirect to maintenance page
                    if let Some(navigator) = use_navigator() {
                        navigator.push(&Route::Maintenance);
                    }
                    return Err(ApiError::ServerError { 
                        message: "Service temporarily unavailable due to maintenance".to_string(), 
                        status 
                    });
                },
                // Server errors
                500 | 502 | 504 => {
                    // Redirect to error page
                    if let Some(navigator) = use_navigator() {
                        navigator.push(&Route::ServerError);
                    }
                    return Err(ApiError::ServerError { 
                        message: format!("Server error ({}): {}", status, error_message), 
                        status 
                    });
                },
                // Other HTTP errors
                _ => return Err(ApiError::from_status(status, error_message)),
            }
        }
        
        // Parse JSON response
        response.json::<T>().await.map_err(|e| {
            ApiError::ParseError(format!("Failed to parse response: {}", e))
        })
    }
    
    /// Build query string from EventQuery
    fn build_query_string(&self, query: &EventQuery) -> String {
        let mut query_parts = Vec::new();
        
        if let Some(city) = &query.city {
            if !city.is_empty() {
                query_parts.push(format!("city={}", city));
            }
        }
        
        if let Some(search) = &query.search {
            if !search.is_empty() {
                query_parts.push(format!("search={}", search));
            }
        }
        
        if let Some(true) = query.free_only {
            query_parts.push("free_only=true".to_string());
        }
        
        if let Some(date_from) = &query.date_from {
            if !date_from.is_empty() {
                query_parts.push(format!("date_from={}", date_from));
            }
        }
        
        if let Some(date_to) = &query.date_to {
            if !date_to.is_empty() {
                query_parts.push(format!("date_to={}", date_to));
            }
        }
        
        if query_parts.is_empty() {
            String::new()
        } else {
            format!("?{}", query_parts.join("&"))
        }
    }
    
    /// Apply query filters to mock events
    fn apply_query_to_mock_events(&self, query: EventQuery) -> Vec<Event> {
        let mut events = generate_fake_events();
        
        // Apply filtering based on query parameters
        if let Some(city) = &query.city {
            if !city.is_empty() {
                events.retain(|event| event.city == *city);
            }
        }
        
        if let Some(search) = &query.search {
            if !search.is_empty() {
                let search_lower = search.to_lowercase();
                events.retain(|event| 
                    event.title.to_lowercase().contains(&search_lower) ||
                    event.location.to_lowercase().contains(&search_lower)
                );
            }
        }
        
        if let Some(true) = query.free_only {
            events.retain(|event| event.is_free());
        }
        
        if let Some(date_from) = &query.date_from {
            if !date_from.is_empty() {
                // Simple string comparison for DD/MM/YYYY format
                events.retain(|event| event.date >= *date_from);
            }
        }
        
        if let Some(date_to) = &query.date_to {
            if !date_to.is_empty() {
                // Simple string comparison for DD/MM/YYYY format
                events.retain(|event| event.date <= *date_to);
            }
        }
        
        events
    }
    
    /// Get a mock event by ID
    fn get_mock_event(&self, id: &str) -> ApiResult<Event> {
        let events = generate_fake_events();
        
        // Find the event with the matching ID
        events.iter()
            .find(|e| e.id == id)
            .cloned()
            .ok_or_else(|| ApiError::NotFound(format!("Event with ID {} not found", id)))
    }
}