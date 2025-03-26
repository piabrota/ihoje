use serde::{Deserialize, Serialize};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::OnceLock;
use wasm_bindgen::prelude::*;
use wasm_bindgen_futures::JsFuture;
// TODO: These types aren't currently available in web-sys, will need custom types instead
// use web_sys::{GeolocationPosition, GeolocationCoordinates};
use gloo::console::log;

// Global storage for the user's location
static USER_LOCATION: OnceLock<UserLocation> = OnceLock::new();
static LOCATION_REQUESTED: AtomicBool = AtomicBool::new(false);

/// User location information
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct UserLocation {
    /// Latitude in degrees
    pub latitude: f64,

    /// Longitude in degrees
    pub longitude: f64,

    /// Accuracy in meters
    pub accuracy: f64,

    /// Timestamp when the location was acquired
    pub timestamp: f64,

    /// Inferred city from coordinates
    pub city_code: Option<String>,

    /// Full city name
    pub city_name: Option<String>,
}

impl Default for UserLocation {
    fn default() -> Self {
        Self {
            latitude: 0.0,
            longitude: 0.0,
            accuracy: 0.0,
            timestamp: 0.0,
            city_code: None,
            city_name: None,
        }
    }
}

// We'll need to implement our own mapping from JS values instead of using the web_sys types
// This is a temporary implementation until we properly add all needed features to web-sys
impl UserLocation {
    /// Create from JavaScript position value
    pub fn from_js_value(position: &JsValue) -> Result<Self, String> {
        // Extract coords from position
        let coords = js_sys::Reflect::get(position, &JsValue::from_str("coords"))
            .map_err(|_| "Failed to get coords from position".to_string())?;

        // Extract individual properties
        let latitude = js_sys::Reflect::get(&coords, &JsValue::from_str("latitude"))
            .map_err(|_| "Failed to get latitude".to_string())?
            .as_f64()
            .ok_or("latitude is not a number".to_string())?;

        let longitude = js_sys::Reflect::get(&coords, &JsValue::from_str("longitude"))
            .map_err(|_| "Failed to get longitude".to_string())?
            .as_f64()
            .ok_or("longitude is not a number".to_string())?;

        let accuracy = js_sys::Reflect::get(&coords, &JsValue::from_str("accuracy"))
            .map_err(|_| "Failed to get accuracy".to_string())?
            .as_f64()
            .ok_or("accuracy is not a number".to_string())?;

        let timestamp = js_sys::Reflect::get(position, &JsValue::from_str("timestamp"))
            .map_err(|_| "Failed to get timestamp".to_string())?
            .as_f64()
            .ok_or("timestamp is not a number".to_string())?;

        Ok(Self {
            latitude,
            longitude,
            accuracy,
            timestamp,
            city_code: None,
            city_name: None,
        })
    }
}

/// Request user location
pub async fn request_user_location() -> Result<UserLocation, String> {
    // Check if we've already requested location
    if LOCATION_REQUESTED.swap(true, Ordering::SeqCst) {
        if let Some(location) = USER_LOCATION.get() {
            // Return cached location if available
            return Ok(location.clone());
        }
    }

    // Check if geolocation is available
    if !has_geolocation_support() {
        return Err("Geolocation is not supported by this browser".to_string());
    }

    // Get the navigation object
    let window = web_sys::window().ok_or("No window object available")?;
    let navigator = window.navigator();
    let geolocation = navigator
        .geolocation()
        .map_err(|e| format!("Failed to get geolocation object: {:?}", e))?;

    // Create a promise for getting current position
    let position_promise = get_current_position(&geolocation)?;

    // Wait for the promise to resolve
    let position_value = JsFuture::from(position_promise).await.map_err(|e| {
        let error_msg = match e.as_string() {
            Some(msg) => msg,
            None => format!("Failed to get position: {:?}", e),
        };

        match e.dyn_into::<js_sys::Error>() {
            Ok(error) => {
                // Handle specific geolocation errors
                if let Some(code) = js_sys::Reflect::get(&error, &JsValue::from_str("code"))
                    .ok()
                    .and_then(|v| v.as_f64())
                {
                    match code as u32 {
                        1 => {
                            return "Location access denied. Please enable location services."
                                .to_string()
                        }
                        2 => {
                            return "Unable to determine your location. Please try again."
                                .to_string()
                        }
                        3 => return "Location request timed out. Please try again.".to_string(),
                        _ => {}
                    }
                }
                error_msg
            }
            _ => error_msg,
        }
    })?;

    // Convert position to our type
    let mut location = UserLocation::from_js_value(&position_value)?;

    // Infer city from coordinates
    if let Ok(city_info) = infer_city_from_coordinates(location.latitude, location.longitude).await
    {
        location.city_code = Some(city_info.0);
        location.city_name = Some(city_info.1);
    }

    // Cache the location
    let _ = USER_LOCATION.set(location.clone());

    Ok(location)
}

/// Check if geolocation is supported
fn has_geolocation_support() -> bool {
    // Simplified implementation since geolocation isn't available in our web_sys version
    if let Some(_window) = web_sys::window() {
        return false; // Temporary until we have proper geolocation support
    }
    false
}

/// Get current position as a Promise
fn get_current_position(geolocation: &web_sys::Geolocation) -> Result<js_sys::Promise, String> {
    // Create options object
    let options = js_sys::Object::new();

    // Enable high accuracy for better results
    let _ = js_sys::Reflect::set(
        &options,
        &JsValue::from_str("enableHighAccuracy"),
        &JsValue::from_bool(true),
    );

    // Set timeout to 10 seconds
    let _ = js_sys::Reflect::set(
        &options,
        &JsValue::from_str("timeout"),
        &JsValue::from_f64(10000.0),
    );

    // Set maximum age of cached position to 5 minutes
    let _ = js_sys::Reflect::set(
        &options,
        &JsValue::from_str("maximumAge"),
        &JsValue::from_f64(300000.0),
    );

    // Call getCurrentPosition with options
    geolocation
        .get_current_position_with_options(options.unchecked_ref())
        .map_err(|e| format!("Error requesting position: {:?}", e))
}

/// Infer city from coordinates using either:
/// 1. A simple bounding box approach for key cities
/// 2. A reverse geocoding API call (optional)
async fn infer_city_from_coordinates(
    latitude: f64,
    longitude: f64,
) -> Result<(String, String), String> {
    // Simple bounding box approach for key Brazilian cities
    // Format: (lat_min, lat_max, lon_min, lon_max, city_code, city_name)
    let city_bounding_boxes = [
        // São Paulo
        (-24.0082, -23.3566, -46.8256, -46.3652, "SP", "São Paulo"),
        // Rio de Janeiro
        (
            -23.0831,
            -22.7460,
            -43.7958,
            -43.0969,
            "RJ",
            "Rio de Janeiro",
        ),
        // Florianópolis
        (
            -27.8465,
            -27.3838,
            -48.5989,
            -48.3393,
            "FL",
            "Florianópolis",
        ),
    ];

    // Check if coordinates are within any of the bounding boxes
    for (lat_min, lat_max, lon_min, lon_max, city_code, city_name) in city_bounding_boxes {
        if latitude >= lat_min
            && latitude <= lat_max
            && longitude >= lon_min
            && longitude <= lon_max
        {
            log!("Inferred city:", city_name);
            return Ok((city_code.to_string(), city_name.to_string()));
        }
    }

    // If not found in bounding boxes, we could call a reverse geocoding API
    // This is left as a placeholder for when you integrate with a real API
    // For now, return a default
    Err("City not recognized".to_string())
}

/// Attempt to get user's city code from location or preferences
pub async fn get_user_city() -> Option<String> {
    // First check if we already have a location
    if let Some(location) = USER_LOCATION.get() {
        if let Some(city) = &location.city_code {
            return Some(city.clone());
        }
    }

    // Try to get location (will be cached)
    match request_user_location().await {
        Ok(location) => location.city_code,
        Err(e) => {
            log!("Error getting user location:", e);
            None
        }
    }
}
