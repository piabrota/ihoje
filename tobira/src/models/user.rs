use serde::{Deserialize, Serialize};

/// User role for authorization
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum UserRole {
    /// Regular user with limited permissions
    User,
    /// Admin user with full access to admin dashboard
    Admin,
}

impl Default for UserRole {
    fn default() -> Self {
        Self::User
    }
}

impl UserRole {
    /// Check if the role is admin
    pub fn is_admin(&self) -> bool {
        matches!(self, Self::Admin)
    }
    
    /// Convert from string representation
    pub fn from_str(s: &str) -> Self {
        match s.to_lowercase().as_str() {
            "admin" => Self::Admin,
            _ => Self::User,
        }
    }
    
    /// Get string representation
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Admin => "admin",
            Self::User => "user",
        }
    }
}

/// User model representing an authenticated user
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct User {
    /// Unique user ID (from Supabase)
    pub id: String,
    
    /// User's email address
    pub email: String,
    
    /// User's display name
    pub name: Option<String>,
    
    /// User's avatar URL
    pub avatar_url: Option<String>,
    
    /// User role for authorization
    pub role: UserRole,
    
    /// Authentication token
    #[serde(skip_serializing)]
    pub access_token: Option<String>,
    
    /// Refresh token
    #[serde(skip_serializing)]
    pub refresh_token: Option<String>,
}

impl User {
    /// Check if the user is authenticated
    pub fn is_authenticated(&self) -> bool {
        !self.id.is_empty() && self.access_token.is_some()
    }
    
    /// Check if the user is an admin
    pub fn is_admin(&self) -> bool {
        self.role.is_admin()
    }
    
    /// Get user's display name, falling back to email if not available
    pub fn display_name(&self) -> String {
        self.name.clone().unwrap_or_else(|| self.email.clone())
    }
}

/// Authentication state for the application
#[derive(Debug, Clone, Default)]
pub struct AuthState {
    /// Currently authenticated user, if any
    pub user: Option<User>,
    
    /// Whether authentication is still loading
    pub loading: bool,
    
    /// Authentication error, if any
    pub error: Option<String>,
}

impl AuthState {
    /// Create a new auth state
    pub fn new() -> Self {
        Self {
            user: None,
            loading: false,
            error: None,
        }
    }
    
    /// Create a loading auth state
    pub fn loading() -> Self {
        Self {
            user: None,
            loading: true,
            error: None,
        }
    }
    
    /// Create an authenticated auth state
    pub fn authenticated(user: User) -> Self {
        Self {
            user: Some(user),
            loading: false,
            error: None,
        }
    }
    
    /// Create an error auth state
    pub fn error(error: impl Into<String>) -> Self {
        Self {
            user: None,
            loading: false,
            error: Some(error.into()),
        }
    }
    
    /// Check if user is authenticated
    pub fn is_authenticated(&self) -> bool {
        self.user.as_ref().map_or(false, |u| u.is_authenticated())
    }
    
    /// Check if user is admin
    pub fn is_admin(&self) -> bool {
        self.user.as_ref().map_or(false, |u| u.is_admin())
    }
}