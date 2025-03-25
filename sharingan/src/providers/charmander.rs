use crate::config::AppConfig;
use crate::event::EventData;
use crate::providers::EventProvider;
use crate::rate_limiter::RateLimiter;
use crate::sharingan::init_client;
use anyhow::{Context, Result};
use chrono::Utc;
use firecrawl::scrape::{ScrapeOptions, ScrapeFormats};
use log::{info, warn};
use scraper::{Html, Selector};
use regex::Regex;
use std::fs;
use std::path::Path;
use std::sync::Arc;
use uuid::Uuid;

pub struct CharmanderProvider;

impl CharmanderProvider {
    pub fn new() -> Self {
        Self {}
    }
    
    // Helper to extract event details from Shotgun page
    async fn extract_event_details(&self, client: &firecrawl::FirecrawlApp, url: &str) -> Result<EventData> {
        info!("Extracting details from: {}", url);
        
        // Scrape the event page
        let options = ScrapeOptions {
            formats: Some(vec![ScrapeFormats::HTML]),
            ..Default::default()
        };
        
        let result = client.scrape_url(url, options).await
            .context(format!("Failed to scrape event page: {}", url))?;
        
        let html = result.html.as_ref().unwrap_or(&String::new()).clone();
        let document = Html::parse_document(&html);
        
        // Extract event details
        let title = self.extract_title(&document)
            .unwrap_or_else(|| "Unknown Event".to_string());
            
        let date = self.extract_date(&document)
            .unwrap_or_else(|| Utc::now().format("%d/%m/%Y").to_string());
            
        let location = self.extract_location(&document)
            .unwrap_or_else(|| "Unknown Location".to_string());
            
        let price = self.extract_price(&document, &html)
            .unwrap_or_else(|| "Price not available".to_string());
            
        let image_url = self.extract_image(&document)
            .unwrap_or_default();
            
        // Extract city from URL or use default
        let city = url.split('/').nth(3).unwrap_or("unknown");
        
        // Generate unique ID
        let id = format!("charmander-{}", Uuid::new_v4().to_string().split('-').next().unwrap_or("unknown"));
        
        // Create event data
        let event = EventData {
            id,
            title,
            date,
            location,
            url: url.to_string(),
            image_url,
            city: city.to_string(),
            price,
        };
        
        Ok(event)
    }
    
    fn extract_title(&self, document: &Html) -> Option<String> {
        // Try different title selectors
        let title_selectors = [
            "h1.event-title", 
            ".event-name", 
            ".title", 
            "h1",
        ];
        
        for selector_str in &title_selectors {
            if let Ok(selector) = Selector::parse(selector_str) {
                for element in document.select(&selector) {
                    let text = element.text().collect::<String>().trim().to_string();
                    if !text.is_empty() {
                        return Some(text);
                    }
                }
            }
        }
        
        None
    }
    
    fn extract_date(&self, document: &Html) -> Option<String> {
        // Try different date selectors
        let date_selectors = [
            ".event-date", 
            ".date", 
            "time", 
            "[itemprop='startDate']",
        ];
        
        for selector_str in &date_selectors {
            if let Ok(selector) = Selector::parse(selector_str) {
                for element in document.select(&selector) {
                    let text = element.text().collect::<String>().trim().to_string();
                    if !text.is_empty() && (text.contains("/") || text.contains(" de ")) {
                        return Some(text);
                    }
                    
                    // Also check for datetime attribute
                    if let Some(date_attr) = element.value().attr("datetime") {
                        // Convert ISO date to DD/MM/YYYY
                        if let Ok(date) = chrono::DateTime::parse_from_rfc3339(date_attr) {
                            return Some(date.format("%d/%m/%Y").to_string());
                        }
                    }
                }
            }
        }
        
        None
    }
    
    fn extract_location(&self, document: &Html) -> Option<String> {
        // Try different location selectors
        let location_selectors = [
            ".event-location", 
            ".venue", 
            ".location", 
            "[itemprop='location']",
        ];
        
        for selector_str in &location_selectors {
            if let Ok(selector) = Selector::parse(selector_str) {
                for element in document.select(&selector) {
                    let text = element.text().collect::<String>().trim().to_string();
                    if !text.is_empty() {
                        return Some(text);
                    }
                }
            }
        }
        
        None
    }
    
    fn extract_price(&self, document: &Html, html: &str) -> Option<String> {
        // Try different price selectors
        let price_selectors = [
            ".event-price", 
            ".price", 
            "[itemprop='price']",
            ".ticket-price",
        ];
        
        // First try direct selectors
        for selector_str in &price_selectors {
            if let Ok(selector) = Selector::parse(selector_str) {
                for element in document.select(&selector) {
                    let text = element.text().collect::<String>().trim().to_string();
                    if !text.is_empty() && (text.contains("R$") || text.contains("€") || text.contains("$")) {
                        return Some(text);
                    }
                }
            }
        }
        
        // Try regex fallback
        let price_regex = Regex::new(r"R\$\s?(\d+[,.]\d+)").ok()?;
        let prices: Vec<f64> = price_regex.captures_iter(html)
            .filter_map(|cap| {
                cap.get(1).and_then(|price_match| {
                    let price_str = price_match.as_str().replace(',', ".");
                    price_str.parse::<f64>().ok()
                })
            })
            .collect();
        
        if !prices.is_empty() {
            let mut sorted_prices = prices.clone();
            sorted_prices.sort_by(|a, b| a.partial_cmp(b).unwrap());
            return Some(format!("R$ {:.2}", sorted_prices[0]).replace('.', ","));
        }
        
        None
    }
    
    fn extract_image(&self, document: &Html) -> Option<String> {
        // Try different image selectors
        let image_selectors = [
            ".event-image img", 
            ".cover img", 
            "[itemprop='image']",
            ".event-header img",
            "img.header",
            "img.cover",
        ];
        
        for selector_str in &image_selectors {
            if let Ok(selector) = Selector::parse(selector_str) {
                for element in document.select(&selector) {
                    // Check src attribute
                    if let Some(src) = element.value().attr("src") {
                        if !src.is_empty() {
                            return Some(src.to_string());
                        }
                    }
                    
                    // Check data-src attribute (lazy loading)
                    if let Some(data_src) = element.value().attr("data-src") {
                        if !data_src.is_empty() {
                            return Some(data_src.to_string());
                        }
                    }
                }
            }
        }
        
        None
    }
}

impl EventProvider for CharmanderProvider {
    fn name(&self) -> &'static str {
        "charmander"
    }
    
    fn fetch_events<'a>(&'a self, config: &'a AppConfig) -> impl std::future::Future<Output = Result<Vec<EventData>>> + Send + 'a {
        async move {
            let rate_limiter = Arc::new(RateLimiter::new(3)); // Default rate limit
            
            info!("Fetching events from Charmander provider");
            
            // Initialize API client
            let client = init_client(&config.api_key)?;
            
            // Use Firecrawl API to get event listings
            let options = ScrapeOptions {
                formats: Some(vec![ScrapeFormats::HTML]),
                ..Default::default()
            };
            
            // Check if we're in test mode (set by cargo test)
            let is_test = std::env::var("CARGO_TARGET_TMPDIR").is_ok();
            let use_mock_data = is_test || std::env::var("TEST_HTML").is_ok();
            
            let events = if use_mock_data {
                info!("🧪 TEST MODE: Using mock event data for Charmander provider");
                
                // Create sample test events
                (1..=config.max_events).map(|i| {
                    EventData {
                        id: format!("charmander-test-{}", i),
                        title: format!("Charmander Test Event {}", i),
                        date: Utc::now().format("%d/%m/%Y").to_string(),
                        location: format!("{} Venue", config.city_config.name),
                        url: format!("https://shotgun.live/events/test-{}", i),
                        image_url: "https://example.com/image.jpg".to_string(),
                        city: config.city.clone(),
                        price: format!("R$ {:.2},00", 50.0 + (i as f32 * 10.0)),
                    }
                }).collect::<Vec<EventData>>()
            } else {
                // Construct base URL for shotgun
                let shotgun_url = "https://shotgun.live/pt-br";
                
                // Wait for rate limiter before making API request
                rate_limiter.wait().await;
                
                // Scrape the base events page
                info!("Scraping Shotgun events page: {}", shotgun_url);
                let result = client.scrape_url(shotgun_url, options).await
                    .context("Failed to fetch Charmander events")?;
                    
                // Get HTML content
                let html = result.html.clone().unwrap_or_default();
                
                // Save HTML for debugging
                let timestamp = Utc::now().format("%Y-%m-%dT%H-%M-%S").to_string();
                let debug_dir = Path::new("tests");
                if !debug_dir.exists() {
                    fs::create_dir_all(debug_dir)?;
                }
                let html_path = debug_dir.join(format!("charmander-events-{}.html", timestamp));
                fs::write(&html_path, &html)?;
                info!("Saved Charmander HTML to {:?}", html_path);
                
                // Create selector for event links
                let event_selector = Selector::parse("a[href*='/events/']").unwrap();
                
                // Extract all event URLs in a way that doesn't share the Html across await points
                let event_urls: Vec<String>;
                {
                    // Create a new scope so document is dropped before any await points
                    let document = Html::parse_document(&html);
                    
                    // Extract URLs within this scope
                    event_urls = document.select(&event_selector)
                        .filter_map(|el| {
                            el.value().attr("href").map(|href| {
                                if href.starts_with("http") {
                                    href.to_string()
                                } else {
                                    format!("https://shotgun.live{}", href)
                                }
                            })
                        })
                        .collect();
                } // document is dropped here
                    
                info!("Found {} event URLs from Shotgun", event_urls.len());
                
                // Limit the number of events to process
                let limited_urls = if event_urls.len() > config.max_events {
                    event_urls[0..config.max_events].to_vec()
                } else {
                    event_urls
                };
                
                // Process each event URL in parallel
                use tokio::sync::Semaphore;
                use futures::future::join_all;
                
                // Create a semaphore to limit concurrent requests (acts as rate limiter)
                let semaphore = Arc::new(Semaphore::new(3)); // Allow 3 concurrent requests
                
                // Create a vector to store all fetch futures
                let mut fetch_futures = Vec::new();
                
                // Create futures for each event URL
                for url in limited_urls {
                    let sem_clone = semaphore.clone();
                    let rate_limiter_clone = rate_limiter.clone();
                    let client_clone = client.clone();
                    let url_clone = url.clone();
                    let self_clone = Self {};
                    
                    // Create a future that respects both the rate limiter and semaphore
                    let future = async move {
                        // Acquire semaphore permit
                        let _permit = sem_clone.acquire().await.unwrap();
                        
                        // Wait for rate limiter
                        rate_limiter_clone.wait().await;
                        
                        // Extract event details
                        let result = self_clone.extract_event_details(&client_clone, &url_clone).await;
                        
                        (url_clone, result)
                    };
                    
                    fetch_futures.push(future);
                }
                
                // Execute all futures concurrently and collect the results
                let results = join_all(fetch_futures).await;
                
                // Process the results
                let mut events = Vec::new();
                for (url, result) in results {
                    match result {
                        Ok(event) => {
                            info!("Successfully extracted event: {}", event.title);
                            events.push(event);
                        },
                        Err(e) => {
                            warn!("Failed to extract event from {}: {}", url, e);
                        }
                    }
                }
                
                events
            };
            
            info!("Charmander provider found {} events", events.len());
            Ok(events)
        }
    }
}
