use std::sync::OnceLock;
use wasm_bindgen::prelude::*;

// JS bridging to get environment variables at runtime
#[wasm_bindgen]
extern "C" {
    #[wasm_bindgen(js_namespace = window)]
    fn get_env_var(name: &str) -> String;
}

/// Configuration values for the application
pub struct Config {
    /// Base URL for API requests
    pub api_base_url: String,
    
    /// Whether to enable CORS for API requests
    pub enable_cors: bool,
    
    /// Whether to use mock data instead of real API
    pub use_mock_data: bool,
    
    /// Environment name
    pub environment: Environment,
    
    /// API request timeout in seconds
    pub api_timeout_seconds: u32,
    
    /// Whether to enable debug logging
    pub enable_debug_logging: bool,
    
    /// Supabase URL
    pub supabase_url: String,
    
    /// Supabase anon key
    pub supabase_anon_key: String,
}

/// Environment types
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Environment {
    Development,
    Staging,
    Production,
}

impl Environment {
    /// Get environment from string
    pub fn from_string(s: &str) -> Self {
        match s.to_lowercase().as_str() {
            "production" => Self::Production,
            "staging" => Self::Staging,
            _ => Self::Development,
        }
    }
    
    /// Get environment name
    pub fn name(&self) -> &'static str {
        match self {
            Self::Development => "development",
            Self::Staging => "staging",
            Self::Production => "production",
        }
    }
    
    /// Check if this is production
    pub fn is_production(&self) -> bool {
        matches!(self, Self::Production)
    }
}

// Global config singleton
static CONFIG: OnceLock<Config> = OnceLock::new();

/// Get the application configuration
pub fn get_config() -> &'static Config {
    CONFIG.get_or_init(|| {
        // Try to get environment variables from window object
        let env = get_env_var_or_default("IHOJE_ENVIRONMENT", "development");
        let environment = Environment::from_string(&env);
        
        // Determine API URL based on environment
        let api_base_url = match environment {
            Environment::Production => {
                get_env_var_or_default("IHOJE_API_URL", "https://api.ihoje.app/api")
            },
            Environment::Staging => {
                get_env_var_or_default("IHOJE_API_URL", "https://staging-api.ihoje.app/api")
            },
            Environment::Development => {
                get_env_var_or_default("IHOJE_API_URL", "http://localhost:8080/api")
            }
        };
        
        // Configure other settings based on environment
        let use_mock_data = match environment {
            Environment::Development => get_env_var_or_default("IHOJE_USE_MOCK_DATA", "true") == "true",
            _ => false,
        };
        
        let enable_debug_logging = match environment {
            Environment::Production => false,
            _ => true,
        };
        
        let api_timeout_seconds = get_env_var_or_default("IHOJE_API_TIMEOUT", "30")
            .parse::<u32>()
            .unwrap_or(30);
        
        // Get Supabase configuration
        let supabase_url = get_env_var_or_default("IHOJE_SUPABASE_URL", "");
        let supabase_anon_key = get_env_var_or_default("IHOJE_SUPABASE_ANON_KEY", "");
            
        // Create config
        Config {
            api_base_url,
            enable_cors: !environment.is_production(),
            use_mock_data,
            environment,
            api_timeout_seconds,
            enable_debug_logging,
            supabase_url,
            supabase_anon_key,
        }
    })
}

/// Try to get environment variable or return default
fn get_env_var_or_default(name: &str, default: &str) -> String {
    let var = get_env_var(name);
    if var.is_empty() {
        default.to_string()
    } else {
        var
    }
}

/// Create a JS snippet to inject environment variables
pub fn generate_environment_js(
    environment: &str, 
    api_url: &str, 
    use_mock_data: bool,
    supabase_url: &str,
    supabase_anon_key: &str
) -> String {
    format!(
        r#"window.ihoje_env = {{
  IHOJE_ENVIRONMENT: "{}",
  IHOJE_API_URL: "{}",
  IHOJE_USE_MOCK_DATA: "{}",
  IHOJE_SUPABASE_URL: "{}",
  IHOJE_SUPABASE_ANON_KEY: "{}"
}};

window.get_env_var = function(name) {{
  return (window.ihoje_env && window.ihoje_env[name]) || "";
}};"#,
        environment,
        api_url,
        if use_mock_data { "true" } else { "false" },
        supabase_url,
        supabase_anon_key
    )
}