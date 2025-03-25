// Import modules directly since this is an integration test
// Note: We're accessing the modules directly from the crate root
extern crate ihoje;

use ihoje::config::get_city_config;
use ihoje::event::{EventData, extract_events};
use ihoje::exporters::{Exporter, csv::CsvExporter};
use std::fs;
use std::path::Path;

// This tests the integration between the event extraction and exporter modules
#[test]
fn test_event_extraction_and_export() {
    // 1. Setup test HTML content from test_events.html file
    let html_content = include_str!("test_events.html");
    
    // 2. Extract events from HTML
    let events = extract_events(html_content, "FL", "https://example.com", 10);
    
    // 3. Verify events were extracted correctly
    assert!(!events.is_empty(), "Should extract at least one event");
    assert_eq!(events[0].title, "Test Event");
    assert_eq!(events[0].id, "test-event-123");
    
    // 4. Export events to CSV directly with the CsvExporter
    let timestamp = "integration-test";
    
    // Use CsvExporter directly
    let exporter = CsvExporter::new();
    let filename = exporter.export_events(&events, timestamp).unwrap();
    
    // 5. We use the filename returned by the exporter
    assert!(Path::new(&filename).exists());
    
    // 6. Verify CSV content
    let csv_content = fs::read_to_string(&filename).unwrap();
    assert!(csv_content.contains("Test Event"));
    assert!(csv_content.contains("Test Convention Center"));
    
    // 7. Clean up
    fs::remove_file(&filename).unwrap();
}

// Test that city configurations are working correctly
#[test]
fn test_city_config_integration() {
    // Get configurations for different cities
    let fl_config = get_city_config("FL");
    let rj_config = get_city_config("RJ");
    let sp_config = get_city_config("SP");
    
    // Verify configurations
    assert_eq!(fl_config.name, "Florianópolis");
    assert_eq!(rj_config.name, "Rio de Janeiro");
    assert_eq!(sp_config.name, "São Paulo");
    
    // Create events with different cities
    let event_fl = EventData::new(
        "test-fl".to_string(),
        "Event in FL".to_string(),
        "25/03/2025".to_string(),
        fl_config.name.clone(),
        "https://example.com/fl".to_string(),
        "https://example.com/image.jpg".to_string(),
        "FL".to_string(),
    );
    
    let event_rj = EventData::new(
        "test-rj".to_string(),
        "Event in RJ".to_string(),
        "26/03/2025".to_string(),
        rj_config.name.clone(),
        "https://example.com/rj".to_string(),
        "https://example.com/image.jpg".to_string(),
        "RJ".to_string(),
    );
    
    // Combine events and export
    let events = vec![event_fl, event_rj];
    let timestamp = "city-test";
    
    // Use CsvExporter directly
    let exporter = CsvExporter::new();
    let filename = exporter.export_events(&events, timestamp).unwrap();
    
    // Verify CSV file was created
    assert!(Path::new(&filename).exists());
    
    // Check content
    let csv_content = fs::read_to_string(&filename).unwrap();
    assert!(csv_content.contains("Event in FL"));
    assert!(csv_content.contains("Event in RJ"));
    assert!(csv_content.contains("Florianópolis"));
    assert!(csv_content.contains("Rio de Janeiro"));
    
    // Clean up
    fs::remove_file(&filename).unwrap();
}