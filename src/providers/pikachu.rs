use crate::config::AppConfig;
use crate::event::{EventData, FailedPriceFetch, extract_events};
use crate::providers::EventProvider;
use crate::rate_limiter::RateLimiter;
use crate::sharingan::{init_client, save_html_for_debugging};
use anyhow::{Result, anyhow, Context};
use chrono::Utc;
use firecrawl::scrape::{ScrapeOptions, ScrapeFormats};
use log::{info, warn, error};
use scraper::{Html, Selector};
use regex::Regex;
use std::fs;
use std::path::Path;
use std::sync::Arc;

pub struct PikachuProvider;

impl PikachuProvider {
    pub fn new() -> Self {
        Self {}
    }
    
    // Make price finding methods public for testing
    pub fn find_price(&self, document: &Html) -> Option<String> {
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

    pub fn find_price_in_text(&self, document: &Html) -> Option<String> {
        let text_selector = Selector::parse("p, span, div").unwrap();
        
        for element in document.select(&text_selector) {
            let text = element.text().collect::<String>().trim().to_string();
            
            // Match text containing price information
            if text.contains("R$") && text.len() < 100 {  // Avoid grabbing large text blocks
                // Simplistic extraction - in production code, you'd use a more precise regex
                return Some(text.split('\n').next().unwrap_or(&text).trim().to_string());
            }
        }
        
        None
    }

    pub fn find_price_with_regex(&self, html_content: &str) -> Option<String> {
        let price_regex = Regex::new(r"R\$\s?(\d+[,.]\d+)").ok()?;
        
        let prices: Vec<f64> = price_regex.captures_iter(html_content)
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

    // Extracts and adapts existing functionality from scraper module
    async fn scrape_events_page(
        &self,
        api_key: &str,
        base_url: &str,
        city_config: &crate::config::CityConfig,
        rate_limiter: &Arc<RateLimiter>,
        date_range: &crate::config::DateRange
    ) -> Result<(String, String)> {
        // Set target URL with date range if specified
        let target_url = if date_range.is_specified() {
            match (date_range.start_date.as_ref(), date_range.end_date.as_ref()) {
                (Some(start), Some(end)) => {
                    format!("{}/{}?date={}&endDate={}", base_url, city_config.path, start, end)
                },
                (Some(start), None) => {
                    format!("{}/{}?date={}", base_url, city_config.path, start)
                },
                (None, Some(end)) => {
                    format!("{}/{}?endDate={}", base_url, city_config.path, end)
                },
                _ => format!("{}/{}", base_url, city_config.path)
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
        } else {
            // Initialize client for real API calls
            let client = init_client(api_key)?;
            
            // Configure scraping options
            let options = ScrapeOptions {
                formats: Some(vec![ScrapeFormats::HTML]),
                ..Default::default()
            };
            
            // Wait for rate limiter before making API request
            rate_limiter.wait().await;
            
            // Scrape the page
            let result = client.scrape_url(&target_url, options).await
                .map_err(|e| {
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

    async fn fetch_event_prices(
        &self,
        html_content: &str,
        city: &str,
        source_url: &str,
        api_key: &str,
        rate_limiter: &Arc<RateLimiter>,
        max_events: usize
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
                info!("Using mock price for event {}: {}", event.title, event.price);
                
                // Simulate a failure for every 5th event to test failure handling
                if event.id.len() % 5 == 0 {
                    let error_msg = "Mock price fetch failure for testing".to_string();
                    warn!("Simulated failure for {}", event.url);
                    failed_price_fetches.push(FailedPriceFetch::new(event, error_msg));
                }
            }
        } else {
            // Real API mode - Initialize client
            let client = init_client(api_key)?;
            
            // Fetch price information for each event with rate limiting but in parallel
            info!("Fetching price information for events in parallel with rate limiting...");
            
            use tokio::sync::Semaphore;
            use futures::future::join_all;
            
            // Create a semaphore to limit concurrent requests (acts as rate limiter)
            let semaphore = Arc::new(Semaphore::new(3)); // Allow 3 concurrent requests
            
            // Create a vector to store all fetch futures
            let mut fetch_futures = Vec::new();
            
            // Create futures for each event
            for (index, event) in events.iter().enumerate() {
                if event.url.starts_with("http") {
                    let event_url = event.url.clone();
                    let title = event.title.clone();
                    let sem_clone = semaphore.clone();
                    let rate_limiter_clone = rate_limiter.clone();
                    let client_clone = client.clone();
                    
                    // Create a future that respects both the rate limiter and semaphore
                    let future = async move {
                        // Acquire semaphore permit
                        let _permit = sem_clone.acquire().await.unwrap();
                        
                        // Wait for rate limiter
                        rate_limiter_clone.wait().await;
                        
                        // Fetch the price
                        let result = self.fetch_event_price(&client_clone, &event_url).await;
                        
                        // Return the result along with the index and event details
                        (index, title, event_url, result)
                    };
                    
                    fetch_futures.push(future);
                }
            }
            
            // Execute all futures concurrently and collect the results
            let results = join_all(fetch_futures).await;
            
            // Process the results and update the events
            for (index, title, url, result) in results {
                match result {
                    Ok(price) => {
                        events[index].price = price;
                        info!("Fetched price for event {}: {}", title, events[index].price);
                    },
                    Err(e) => {
                        let error_msg = format!("{}", e);
                        warn!("Failed to fetch price for {}: {}", url, error_msg);
                        
                        // Create summary reason for price field
                        let summary_reason = error_msg.split_whitespace().take(10).collect::<Vec<_>>().join(" ");
                        
                        // Record the failure
                        failed_price_fetches.push(FailedPriceFetch::new(&events[index], error_msg));
                        
                        events[index].price = format!("Price not available (Reason: {})", summary_reason);
                    }
                }
            }
        }
        
        Ok((events, failed_price_fetches))
    }

    async fn fetch_event_price(&self, client: &firecrawl::FirecrawlApp, event_url: &str) -> Result<String> {
        // Configure scraping options
        let options = ScrapeOptions {
            formats: Some(vec![ScrapeFormats::HTML]),
            ..Default::default()
        };
        
        // Scrape the event page with improved error context
        let result = client.scrape_url(event_url, options).await
            .with_context(|| format!("Failed to scrape event page at URL: {}", event_url))?;
        
        // Extract the HTML content with improved error handling
        let html_content = result.html
            .as_ref()
            .ok_or_else(|| anyhow!("No HTML content returned from {}", event_url))?
            .clone();
        
        // Parse HTML document
        let document = Html::parse_document(&html_content);
        
        // Try multiple methods to find the price, with detailed context if all fail
        self.find_price(&document)
            .or_else(|| self.find_price_in_text(&document))
            .or_else(|| self.find_price_with_regex(&html_content))
            .ok_or_else(|| {
                // Provide more specific error information
                let doc_text_sample = document.root_element()
                    .text()
                    .take(100)
                    .collect::<String>();
                
                anyhow!(
                    "Price not found for event at {}. Document begins with: '{}'...",
                    event_url,
                    doc_text_sample.trim()
                )
            })
    }

    fn find_price(&self, document: &Html) -> Option<String> {
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

    fn find_price_in_text(&self, document: &Html) -> Option<String> {
        let text_selector = Selector::parse("p, span, div").unwrap();
        
        for element in document.select(&text_selector) {
            let text = element.text().collect::<String>().trim().to_string();
            
            // Match text containing price information
            if text.contains("R$") && text.len() < 100 {  // Avoid grabbing large text blocks
                // Simplistic extraction - in production code, you'd use a more precise regex
                return Some(text.split('\n').next().unwrap_or(&text).trim().to_string());
            }
        }
        
        None
    }

    fn find_price_with_regex(&self, html_content: &str) -> Option<String> {
        let price_regex = Regex::new(r"R\$\s?(\d+[,.]\d+)").ok()?;
        
        let prices: Vec<f64> = price_regex.captures_iter(html_content)
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
}

impl EventProvider for PikachuProvider {
    fn name(&self) -> &'static str {
        "pikachu"
    }
    
    fn fetch_events<'a>(&'a self, config: &'a AppConfig) -> impl std::future::Future<Output = Result<Vec<EventData>>> + Send + 'a {
        async move {
            let rate_limiter = Arc::new(RateLimiter::new(3)); // Default rate limit
            
            // Scrape events page with date range
            let (events_html, timestamp) = self.scrape_events_page(
                &config.api_key,
                &config.target_url,
                &config.city_config,
                &rate_limiter,
                &config.date_range
            ).await?;
            
            info!("Pikachu provider scraped events page at {}", timestamp);
            
            // Extract and enrich events with price information
            let (events, failures) = self.fetch_event_prices(
                &events_html,
                &config.city,
                &config.target_url,
                &config.api_key,
                &rate_limiter,
                config.max_events
            ).await?;
            
            info!("Pikachu provider found {} events with {} failures (max limit: {})", 
                    events.len(), failures.len(), config.max_events);
            
            Ok(events)
        }
    }
}
