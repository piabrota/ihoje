use anyhow::{Context, Result};
use log;

use crate::db::gcp::GcpBucketStore;
use crate::db::postgres::PostgresEventStore;
use crate::db::{EventStore, ExportFormat};
use crate::event::{EventData, FailedPriceFetch};

/// Export scraped data to configured destinations
pub async fn export_data(
    events: &[EventData],
    failed_price_fetches: &[FailedPriceFetch],
    _timestamp: &str,
    export_format: ExportFormat,
) -> Result<()> {
    match export_format {
        ExportFormat::Gcp => {
            // Use GCP bucket exporter
            let gcp_store =
                GcpBucketStore::new().context("Failed to create GCP bucket connection")?;

            // Store events
            gcp_store
                .store_events(events)
                .context("Failed to store events to GCP bucket")?;

            // Store failures if any
            if !failed_price_fetches.is_empty() {
                gcp_store
                    .store_failures(failed_price_fetches)
                    .await
                    .context("Failed to store failures to GCP bucket")?;
            }

            // Log success
            log::info!(
                "Successfully exported {} events and {} failures to GCP bucket",
                events.len(),
                failed_price_fetches.len()
            );
        }
        ExportFormat::Postgres => {
            // Use PostgreSQL exporter
            let postgres_store = PostgresEventStore::new()
                .await
                .context("Failed to create PostgreSQL connection")?;

            // Store events
            postgres_store
                .store_events(events)
                .context("Failed to store events to PostgreSQL")?;

            // Store failures
            if !failed_price_fetches.is_empty() {
                postgres_store
                    .store_failures(failed_price_fetches)
                    .await
                    .context("Failed to store failures to PostgreSQL")?;
            }

            // Log success
            log::info!(
                "Successfully exported {} events and {} failures to PostgreSQL",
                events.len(),
                failed_price_fetches.len()
            );
        }
        ExportFormat::Both => {
            // Use both exporters
            log::info!("Exporting to both PostgreSQL and GCP");

            // Try PostgreSQL first
            let postgres_result = PostgresEventStore::new().await;

            match postgres_result {
                Ok(postgres_store) => {
                    // Store events in PostgreSQL
                    if let Err(e) = postgres_store.store_events(events) {
                        log::error!("Failed to store events to PostgreSQL: {}", e);
                    } else {
                        log::info!(
                            "Successfully exported {} events to PostgreSQL",
                            events.len()
                        );
                    }

                    // Store failures in PostgreSQL
                    if !failed_price_fetches.is_empty() {
                        if let Err(e) = postgres_store.store_failures(failed_price_fetches).await {
                            log::error!("Failed to store failures to PostgreSQL: {}", e);
                        } else {
                            log::info!(
                                "Successfully exported {} failures to PostgreSQL",
                                failed_price_fetches.len()
                            );
                        }
                    }
                }
                Err(e) => {
                    log::error!("Failed to connect to PostgreSQL: {}", e);
                }
            }

            // Then try GCP
            let gcp_result = GcpBucketStore::new();

            match gcp_result {
                Ok(gcp_store) => {
                    // Store events in GCP
                    if let Err(e) = gcp_store.store_events(events) {
                        log::error!("Failed to store events to GCP: {}", e);
                    } else {
                        log::info!("Successfully exported {} events to GCP", events.len());
                    }

                    // Store failures in GCP
                    if !failed_price_fetches.is_empty() {
                        if let Err(e) = gcp_store.store_failures(failed_price_fetches).await {
                            log::error!("Failed to store failures to GCP: {}", e);
                        } else {
                            log::info!(
                                "Successfully exported {} failures to GCP",
                                failed_price_fetches.len()
                            );
                        }
                    }
                }
                Err(e) => {
                    log::error!("Failed to connect to GCP: {}", e);
                }
            }

            log::info!("Export to both destinations completed");
        }
        ExportFormat::PgWithGcpFallback => {
            log::info!("Exporting to PostgreSQL with GCP bucket fallback");

            // Try PostgreSQL first
            let postgres_result = PostgresEventStore::new().await;

            match postgres_result {
                Ok(postgres_store) => {
                    // Successfully created PostgreSQL connection
                    let events_result = postgres_store.store_events(events);
                    let mut events_stored = false;

                    match events_result {
                        Ok(()) => {
                            log::info!(
                                "Successfully exported {} events to PostgreSQL",
                                events.len()
                            );
                            events_stored = true;
                        }
                        Err(e) => {
                            log::error!("Failed to store events to PostgreSQL: {}", e);
                            log::warn!("Will attempt to fallback to GCP bucket for events");
                        }
                    }

                    // Handle failures export to PostgreSQL if there are any
                    let mut failures_stored = false;
                    if !failed_price_fetches.is_empty() {
                        match postgres_store.store_failures(failed_price_fetches).await {
                            Ok(()) => {
                                log::info!(
                                    "Successfully exported {} failures to PostgreSQL",
                                    failed_price_fetches.len()
                                );
                                failures_stored = true;
                            }
                            Err(e) => {
                                log::error!("Failed to store failures to PostgreSQL: {}", e);
                                log::warn!("Will attempt to fallback to GCP bucket for failures");
                            }
                        }
                    } else {
                        // No failures to export
                        failures_stored = true;
                    }

                    // If either events or failures weren't stored successfully, try GCP fallback
                    if !events_stored || !failures_stored {
                        log::info!(
                            "Attempting GCP bucket fallback for data not stored in PostgreSQL"
                        );

                        // Create GCP bucket connection
                        match GcpBucketStore::new() {
                            Ok(gcp_store) => {
                                // Store events if they weren't stored in PostgreSQL
                                if !events_stored {
                                    match gcp_store.store_events(events) {
                                        Ok(()) => {
                                            log::info!("Successfully exported {} events to GCP bucket as fallback", 
                                                      events.len());
                                        }
                                        Err(e) => {
                                            log::error!(
                                                "GCP fallback failed: could not store events: {}",
                                                e
                                            );
                                            return Err(anyhow::anyhow!(
                                                "Failed to export events to both PostgreSQL and GCP: {}", e));
                                        }
                                    }
                                }

                                // Store failures if they weren't stored in PostgreSQL
                                if !failures_stored && !failed_price_fetches.is_empty() {
                                    match gcp_store.store_failures(failed_price_fetches).await {
                                        Ok(()) => {
                                            log::info!("Successfully exported {} failures to GCP bucket as fallback", 
                                                      failed_price_fetches.len());
                                        }
                                        Err(e) => {
                                            log::error!(
                                                "GCP fallback failed: could not store failures: {}",
                                                e
                                            );
                                            return Err(anyhow::anyhow!(
                                                "Failed to export failures to both PostgreSQL and GCP: {}", e));
                                        }
                                    }
                                }
                            }
                            Err(e) => {
                                log::error!("GCP fallback failed: could not create GCP bucket connection: {}", e);
                                return Err(anyhow::anyhow!(
                                    "Failed to export to PostgreSQL and could not create GCP fallback: {}", e));
                            }
                        }
                    }
                }
                Err(pg_error) => {
                    // PostgreSQL connection failed completely, try GCP
                    log::error!("Failed to create PostgreSQL connection: {}", pg_error);
                    log::warn!("Falling back to GCP bucket for all data");

                    // Create GCP bucket connection
                    let gcp_store = GcpBucketStore::new()
                        .context("Failed to create GCP bucket connection for fallback")?;

                    // Store events
                    gcp_store
                        .store_events(events)
                        .context("GCP fallback failed: could not store events")?;

                    // Store failures if any
                    if !failed_price_fetches.is_empty() {
                        gcp_store
                            .store_failures(failed_price_fetches)
                            .await
                            .context("GCP fallback failed: could not store failures")?;
                    }

                    log::info!("Successfully exported {} events and {} failures to GCP bucket as complete fallback", 
                              events.len(), failed_price_fetches.len());
                }
            }

            log::info!(
                "Export complete for {} events and {} failures",
                events.len(),
                failed_price_fetches.len()
            );
        }
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::env;

    #[tokio::test]
    async fn test_export_data_postgres_format() {
        // Skip if not in test mode
        if std::env::var("TEST_POSTGRES").is_err() {
            return;
        }

        // Create test data
        let events = vec![EventData {
            id: "test-1".to_string(),
            title: "Test Event 1".to_string(),
            date: "25/03/2025".to_string(),
            location: "Test Location 1".to_string(),
            url: "https://example.com/event1".to_string(),
            image_url: "https://example.com/image1.jpg".to_string(),
            city: "FL".to_string(),
            price: "R$ 50,00".to_string(),
        }];

        let failures = vec![FailedPriceFetch {
            id: "test-1".to_string(),
            title: "Test Event 1".to_string(),
            url: "https://example.com/event1".to_string(),
            error: "Connection error".to_string(),
            timestamp: "2025-03-25T12:00:00Z".to_string(),
        }];

        // Test PostgreSQL export format
        let timestamp = "test";

        // Set mock test values for PostgreSQL
        env::set_var("PG_HOST", "localhost");
        env::set_var("PG_PORT", "5432");
        env::set_var("PG_USER", "test_user");
        env::set_var("PG_PASSWORD", "test_password");
        env::set_var("PG_DATABASE", "test_db");

        // Test is in mock mode so it won't actually connect
        env::set_var("CARGO_TARGET_TMPDIR", "1");

        let result = export_data(&events, &failures, timestamp, ExportFormat::Postgres).await;

        // Should succeed in test mode
        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn test_export_data_gcp_format() {
        // Create test data
        let events = vec![EventData {
            id: "test-2".to_string(),
            title: "Test Event 2".to_string(),
            date: "26/03/2025".to_string(),
            location: "Test Location 2".to_string(),
            url: "https://example.com/event2".to_string(),
            image_url: "https://example.com/image2.jpg".to_string(),
            city: "RJ".to_string(),
            price: "R$ 75,00".to_string(),
        }];

        let failures = vec![];

        // Set mock test values for GCP
        env::set_var("GCP_BUCKET_NAME", "test-bucket");
        env::set_var("GCP_PROJECT_ID", "test-project");
        env::set_var("GCP_API_KEY", "test-api-key");

        // Test GCP export format
        let timestamp = "test";
        let result = export_data(&events, &failures, timestamp, ExportFormat::Gcp).await;

        // Should succeed with mock GCP implementation
        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn test_export_data_fallback_format() {
        // Create test data
        let events = vec![EventData {
            id: "test-3".to_string(),
            title: "Test Event 3".to_string(),
            date: "27/03/2025".to_string(),
            location: "Test Location 3".to_string(),
            url: "https://example.com/event3".to_string(),
            image_url: "https://example.com/image3.jpg".to_string(),
            city: "SP".to_string(),
            price: "R$ 100,00".to_string(),
        }];

        let failures = vec![];

        // Set mock test values for PostgreSQL and GCP
        env::set_var("PG_HOST", "localhost");
        env::set_var("PG_PORT", "5432");
        env::set_var("PG_USER", "test_user");
        env::set_var("PG_PASSWORD", "test_password");
        env::set_var("PG_DATABASE", "test_db");

        env::set_var("GCP_BUCKET_NAME", "test-bucket");
        env::set_var("GCP_PROJECT_ID", "test-project");
        env::set_var("GCP_API_KEY", "test-api-key");

        // Test is in mock mode so it won't actually connect
        env::set_var("CARGO_TARGET_TMPDIR", "1");

        // Test fallback export format
        let timestamp = "test";
        let result = export_data(
            &events,
            &failures,
            timestamp,
            ExportFormat::PgWithGcpFallback,
        )
        .await;

        // Should succeed with mock implementations
        assert!(result.is_ok());
    }
}
