pub mod charmander;
pub mod pikachu; // Main event provider // Secondary event provider

use crate::config::AppConfig;
use crate::event::EventData;
use anyhow::Result;

pub use charmander::CharmanderProvider;
pub use pikachu::PikachuProvider;

pub trait EventProvider {
    // Using impl Future instead of async fn, explicitly specifying Send bound
    // for better compatibility with Rust 1.84's async trait features

    /// Fetch events from the provider
    ///
    /// The provider implementation should respect the `use_firecrawl` flag in the config:
    /// - When `true`, use the FireCrawl API for scraping
    /// - When `false`, use local files from `extraction_folder` (HTTrack extraction)
    fn fetch_events<'a>(
        &'a self,
        config: &'a AppConfig,
    ) -> impl std::future::Future<Output = Result<Vec<EventData>>> + Send + 'a;

    /// Get the name of the provider
    fn name(&self) -> &'static str;
}

// Provider enum that can be matched on
pub enum Provider {
    Pikachu(PikachuProvider),
    Charmander(CharmanderProvider),
}

impl Provider {
    // Fetch events from the selected provider
    pub async fn fetch_events(&self, config: &AppConfig) -> Result<Vec<EventData>> {
        match self {
            Provider::Pikachu(provider) => provider.fetch_events(config).await,
            Provider::Charmander(provider) => provider.fetch_events(config).await,
        }
    }

    // Get the name of the provider
    pub fn name(&self) -> &'static str {
        match self {
            Provider::Pikachu(provider) => provider.name(),
            Provider::Charmander(provider) => provider.name(),
        }
    }
}

// Factory function to get provider by name
pub fn get_provider(name: &str) -> Provider {
    match name {
        "pikachu" => Provider::Pikachu(PikachuProvider::new()),
        "charmander" => Provider::Charmander(CharmanderProvider::new()),
        _ => {
            log::warn!("Unknown provider: {}, defaulting to pikachu", name);
            Provider::Pikachu(PikachuProvider::new())
        }
    }
}
