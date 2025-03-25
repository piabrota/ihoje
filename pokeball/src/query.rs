use serde::{Deserialize, Serialize};

/// Query parameters for event filtering
#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq)]
pub struct EventQuery {
    pub city: Option<String>,
    pub date_from: Option<String>,
    pub date_to: Option<String>, 
    pub search: Option<String>,
    pub free_only: Option<bool>,
}

/// Sort options for event lists
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum SortOption {
    DateAsc,
    DateDesc,
    TitleAsc,
    TitleDesc,
    PriceAsc,
    PriceDesc,
}

impl Default for SortOption {
    fn default() -> Self {
        SortOption::DateAsc
    }
}