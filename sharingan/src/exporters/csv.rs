use anyhow::Result;
use csv::Writer;
use log::info;
use std::fs;
use std::fs::File;

use crate::db::EventStore;
use crate::event::{EventData, FailedPriceFetch};
use crate::exporters::Exporter;

/// CSV exporter implementation
#[derive(Default)]
pub struct CsvExporter;

impl CsvExporter {
    /// Create a new CSV exporter
    pub fn new() -> Self {
        Self
    }
}

impl Exporter for CsvExporter {
    fn export_events(&self, events: &[EventData], timestamp: &str) -> Result<String> {
        // Create CSV file
        let filename = format!("events_{}.csv", timestamp);
        let file = File::create(&filename)?;
        let mut wtr = Writer::from_writer(file);

        // Write header
        wtr.write_record([
            "id",
            "title",
            "date",
            "location",
            "url",
            "image_url",
            "city",
            "price",
        ])?;

        // Write each event
        for event in events {
            wtr.write_record([
                &event.id,
                &event.title,
                &event.date,
                &event.location,
                &event.url,
                &event.image_url,
                &event.city,
                &event.price,
            ])?;
        }

        // Flush writer
        wtr.flush()?;

        info!("Exported {} events to CSV file: {}", events.len(), filename);
        Ok(filename)
    }

    fn export_failures(&self, failures: &[FailedPriceFetch], timestamp: &str) -> Result<String> {
        if failures.is_empty() {
            return Ok("No failures to export".to_string());
        }

        // Create CSV file
        let filename = format!("failures_{}.csv", timestamp);
        let file = File::create(&filename)?;
        let mut wtr = Writer::from_writer(file);

        // Write header
        wtr.write_record(["id", "title", "url", "error", "timestamp"])?;

        // Write each failure
        for failure in failures {
            wtr.write_record([
                &failure.id,
                &failure.title,
                &failure.url,
                &failure.error,
                &failure.timestamp,
            ])?;
        }

        // Flush writer
        wtr.flush()?;

        info!(
            "Exported {} failures to CSV file: {}",
            failures.len(),
            filename
        );
        Ok(filename)
    }
}

// Implement EventStore for CsvExporter (for consistency with the interface)
impl EventStore for CsvExporter {
    fn store_events(&self, events: &[EventData]) -> Result<()> {
        // Generate timestamp for the filename
        let timestamp = chrono::Utc::now().format("%Y-%m-%dT%H-%M-%S").to_string();

        // Use the Exporter implementation
        self.export_events(events, &timestamp)?;

        Ok(())
    }

    fn clear_events(&self) -> Result<()> {
        // Find and delete all CSV files starting with "events_"
        let entries = fs::read_dir(".")?;
        let mut deleted_count = 0;

        for entry in entries {
            let entry = entry?;
            let path = entry.path();

            if path.is_file() {
                if let Some(filename) = path.file_name() {
                    if let Some(filename_str) = filename.to_str() {
                        if filename_str.starts_with("events_") && filename_str.ends_with(".csv") {
                            fs::remove_file(&path)?;
                            deleted_count += 1;
                        }
                    }
                }
            }
        }

        info!("Cleared {} CSV event files", deleted_count);
        Ok(())
    }

    fn get_events(&self, city: Option<&str>, limit: Option<usize>) -> Result<Vec<EventData>> {
        // Find the most recent events CSV file
        let entries = fs::read_dir(".")?;
        let mut latest_file = None;
        let mut latest_time = std::time::UNIX_EPOCH;

        for entry in entries {
            let entry = entry?;
            let path = entry.path();

            if path.is_file() {
                if let Some(filename) = path.file_name() {
                    if let Some(filename_str) = filename.to_str() {
                        if filename_str.starts_with("events_") && filename_str.ends_with(".csv") {
                            if let Ok(metadata) = fs::metadata(&path) {
                                if let Ok(modified) = metadata.modified() {
                                    if modified > latest_time {
                                        latest_time = modified;
                                        latest_file = Some(path);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // If no file found, return empty vector
        let latest_file = match latest_file {
            Some(file) => file,
            None => {
                info!("No CSV event files found when trying to get events");
                return Ok(Vec::new());
            }
        };

        // Read CSV file
        let file = File::open(latest_file)?;
        let mut rdr = csv::Reader::from_reader(file);

        // Parse records into EventData objects
        let mut events = Vec::new();
        for result in rdr.records() {
            let record = result?;
            if record.len() < 8 {
                continue; // Skip invalid records
            }

            let event = EventData {
                id: record[0].to_string(),
                title: record[1].to_string(),
                date: record[2].to_string(),
                location: record[3].to_string(),
                url: record[4].to_string(),
                image_url: record[5].to_string(),
                city: record[6].to_string(),
                price: record[7].to_string(),
            };

            // Apply city filter if provided
            if let Some(city_filter) = city {
                if event.city != city_filter {
                    continue;
                }
            }

            events.push(event);
        }

        // Apply limit if provided
        if let Some(limit_value) = limit {
            if events.len() > limit_value {
                events.truncate(limit_value);
            }
        }

        info!("Retrieved {} events from CSV file", events.len());
        Ok(events)
    }

    fn get_event_by_id(&self, id: &str) -> Result<Option<EventData>> {
        // Get all events from CSV
        let events = self.get_events(None, None)?;

        // Find the event with matching ID
        let event = events.into_iter().find(|e| e.id == id);

        if event.is_some() {
            info!("Found event with ID {} in CSV", id);
        } else {
            info!("No event found with ID {} in CSV", id);
        }

        Ok(event)
    }

    fn get_upcoming_events(
        &self,
        city: Option<&str>,
        limit: Option<usize>,
    ) -> Result<Vec<EventData>> {
        // Get all events from CSV
        let all_events = self.get_events(city, None)?;

        // Get today's date for comparison
        let today = chrono::Local::now().date_naive();

        // Filter events with future dates
        let mut upcoming = all_events
            .into_iter()
            .filter(|event| {
                // Parse date from DD/MM/YYYY format
                let parts: Vec<&str> = event.date.split('/').collect();
                if parts.len() != 3 {
                    return false; // Invalid date format
                }

                // Parse day, month, year
                let day = parts[0].parse::<u32>().unwrap_or(0);
                let month = parts[1].parse::<u32>().unwrap_or(0);
                let year = parts[2].parse::<i32>().unwrap_or(0);

                if day == 0 || month == 0 || year == 0 {
                    return false; // Invalid date
                }

                // Create NaiveDate and compare with today
                match chrono::NaiveDate::from_ymd_opt(year, month, day) {
                    Some(event_date) => event_date >= today,
                    None => false,
                }
            })
            .collect::<Vec<_>>();

        // Sort by date (ascending)
        upcoming.sort_by(|a, b| {
            let parse_date = |date_str: &str| -> Option<chrono::NaiveDate> {
                let parts: Vec<&str> = date_str.split('/').collect();
                if parts.len() != 3 {
                    return None;
                }

                let day = parts[0].parse::<u32>().ok()?;
                let month = parts[1].parse::<u32>().ok()?;
                let year = parts[2].parse::<i32>().ok()?;

                chrono::NaiveDate::from_ymd_opt(year, month, day)
            };

            let date_a = parse_date(&a.date);
            let date_b = parse_date(&b.date);

            match (date_a, date_b) {
                (Some(da), Some(db)) => da.cmp(&db),
                (Some(_), None) => std::cmp::Ordering::Less,
                (None, Some(_)) => std::cmp::Ordering::Greater,
                (None, None) => a.date.cmp(&b.date), // Fallback to string comparison
            }
        });

        // Apply limit if provided
        if let Some(limit_value) = limit {
            if upcoming.len() > limit_value {
                upcoming.truncate(limit_value);
            }
        }

        info!("Retrieved {} upcoming events from CSV", upcoming.len());
        Ok(upcoming)
    }
}
