//! Tests for the PostgreSQL implementation

extern crate ihoje;

use ihoje::db::postgres::PostgresEventStore;
use ihoje::db::EventStore;
use ihoje::event::EventData;
use ihoje::event::FailedPriceFetch;
use std::env;

// This test will run in "test mode" automatically
#[tokio::test]
async fn test_postgres_event_store() {
    // Explicitly set test mode to be sure
    env::set_var("TEST_POSTGRES", "1");
    
    // Create a test PostgreSQL store - this uses the test mode
    let postgres_store = PostgresEventStore::new().await.expect("Should create test store");
    
    // Create test events
    let events = vec![
        EventData {
            id: "test-1".to_string(),
            title: "Test Event 1".to_string(),
            date: "25/03/2025".to_string(),
            location: "Test Location 1".to_string(),
            url: "https://example.com/event1".to_string(),
            image_url: "https://example.com/image1.jpg".to_string(),
            city: "FL".to_string(),
            price: "R$ 50,00".to_string(),
        },
        EventData {
            id: "test-2".to_string(),
            title: "Test Event 2".to_string(),
            date: "26/03/2025".to_string(),
            location: "Test Location 2".to_string(),
            url: "https://example.com/event2".to_string(),
            image_url: "https://example.com/image2.jpg".to_string(),
            city: "RJ".to_string(),
            price: "R$ 75,00".to_string(),
        },
    ];
    
    // Test storing events - this should work in test mode without a real database
    postgres_store.store_events(&events).expect("Should store events in test mode");
    
    // Create test failures
    let failures = vec![
        FailedPriceFetch {
            id: "test-1".to_string(),
            title: "Test Event 1".to_string(),
            url: "https://example.com/event1".to_string(),
            error: "Test error 1".to_string(),
            timestamp: "2025-03-25T12:00:00Z".to_string(),
        },
    ];
    
    // Test storing failures - this should work in test mode without a real database
    postgres_store.store_failures(&failures).await.expect("Should store failures in test mode");
    
    // Test clearing events - this should work in test mode without a real database
    postgres_store.clear_events().expect("Should clear events in test mode");
}

// Test for the "both" export format mode
#[tokio::test]
async fn test_postgres_and_csv_export() {
    use ihoje::exporters::csv::CsvExporter;
    use ihoje::db::ExportFormat;
    use ihoje::exporter::export_data;
    
    // Set test modes
    env::set_var("TEST_POSTGRES", "1");
    env::set_var("TEST_HTML", "1");
    
    // Create test events
    let events = vec![
        EventData {
            id: "test-both-1".to_string(),
            title: "Test Both Event 1".to_string(),
            date: "25/03/2025".to_string(),
            location: "Test Location 1".to_string(),
            url: "https://example.com/event1".to_string(),
            image_url: "https://example.com/image1.jpg".to_string(),
            city: "FL".to_string(),
            price: "R$ 50,00".to_string(),
        },
    ];
    
    // Create test failures
    let failures = vec![
        FailedPriceFetch {
            id: "test-both-1".to_string(),
            title: "Test Both Event 1".to_string(),
            url: "https://example.com/event1".to_string(),
            error: "Test error for both export".to_string(),
            timestamp: "2025-03-25T12:00:00Z".to_string(),
        },
    ];
    
    // Test export with the "both" format
    let timestamp = "test-both";
    let result = export_data(&events, &failures, timestamp, ExportFormat::Both).await;
    
    // Should succeed with test mode
    assert!(result.is_ok());
    
    // Clean up any CSV files that may have been created
    let csv_exporter = CsvExporter::new();
    let _ = csv_exporter.clear_events();
}

// Test the new query functionality
#[tokio::test]
async fn test_postgres_query_functionality() {
    // Set test mode
    env::set_var("TEST_POSTGRES", "1");
    
    // Create PostgreSQL store
    let pg_store = PostgresEventStore::new().await.expect("Should create test store");
    
    // Create test data
    let test_events = vec![
        EventData {
            id: "test-1".to_string(),
            title: "Test Event 1".to_string(),
            date: "25/03/2025".to_string(),
            location: "Test Location".to_string(),
            url: "https://example.com/event/1".to_string(),
            image_url: "https://example.com/image1.jpg".to_string(),
            city: "FL".to_string(),
            price: "R$ 50,00".to_string(),
        },
        EventData {
            id: "test-2".to_string(),
            title: "Test Event 2".to_string(),
            date: "26/03/2025".to_string(),
            location: "Another Location".to_string(),
            url: "https://example.com/event/2".to_string(),
            image_url: "https://example.com/image2.jpg".to_string(),
            city: "RJ".to_string(),
            price: "R$ 75,00".to_string(),
        },
    ];
    
    // Store test events
    pg_store.store_events(&test_events).expect("Should store events in test mode");
    
    // Test get_events (all events)
    let events = pg_store.get_events(None, None).expect("Should get events");
    assert!(!events.is_empty(), "Should return events");
    
    // Test get_events with city filter
    let fl_events = pg_store.get_events(Some("FL"), None).expect("Should get FL events");
    assert!(fl_events.iter().all(|e| e.city == "FL"), "All events should be from FL");
    
    // Test get_events with limit
    let limited_events = pg_store.get_events(None, Some(1)).expect("Should get limited events");
    assert_eq!(limited_events.len(), 1, "Should return only one event");
    
    // Test get_event_by_id
    let event = pg_store.get_event_by_id("test-1").expect("Should get event by ID");
    assert!(event.is_some(), "Should find event by ID");
    if let Some(e) = event {
        assert_eq!(e.id, "test-1");
        assert_eq!(e.title, "Test Event 1");
    }
    
    // Test get_upcoming_events
    let upcoming = pg_store.get_upcoming_events(None, None).expect("Should get upcoming events");
    assert!(!upcoming.is_empty(), "Should return upcoming events");
    
    // Clean up
    pg_store.clear_events().expect("Should clear events");
}