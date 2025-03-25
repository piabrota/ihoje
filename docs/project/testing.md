# Testing Guide

## Overview

This document provides information about the testing approach for the iHoje application, including test organization, running tests, and best practices.

## Test Organization

### Unit Tests

Unit tests are co-located with the code they test, typically in a `tests` module within the same file:

```rust
#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_parse_event() {
        // Test implementation
    }
}
```

### Integration Tests

Integration tests are in the `/tests` directory and test larger components or workflows:

- `integration_test.rs`: Basic integration tests
- `provider_test.rs`: Tests for provider implementations
- `postgres_test.rs`: Database integration tests
- `workflow_test.rs`: End-to-end workflow tests

## Running Tests

### All Tests

```bash
just test
```

This runs all tests including unit and integration tests.

### Specific Tests

```bash
# Run a specific test or test module
just test-specific "test_name"

# Run tests for a specific provider
just test-provider "provider_name"

# Run database tests
just test-db
```

### Frontend Tests

```bash
just test-frontend
```

This runs tests for the Tobira frontend components.

## Test Database

Database tests use a test-specific database to avoid affecting development data.

```bash
# Initialize test database
just init-test-db

# Reset test database
just reset-test-db
```

## Mocking

The application uses several approaches for mocking:

### Mock HTTP Responses

For testing providers without making real HTTP requests:

```rust
let mock_response = MockResponse::new()
    .with_status(200)
    .with_body(include_str!("../tests/test_events.html"));
    
let mock_client = MockClient::new()
    .with_response("https://example.com/events", mock_response);
```

### Mock Database

For testing database operations without a real database:

```rust
let mock_db = MockDb::new()
    .with_query_result("SELECT * FROM events", mock_events);
```

## Test Data

The repository includes test data files:

- `tests/test_events.html`: Sample event HTML for testing scrapers
- `tests/events-*.html`: Provider-specific test data

## Continuous Integration

The CI pipeline runs tests on each pull request:

1. Unit tests
2. Integration tests
3. Database tests with a temporary database
4. Frontend tests

## Best Practices

1. **Write Tests First**: Follow a test-driven development approach
2. **Test Edge Cases**: Include tests for error conditions and edge cases
3. **Use Descriptive Names**: Name tests clearly, describing what they verify
4. **Isolate Tests**: Each test should be independent of others
5. **Keep Tests Fast**: Optimize tests to run quickly

## Troubleshooting

### Common Issues

- **Database Connection Failures**: Check that the test database is running
- **Missing Test Data**: Verify that test files are included in the repository
- **Flaky Tests**: Look for timing issues or external dependencies

### Debugging Tests

```bash
# Run tests with more verbose output
just test-debug "test_name"

# Print debug information during tests
CARGO_LOG=debug just test
```