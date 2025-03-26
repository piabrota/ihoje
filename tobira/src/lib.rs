pub mod api;
pub mod app;
pub mod components;
pub mod i18n;
pub mod models;
pub mod pages;
pub mod router;
pub mod utils;

use wasm_bindgen::prelude::*;
use web_sys::{console, window, Performance};
use yew::html;

// Re-export the mock data functions so they're available at the top level
pub use utils::mock_data::{enable_mock_data, is_mock_data_enabled};

// Performance tracking function
fn mark_performance(name: &str) {
    if let Some(window) = window() {
        if let Ok(Some(performance)) = window.performance() {
            let _ = performance.mark(name);
        }
    }
}

// This is the entry point that will be used when loaded as a library
#[wasm_bindgen(start)]
pub fn start() {
    // Mark when WASM execution begins
    mark_performance("wasm-execution-start");
    
    // Set panic hook for better error messages
    console_error_panic_hook::set_once();

    // Initialize logging with debug level
    wasm_logger::init(wasm_logger::Config::new(log::Level::Debug));

    // Log startup message
    log::info!("Starting iHoje tobira application via lib.rs");

    // Initialize the Yew app
    yew::Renderer::<app::App>::new().render();
    
    // Mark when first render completes
    mark_performance("wasm-first-render-complete");
    
    // Create performance measure
    if let Some(window) = window() {
        if let Ok(Some(performance)) = window.performance() {
            let _ = performance.measure("wasm-to-render", "wasm-execution-start", "wasm-first-render-complete");
            if let Ok(entries) = performance.get_entries_by_name("wasm-to-render") {
                if let Some(measure) = entries.get(0) {
                    console::log_1(&format!("WASM execution to render time: {}ms", measure.duration()).into());
                }
            }
        }
    }
}

// Kept for backward compatibility
#[wasm_bindgen]
pub fn run_app() -> Result<(), JsValue> {
    start();
    Ok(())
}

// For testing page in isolation
#[wasm_bindgen]
pub fn render_test_component() -> Result<(), JsValue> {
    let document = web_sys::window()
        .expect("should have a window")
        .document()
        .expect("should have a document");
    
    let app_element = document
        .get_element_by_id("app")
        .expect("should have app element");
    
    // Clear the app element
    app_element.set_inner_html("");
    
    // Create a simple test component
    let test_html = html! {
        <div class="test-component">
            <h2>{"Test Component Rendered"}</h2>
            <p>{"This is a test component rendered by the WASM module."}</p>
            <button id="click-me">{"Click Me"}</button>
        </div>
    };
    
    // Render the test component
    yew::Renderer::<components::ui::loading::Loading>::with_root(app_element).render();
    
    // Log success
    console::log_1(&"Test component rendered successfully".into());
    
    Ok(())
}
