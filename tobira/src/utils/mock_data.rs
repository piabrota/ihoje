use gloo::console::log;
use pokeball::{mock, Event, EventQuery};
use std::cell::Cell;
use wasm_bindgen::prelude::*;

// Use thread_local for Wasm-compatible global state
thread_local! {
    static USE_MOCK_DATA: Cell<bool> = Cell::new(false);
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
    if let Ok(value) = std::panic::catch_unwind(|| crate::utils::config::get_config().use_mock_data)
    {
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

/// Get events from the shared mock repository
/// This replaces the previous dynamic generation with a consistent set of 10 events
pub fn get_mock_events() -> Vec<Event> {
    log!("Using predefined mock events from shared repository");
    mock::get_mock_events()
}

/// Find a mock event by ID
pub fn get_mock_event(id: &str) -> Option<Event> {
    mock::find_mock_event(id)
}

/// Apply event query filters to mock events
pub fn apply_query_to_mock_events(query: EventQuery) -> Vec<Event> {
    mock::filter_mock_events(&query)
}
