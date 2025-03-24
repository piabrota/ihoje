use ihoje::config::{AppConfig, CityConfig, DateRange, DatabaseConfig};
use ihoje::providers::{EventProvider, PikachuProvider, CharmanderProvider};
use std::env;

#[tokio::test]
async fn test_pikachu_provider() {
    // Enable test mode
    env::set_var("TEST_HTML", "1");
    
    // Create a mock config
    let config = create_test_config();
    
    // Create provider and fetch events
    let provider = PikachuProvider::new();
    let events = provider.fetch_events(&config).await.unwrap();
    
    // Check that events were returned
    assert!(!events.is_empty());
    assert_eq!(events[0].city, "FL");
}

#[tokio::test]
async fn test_charmander_provider() {
    // Enable test mode
    env::set_var("TEST_HTML", "1");
    
    // Create a mock config
    let config = create_test_config();
    
    // Create provider and fetch events
    let provider = CharmanderProvider::new();
    let events = provider.fetch_events(&config).await.unwrap();
    
    // Check that events were returned
    assert!(!events.is_empty());
    assert_eq!(events[0].city, "FL");
}

/// Helper to create a test config
fn create_test_config() -> AppConfig {
    AppConfig {
        api_key: "test_key".to_string(),
        city: "FL".to_string(),
        target_url: "https://example.com".to_string(),
        city_config: CityConfig {
            name: "Florianópolis".to_string(),
            path: "florianopolis".to_string(),
        },
        date_range: DateRange {
            start_date: Some("2025-04-01".to_string()),
            end_date: Some("2025-04-30".to_string()),
        },
        max_events: 5,
        db_config: DatabaseConfig {
            export_format: ihoje::db::ExportFormat::Csv,
        },
        provider: "pikachu".to_string(),
        timeout_seconds: 30,
    }
}