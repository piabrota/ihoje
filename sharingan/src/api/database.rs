use crate::config::AppConfig;
use crate::db::postgres::PostgresEventStore;
use crate::db::EventStore; // Add this trait import
use anyhow::Result;
use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    Json,
};
use chrono::NaiveDate;
use pokeball::{Event, EventQuery};
use std::sync::Arc;

/// Get events from the database with filtering
pub async fn get_db_events(
    Query(query): Query<EventQuery>,
    State(_config): State<Arc<AppConfig>>,
) -> Result<Json<Vec<Event>>, (StatusCode, Json<crate::api::ApiError>)> {
    let store = PostgresEventStore::new().await.map_err(|e| {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(crate::api::ApiError {
                message: format!("Failed to connect to database: {}", e),
                code: 500,
            }),
        )
    })?;

    let city_filter = Some(query.city.as_str());
    let limit = Some(100); // Configurable limit

    let events = store.get_events(city_filter, limit).map_err(|e| {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(crate::api::ApiError {
                message: format!("Failed to fetch events: {}", e),
                code: 500,
            }),
        )
    })?;

    // Convert backend EventData to shared Event model
    let shared_events: Vec<Event> = events
        .into_iter()
        .map(|e| {
            // Try to parse the date string into a NaiveDate
            let date = NaiveDate::parse_from_str(&e.date, "%d/%m/%Y")
                .unwrap_or_else(|_| NaiveDate::from_ymd_opt(2025, 1, 1).unwrap());

            Event {
                id: e.id,
                title: e.title,
                description: Some(format!("Event at {}", e.location)), // Add description
                date,
                time: None,              // No time information in the original model
                venue: Some(e.location), // Map location to venue
                url: e.url,
                image_url: Some(e.image_url),
                city: e.city,
                price: Some(e.price),
                provider: "pikachu".to_string(), // Default provider
            }
        })
        // We don't need the old filtering since query structure is now different
        .collect();

    Ok(Json(shared_events))
}

/// Get a single event by ID from the database
pub async fn get_db_event(
    Path(id): Path<String>,
    State(_config): State<Arc<AppConfig>>,
) -> Result<Json<Event>, (StatusCode, Json<crate::api::ApiError>)> {
    let store = PostgresEventStore::new().await.map_err(|e| {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(crate::api::ApiError {
                message: format!("Failed to connect to database: {}", e),
                code: 500,
            }),
        )
    })?;

    match store.get_event_by_id(&id) {
        Ok(Some(e)) => {
            // Convert backend EventData to shared Event model
            // Try to parse the date string into a NaiveDate
            let date = NaiveDate::parse_from_str(&e.date, "%d/%m/%Y")
                .unwrap_or_else(|_| NaiveDate::from_ymd_opt(2025, 1, 1).unwrap());

            let event = Event {
                id: e.id,
                title: e.title,
                description: Some(format!("Event at {}", e.location)), // Add description
                date,
                time: None,              // No time information in the original model
                venue: Some(e.location), // Map location to venue
                url: e.url,
                image_url: Some(e.image_url),
                city: e.city,
                price: Some(e.price),
                provider: "pikachu".to_string(), // Default provider
            };
            Ok(Json(event))
        }
        Ok(None) => Err((
            StatusCode::NOT_FOUND,
            Json(crate::api::ApiError {
                message: format!("Event with ID {} not found", id),
                code: 404,
            }),
        )),
        Err(e) => Err((
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(crate::api::ApiError {
                message: format!("Failed to fetch event: {}", e),
                code: 500,
            }),
        )),
    }
}

/// Get list of cities from the database
pub async fn get_db_cities(
    State(_config): State<Arc<AppConfig>>,
) -> Result<Json<Vec<String>>, (StatusCode, Json<crate::api::ApiError>)> {
    let store = PostgresEventStore::new().await.map_err(|e| {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(crate::api::ApiError {
                message: format!("Failed to connect to database: {}", e),
                code: 500,
            }),
        )
    })?;

    // Get all events to extract unique cities
    let events = store.get_events(None, None).map_err(|e| {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(crate::api::ApiError {
                message: format!("Failed to fetch events: {}", e),
                code: 500,
            }),
        )
    })?;

    // Extract unique cities
    let mut cities: Vec<String> = events.iter().map(|e| e.city.clone()).collect();

    cities.sort();
    cities.dedup();

    Ok(Json(cities))
}
