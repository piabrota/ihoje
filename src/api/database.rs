use axum::{
    extract::{Path, Query, State},
    Json,
    http::StatusCode,
};
use std::sync::Arc;
use anyhow::Result;
use ihoje_models::{Event, EventQuery};
use crate::db::postgres::PostgresEventStore;
use crate::db::EventStore;  // Add this trait import
use crate::config::AppConfig;

/// Get events from the database with filtering
pub async fn get_db_events(
    Query(query): Query<EventQuery>,
    State(_config): State<Arc<AppConfig>>,
) -> Result<Json<Vec<Event>>, (StatusCode, Json<crate::api::ApiError>)> {
    let store = PostgresEventStore::new().await
        .map_err(|e| {
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(crate::api::ApiError {
                    message: format!("Failed to connect to database: {}", e),
                    code: 500,
                })
            )
        })?;

    let city_filter = query.city.as_deref();
    let limit = Some(100); // Configurable limit
    
    let events = store.get_events(city_filter, limit)
        .map_err(|e| {
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(crate::api::ApiError {
                    message: format!("Failed to fetch events: {}", e),
                    code: 500,
                })
            )
        })?;
        
    // Convert backend EventData to shared Event model
    let shared_events: Vec<Event> = events.into_iter()
        .map(|e| Event {
            id: e.id,
            title: e.title,
            date: e.date,
            location: e.location,
            url: e.url,
            image_url: e.image_url,
            city: e.city,
            price: e.price,
            created_at: None, // Not needed for tobira
        })
        // Apply additional filters that can't be done in the database
        .filter(|event| {
            // Search filter
            if let Some(search) = &query.search {
                if !search.is_empty() && !event.title.to_lowercase().contains(&search.to_lowercase()) {
                    return false;
                }
            }
            
            // Free only filter
            if let Some(true) = query.free_only {
                if !event.is_free() {
                    return false;
                }
            }
            
            true
        })
        .collect();
    
    Ok(Json(shared_events))
}

/// Get a single event by ID from the database
pub async fn get_db_event(
    Path(id): Path<String>,
    State(_config): State<Arc<AppConfig>>,
) -> Result<Json<Event>, (StatusCode, Json<crate::api::ApiError>)> {
    let store = PostgresEventStore::new().await
        .map_err(|e| {
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(crate::api::ApiError {
                    message: format!("Failed to connect to database: {}", e),
                    code: 500,
                })
            )
        })?;
    
    match store.get_event_by_id(&id) {
        Ok(Some(e)) => {
            // Convert backend EventData to shared Event model
            let event = Event {
                id: e.id,
                title: e.title,
                date: e.date,
                location: e.location,
                url: e.url,
                image_url: e.image_url,
                city: e.city,
                price: e.price,
                created_at: None, // Not needed for tobira
            };
            Ok(Json(event))
        },
        Ok(None) => Err((
            StatusCode::NOT_FOUND,
            Json(crate::api::ApiError {
                message: format!("Event with ID {} not found", id),
                code: 404,
            })
        )),
        Err(e) => Err((
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(crate::api::ApiError {
                message: format!("Failed to fetch event: {}", e),
                code: 500,
            })
        )),
    }
}

/// Get list of cities from the database
pub async fn get_db_cities(
    State(_config): State<Arc<AppConfig>>,
) -> Result<Json<Vec<String>>, (StatusCode, Json<crate::api::ApiError>)> {
    let store = PostgresEventStore::new().await
        .map_err(|e| {
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(crate::api::ApiError {
                    message: format!("Failed to connect to database: {}", e),
                    code: 500,
                })
            )
        })?;
    
    // Get all events to extract unique cities
    let events = store.get_events(None, None)
        .map_err(|e| {
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(crate::api::ApiError {
                    message: format!("Failed to fetch events: {}", e),
                    code: 500,
                })
            )
        })?;
    
    // Extract unique cities
    let mut cities: Vec<String> = events
        .iter()
        .map(|e| e.city.clone())
        .collect();
    
    cities.sort();
    cities.dedup();
    
    Ok(Json(cities))
}