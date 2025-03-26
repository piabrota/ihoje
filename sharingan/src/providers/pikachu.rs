use crate::config::AppConfig;
use crate::event::{EventData, FailedPriceFetch}; // Removed unused extract_events
use crate::providers::EventProvider;
use crate::rate_limiter::RateLimiter;
use anyhow::Result;
use log::info; // Only keep the log level we're using
use std::sync::Arc;

#[derive(Default)]
pub struct PikachuProvider;

impl PikachuProvider {
    pub fn new() -> Self {
        Self {}
    }

    // Forward function calls to the core sharingan module
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
        // Use the core function from the sharingan module
        crate::sharingan::scrape_events_page(
            api_key,
            base_url,
            city_config,
            rate_limiter,
            date_range,
            extraction_mode,
            extraction_folder,
        )
        .await
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
        // Use the core function from the sharingan module
        crate::sharingan::fetch_event_prices(
            html_content,
            city,
            source_url,
            api_key,
            rate_limiter,
            max_events,
            extraction_mode,
            extraction_folder,
        )
        .await
    }

    // Price fetching methods removed as they are now handled by the core sharingan module
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
