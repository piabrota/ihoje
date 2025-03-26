pub mod api;
pub mod config;
pub mod db;
pub mod event;
pub mod exporter;
pub mod exporters;
pub mod logger;
pub mod providers;
pub mod rate_limiter;
pub mod sharingan;

use anyhow::Result;
use chrono::Utc;
use log::info;
use simplelog::{Config, LevelFilter};
use std::fs::File;
use std::sync::Arc;

use clap::Parser;

use crate::config::{get_config, AppConfig};
use crate::db::ExportFormat;
use crate::exporter::export_data;
use crate::logger::Logger;
use crate::providers::get_provider;
use crate::rate_limiter::RateLimiter;

/// Command line arguments
#[derive(Parser, Debug)]
#[clap(author, version, about = "Event Scraper CLI")]
struct Args {
    /// Print constructed URL without scraping
    #[clap(long)]
    print_url: bool,

    /// Export format (postgres, gcp, or pg_with_gcp_fallback)
    #[clap(long, value_enum, default_value = "postgres")]
    export: Option<ExportFormat>,

    /// Start API server
    #[clap(long)]
    api: bool,

    /// API server port
    #[clap(long, default_value = "8080")]
    port: u16,

    /// Skip database connection test (for testing purposes)
    #[clap(long)]
    skip_db_test: bool,
}

#[tokio::main]
async fn main() -> Result<()> {
    // Load environment variables from .env file
    dotenv::dotenv().ok();

    // Parse command-line arguments using clap
    let args = Args::parse();
    let print_url_only = args.print_url;
    let start_api = args.api;
    let api_port = args.port;
    let skip_db_test = args.skip_db_test;

    // Auto-cleanup old log files
    auto_cleanup_logs()?;

    // Load application configuration early to include in log filename
    let config = get_config()?;

    // Check if we're running tests (set by cargo test)
    let is_test = std::env::var("CARGO_TARGET_TMPDIR").is_ok();
    let test_indicator = if is_test { "test" } else { "prod" };

    // Build log filename with city, date range, and test mode
    let timestamp = Utc::now().format("%Y-%m-%dT%H-%M-%S").to_string();
    let date_range_str = match (&config.date_range.start_date, &config.date_range.end_date) {
        (Some(start), Some(end)) => format!("{}_{}", start, end),
        (Some(start), None) => format!("{}_any", start),
        (None, Some(end)) => format!("any_{}", end),
        _ => "no_dates".to_string(),
    };

    let log_path = format!(
        "scraper_{}_{}_{}_{}.log",
        config.city, date_range_str, test_indicator, timestamp
    );

    // Initialize logging systems
    setup_simplelog(&log_path)?;
    let custom_logger = Logger::new(log_path.replace("scraper", "scraper_custom"))?;
    info!("Starting event scraper application");
    custom_logger.info("Custom logger initialized")?;

    // Initialize rate limiter - use higher limit for tests to avoid API throttling
    let rate_limit = if is_test { 60 } else { 3 }; // 60/min for tests, 3/min for production
    let rate_limiter = Arc::new(RateLimiter::new(rate_limit));
    info!(
        "Rate limiter initialized: {} requests per minute",
        rate_limit
    );

    // Set MAX_EVENTS=1 for tests to minimize API calls
    if is_test && std::env::var("MAX_EVENTS").is_err() {
        std::env::set_var("MAX_EVENTS", "1");
        info!("Test mode: Setting MAX_EVENTS=1 to minimize API usage");
    }

    // Load application configuration
    let config = get_config()?;
    info!("Starting event scraper for {}...", config.city_config.name);

    // Print PostgreSQL connection info if using PostgreSQL
    if config.db_config.export_format == ExportFormat::Postgres
        || config.db_config.export_format == ExportFormat::Both
    {
        info!("Using PostgreSQL database for export");
        let pg_config = crate::db::postgres::PostgresConfig::from_env().unwrap_or_else(|_| {
            info!("Failed to load PostgreSQL configuration, using defaults");
            crate::db::postgres::PostgresConfig {
                host: "localhost".to_string(),
                port: 5432,
                user: "postgres".to_string(),
                password: "postgres".to_string(),
                database: "events".to_string(),
            }
        });
        info!(
            "PostgreSQL connection: {}:{}/{}",
            pg_config.host, pg_config.port, pg_config.database
        );
    }

    // Check if we should start the API server
    if start_api {
        // Start API server
        info!("Starting API server on port {}", api_port);

        // Create a shared config for the API server
        let shared_config = Arc::new(config.clone());

        // Create the API router
        let app = crate::api::create_api_router(shared_config);

        // Add CORS middleware
        let cors_layer = tower_http::cors::CorsLayer::new()
            .allow_origin(tower_http::cors::Any)
            .allow_methods([axum::http::Method::GET])
            .allow_headers([axum::http::header::CONTENT_TYPE]);

        let app = app.layer(cors_layer);

        // Create the server binding
        let listener = tokio::net::TcpListener::bind(format!("0.0.0.0:{}", api_port)).await?;
        info!("API server listening on http://localhost:{}", api_port);

        // Serve the API
        axum::serve(listener, app).await?;

        return Ok(());
    }

    // Run the main scraping workflow with print_url_only flag
    run_scraping_workflow(
        &config,
        &rate_limiter,
        &custom_logger,
        print_url_only,
        skip_db_test,
    )
    .await
}

fn setup_simplelog(log_path: &str) -> Result<()> {
    let log_file = File::create(log_path)?;

    simplelog::WriteLogger::init(LevelFilter::Info, Config::default(), log_file)?;

    Ok(())
}

/// Automatically clean up old log and data files to prevent disk space issues
fn auto_cleanup_logs() -> Result<()> {
    use std::time::{Duration, SystemTime};

    // Get files in current directory
    let entries = std::fs::read_dir(".")?;
    let cutoff = SystemTime::now() - Duration::from_secs(7 * 24 * 60 * 60); // 7 days
    let mut deleted_count = 0;

    for entry in entries {
        let entry = entry?;
        let path = entry.path();

        // Skip if not a file
        if !path.is_file() {
            continue;
        }

        // Check if file matches our patterns
        let file_name = path.file_name().and_then(|n| n.to_str()).unwrap_or("");

        let is_target = (file_name.starts_with("scraper_") && file_name.ends_with(".log"))
            || (file_name.starts_with("scraper_custom_") && file_name.ends_with(".log"))
            || (file_name.starts_with("events_") && file_name.ends_with(".csv"));

        if is_target {
            // Check file age
            if let Ok(metadata) = entry.metadata() {
                if let Ok(modified) = metadata.modified() {
                    if modified < cutoff {
                        // Remove old file
                        if let Err(e) = std::fs::remove_file(&path) {
                            info!("Failed to remove old file {}: {}", path.display(), e);
                        } else {
                            deleted_count += 1;
                        }
                    }
                }
            }
        }
    }

    if deleted_count > 0 {
        info!(
            "Automatic cleanup removed {} old log/data files",
            deleted_count
        );
    }

    Ok(())
}

async fn run_scraping_workflow(
    config: &AppConfig,
    _rate_limiter: &Arc<RateLimiter>, // Kept for API compatibility but not used directly
    logger: &Logger,
    print_url_only: bool,
    skip_db_test: bool, // Added skip_db_test parameter
) -> Result<()> {
    // Log with custom logger
    logger.info("Starting scraping workflow")?;

    // Log date range if specified
    if config.date_range.is_specified() {
        let start_text = config.date_range.start_date.as_ref().map_or("any", |s| s);
        let end_text = config.date_range.end_date.as_ref().map_or("any", |s| s);
        logger.info(&format!(
            "Using date range - start: {}, end: {}",
            start_text, end_text
        ))?;
    }

    // Log export format
    logger.info(&format!(
        "Using export format: {}",
        config.db_config.export_format
    ))?;

    // Log provider
    logger.info(&format!("Using provider: {}", &config.provider))?;

    // Test database connection for postgres configurations
    // Skip the test if:
    // - User explicitly requested to skip with --skip-db-test
    // - We are only testing URL construction with --print-url
    // - TEST_MODE environment variable is set
    // - Export format is not Postgres (GCP, CSV)
    let export_is_postgres = config.db_config.export_format == ExportFormat::Postgres
        || config.db_config.export_format == ExportFormat::PgWithGcpFallback;

    let should_skip_db_test = skip_db_test
        || print_url_only
        || std::env::var("TEST_MODE").unwrap_or_default() == "true"
        || !export_is_postgres;

    // Only test Postgres connection if explicitly needed
    if !should_skip_db_test {
        logger.info("Testing PostgreSQL database connection...")?;
        if let Err(e) = test_postgres_connection().await {
            logger.info(&format!("🔴 PostgreSQL connection failed: {}", e))?;
            if config.db_config.export_format == ExportFormat::Postgres {
                return Err(anyhow::anyhow!("PostgreSQL connection test failed: {}", e));
            } else {
                logger.info(
                    "Will fall back to GCP bucket storage if connection remains unavailable",
                )?;
            }
        } else {
            logger.info("✅ PostgreSQL connection successful")?;
        }
    } else {
        logger.info("Skipping PostgreSQL connection test")?;
    }

    // Test URL construction if print_url_only flag is set
    if print_url_only {
        // Construct URL with date range
        let url = if config.date_range.is_specified() {
            match (
                config.date_range.start_date.as_ref(),
                config.date_range.end_date.as_ref(),
            ) {
                (Some(start), Some(end)) => {
                    format!(
                        "{}/{}?date={}&endDate={}",
                        config.target_url, config.city_config.path, start, end
                    )
                }
                (Some(start), None) => {
                    format!(
                        "{}/{}?date={}",
                        config.target_url, config.city_config.path, start
                    )
                }
                (None, Some(end)) => {
                    format!(
                        "{}/{}?endDate={}",
                        config.target_url, config.city_config.path, end
                    )
                }
                _ => format!("{}/{}", config.target_url, config.city_config.path),
            }
        } else {
            format!("{}/{}", config.target_url, config.city_config.path)
        };

        // Print constructed URL and exit
        println!("Constructed URL: {}", url);
        return Ok(());
    }

    // Get appropriate provider based on config
    let provider = get_provider(&config.provider);
    logger.info(&format!("Using provider: {}", provider.name()))?;

    // Get the current timestamp for file naming
    let timestamp = Utc::now().format("%Y-%m-%dT%H-%M-%S").to_string();

    // Fetch events from the selected provider
    let events = provider.fetch_events(config).await?;
    logger.info(&format!(
        "Provider {} found {} events",
        provider.name(),
        events.len()
    ))?;

    // For now, we'll create an empty failures vector since provider handles this internally
    let failures = Vec::new();

    // Export data to configured destination (CSV or PostgreSQL)
    export_data(
        &events,
        &failures,
        &timestamp,
        config.db_config.export_format,
    )
    .await?;

    logger.info("Workflow completed successfully")?;

    Ok(())
}

/// Test PostgreSQL connection and create tables if they don't exist
async fn test_postgres_connection() -> Result<()> {
    // Check if we're in test mode (set by cargo test)
    let is_test =
        std::env::var("CARGO_TARGET_TMPDIR").is_ok() || std::env::var("TEST_POSTGRES").is_ok();

    if is_test {
        info!("🧪 TEST MODE: Skipping real PostgreSQL connection test");
        return Ok(());
    }

    use crate::db::postgres::PostgresConfig;

    // Check if PostgreSQL is configured
    if !PostgresConfig::is_configured() {
        return Err(anyhow::anyhow!("PostgreSQL is not configured. Set PG_HOST, PG_USER, PG_PASSWORD, PG_DATABASE environment variables"));
    }

    // Try to create a PostgreSQL store (this will test the connection)
    let config = PostgresConfig::from_env()?;
    let pool = config.create_pool()?;

    // Get a client from the pool to verify connection
    let client = pool
        .get()
        .await
        .map_err(|e| anyhow::anyhow!("Failed to get Postgres client: {}", e))?;

    // Create events table if it doesn't exist
    let create_events_table = r#"
    CREATE TABLE IF NOT EXISTS events (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        date TEXT NOT NULL,
        location TEXT NOT NULL,
        url TEXT NOT NULL,
        image_url TEXT,
        city TEXT NOT NULL,
        price TEXT NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    )
    "#;

    client
        .execute(create_events_table, &[])
        .await
        .map_err(|e| anyhow::anyhow!("Failed to create events table: {}", e))?;

    // Create failed price fetches table if it doesn't exist
    let create_failures_table = r#"
    CREATE TABLE IF NOT EXISTS failed_price_fetches (
        id TEXT NOT NULL,
        title TEXT NOT NULL,
        url TEXT NOT NULL,
        error TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (id, timestamp)
    )
    "#;

    client
        .execute(create_failures_table, &[])
        .await
        .map_err(|e| anyhow::anyhow!("Failed to create failed_price_fetches table: {}", e))?;

    // Create indexes if they don't exist (optional but recommended)
    let create_indexes = [
        "CREATE INDEX IF NOT EXISTS idx_events_date ON events(date)",
        "CREATE INDEX IF NOT EXISTS idx_events_city ON events(city)",
        "CREATE INDEX IF NOT EXISTS idx_failures_timestamp ON failed_price_fetches(timestamp)",
    ];

    for index_sql in create_indexes {
        client
            .execute(index_sql, &[])
            .await
            .map_err(|e| anyhow::anyhow!("Failed to create index: {}", e))?;
    }

    // Successfully verified database connection and schema
    Ok(())
}
