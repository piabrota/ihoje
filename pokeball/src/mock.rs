use crate::Event;
use crate::EventQuery;
use chrono::NaiveDate;

/// Generate a specified number of mock events for testing
pub fn generate_mock_events(count: usize, city: &str) -> Vec<Event> {
    let mut events = Vec::with_capacity(count);

    for i in 1..=count {
        events.push(Event {
            id: format!("mock-event-{}", i),
            title: format!("Mock Event {}", i),
            description: Some(format!("Description for mock event {}", i)),
            url: format!("https://example.com/events/{}", i),
            date: NaiveDate::from_ymd_opt(2025, 4, i as u32 % 30 + 1).unwrap(),
            time: Some(format!("{}:00", 18 + (i % 5))),
            venue: Some(format!("Venue {}", i)),
            city: city.to_string(),
            price: Some(format!("${}.00", i * 10)),
            image_url: Some(format!("/static/images/event{}.svg", i % 4 + 1)),
            provider: "pikachu".to_string(),
        });
    }

    events
}

/// Returns a predefined list of 10 mock events for testing and development
pub fn get_mock_events() -> Vec<Event> {
    vec![
        Event {
            id: "mock-event-1".to_string(),
            title: "Rock Revolution '25".to_string(),
            description: Some("The ultimate rock experience".to_string()),
            date: NaiveDate::from_ymd_opt(2025, 4, 15).unwrap(),
            time: Some("20:00".to_string()),
            venue: Some("City Convention Center".to_string()),
            url: "https://example.com/events/rock-revolution".to_string(),
            image_url: Some("/static/images/event1.svg".to_string()),
            city: "SP".to_string(),
            price: Some("R$ 85,00".to_string()),
            provider: "pikachu".to_string(),
        },
        Event {
            id: "mock-event-2".to_string(),
            title: "Jazz in the Square".to_string(),
            description: Some("An evening of smooth jazz".to_string()),
            date: NaiveDate::from_ymd_opt(2025, 4, 22).unwrap(),
            time: Some("19:30".to_string()),
            venue: Some("Central Park Amphitheater".to_string()),
            url: "https://example.com/events/jazz-square".to_string(),
            image_url: Some("/static/images/event2.svg".to_string()),
            city: "RJ".to_string(),
            price: Some("R$ 45,00".to_string()),
            provider: "pikachu".to_string(),
        },
        Event {
            id: "mock-event-3".to_string(),
            title: "Symphony Under the Stars".to_string(),
            description: Some("Classical music under open skies".to_string()),
            date: NaiveDate::from_ymd_opt(2025, 5, 5).unwrap(),
            time: Some("20:00".to_string()),
            venue: Some("Metropolitan Opera House".to_string()),
            url: "https://example.com/events/symphony".to_string(),
            image_url: Some("/static/images/event3.svg".to_string()),
            city: "SP".to_string(),
            price: Some("R$ 120,00".to_string()),
            provider: "pikachu".to_string(),
        },
        Event {
            id: "mock-event-4".to_string(),
            title: "World Culture Festival".to_string(),
            description: Some("Celebrating diverse cultures".to_string()),
            date: NaiveDate::from_ymd_opt(2025, 5, 10).unwrap(),
            time: Some("10:00".to_string()),
            venue: Some("Riverside Exhibition Center".to_string()),
            url: "https://example.com/events/world-culture".to_string(),
            image_url: Some("/static/images/event4.svg".to_string()),
            city: "RJ".to_string(),
            price: Some("R$ 0,00 (Gratuito)".to_string()),
            provider: "pikachu".to_string(),
        },
        Event {
            id: "mock-event-5".to_string(),
            title: "Shakespeare in the Park".to_string(),
            description: Some("Classic theater in a natural setting".to_string()),
            date: NaiveDate::from_ymd_opt(2025, 5, 18).unwrap(),
            time: Some("18:30".to_string()),
            venue: Some("Central Park Amphitheater".to_string()),
            url: "https://example.com/events/shakespeare".to_string(),
            image_url: Some("/static/images/event1.svg".to_string()),
            city: "FL".to_string(),
            price: Some("R$ 0,00 (Entrada franca)".to_string()),
            provider: "pikachu".to_string(),
        },
        Event {
            id: "mock-event-6".to_string(),
            title: "Contemporary Art Exhibition".to_string(),
            description: Some("Modern masterpieces on display".to_string()),
            date: NaiveDate::from_ymd_opt(2025, 5, 25).unwrap(),
            time: Some("09:00".to_string()),
            venue: Some("Modern Art Museum".to_string()),
            url: "https://example.com/events/art-exhibition".to_string(),
            image_url: Some("/static/images/event2.svg".to_string()),
            city: "SP".to_string(),
            price: Some("R$ 35,00".to_string()),
            provider: "pikachu".to_string(),
        },
        Event {
            id: "mock-event-7".to_string(),
            title: "Electronic Pulse Night".to_string(),
            description: Some("Cutting-edge electronic music".to_string()),
            date: NaiveDate::from_ymd_opt(2025, 6, 1).unwrap(),
            time: Some("22:00".to_string()),
            venue: Some("Downtown Concert Hall".to_string()),
            url: "https://example.com/events/electronic-pulse".to_string(),
            image_url: Some("/static/images/event3.svg".to_string()),
            city: "RJ".to_string(),
            price: Some("R$ 75,00".to_string()),
            provider: "pikachu".to_string(),
        },
        Event {
            id: "mock-event-8".to_string(),
            title: "Film Festival Weekend".to_string(),
            description: Some("Celebrating independent cinema".to_string()),
            date: NaiveDate::from_ymd_opt(2025, 6, 7).unwrap(),
            time: Some("14:00".to_string()),
            venue: Some("The Grand Theater".to_string()),
            url: "https://example.com/events/film-festival".to_string(),
            image_url: Some("/static/images/event4.svg".to_string()),
            city: "FL".to_string(),
            price: Some("R$ 90,00".to_string()),
            provider: "pikachu".to_string(),
        },
        Event {
            id: "mock-event-9".to_string(),
            title: "Food & Wine Celebration".to_string(),
            description: Some("Culinary delights and fine wines".to_string()),
            date: NaiveDate::from_ymd_opt(2025, 6, 14).unwrap(),
            time: Some("17:00".to_string()),
            venue: Some("Beachfront Stage".to_string()),
            url: "https://example.com/events/food-wine".to_string(),
            image_url: Some("/static/images/event1.svg".to_string()),
            city: "RJ".to_string(),
            price: Some("R$ 150,00".to_string()),
            provider: "pikachu".to_string(),
        },
        Event {
            id: "mock-event-10".to_string(),
            title: "Street Art Festival".to_string(),
            description: Some("Urban art in its natural environment".to_string()),
            date: NaiveDate::from_ymd_opt(2025, 6, 21).unwrap(),
            time: Some("12:00".to_string()),
            venue: Some("Downtown Area".to_string()),
            url: "https://example.com/events/street-art".to_string(),
            image_url: Some("/static/images/event2.svg".to_string()),
            city: "SP".to_string(),
            price: Some("R$ 0,00 (Gratuito)".to_string()),
            provider: "pikachu".to_string(),
        },
    ]
}

/// Find a mock event by ID
pub fn find_mock_event(id: &str) -> Option<Event> {
    get_mock_events().into_iter().find(|event| event.id == id)
}

/// Apply query filters to mock events
pub fn filter_mock_events(query: &EventQuery) -> Vec<Event> {
    let events = get_mock_events();

    // Apply filtering based on query parameters
    events
        .into_iter()
        .filter(|event| {
            // City filter
            if event.city != query.city {
                return false;
            }

            // Date range filters
            if let Some(start_date) = query.date_range.start_date {
                if event.date < start_date {
                    return false;
                }
            }

            if let Some(end_date) = query.date_range.end_date {
                if event.date > end_date {
                    return false;
                }
            }

            true
        })
        .collect()
}
