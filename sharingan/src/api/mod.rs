use axum::{
    routing::get,
    Router,
};
use serde::Serialize;
use crate::config::AppConfig;
use std::sync::Arc;

// Database API module
pub mod database;

// API response types
#[derive(Debug, Serialize)]
pub struct ApiError {
    pub message: String,
    pub code: u16,
}

// Initialize API router with database-backed endpoints only
pub fn create_api_router(config: Arc<AppConfig>) -> Router {
    Router::new()
        // Database API endpoints
        .route("/api/events", get(database::get_db_events))
        .route("/api/events/:id", get(database::get_db_event))
        .route("/api/cities", get(database::get_db_cities))
        .with_state(config)
}