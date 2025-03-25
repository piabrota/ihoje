use std::fmt;

/// Error type for API requests
#[derive(Debug, Clone)]
pub enum ApiError {
    /// HTTP error with status code
    HttpError {
        message: String,
        status: u16,
    },
    
    /// Network error without status code
    NetworkError(String),
    
    /// JSON parsing error
    ParseError(String),
    
    /// Not found error
    NotFound(String),
    
    /// Client error (4xx)
    ClientError {
        message: String,
        status: u16,
    },
    
    /// Server error (5xx)
    ServerError {
        message: String,
        status: u16,
    },
    
    /// Authentication error
    AuthError(String),
    
    /// Authorization error (user doesn't have permission)
    AuthorizationError(String),
    
    /// Storage error for local storage operations
    StorageError(String),
}

impl ApiError {
    /// Returns true if the error is a not found error
    pub fn is_not_found(&self) -> bool {
        matches!(self, Self::NotFound(_)) || matches!(self, Self::HttpError { status, .. } if *status == 404)
    }
    
    /// Returns true if the error is a server error
    pub fn is_server_error(&self) -> bool {
        matches!(self, Self::ServerError { .. }) || 
        matches!(self, Self::HttpError { status, .. } if *status >= 500)
    }
    
    /// Returns true if the error is a client error
    pub fn is_client_error(&self) -> bool {
        matches!(self, Self::ClientError { .. }) || 
        matches!(self, Self::HttpError { status, .. } if *status >= 400 && *status < 500)
    }
    
    /// Returns the error message
    pub fn message(&self) -> &str {
        match self {
            Self::HttpError { message, .. } => message,
            Self::NetworkError(message) => message,
            Self::ParseError(message) => message,
            Self::NotFound(message) => message,
            Self::ClientError { message, .. } => message,
            Self::ServerError { message, .. } => message,
            Self::AuthError(message) => message,
            Self::AuthorizationError(message) => message,
            Self::StorageError(message) => message,
        }
    }
    
    /// Creates an error from a reqwasm error
    pub fn from_reqwasm_error(error: reqwasm::Error) -> Self {
        match error {
            reqwasm::Error::JsError(e) => Self::NetworkError(format!("JavaScript error: {}", e)),
            reqwasm::Error::SerdeError(e) => Self::ParseError(format!("Serde error: {}", e)),
            reqwasm::Error::FetchError => Self::NetworkError("Failed to fetch data".to_string()),
        }
    }
    
    /// Creates an error from a status code and message
    pub fn from_status(status: u16, message: impl Into<String>) -> Self {
        let message = message.into();
        
        match status {
            404 => Self::NotFound(message),
            400..=499 => Self::ClientError { 
                message, 
                status, 
            },
            500..=599 => Self::ServerError { 
                message, 
                status, 
            },
            _ => Self::HttpError { 
                message, 
                status, 
            },
        }
    }
}

impl fmt::Display for ApiError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::HttpError { message, status } => 
                write!(f, "HTTP Error ({}): {}", status, message),
            Self::NetworkError(message) => 
                write!(f, "Network Error: {}", message),
            Self::ParseError(message) => 
                write!(f, "Parse Error: {}", message),
            Self::NotFound(message) => 
                write!(f, "Not Found: {}", message),
            Self::ClientError { message, status } => 
                write!(f, "Client Error ({}): {}", status, message),
            Self::ServerError { message, status } => 
                write!(f, "Server Error ({}): {}", status, message),
            Self::AuthError(message) => 
                write!(f, "Authentication Error: {}", message),
            Self::AuthorizationError(message) => 
                write!(f, "Authorization Error: {}", message),
            Self::StorageError(message) => 
                write!(f, "Storage Error: {}", message),
        }
    }
}

/// Result type for API requests
pub type ApiResult<T> = Result<T, ApiError>;