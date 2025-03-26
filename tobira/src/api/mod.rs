mod auth;
mod client;
mod error;

pub use auth::SupabaseAuth;
pub use client::ApiClient;
pub use error::{ApiError, ApiResult};
