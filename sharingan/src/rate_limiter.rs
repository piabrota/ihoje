use std::time::{Duration, Instant};
use tokio::sync::Mutex;
use tokio::time::sleep;

/// Rate limiter to respect the Firecrawl API limits
/// Free tier: 3 requests per minute
pub struct RateLimiter {
    last_request: Mutex<Instant>,
    interval: Duration,
}

impl RateLimiter {
    pub fn new(requests_per_minute: u32) -> Self {
        Self {
            last_request: Mutex::new(Instant::now() - Duration::from_secs(60)), // Allow immediate first request
            interval: Duration::from_secs(60) / requests_per_minute, // Calculate interval between requests
        }
    }

    pub async fn wait(&self) {
        let mut last_request = self.last_request.lock().await;
        let now = Instant::now();
        let elapsed = now.duration_since(*last_request);

        if elapsed < self.interval {
            // Need to wait before sending next request
            let wait_time = self.interval.saturating_sub(elapsed);
            drop(last_request); // Release lock before sleeping
            sleep(wait_time).await;
            *self.last_request.lock().await = Instant::now();
        } else {
            // No need to wait
            *last_request = now;
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::time::Instant;

    #[tokio::test]
    async fn test_rate_limiter_initialization() {
        let rate_limiter = RateLimiter::new(3);

        assert_eq!(rate_limiter.interval, Duration::from_secs(20)); // 60/3 = 20
    }

    #[tokio::test]
    async fn test_rate_limiter_first_request() {
        let rate_limiter = RateLimiter::new(3);

        // First request should not wait
        let start = Instant::now();
        rate_limiter.wait().await;
        let elapsed = start.elapsed();

        // Should be almost immediate (less than 10ms)
        assert!(elapsed < Duration::from_millis(10));
    }

    #[tokio::test]
    async fn test_rate_limiter_second_request() {
        let rate_limiter = RateLimiter::new(60); // 1 request per second

        // First request
        rate_limiter.wait().await;

        // Second request immediately after (should wait ~1 second)
        let start = Instant::now();
        rate_limiter.wait().await;
        let elapsed = start.elapsed();

        // Should wait close to 1 second (allow some margin for test execution time)
        assert!(elapsed >= Duration::from_millis(990));
    }
}
