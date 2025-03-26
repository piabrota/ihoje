use chrono::NaiveDate;
use serde::{Deserialize, Serialize};

/// Date range for event filtering
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Default)]
pub struct DateRange {
    pub start_date: Option<NaiveDate>,
    pub end_date: Option<NaiveDate>,
}

/// Query parameters for event filtering
#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq)]
pub struct EventQuery {
    pub city: String,
    pub date_range: DateRange,
}

/// Sort options for event lists
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Default)]
pub enum SortOption {
    #[default]
    DateAsc,
    DateDesc,
    TitleAsc,
    TitleDesc,
    PriceAsc,
    PriceDesc,
}

/// Pagination parameters
#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq)]
pub struct PaginationParams {
    pub page: usize,
    pub per_page: usize,
}

impl PaginationParams {
    pub fn new(page: usize, per_page: usize) -> Self {
        Self { page, per_page }
    }

    pub fn offset(&self) -> usize {
        self.page * self.per_page
    }

    pub fn limit(&self) -> usize {
        self.per_page
    }
}
