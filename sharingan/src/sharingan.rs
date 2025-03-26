/// # Sharingan Module
///
/// The Sharingan module is the core visual pattern recognition engine of the iHoje application.
/// It provides advanced DOM traversal and HTML analysis capabilities for extracting structured
/// event data from web pages.
///
/// ## Features
///
/// - Pattern recognition to identify and extract event data
/// - Multi-method price extraction with intelligent fallbacks
/// - Adaptive rate limiting and request throttling
/// - Support for mock data in test environments
/// - Support for HTTrack extraction or FireCrawl API scraping
/// - Comprehensive error handling and debugging capabilities
///
/// ## Core Functions
///
/// - `init_client`: Initialize the Firecrawl API client
/// - `scrape_events_page`: Extract HTML from event pages
/// - `fetch_event_prices`: Get detailed price information for events
/// - `url_to_file_path`: Convert URL to local file path for HTTrack extraction
///
/// The module is named after the Sharingan, a fictional visual prowess that allows its users
/// to comprehend the visual world with exceptional clarity and pattern recognition.
use anyhow::{anyhow, Result};
use chrono::Utc;
use firecrawl::scrape::{ScrapeFormats, ScrapeOptions};
use firecrawl::FirecrawlApp;
use log::{error, info, warn};
use regex::Regex;
use scraper::{Html, Selector};
use std::fs;
use std::path::Path;
use std::sync::Arc;
use url::Url;

use crate::config::CityConfig;
use crate::event::{extract_events, EventData, FailedPriceFetch};
use crate::rate_limiter::RateLimiter;

/// Initialize the Firecrawl client
pub fn init_client(api_key: &str) -> Result<FirecrawlApp> {
    // Debug log the API key (first 5 chars only for security)
    let prefix = if api_key.len() > 5 {
        &api_key[0..5]
    } else {
        api_key
    };
    info!(
        "Initializing client with API key starting with: {}...",
        prefix
    );

    FirecrawlApp::new(api_key).map_err(|e| {
        error!("Failed to initialize FirecrawlApp: {}", e);
        anyhow!("Failed to initialize FirecrawlApp: {}", e)
    })
}

/// Convert a URL to a file path in the extraction folder
pub fn url_to_file_path(extraction_folder: &str, url: &str) -> String {
    // Parse the URL to extract domain and path
    let url_parsed = Url::parse(url).unwrap_or_else(|_| {
        // If URL parsing fails, treat it as a relative path
        Url::parse(&format!("https://example.com{}", url)).unwrap()
    });

    // Extract domain and path
    let host = url_parsed.host_str().unwrap_or("unknown");
    let path = url_parsed.path();

    // If path ends with slash or is empty, append "index.html"
    let file_path = if path.ends_with('/') || path.is_empty() {
        format!("{}{}/index.html", host, path)
    } else if path.contains('.') {
        // If path contains a dot (likely already a file), use as is
        format!("{}{}", host, path)
    } else {
        // Otherwise, append ".html"
        format!("{}{}.html", host, path)
    };

    // Combine with extraction folder
    Path::new(extraction_folder)
        .join(file_path)
        .to_string_lossy()
        .to_string()
}

/// Scrape the events page with optional date range
pub async fn scrape_events_page(
    api_key: &str,
    base_url: &str,
    city_config: &CityConfig,
    rate_limiter: &Arc<RateLimiter>,
    date_range: &crate::config::DateRange,
    extraction_mode: &crate::config::ExtractionMode,
    extraction_folder: Option<&str>,
) -> Result<(String, String)> {
    // Set target URL with date range if specified
    let target_url = if date_range.is_specified() {
        match (date_range.start_date.as_ref(), date_range.end_date.as_ref()) {
            (Some(start), Some(end)) => {
                format!(
                    "{}/{}?date={}&endDate={}",
                    base_url, city_config.path, start, end
                )
            }
            (Some(start), None) => {
                format!("{}/{}?date={}", base_url, city_config.path, start)
            }
            (None, Some(end)) => {
                format!("{}/{}?endDate={}", base_url, city_config.path, end)
            }
            _ => format!("{}/{}", base_url, city_config.path),
        }
    } else {
        format!("{}/{}", base_url, city_config.path)
    };

    info!("Fetching events from: {}", target_url);

    // Current timestamp for file naming
    let timestamp = Utc::now().format("%Y-%m-%dT%H-%M-%S").to_string();

    // Check if we're in test mode (set by cargo test)
    let is_test = std::env::var("CARGO_TARGET_TMPDIR").is_ok();

    // In test mode, use test HTML file instead of making API call
    // Or if TEST_HTML environment variable is set
    let use_test_html = is_test || std::env::var("TEST_HTML").is_ok();

    let html_content = if use_test_html {
        info!("🧪 TEST MODE: Using test HTML file instead of API call");

        // Try to use test_events.html from tests directory
        let test_html_path = Path::new("tests/test_events.html");
        if test_html_path.exists() {
            fs::read_to_string(test_html_path)?
        } else {
            // Create minimal test HTML if test file doesn't exist
            let minimal_html = r#"<html><body>
                <div class="event-card">
                    <a href="/evento/test-event-123">
                        <h3>Test Event (Generated)</h3>
                        <span>25/03/2025</span>
                        <div>Test Convention Center</div>
                        <span>R$ 50,00</span>
                    </a>
                </div>
            </body></html>"#;

            // Save the minimal test HTML for future use
            save_html_for_debugging(minimal_html, &city_config.path, &timestamp)?;

            minimal_html.to_string()
        }
    } else if *extraction_mode == crate::config::ExtractionMode::Static {
        // Use static extraction folder
        if let Some(folder) = extraction_folder {
            info!("Using static extraction folder: {}", folder);

            // Convert target URL to a file path in the extraction folder
            let file_path = url_to_file_path(folder, &target_url);
            info!("Looking for HTML file at: {}", file_path);

            // Check if the file exists
            if Path::new(&file_path).exists() {
                // Read the HTML content from the file
                fs::read_to_string(&file_path)?
            } else {
                // Try index.html alternative
                let index_path = format!("{}/index.html", file_path.trim_end_matches(".html"));
                if Path::new(&index_path).exists() {
                    fs::read_to_string(&index_path)?
                } else {
                    // Try .html extension alternative
                    let html_path = format!("{}.html", file_path.trim_end_matches(".html"));
                    if Path::new(&html_path).exists() {
                        fs::read_to_string(&html_path)?
                    } else {
                        // Log error and return empty HTML
                        error!("HTML file not found in extraction folder: {}", file_path);
                        warn!("Tried alternatives: {} and {}", index_path, html_path);
                        "<html><body><p>No content found</p></body></html>".to_string()
                    }
                }
            }
        } else {
            // Log error and return empty HTML
            error!("Extraction folder not specified when in static extraction mode");
            "<html><body><p>No content found</p></body></html>".to_string()
        }
    } else {
        // FireCrawler mode - Initialize client for API calls
        let client = init_client(api_key)?;

        // Configure scraping options
        let options = ScrapeOptions {
            formats: Some(vec![ScrapeFormats::HTML]),
            ..Default::default()
        };

        // Wait for rate limiter before making API request
        rate_limiter.wait().await;

        // Scrape the page
        let result = client.scrape_url(&target_url, options).await.map_err(|e| {
            error!("Firecrawl error: {}", e);
            anyhow!("Failed to scrape events page: {}", e)
        })?;

        // Save HTML for debugging
        let html = result.html.clone().unwrap_or_default();
        save_html_for_debugging(&html, &city_config.path, &timestamp)?;

        html
    };

    Ok((html_content, timestamp))
}

/// Save HTML content to file for debugging
pub fn save_html_for_debugging(html_content: &str, city: &str, timestamp: &str) -> Result<()> {
    let debug_dir = Path::new("tests");
    if !debug_dir.exists() {
        fs::create_dir_all(debug_dir)?;
    }

    let html_path = debug_dir.join(format!("events-{}-{}.html", city, timestamp));
    fs::write(&html_path, html_content)?;
    info!("Saved HTML to {:?}", html_path);

    Ok(())
}

/// Fetch price information for each event
pub async fn fetch_event_prices(
    html_content: &str,
    city: &str,
    source_url: &str,
    api_key: &str,
    rate_limiter: &Arc<RateLimiter>,
    max_events: usize,
    extraction_mode: &crate::config::ExtractionMode,
    extraction_folder: Option<&str>,
) -> Result<(Vec<EventData>, Vec<FailedPriceFetch>)> {
    // Extract events from HTML with max_events limit
    let mut events = extract_events(html_content, city, source_url, max_events);
    info!("Found {} events (limited to {})", events.len(), max_events);

    // Vector for tracking failed price fetches
    let mut failed_price_fetches: Vec<FailedPriceFetch> = Vec::new();

    // Check if we're in test mode (set by cargo test)
    let is_test = std::env::var("CARGO_TARGET_TMPDIR").is_ok();

    // In test mode, or if TEST_NO_PRICES is set, use mock data instead of API calls
    let use_mock_prices = is_test || std::env::var("TEST_NO_PRICES").is_ok();

    if use_mock_prices {
        info!("🧪 TEST MODE: Using mock price data instead of API calls");

        // Apply mock prices to avoid API calls
        for event in events.iter_mut() {
            // Apply a mock price based on event ID to make it deterministic
            let mock_price = if event.id.contains("test") {
                "R$ 50,00 (TEST)".to_string()
            } else {
                format!("R$ {:.2},00 (TEST)", event.id.len() as f32 * 10.0)
            };

            event.price = mock_price;
            info!(
                "Using mock price for event {}: {}",
                event.title, event.price
            );

            // Simulate a failure for every 5th event to test failure handling
            if event.id.len() % 5 == 0 {
                let error_msg = "Mock price fetch failure for testing".to_string();
                warn!("Simulated failure for {}", event.url);
                failed_price_fetches.push(FailedPriceFetch::new(event, error_msg));
            }
        }
    } else if *extraction_mode == crate::config::ExtractionMode::Static {
        // Use static extraction folder for HTML files
        if let Some(folder) = extraction_folder {
            info!(
                "Using static extraction folder for price fetching: {}",
                folder
            );

            for event in events.iter_mut() {
                // Convert event URL to a file path in the extraction folder
                let file_path = url_to_file_path(folder, &event.url);
                info!("Looking for event HTML file at: {}", file_path);

                // Try to read the HTML file
                match fs::read_to_string(&file_path) {
                    Ok(html_content) => {
                        // Parse HTML document
                        let document = Html::parse_document(&html_content);

                        // Try to find the price
                        match find_price(&document)
                            .or_else(|| find_price_in_text(&document))
                            .or_else(|| find_price_with_regex(&html_content))
                        {
                            Some(price) => {
                                event.price = price;
                                info!("Found price for event {}: {}", event.title, event.price);
                            }
                            None => {
                                let error_msg =
                                    format!("Price not found in HTML file: {}", file_path);
                                warn!("{}", error_msg);

                                // Record the failure
                                failed_price_fetches.push(FailedPriceFetch::new(event, error_msg));

                                event.price =
                                    "Price not available (Not found in local HTML)".to_string();
                            }
                        }
                    }
                    Err(e) => {
                        // Try index.html alternative
                        let index_path =
                            format!("{}/index.html", file_path.trim_end_matches(".html"));
                        match fs::read_to_string(&index_path) {
                            Ok(html_content) => {
                                // Parse HTML document
                                let document = Html::parse_document(&html_content);

                                // Try to find the price
                                match find_price(&document)
                                    .or_else(|| find_price_in_text(&document))
                                    .or_else(|| find_price_with_regex(&html_content))
                                {
                                    Some(price) => {
                                        event.price = price;
                                        info!(
                                            "Found price for event {}: {}",
                                            event.title, event.price
                                        );
                                    }
                                    None => {
                                        let error_msg =
                                            format!("Price not found in HTML file: {}", index_path);
                                        warn!("{}", error_msg);

                                        // Record the failure
                                        failed_price_fetches
                                            .push(FailedPriceFetch::new(event, error_msg));

                                        event.price =
                                            "Price not available (Not found in local HTML)"
                                                .to_string();
                                    }
                                }
                            }
                            Err(_) => {
                                let error_msg = format!(
                                    "Event HTML file not found: {} (error: {})",
                                    file_path, e
                                );
                                warn!("{}", error_msg);

                                // Record the failure
                                failed_price_fetches.push(FailedPriceFetch::new(event, error_msg));

                                event.price =
                                    "Price not available (Local HTML file not found)".to_string();
                            }
                        }
                    }
                }
            }
        } else {
            // Log error and set default prices
            error!("Extraction folder not specified in static extraction mode");
            for event in events.iter_mut() {
                let error_msg = "Extraction folder not specified for static mode".to_string();
                warn!("{}", error_msg);

                // Record the failure
                failed_price_fetches.push(FailedPriceFetch::new(event, error_msg));

                event.price = "Price not available (No extraction folder)".to_string();
            }
        }
    } else {
        // Real API mode - Initialize client
        let client = init_client(api_key)?;

        // Fetch price information for each event with rate limiting
        info!("Fetching price information for events with rate limiting...");

        for event in events.iter_mut() {
            if event.url.starts_with("http") {
                // Wait for rate limiter before making API request
                rate_limiter.wait().await;

                match fetch_event_price(&client, &event.url).await {
                    Ok(price) => {
                        event.price = price;
                        info!("Fetched price for event {}: {}", event.title, event.price);
                    }
                    Err(e) => {
                        let error_msg = format!("{}", e);
                        warn!("Failed to fetch price for {}: {}", event.url, error_msg);

                        // Record the failure with detailed reason
                        let detailed_reason = format!("Failed to fetch price: {}", error_msg);
                        info!(
                            "Event {} - Failure reason: {}",
                            event.title, detailed_reason
                        );

                        // Create summary reason for price field
                        let summary_reason = error_msg
                            .split_whitespace()
                            .take(10)
                            .collect::<Vec<_>>()
                            .join(" ");

                        // Record the failure
                        failed_price_fetches.push(FailedPriceFetch::new(event, error_msg));

                        event.price = format!("Price not available (Reason: {})", summary_reason);
                    }
                }
            }
        }
    }

    Ok((events, failed_price_fetches))
}

/// Fetch the price information from an event page
async fn fetch_event_price(client: &FirecrawlApp, event_url: &str) -> Result<String> {
    // Configure scraping options
    let options = ScrapeOptions {
        formats: Some(vec![ScrapeFormats::HTML]),
        ..Default::default()
    };

    // Scrape the event page
    let result = client.scrape_url(event_url, options).await?;

    // Extract the HTML content
    let html_content = result.html.as_ref().unwrap_or(&String::new()).clone();

    // Parse HTML document
    let document = Html::parse_document(&html_content);

    find_price(&document)
        .or_else(|| find_price_in_text(&document))
        .or_else(|| find_price_with_regex(&html_content))
        .ok_or_else(|| anyhow!("Price not found"))
}

/// Find price using specific price selectors
fn find_price(document: &Html) -> Option<String> {
    // Look for price information using various selectors
    let price_selectors = [
        ".ticket-buy-price",
        ".evento-preco",
        ".price-box",
        "[data-testid='price']",
        "[class*='price']",
        "[class*='valor']",
    ];

    // Try to find price with each selector
    for selector_str in &price_selectors {
        if let Ok(selector) = Selector::parse(selector_str) {
            for element in document.select(&selector) {
                let text = element.text().collect::<String>().trim().to_string();

                // If text contains "R$", it's likely a price
                if text.contains("R$") {
                    return Some(text);
                }

                // Also check for attributes that might contain price info
                if let Some(price_attr) = element.value().attr("data-price") {
                    if !price_attr.is_empty() {
                        return Some(format!("R$ {}", price_attr));
                    }
                }
            }
        }
    }

    None
}

/// Find price in general text elements
fn find_price_in_text(document: &Html) -> Option<String> {
    let text_selector = Selector::parse("p, span, div").unwrap();

    for element in document.select(&text_selector) {
        let text = element.text().collect::<String>().trim().to_string();

        // Match text containing price information
        if text.contains("R$") && text.len() < 100 {
            // Avoid grabbing large text blocks
            // Simplistic extraction - in production code, you'd use a more precise regex
            return Some(text.split('\n').next().unwrap_or(&text).trim().to_string());
        }
    }

    None
}

/// Find price using regex as a last resort
fn find_price_with_regex(html_content: &str) -> Option<String> {
    let price_regex = Regex::new(r"R\$\s?(\d+[,.]\d+)").ok()?;

    let prices: Vec<f64> = price_regex
        .captures_iter(html_content)
        .filter_map(|cap| {
            cap.get(1).and_then(|price_match| {
                let price_str = price_match.as_str().replace(',', ".");
                price_str.parse::<f64>().ok()
            })
        })
        .collect();

    // Return lowest price if found
    if !prices.is_empty() {
        let mut sorted_prices = prices.clone();
        sorted_prices.sort_by(|a, b| a.partial_cmp(b).unwrap());

        return Some(format!("R$ {:.2}", sorted_prices[0]).replace('.', ","));
    }

    None
}
