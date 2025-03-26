pub mod event;
pub mod mock;
pub mod query;

// Re-export key types for easier imports
pub use event::Event;
pub use query::{DateRange, EventQuery};

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::{Datelike, NaiveDate};

    #[test]
    fn test_event_creation() {
        let event = Event {
            id: "test-id".to_string(),
            title: "Test Event".to_string(),
            description: Some("Test Description".to_string()),
            url: "https://example.com/event".to_string(),
            date: NaiveDate::from_ymd_opt(2025, 4, 1).unwrap(),
            time: Some("20:00".to_string()),
            venue: Some("Test Venue".to_string()),
            city: "FL".to_string(),
            price: Some("$10".to_string()),
            image_url: Some("https://example.com/image.jpg".to_string()),
            provider: "pikachu".to_string(),
        };

        assert_eq!(event.id, "test-id");
        assert_eq!(event.title, "Test Event");
        assert_eq!(event.description, Some("Test Description".to_string()));
        assert_eq!(event.date.year(), 2025);
        assert_eq!(event.time, Some("20:00".to_string()));
        assert_eq!(event.provider, "pikachu");
    }

    #[test]
    fn test_query_creation() {
        let query = EventQuery {
            city: "FL".to_string(),
            date_range: DateRange {
                start_date: NaiveDate::from_ymd_opt(2025, 4, 1),
                end_date: NaiveDate::from_ymd_opt(2025, 4, 30),
            },
        };

        assert_eq!(query.city, "FL");
        assert_eq!(
            query.date_range.start_date,
            NaiveDate::from_ymd_opt(2025, 4, 1)
        );
        assert_eq!(
            query.date_range.end_date,
            NaiveDate::from_ymd_opt(2025, 4, 30)
        );
    }

    #[test]
    fn test_mock_events() {
        let events = mock::generate_mock_events(10, "FL");

        assert_eq!(events.len(), 10);
        assert!(events.iter().all(|e| e.city == "FL"));
        assert!(events.iter().all(|e| !e.id.is_empty()));
        assert!(events.iter().all(|e| !e.title.is_empty()));
    }
}
