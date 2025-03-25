use crate::config::AppConfig;
use crate::event::{EventData, FailedPriceFetch}; // Removed unused extract_events
use crate::providers::EventProvider;
use crate::rate_limiter::RateLimiter;
use crate::sharingan;  // Import the whole module instead of unused specific functions
use anyhow::{anyhow, Context, Result};
use firecrawl::scrape::{ScrapeFormats, ScrapeOptions};
use log::info;  // Only keep the log level we're using
use regex::Regex;
use scraper::{Html, Selector};
use std::sync::Arc;

pub struct PikachuProvider;

impl PikachuProvider {
    pub fn new() -> Self {
        Self {}
    }

    // Extracts and adapts existing functionality from scraper module
    async fn scrape_events_page(
        &self,
        api_key: &str,
        base_url: &str,
        city_config: &crate::config::CityConfig,
        rate_limiter: &Arc<RateLimiter>,
        date_range: &crate::config::DateRange,
        extraction_mode: &crate::config::ExtractionMode,
        extraction_folder: Option<&str>,
    ) -> Result<(String, String)> {
        // Use the core sharingan function with the extraction mode
        crate::sharingan::scrape_events_page(
            api_key,
            base_url,
            city_config,
            rate_limiter,
            date_range,
            extraction_mode,
            extraction_folder,
        ).await
    }

    async fn fetch_event_prices(
        &self,
        html_content: &str,
        city: &str,
        source_url: &str,
        api_key: &str,
        rate_limiter: &Arc<RateLimiter>,
        max_events: usize,
        extraction_mode: &crate::config::ExtractionMode,
        extraction_folder: Option<&str>,
    ) -> Result<(Vec<EventData>, Vec<FailedPriceFetch>)> {
        // Use the core sharingan function with the extraction mode
        crate::sharingan::fetch_event_prices(
            html_content,
            city,
            source_url,
            api_key,
            rate_limiter,
            max_events,
            extraction_mode,
            extraction_folder,
        ).await
    }

    async fn fetch_event_price(
        &self,
        client: &firecrawl::FirecrawlApp,
        event_url: &str,
    ) -> Result<String> {
        // Configure scraping options
        let options = ScrapeOptions {
            formats: Some(vec![ScrapeFormats::HTML]),
            ..Default::default()
        };

        // Scrape the event page with improved error context
        let result = client
            .scrape_url(event_url, options)
            .await
            .with_context(|| format!("Failed to scrape event page at URL: {}", event_url))?;

        // Extract the HTML content with improved error handling
        let html_content = result
            .html
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
                let doc_text_sample = document.root_element().text().take(100).collect::<String>();

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
            if text.contains("R$") && text.len() < 100 {
                // Avoid grabbing large text blocks
                // Simplistic extraction - in production code, you'd use a more precise regex
                return Some(text.split('\n').next().unwrap_or(&text).trim().to_string());
            }
        }

        None
    }

    fn find_price_with_regex(&self, html_content: &str) -> Option<String> {
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
}

impl EventProvider for PikachuProvider {
    fn name(&self) -> &'static str {
        "pikachu"
    }

    fn fetch_events<'a>(
        &'a self,
        config: &'a AppConfig,
    ) -> impl std::future::Future<Output = Result<Vec<EventData>>> + Send + 'a {
        async move {
            let rate_limiter = Arc::new(RateLimiter::new(3)); // Default rate limit

            // Scrape events page with date range, using extraction mode
            let (events_html, timestamp) = self
                .scrape_events_page(
                    &config.api_key,
                    &config.target_url,
                    &config.city_config,
                    &rate_limiter,
                    &config.date_range,
                    &config.extraction_mode,
                    config.extraction_folder.as_deref(),
                )
                .await?;

            info!("Pikachu provider scraped events page at {}", timestamp);

            // Extract and enrich events with price information
            let (events, failures) = self
                .fetch_event_prices(
                    &events_html,
                    &config.city,
                    &config.target_url,
                    &config.api_key,
                    &rate_limiter,
                    config.max_events,
                    &config.extraction_mode,
                    config.extraction_folder.as_deref(),
                )
                .await?;

            info!(
                "Pikachu provider found {} events with {} failures (max limit: {})",
                events.len(),
                failures.len(),
                config.max_events
            );

            Ok(events)
        }
    }
}
