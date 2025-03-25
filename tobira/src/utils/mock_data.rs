use pokeball::Event;
use std::collections::HashMap;
use wasm_bindgen::prelude::*;
use wasm_bindgen::JsValue;
use gloo::console::log;
use chrono::Utc;

/// Generate random fake events data for tobira testing
/// This allows us to test the tobira without hitting the PostgreSQL database
pub fn generate_fake_events() -> Vec<Event> {
    // Use Rust's random number generator for WASM
    let timestamp = js_sys::Date::now() as u32;
    let mut events = Vec::new();
    
    log!("Generating fake events data with seed: {}", timestamp);
    
    // Set of event images from various categories
    let images = vec![
        // Local images (available in the Docker image)
        "/static/images/event1.svg",
        "/static/images/event2.svg",
        "/static/images/event3.svg",
        "/static/images/event4.svg",
        
        // Use the same local images again to make sure we have enough
        "/static/images/event1.svg", 
        "/static/images/event2.svg",
        "/static/images/event3.svg",
    ];
    
    // Event titles in different categories
    let event_titles: HashMap<&str, Vec<&str>> = [
        ("concert", vec![
            "Rock Revolution '25",
            "Jazz in the Square",
            "Symphony Under the Stars",
            "Electronic Pulse Night",
            "Acoustic Sunset Sessions",
            "Metal Mayhem Festival"
        ]),
        ("festival", vec![
            "World Culture Festival",
            "Summer Music Fest",
            "Digital Art Exhibition",
            "Food & Wine Celebration",
            "Film Festival Weekend",
            "Literary Arts Showcase"
        ]),
        ("theater", vec![
            "Shakespeare in the Park",
            "Modern Dance Showcase",
            "Broadway Classics Night",
            "Improv Comedy Hour",
            "Ballet Performances",
            "Opera Highlights"
        ]),
        ("art", vec![
            "Contemporary Art Exhibition",
            "Photography Showcase",
            "Sculpture Garden Opening",
            "Digital Installations",
            "Street Art Festival",
            "Avant-garde Expressions"
        ])
    ].iter().cloned().collect();
    
    // Locations in the city
    let locations = vec![
        "City Convention Center",
        "Central Park Amphitheater",
        "Downtown Concert Hall",
        "The Grand Theater",
        "Riverside Exhibition Center",
        "Modern Art Museum",
        "University Auditorium",
        "Beachfront Stage",
        "Metropolitan Opera House"
    ];
    
    // Cities we can use
    let cities = vec!["FL", "SP", "RJ"];
    
    // Prices (mix of free and paid)
    let prices = vec![
        "R$ 0,00 (Gratuito)",
        "R$ 45,00",
        "R$ 60,00",
        "R$ 85,00",
        "R$ 120,00",
        "R$ 150,00",
        "R$ 0,00 (Entrada franca)",
        "R$ 75,00",
        "R$ 35,00",
        "R$ 90,00"
    ];
    
    // Generate dates over the next 60 days
    let dates = generate_upcoming_dates(60);
    
    // Generate random events
    for i in 1..30 {
        // Create variation with some randomness based on the index
        let idx = (i as usize) % images.len();
        let date_idx = (i as usize * 3) % dates.len();
        let loc_idx = (i as usize * 7) % locations.len();
        let price_idx = (i as usize * 11) % prices.len();
        let city_idx = (i as usize * 13) % cities.len();
        
        // Select a random category
        let categories = vec!["concert", "festival", "theater", "art"];
        let category = categories[(i as usize * 17) % categories.len()];
        
        // Get titles for this category
        let titles = event_titles.get(category).unwrap();
        let title_idx = (i as usize * 19) % titles.len();
        
        // Generate a unique ID
        let id = format!("fake-event-{}-{}", category, i);
        
        // Create the event
        let event = Event {
            id,
            title: titles[title_idx].to_string(),
            date: dates[date_idx].clone(),
            location: locations[loc_idx].to_string(),
            url: format!("https://example.com/events/{}", i),
            image_url: images[idx].to_string(),
            city: cities[city_idx].to_string(),
            price: prices[price_idx].to_string(),
            created_at: Some(Utc::now()),
        };
        
        events.push(event);
    }
    
    log!("Generated {} fake events", events.len());
    events
}

/// Generate formatted dates for the next n days
fn generate_upcoming_dates(days: usize) -> Vec<String> {
    let mut dates = Vec::new();
    
    // Use JavaScript to create dates 
    let now_ms = js_sys::Date::now();
    
    // One day in milliseconds
    let day_ms = 1000.0 * 60.0 * 60.0 * 24.0;
    
    for i in 0..days {
        // Create a new date by adding days in milliseconds
        let future_ms = now_ms + (i as f64 * day_ms);
        let date = js_sys::Date::new(&JsValue::from_f64(future_ms));
        
        // Get day (1-31)
        let day = format!("{:02}", date.get_date() as i32);
        
        // Get month (0-11) and add 1
        let month = format!("{:02}", (date.get_month() as i32) + 1);
        
        // Get full year
        let year = date.get_full_year().to_string();
        
        // Format as DD/MM/YYYY
        let formatted = format!("{}/{}/{}", day, month, year);
        dates.push(formatted);
    }
    
    dates
}

// Use thread_local for Wasm-compatible global state
thread_local! {
    static USE_MOCK_DATA: std::cell::Cell<bool> = std::cell::Cell::new(false);
}

/// Enable mock data mode
#[wasm_bindgen]
pub fn enable_mock_data() {
    USE_MOCK_DATA.with(|flag| {
        flag.set(true);
        log!("Mock data mode enabled");
    });
}

/// Check if mock data mode is enabled
pub fn is_mock_data_enabled() -> bool {
    // First check if it's enabled by environment config
    if let Ok(value) = std::panic::catch_unwind(|| {
        crate::utils::config::get_config().use_mock_data
    }) {
        if value {
            return true;
        }
    }
    
    // Then check the override flag
    USE_MOCK_DATA.with(|flag| flag.get())
}

/// JavaScript-friendly version for external calls
#[wasm_bindgen(js_name = isMockDataEnabled)]
pub fn js_is_mock_data_enabled() -> bool {
    is_mock_data_enabled()
}