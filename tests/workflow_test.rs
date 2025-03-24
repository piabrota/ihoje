// This file contains a more comprehensive integration test that simulates the full workflow

extern crate ihoje;

use ihoje::config::{AppConfig, CityConfig, DatabaseConfig};
use ihoje::event::extract_events;
use ihoje::rate_limiter::RateLimiter;
use ihoje::logger::Logger;
use ihoje::exporters::{Exporter, csv::CsvExporter};
use ihoje::db::ExportFormat;

use std::fs;
use std::path::Path;
use std::sync::Arc;
use std::time::SystemTime;

/// Test a simplified version of the main workflow
#[tokio::test]
async fn test_workflow() {
    // Create test directory if it doesn't exist
    let test_dir = Path::new("target/workflow-test");
    if !test_dir.exists() {
        std::fs::create_dir_all(test_dir).unwrap();
    }
    
    // Set up logger
    let log_path = test_dir.join("test-workflow.log");
    if log_path.exists() {
        fs::remove_file(&log_path).unwrap();
    }
    let logger = Logger::new(log_path.to_string_lossy().to_string()).unwrap();
    
    // Log start of test
    logger.info("Starting workflow test").unwrap();
    
    // Set up rate limiter (not used in this test but would be in a real workflow)
    let _rate_limiter = Arc::new(RateLimiter::new(60)); // 1 per second for testing
    
    // Import DateRange
    use ihoje::config::DateRange;
    
    // Create mock config
    let config = AppConfig {
        city: "FL".to_string(),
        city_config: CityConfig {
            name: "Florianópolis".to_string(),
            path: "florianopolis-sc".to_string(),
        },
        api_key: "test-key".to_string(),
        target_url: "https://example.com".to_string(),
        max_events: 5,
        date_range: DateRange::new(None, None),
        db_config: DatabaseConfig {
            export_format: ExportFormat::Csv,
        },
        provider: "pikachu".to_string(),
        timeout_seconds: 30,
    };
    
    // Mock HTML content
    let html_content = include_str!("test_events.html");
    
    // Extract events (simulate the scraping step)
    let events = extract_events(html_content, &config.city, &config.target_url, config.max_events);
    
    // Log event count
    logger.info(&format!("Extracted {} events", events.len())).unwrap();
    
    // Verify events were extracted
    assert!(!events.is_empty(), "Should extract at least one event");
    
    // Generate timestamp for export
    let timestamp = SystemTime::now()
        .duration_since(SystemTime::UNIX_EPOCH)
        .unwrap()
        .as_secs()
        .to_string();
    
    // Export events using CsvExporter directly
    let exporter = CsvExporter::new();
    let filename = exporter.export_events(&events, &timestamp).unwrap();
    
    // Verify CSV file was created
    assert!(Path::new(&filename).exists());
    
    // Log completion
    logger.info("Workflow test completed successfully").unwrap();
    
    // Clean up
    fs::remove_file(&filename).unwrap();
    fs::remove_file(&log_path).unwrap();
}