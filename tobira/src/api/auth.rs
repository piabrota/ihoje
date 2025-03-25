use wasm_bindgen::prelude::*;
use wasm_bindgen_futures::JsFuture;
use web_sys::{window, Storage};
use js_sys::{Promise, Object, Reflect, JSON, Function};
use serde::{Deserialize, Serialize};
use gloo_storage::{LocalStorage, Storage as GlooStorage};
use log;

use crate::models::{User, UserRole, AuthState};
use crate::utils::config::get_config;
use super::error::{ApiError, ApiResult};

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
        let document = window.document().ok_or_else(|| JsValue::from_str("Unable to get document"))?;
        
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
        let session_json = session_str.as_string()
            .ok_or_else(|| ApiError::AuthError("Failed to get session string".to_string()))?;
            
        // Parse the session into our format
        let session: SupabaseSession = serde_json::from_str(&session_json)
            .map_err(|e| ApiError::ParseError(format!("Failed to parse session: {}", e)))?;
            
        // Convert to our User type
        let user = self.supabase_user_to_user(session.user, Some(session.access_token), Some(session.refresh_token));
        
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
        let session_json = session_str.as_string()
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
        let user = self.supabase_user_to_user(session.user, Some(session.access_token), Some(session.refresh_token));
        
        // Save to local storage
        self.save_session(&user)?;
        
        Ok(Some(user))
    }
    
    /// Get a user's role
    pub async fn get_user_role(&self, user_id: &str) -> ApiResult<UserRole> {
        // In a real implementation, this would call a Supabase function or query
        // For now, we'll just check if the email is an admin email
        
        // Get the current user from session
        if let Some(user) = self.get_session_from_storage().ok() {
            if user.id == user_id && (
                user.email.ends_with("@ihoje.app") || 
                user.email == "test@example.com" || // Test email for admin access
                user.email == "admin@test.com"      // Alternative test email
            ) {
                log::info!("Admin access granted to: {}", user.email);
                return Ok(UserRole::Admin);
            }
        }
        
        // Default to regular user
        Ok(UserRole::User)
    }
    
    /// Save session to local storage
    fn save_session(&self, user: &User) -> ApiResult<()> {
        let json = serde_json::to_string(user)
            .map_err(|e| ApiError::ParseError(format!("Failed to serialize user: {}", e)))?;
            
        LocalStorage::set(AUTH_STORAGE_KEY, json)
            .map_err(|e| ApiError::StorageError(format!("Failed to save to local storage: {}", e)))?;
            
        Ok(())
    }
    
    /// Clear session from local storage
    fn clear_session(&self) -> ApiResult<()> {
        LocalStorage::delete(AUTH_STORAGE_KEY);
        Ok(())
    }
    
    /// Get session from local storage
    fn get_session_from_storage(&self) -> ApiResult<User> {
        let json: String = LocalStorage::get(AUTH_STORAGE_KEY)
            .map_err(|e| ApiError::StorageError(format!("Failed to get from local storage: {}", e)))?;
            
        let user: User = serde_json::from_str(&json)
            .map_err(|e| ApiError::ParseError(format!("Failed to parse user: {}", e)))?;
            
        Ok(user)
    }
    
    /// Convert Supabase user to our User type
    fn supabase_user_to_user(&self, supabase_user: SupabaseUser, access_token: Option<String>, refresh_token: Option<String>) -> User {
        // Determine role based on app_metadata or email domain
        let role = if supabase_user.app_metadata.role.to_lowercase() == "admin" {
            UserRole::Admin
        } else if supabase_user.email.ends_with("@ihoje.app") || 
                  supabase_user.email == "test@example.com" || 
                  supabase_user.email == "admin@test.com" {
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