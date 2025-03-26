use ihoje_tobira::app::App;
use ihoje_tobira::i18n::I18nProvider;
use ihoje_tobira::utils::mock_data::enable_mock_data;
use wasm_bindgen::prelude::*;
use web_sys::window;
use yew::html;

// Main function needed for wasm-bindgen
fn main() {
    // This is just a placeholder to satisfy the compiler
    // The actual entry point is the start function
}

// Check if the URL has a mock=true parameter
fn check_mock_data_flag() {
    if let Some(window) = window() {
        if let Ok(location) = window.location().search() {
            if location.contains("mock=true") {
                log::info!("Mock data flag detected in URL");
                enable_mock_data();
            }
        }
    }
}

// Try to detect browser language preference
fn detect_browser_language() -> Option<String> {
    window()
        .and_then(|window| window.navigator().language())
        .map(|lang| lang.to_lowercase())
}

// This is the actual entry point
#[wasm_bindgen(start)]
pub fn start() {
    // Initialize console error handling
    console_error_panic_hook::set_once();

    // Initialize logging
    wasm_logger::init(wasm_logger::Config::default());

    // Log startup
    log::info!("Starting Shinri no Tobira application");

    // Log browser language detection
    if let Some(lang) = detect_browser_language() {
        log::info!("Detected browser language: {}", lang);
    }

    // Check for mock data flag
    check_mock_data_flag();

    // Mount the Yew app with I18n provider
    yew::Renderer::new().render(html! {
        <I18nProvider>
            <App />
        </I18nProvider>
    });
}
