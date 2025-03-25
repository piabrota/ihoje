use anyhow::Result;
use ihoje::config::{AppConfig, CityConfig, DateRange, DatabaseConfig};
use ihoje::providers::{EventProvider, PikachuProvider, CharmanderProvider};
use ihoje::db::ExportFormat;
use std::time::Instant;

// Simple benchmark for provider implementations
#[tokio::main]
async fn main() -> Result<()> {
    // Enable test mode to use mock data
    std::env::set_var("TEST_HTML", "1");
    
    // Create a mock config
    let config = AppConfig {
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
        max_events: 50,
        db_config: DatabaseConfig {
            export_format: ExportFormat::Csv,
        },
        provider: "pikachu".to_string(),
        timeout_seconds: 30,
    };
    
    // Run Pikachu provider benchmark
    println!("Benchmarking PikachuProvider...");
    let pikachu = PikachuProvider::new();
    let start = Instant::now();
    let events = pikachu.fetch_events(&config).await?;
    let duration = start.elapsed();
    println!("PikachuProvider fetched {} events in {:?}", events.len(), duration);
    
    // Run Charmander provider benchmark
    println!("Benchmarking CharmanderProvider...");
    let charmander = CharmanderProvider::new();
    let start = Instant::now();
    let events = charmander.fetch_events(&config).await?;
    let duration = start.elapsed();
    println!("CharmanderProvider fetched {} events in {:?}", events.len(), duration);
    
    Ok(())
}