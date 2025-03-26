use anyhow::Result;
use sharingan::config::{AppConfig, CityConfig, DatabaseConfig, DateRange};
use sharingan::db::ExportFormat;
use sharingan::providers::{CharmanderProvider, EventProvider, PikachuProvider};
use std::time::Instant;

// Benchmark for provider implementations using static extraction
// This benchmark tests the performance of the event extraction and parsing logic
// without making any actual API calls, to avoid unnecessary costs and network dependencies
#[tokio::main]
async fn main() -> Result<()> {
    // Create test directory for static extraction if it doesn't exist
    let test_dir = "tests/bench_extraction";
    if !std::path::Path::new(test_dir).exists() {
        std::fs::create_dir_all(test_dir)?;

        // Create a sample HTML file for testing
        let sample_html = r#"
        <!DOCTYPE html>
        <html>
        <head><title>Test Events</title></head>
        <body>
            <div class="events-list">
                <a href="/events/test-event-1">Test Event 1</a>
                <a href="/events/test-event-2">Test Event 2</a>
                <a href="/events/test-event-3">Test Event 3</a>
                <a href="/events/test-event-4">Test Event 4</a>
                <a href="/events/test-event-5">Test Event 5</a>
            </div>
        </body>
        </html>
        "#;

        // Write main index file
        std::fs::write(format!("{}/index.html", test_dir), sample_html)?;

        // Create individual event files
        for i in 1..=5 {
            let event_dir = format!("{}/events/test-event-{}", test_dir, i);
            std::fs::create_dir_all(&event_dir)?;

            let event_html = format!(
                r#"
            <!DOCTYPE html>
            <html>
            <head><title>Test Event {}</title></head>
            <body>
                <h1 class="event-title">Test Event {}</h1>
                <div class="event-date">01/05/2025</div>
                <div class="event-location">Test Venue {}</div>
                <div class="event-price">R$ {}.00</div>
                <img src="/images/event{}.jpg" class="event-image">
            </body>
            </html>
            "#,
                i,
                i,
                i,
                i * 10,
                i % 4 + 1
            );

            std::fs::write(format!("{}/index.html", event_dir), event_html)?;
        }
    }

    // Create a mock config using static extraction
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
            export_format: ExportFormat::Postgres,
        },
        provider: "pikachu".to_string(),
        timeout_seconds: 30,
        extraction_mode: sharingan::config::ExtractionMode::Static,
        extraction_folder: Some(test_dir.to_string()),
        use_firecrawl: false,
    };

    // Run Pikachu provider benchmark
    println!("Benchmarking PikachuProvider...");
    let pikachu = PikachuProvider::new();
    let start = Instant::now();
    let events = pikachu.fetch_events(&config).await?;
    let duration = start.elapsed();
    println!(
        "PikachuProvider fetched {} events in {:?}",
        events.len(),
        duration
    );

    // Run Charmander provider benchmark
    println!("Benchmarking CharmanderProvider...");
    let charmander = CharmanderProvider::new();
    let start = Instant::now();
    let events = charmander.fetch_events(&config).await?;
    let duration = start.elapsed();
    println!(
        "CharmanderProvider fetched {} events in {:?}",
        events.len(),
        duration
    );

    Ok(())
}
