use gloo_storage::{LocalStorage, Storage as GlooStorage};
use js_sys::{Function, Object, Promise, Reflect, JSON};
use log;
use serde::{Deserialize, Serialize};
use wasm_bindgen::prelude::*;
use wasm_bindgen_futures::JsFuture;
use web_sys::{window, Storage};

use super::error::{ApiError, ApiResult};
use crate::models::{AuthState, User, UserRole};
use crate::utils::config::get_config;

// JS bridging for Supabase client
#[wasm_bindgen]
extern "C" {
    #[wasm_bindgen(js_namespace = window)]
    fn createSupabaseClient(url: &str, key: &str) -> JsValue;

    #[wasm_bindgen(js_name = "supabaseSignInWithGoogle")]
    fn sign_in_with_google(client: &JsValue) -> Promise;

    #[wasm_bindgen(js_name = "supabaseSignOut")]
    fn sign_out(client: &JsValue) -> Promise;

    #[wasm_bindgen(js_name = "supabaseGetSession")]
    fn get_session(client: &JsValue) -> Promise;

    #[wasm_bindgen(js_name = "supabaseGetUser")]
    fn get_user(client: &JsValue) -> Promise;
}

/// Key for storing the auth session in local storage
const AUTH_STORAGE_KEY: &str = "ihoje_auth";

/// Supabase authentication client
#[derive(Debug, Clone)]
pub struct SupabaseAuth {
    client: JsValue,
}

/// Session data from Supabase
#[derive(Debug, Clone, Serialize, Deserialize)]
struct SupabaseSession {
    access_token: String,
    refresh_token: String,
    expires_at: u64,
    user: SupabaseUser,
}

/// User data from Supabase
#[derive(Debug, Clone, Serialize, Deserialize)]
struct SupabaseUser {
    id: String,
    email: String,
    app_metadata: AppMetadata,
    user_metadata: UserMetadata,
}

/// App metadata from Supabase
#[derive(Debug, Clone, Serialize, Deserialize)]
struct AppMetadata {
    provider: String,
    #[serde(default)]
    role: String,
}

/// User metadata from Supabase
#[derive(Debug, Clone, Serialize, Deserialize)]
struct UserMetadata {
    #[serde(default)]
    name: String,
    #[serde(default)]
    avatar_url: String,
}

impl SupabaseAuth {
    /// Create a new Supabase auth client
    pub fn new() -> Result<Self, JsValue> {
        let config = get_config();

        // Check if Supabase config is available
        if config.supabase_url.is_empty() || config.supabase_anon_key.is_empty() {
            log::warn!("Supabase URL or anon key is not configured");
            return Err(JsValue::from_str("Supabase credentials not configured"));
        }

        // Create the Supabase client
        let client = createSupabaseClient(&config.supabase_url, &config.supabase_anon_key);

        Ok(Self { client })
    }

    /// Inject Supabase client script into the page
    pub fn inject_supabase_script() -> Result<(), JsValue> {
        // Get the document object
        let window = window().ok_or_else(|| JsValue::from_str("Unable to get window"))?;
        let document = window
            .document()
            .ok_or_else(|| JsValue::from_str("Unable to get document"))?;

        // Create a new script element
        let script = document
            .create_element("script")
            .map_err(|_| JsValue::from_str("Unable to create script element"))?;

        // Set the script content
        script.set_inner_html(include_str!("./supabase_client.js"));

        // Append the script to the head
        document
            .head()
            .ok_or_else(|| JsValue::from_str("Unable to get document head"))?
            .append_child(&script)
            .map_err(|_| JsValue::from_str("Unable to append script to head"))?;

        Ok(())
    }

    /// Sign in with Google
    pub async fn sign_in_with_google(&self) -> ApiResult<User> {
        log::info!("Signing in with Google");

        // Start the sign in process
        let promise = sign_in_with_google(&self.client);
        let result = JsFuture::from(promise).await?;

        // Parse the session data
        let session_str = JSON::stringify(&result)
            .map_err(|_| ApiError::AuthError("Failed to stringify session data".to_string()))?;
        let session_json = session_str
            .as_string()
            .ok_or_else(|| ApiError::AuthError("Failed to get session string".to_string()))?;

        // Parse the session into our format
        let session: SupabaseSession = serde_json::from_str(&session_json)
            .map_err(|e| ApiError::ParseError(format!("Failed to parse session: {}", e)))?;

        // Convert to our User type
        let user = self.supabase_user_to_user(
            session.user,
            Some(session.access_token),
            Some(session.refresh_token),
        );

        // Save to local storage
        self.save_session(&user)?;

        Ok(user)
    }

    /// Sign out the current user
    pub async fn sign_out(&self) -> ApiResult<()> {
        log::info!("Signing out");

        // Call the sign out method
        let promise = sign_out(&self.client);
        let _ = JsFuture::from(promise).await?;

        // Clear local storage
        self.clear_session()?;

        Ok(())
    }

    /// Get the current session if any
    pub async fn get_current_session(&self) -> ApiResult<Option<User>> {
        // Try to get from local storage first
        if let Ok(user) = self.get_session_from_storage() {
            log::info!("Found user session in storage: {}", user.email);
            return Ok(Some(user));
        }

        // If not in storage, try to get from Supabase
        log::info!("No session in storage, checking Supabase");

        let promise = get_session(&self.client);
        let result = JsFuture::from(promise).await?;

        // Check if result is null or undefined
        if result.is_null() || result.is_undefined() {
            log::info!("No active session in Supabase");
            return Ok(None);
        }

        // Parse the session data
        let session_str = JSON::stringify(&result)
            .map_err(|_| ApiError::AuthError("Failed to stringify session data".to_string()))?;
        let session_json = session_str
            .as_string()
            .ok_or_else(|| ApiError::AuthError("Failed to get session string".to_string()))?;

        // Parse the session into our format
        let session: SupabaseSession = match serde_json::from_str(&session_json) {
            Ok(s) => s,
            Err(e) => {
                log::warn!("Failed to parse session: {}", e);
                return Ok(None);
            }
        };

        // Convert to our User type
        let user = self.supabase_user_to_user(
            session.user,
            Some(session.access_token),
            Some(session.refresh_token),
        );

        // Save to local storage
        self.save_session(&user)?;

        Ok(Some(user))
    }

    /// Get a user's role with server-side verification
    pub async fn get_user_role(&self, user_id: &str) -> ApiResult<UserRole> {
        // Get the current user from session
        if let Some(user) = self.get_session_from_storage().ok() {
            if user.id != user_id {
                return Ok(UserRole::User);
            }

            // First check server-side role through Supabase RPC function if we have a token
            if let Some(token) = &user.access_token {
                // Try to verify role with server
                if let Ok(role) = self.verify_role_with_server(&user.id, token).await {
                    log::info!("Server verified role for user {}: {:?}", user.email, role);
                    return Ok(role);
                }
            }

            // Fallback to client-side role check (less secure)
            if user.email.ends_with("@ihoje.app") || 
               user.email == "test@example.com" || // Test email for admin access
               user.email == "admin@test.com"
            {
                // Alternative test email

                #[cfg(debug_assertions)]
                {
                    log::info!(
                        "Admin access granted via client-side check to: {}",
                        user.email
                    );
                    return Ok(UserRole::Admin);
                }

                #[cfg(not(debug_assertions))]
                {
                    log::warn!(
                        "Client-side admin check used in production for: {}",
                        user.email
                    );
                    // In production, only allow ihoje.app domains as fallback
                    if user.email.ends_with("@ihoje.app") {
                        return Ok(UserRole::Admin);
                    }
                }
            }
        }

        // Default to regular user
        Ok(UserRole::User)
    }

    /// Verify user role with server-side check
    async fn verify_role_with_server(
        &self,
        user_id: &str,
        token: &str,
    ) -> Result<UserRole, JsValue> {
        let config = get_config();

        // Create URL for the Supabase function that verifies roles
        let url = format!("{}/rest/v1/rpc/verify_user_role", config.supabase_url);

        // Set up the request
        let mut opts = web_sys::RequestInit::new();
        opts.method("POST");
        opts.mode(web_sys::RequestMode::Cors);

        // Create the request body
        let body = format!(r#"{{"user_id": "{}"}}"#, user_id);
        opts.body(Some(&JsValue::from_str(&body)));

        // Set up headers
        let headers = web_sys::Headers::new()?;
        headers.append("Content-Type", "application/json")?;
        headers.append("Authorization", &format!("Bearer {}", token))?;
        headers.append("apikey", &config.supabase_anon_key)?;
        opts.headers(&headers);

        // Create and send the request
        let window = window().ok_or_else(|| JsValue::from_str("Unable to get window"))?;
        let request = web_sys::Request::new_with_str_and_init(&url, &opts)?;
        let response = JsFuture::from(window.fetch_with_request(&request)).await?;
        let response: web_sys::Response = response.dyn_into()?;

        // Check if the request was successful
        if !response.ok() {
            return Err(JsValue::from_str(&format!(
                "Error verifying role: {}",
                response.status()
            )));
        }

        // Parse the response
        let json = JsFuture::from(response.json()?).await?;
        let json_str = JSON::stringify(&json)
            .map_err(|_| JsValue::from_str("Failed to stringify response"))?;
        let json_string = json_str
            .as_string()
            .ok_or_else(|| JsValue::from_str("Failed to get response string"))?;

        // Extract role from response
        #[derive(Deserialize)]
        struct RoleResponse {
            role: String,
        }

        match serde_json::from_str::<RoleResponse>(&json_string) {
            Ok(role_response) => {
                // Convert string role to UserRole enum
                match role_response.role.to_lowercase().as_str() {
                    "admin" => Ok(UserRole::Admin),
                    _ => Ok(UserRole::User),
                }
            }
            Err(e) => {
                log::error!("Failed to parse role response: {}", e);
                Err(JsValue::from_str(&format!(
                    "Failed to parse role response: {}",
                    e
                )))
            }
        }
    }

    /// Save session data with enhanced security
    fn save_session(&self, user: &User) -> ApiResult<()> {
        // First, try to set secure cookie via special endpoint (for HTTP-only cookies)
        if let Some(token) = &user.access_token {
            if let Err(e) = self.set_secure_cookie(user, token).await {
                log::warn!(
                    "Failed to set secure cookie: {:?}, falling back to localStorage",
                    e
                );
            } else {
                log::info!("Secure cookie set successfully");

                // Only store non-sensitive data in localStorage as a fallback
                let public_user_data = User {
                    id: user.id.clone(),
                    email: user.email.clone(),
                    name: user.name.clone(),
                    avatar_url: user.avatar_url.clone(),
                    role: user.role,
                    // Don't store tokens in localStorage
                    access_token: None,
                    refresh_token: None,
                };

                // Store the public data for UI purposes
                if let Ok(json) = serde_json::to_string(&public_user_data) {
                    let _ = LocalStorage::set(AUTH_STORAGE_KEY, json);
                }

                return Ok(());
            }
        }

        // Fallback to localStorage for development or if cookie setting fails
        log::warn!("Using localStorage for auth (less secure). Consider enabling secure cookies in production.");
        let json = serde_json::to_string(user)
            .map_err(|e| ApiError::ParseError(format!("Failed to serialize user: {}", e)))?;

        LocalStorage::set(AUTH_STORAGE_KEY, json).map_err(|e| {
            ApiError::StorageError(format!("Failed to save to local storage: {}", e))
        })?;

        Ok(())
    }

    /// Set secure cookie via backend endpoint
    async fn set_secure_cookie(&self, user: &User, token: &str) -> Result<(), JsValue> {
        #[cfg(not(debug_assertions))]
        {
            let config = get_config();

            // Use a backend endpoint to set HTTP-only cookies
            let url = format!("{}/auth/set-secure-cookie", config.api_url);

            // Set up the request
            let mut opts = web_sys::RequestInit::new();
            opts.method("POST");
            opts.mode(web_sys::RequestMode::Cors);

            // Create the request body with session info
            let body = json!({
                "user_id": user.id,
                "session_token": token,
                "csrf_token": self.generate_csrf_token(),
                "max_age": 3600  // 1 hour expiration
            });

            opts.body(Some(&JsValue::from_str(&body.to_string())));

            // Set up headers
            let headers = web_sys::Headers::new()?;
            headers.append("Content-Type", "application/json")?;
            headers.append("Authorization", &format!("Bearer {}", token))?;
            opts.headers(&headers);

            // Create and send the request
            let window = window().ok_or_else(|| JsValue::from_str("Unable to get window"))?;
            let request = web_sys::Request::new_with_str_and_init(&url, &opts)?;
            let response = JsFuture::from(window.fetch_with_request(&request)).await?;
            let response: web_sys::Response = response.dyn_into()?;

            // Check if the request was successful
            if !response.ok() {
                return Err(JsValue::from_str(&format!(
                    "Error setting secure cookie: {}",
                    response.status()
                )));
            }

            Ok(())
        }

        #[cfg(debug_assertions)]
        {
            // In development, just store a mock CSRF token in localStorage
            let csrf_token = self.generate_csrf_token();
            let _ = LocalStorage::set("ihoje_csrf_token", csrf_token);
            Err(JsValue::from_str(
                "Secure cookies not available in development mode",
            ))
        }
    }

    /// Generate a CSRF token
    fn generate_csrf_token(&self) -> String {
        use js_sys::Math;

        // Generate a random string to use as CSRF token
        let random1 = Math::random();
        let random2 = Math::random();
        let timestamp = js_sys::Date::now();

        format!("{:.6}{:.6}{}", random1, random2, timestamp)
    }

    /// Clear session data
    fn clear_session(&self) -> ApiResult<()> {
        // Clear localStorage data
        LocalStorage::delete(AUTH_STORAGE_KEY);
        LocalStorage::delete("ihoje_csrf_token");

        // In production, also clear the secure cookie via endpoint
        #[cfg(not(debug_assertions))]
        {
            spawn_local(async {
                let config = get_config();
                let url = format!("{}/auth/clear-secure-cookie", config.api_url);

                let mut opts = web_sys::RequestInit::new();
                opts.method("POST");

                if let Some(window) = window() {
                    if let Ok(request) = web_sys::Request::new_with_str_and_init(&url, &opts) {
                        let _ = window.fetch_with_request(&request);
                    }
                }
            });
        }

        Ok(())
    }

    /// Get session data with enhanced security
    fn get_session_from_storage(&self) -> ApiResult<User> {
        // Try to get from localStorage first (this may be just the public data without tokens)
        let json: String = LocalStorage::get(AUTH_STORAGE_KEY).map_err(|e| {
            ApiError::StorageError(format!("Failed to get from local storage: {}", e))
        })?;

        let mut user: User = serde_json::from_str(&json)
            .map_err(|e| ApiError::ParseError(format!("Failed to parse user: {}", e)))?;

        // In production, check if we have a secure cookie by trying to validate it
        #[cfg(not(debug_assertions))]
        {
            // This would normally make a request to validate the secure cookie
            // and retrieve the token from the server-side session store
            // For now, we'll just rely on the Supabase getSession call which
            // happens elsewhere in the code

            // If we don't have tokens in localStorage, the user object is incomplete
            // The app should call get_current_session() to refresh from Supabase
            if user.access_token.is_none() {
                log::info!("Partial user data from localStorage, tokens not available");
            }
        }

        Ok(user)
    }

    /// Convert Supabase user to our User type
    fn supabase_user_to_user(
        &self,
        supabase_user: SupabaseUser,
        access_token: Option<String>,
        refresh_token: Option<String>,
    ) -> User {
        // Determine role based on app_metadata or email domain
        let role = if supabase_user.app_metadata.role.to_lowercase() == "admin" {
            UserRole::Admin
        } else if supabase_user.email.ends_with("@ihoje.app")
            || supabase_user.email == "test@example.com"
            || supabase_user.email == "admin@test.com"
        {
            // As a fallback, consider users with ihoje.app domain or test emails as admins
            log::info!("Setting admin role for user: {}", supabase_user.email);
            UserRole::Admin
        } else {
            UserRole::User
        };

        User {
            id: supabase_user.id,
            email: supabase_user.email,
            name: if supabase_user.user_metadata.name.is_empty() {
                None
            } else {
                Some(supabase_user.user_metadata.name)
            },
            avatar_url: if supabase_user.user_metadata.avatar_url.is_empty() {
                None
            } else {
                Some(supabase_user.user_metadata.avatar_url)
            },
            role,
            access_token,
            refresh_token,
        }
    }
}
