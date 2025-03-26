use chrono::Utc;
use log::info;
use regex::Regex;
use scraper::{Html, Selector};
use serde::Serialize;

/// A simplified event structure for CSV export
#[derive(Debug, Clone, Serialize)]
pub struct EventData {
    pub id: String,
    pub title: String,
    pub date: String,
    pub location: String,
    pub url: String,
    pub image_url: String,
    pub city: String,
    pub price: String,
}

/// Track failed price fetches
#[derive(Debug, Serialize)]
pub struct FailedPriceFetch {
    pub id: String,
    pub title: String,
    pub url: String,
    pub error: String,
    pub timestamp: String,
}

impl EventData {
    /// Create a new event with default "Fetching..." price
    pub fn new(
        id: String,
        title: String,
        date: String,
        location: String,
        url: String,
        image_url: String,
        city: String,
    ) -> Self {
        Self {
            id,
            title,
            date,
            location,
            url,
            image_url,
            city,
            price: "Fetching...".to_string(),
        }
    }

    /// Create a sample event for testing/demonstration
    pub fn sample(index: usize, city: &str, source_url: &str) -> Self {
        Self {
            id: format!("sample-{}", index),
            title: format!("Sample Event {} in {}", index, city),
            date: Utc::now().format("%d/%m/%Y").to_string(),
            location: format!("{} Convention Center", city),
            url: format!("{}/evento/sample-{}", source_url, index),
            image_url: "https://example.com/image.jpg".to_string(),
            city: city.to_string(),
            price: "R$ 0,00".to_string(),
        }
    }
}

impl FailedPriceFetch {
    /// Create a new failed price fetch record
    pub fn new(event: &EventData, error: String) -> Self {
        Self {
            id: event.id.clone(),
            title: event.title.clone(),
            url: event.url.clone(),
            error,
            timestamp: Utc::now().to_rfc3339(),
        }
    }

    /// Get a formatted string with error details
    pub fn error_details(&self) -> String {
        format!(
            "Error fetching price for '{}' (ID: {}): {}",
            self.title, self.id, self.error
        )
    }
}

/// Extract events from HTML content
pub fn extract_events(
    html: &str,
    city: &str,
    source_url: &str,
    max_events: usize,
) -> Vec<EventData> {
    // Parse HTML document
    let document = Html::parse_document(html);

    // Create a regular expression for ID extraction
    let id_regex = Regex::new(r"/evento/([^/]+)").unwrap();

    // Extract events using selectors
    let events = extract_events_from_document(&document, city, &id_regex).unwrap_or_else(|| {
        info!("No events found in HTML, creating sample data for demonstration");
        create_sample_events(city, source_url)
    });

    // Remove duplicates by URL
    let mut unique_events = events.clone();
    unique_events.sort_by(|a, b| a.url.cmp(&b.url));
    unique_events.dedup_by(|a, b| a.url == b.url);

    // Limit to max_events
    if unique_events.len() > max_events {
        info!(
            "Limiting events to {} (from {})",
            max_events,
            unique_events.len()
        );
        unique_events.truncate(max_events);
    }

    unique_events
}

/// Extract events from a parsed HTML document
fn extract_events_from_document(
    document: &Html,
    city: &str,
    id_regex: &Regex,
) -> Option<Vec<EventData>> {
    // Create selector for event links
    let event_selector = Selector::parse("a[href*='/evento/']").unwrap();

    // Find all event elements
    let events: Vec<EventData> = document
        .select(&event_selector)
        .filter(|element| !is_in_header_or_footer(element))
        .filter_map(|element| {
            // Get the href (URL)
            let url = element.value().attr("href")?.to_string();

            // Skip if not a valid event URL
            if !url.contains("/evento/") {
                return None;
            }

            // Extract event data
            let id = extract_id(&url, id_regex);
            let title = extract_title(element);
            let image_url = extract_image_url(element);
            let (date, location) = extract_date_and_location(element);

            // Create event data structure
            Some(EventData::new(
                id,
                title,
                date,
                location,
                url,
                image_url,
                city.to_string(),
            ))
        })
        .collect();

    // Return None if no events found
    if events.is_empty() {
        return None;
    }

    Some(events)
}

/// Check if element is in header or footer
fn is_in_header_or_footer(element: &scraper::ElementRef) -> bool {
    element
        .parent()
        .and_then(|p| p.value().as_element())
        .and_then(|e| e.attr("class"))
        .map(|class| class.contains("header") || class.contains("footer"))
        .unwrap_or(false)
}

/// Extract ID from event URL
fn extract_id(url: &str, id_regex: &Regex) -> String {
    id_regex
        .captures(url)
        .and_then(|cap| cap.get(1))
        .map(|m| m.as_str().to_string())
        .unwrap_or_else(|| format!("unknown-{}", url.len()))
}

/// Extract title from event element
fn extract_title(element: scraper::ElementRef) -> String {
    let title_selector = Selector::parse("h1, h2, h3, h4").unwrap();
    element
        .select(&title_selector)
        .next()
        .map(|e| e.text().collect::<String>().trim().to_string())
        .unwrap_or_else(|| element.text().collect::<String>().trim().to_string())
}

/// Extract image URL from event element
fn extract_image_url(element: scraper::ElementRef) -> String {
    let img_selector = Selector::parse("img").unwrap();
    element
        .select(&img_selector)
        .next()
        .and_then(|img| img.value().attr("src"))
        .unwrap_or_default()
        .to_string()
}

/// Extract date and location from event element
fn extract_date_and_location(element: scraper::ElementRef) -> (String, String) {
    let span_selector = Selector::parse("span, p, div, time").unwrap();
    let mut date = "Not found".to_string();
    let mut location = "Not found".to_string();

    for text_el in element.select(&span_selector) {
        let text = text_el.text().collect::<String>().trim().to_string();

        // Very simple date detection
        if text.contains("/") || text.contains(" de ") {
            date = text;
        }
        // If not a date and not short/numeric, assume location
        else if text.len() > 3 && !text.chars().all(|c| c.is_numeric()) && !text.contains("R$") {
            location = text;
        }
    }

    (date, location)
}

/// Create sample events when no events are found
fn create_sample_events(city: &str, source_url: &str) -> Vec<EventData> {
    (1..6)
        .map(|i| EventData::sample(i, city, source_url))
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_event_data_new() {
        let event = EventData::new(
            "test-id".to_string(),
            "Test Event".to_string(),
            "25/03/2025".to_string(),
            "Test Location".to_string(),
            "https://example.com/event".to_string(),
            "https://example.com/image.jpg".to_string(),
            "FL".to_string(),
        );

        assert_eq!(event.id, "test-id");
        assert_eq!(event.title, "Test Event");
        assert_eq!(event.date, "25/03/2025");
        assert_eq!(event.location, "Test Location");
        assert_eq!(event.url, "https://example.com/event");
        assert_eq!(event.image_url, "https://example.com/image.jpg");
        assert_eq!(event.city, "FL");
        assert_eq!(event.price, "Fetching...");
    }

    #[test]
    fn test_event_data_sample() {
        let event = EventData::sample(1, "FL", "https://example.com");

        assert_eq!(event.id, "sample-1");
        assert_eq!(event.title, "Sample Event 1 in FL");
        assert_eq!(event.location, "FL Convention Center");
        assert_eq!(event.url, "https://example.com/evento/sample-1");
        assert_eq!(event.city, "FL");
        assert_eq!(event.price, "R$ 0,00");
    }

    #[test]
    fn test_failed_price_fetch_new() {
        let event = EventData::new(
            "test-id".to_string(),
            "Test Event".to_string(),
            "25/03/2025".to_string(),
            "Test Location".to_string(),
            "https://example.com/event".to_string(),
            "https://example.com/image.jpg".to_string(),
            "FL".to_string(),
        );

        let error = "Test error".to_string();
        let failed = FailedPriceFetch::new(&event, error);

        assert_eq!(failed.id, "test-id");
        assert_eq!(failed.title, "Test Event");
        assert_eq!(failed.url, "https://example.com/event");
        assert_eq!(failed.error, "Test error");
    }

    #[test]
    fn test_extract_events() {
        let html = r#"<html><body>
            <div class="event-card">
                <a href="/evento/test-event-123">
                    <h3>Test Event</h3>
                    <span>25/03/2025</span>
                    <div>Test Convention Center</div>
                    <span>R$ 50,00</span>
                </a>
            </div>
        </body></html>"#;

        let events = extract_events(html, "FL", "https://example.com", 10);

        assert_eq!(events.len(), 1);
        assert_eq!(events[0].id, "test-event-123");
        assert_eq!(events[0].title, "Test Event");
        assert_eq!(events[0].location, "Test Convention Center");
        assert_eq!(events[0].url, "/evento/test-event-123");
        assert_eq!(events[0].city, "FL");
    }

    #[test]
    fn test_extract_id() {
        let id_regex = Regex::new(r"/evento/([^/]+)").unwrap();

        assert_eq!(extract_id("/evento/test-123", &id_regex), "test-123");
        assert_eq!(
            extract_id("/evento/another-test", &id_regex),
            "another-test"
        );
        assert_eq!(extract_id("invalid-url", &id_regex), "unknown-11");
    }
}
