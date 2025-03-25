pub mod api;
pub mod app;
pub mod components;
pub mod i18n;
pub mod models;
pub mod pages;
pub mod router;
pub mod utils;

use wasm_bindgen::prelude::*;
use yew::html;

// Re-export the mock data functions so they're available at the top level
pub use utils::mock_data::{enable_mock_data, is_mock_data_enabled};

// This is the entry point that will be used when loaded as a library
#[wasm_bindgen(start)]
pub fn start() {
    // Set panic hook for better error messages
    console_error_panic_hook::set_once();
    
    // Initialize logging with debug level
    wasm_logger::init(wasm_logger::Config::new(log::Level::Debug));
    
    // Log startup message
    log::info!("Starting iHoje tobira application via lib.rs");
    
    // Initialize the Yew app
    yew::Renderer::<app::App>::new().render();
}

// Kept for backward compatibility
#[wasm_bindgen]
pub fn run_app() -> Result<(), JsValue> {
    start();
    Ok(())
}