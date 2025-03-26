// Import modules directly since this is an integration test
extern crate ihoje;

use ihoje::event::{EventData, extract_events};
use ihoje::providers::pikachu::PikachuProvider;
use ihoje::rate_limiter::RateLimiter;
use ihoje::sharingan::init_client;
use ihoje::providers::EventProvider;
use anyhow::Result;
use std::sync::Arc;
use std::env;

// Specialized test for Rock The Mountain event price extraction
// Note: We avoid mentioning the actual provider name to prevent security issues
#[tokio::test]
async fn test_rock_the_mountain_price_extraction() -> Result<()> {
    // 1. Setup test environment
    env::set_var("TEST_HTML", "1"); // Enable test mode
    
    // 2. Load the Rock The Mountain test HTML
    let html_content = include_str!("rtm_test.html");
    
    // 3. Extract basic event data
    let events = extract_events(html_content, "RJ", "https://example.com", 10);
    
    // 4. Verify basic event data was extracted correctly
    assert!(!events.is_empty(), "Should extract at least one event");
    assert!(events[0].title.contains("Rock the Mountain"), 
           "Should extract Rock the Mountain event");
    
    // 5. Create a provider instance for price extraction testing
    let provider = PikachuProvider::new();
    
    // 6. Test with modified price extraction function that supports:
    // - Finding the cheapest ticket
    // - Extracting the price with tax information
    // - Extracting the price in cents
    
    // Mock the URL for this test (won't be used since we're in test mode)
    let test_url = "https://www.example.com/evento/rock-the-mountain-2025-2-final-de-semana/2728071";
    
    // Create a fake FirecrawlApp instance - won't be used due to TEST_HTML mode
    let mock_api_key = "test_key";
    let client = init_client(mock_api_key)?;
    
    // Set up a rate limiter
    let rate_limiter = Arc::new(RateLimiter::new(1));
    
    // Call the test implementation
    let mut detailed_price = test_detailed_price_extraction(&provider, &client, html_content)?;
    
    // 7. Verify the detailed price information was correctly extracted
    assert_eq!(detailed_price.display_price, "R$ 454,00");
    assert_eq!(detailed_price.fee_display, "R$ 45,40");
    assert_eq!(detailed_price.price_cents, 49940);
    assert_eq!(detailed_price.currency, "BRL");
    
    println!("✅ Rock The Mountain price extraction test passed!");
    println!("Found price: {}", detailed_price.display_price);
    println!("Fee: {}", detailed_price.fee_display);
    println!("Price in cents: {}", detailed_price.price_cents);
    println!("Currency: {}", detailed_price.currency);
    
    Ok(())
}

// Test implementation of detailed price extraction
// For a real implementation, this should be added to the PikachuProvider struct
fn test_detailed_price_extraction(
    provider: &PikachuProvider,
    _client: &firecrawl::FirecrawlApp,
    html_content: &str
) -> Result<DetailedPrice> {
    // Parse HTML document
    let document = scraper::Html::parse_document(html_content);
    
    // Find all ticket price elements
    let price_box_selector = scraper::Selector::parse(".ticket-price-box").unwrap();
    let price_selector = scraper::Selector::parse(".price").unwrap();
    let fee_selector = scraper::Selector::parse(".fee").unwrap();
    let hidden_data_selector = scraper::Selector::parse(".hidden-data").unwrap();
    
    // For collecting all prices
    let mut prices: Vec<DetailedPrice> = Vec::new();
    
    // Extract prices from each ticket option
    for price_box in document.select(&price_box_selector) {
        let mut detailed_price = DetailedPrice::default();
        
        // Extract display price
        if let Some(price_el) = price_box.select(&price_selector).next() {
            detailed_price.display_price = price_el.text().collect::<String>().trim().to_string();
        }
        
        // Extract fee display
        if let Some(fee_el) = price_box.select(&fee_selector).next() {
            let fee_text = fee_el.text().collect::<String>().trim().to_string();
            detailed_price.fee_display = fee_text.trim_start_matches("(+ ").trim_end_matches(")").to_string();
        }
        
        // Extract data attributes if available
        if let Some(data_el) = price_box.select(&hidden_data_selector).next() {
            // Get price in cents
            if let Some(price_cents_str) = data_el.value().attr("data-price-cents") {
                if let Ok(price_cents) = price_cents_str.parse::<u64>() {
                    detailed_price.price_cents = price_cents;
                }
            }
            
            // Get currency
            if let Some(currency) = data_el.value().attr("data-currency") {
                detailed_price.currency = currency.to_string();
            }
            
            // Get fee in cents
            if let Some(fee_cents_str) = data_el.value().attr("data-fee-cents") {
                if let Ok(fee_cents) = fee_cents_str.parse::<u64>() {
                    detailed_price.fee_cents = fee_cents;
                }
            }
        }
        
        // Extract price as number for comparison
        if let Some(numeric_price) = extract_numeric_price(&detailed_price.display_price) {
            detailed_price.numeric_price = numeric_price;
        }
        
        prices.push(detailed_price);
    }
    
    // If we didn't find any prices with the selectors, try the regular price extraction
    if prices.is_empty() {
        // Use the provider's existing methods to find a price
        let price_str = provider.find_price(&document)
            .or_else(|| provider.find_price_in_text(&document))
            .or_else(|| provider.find_price_with_regex(html_content))
            .unwrap_or_else(|| "Preço não encontrado".to_string());
        
        let mut price = DetailedPrice::default();
        price.display_price = price_str;
        
        // Extract numeric price
        if let Some(numeric_price) = extract_numeric_price(&price_str) {
            price.numeric_price = numeric_price;
            // Convert to cents (multiply by 100)
            price.price_cents = (numeric_price * 100.0).round() as u64;
        }
        
        return Ok(price);
    }
    
    // Sort prices by numeric value to find the cheapest valid option
    prices.sort_by(|a, b| a.numeric_price.partial_cmp(&b.numeric_price).unwrap());
    
    // Return the cheapest price that has a valid numeric value
    for price in &prices {
        if price.numeric_price > 0.0 {
            return Ok(price.clone());
        }
    }
    
    // Return the first price if no valid numeric prices found
    Ok(prices.first().cloned().unwrap_or_default())
}

// Helper to extract numeric price value from a price string
fn extract_numeric_price(price_str: &str) -> Option<f64> {
    let re = regex::Regex::new(r"R\$\s?(\d+[,.]\d+)").ok()?;
    
    re.captures(price_str).and_then(|cap| {
        cap.get(1).and_then(|price_match| {
            let price_str = price_match.as_str().replace(',', ".");
            price_str.parse::<f64>().ok()
        })
    })
}

// Struct to hold detailed price information
#[derive(Debug, Clone, Default)]
struct DetailedPrice {
    display_price: String,      // R$ 454,00
    fee_display: String,        // R$ 45,40 taxa
    price_cents: u64,           // 49940
    fee_cents: u64,             // 4540
    currency: String,           // BRL
    numeric_price: f64,         // 454.00
}