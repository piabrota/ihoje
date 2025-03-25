mod client;
mod error;
mod auth;

pub use client::ApiClient;
pub use error::{ApiError, ApiResult};
pub use auth::SupabaseAuth;