# Testing Guidelines for iHoje Rust Scraper

This document outlines the best practices for testing the iHoje Rust Scraper application to ensure test reliability while minimizing API usage.

## Test Environment Variables

The following environment variables can be used to control test behavior:

| Variable | Description |
|----------|-------------|
| `TEST_HTML` | If set, uses test HTML files instead of making API calls for scraping events |
| `TEST_NO_PRICES` | If set, uses mock prices instead of fetching real prices via API |
| `MAX_EVENTS` | Sets the maximum number of events to process (defaults to 1 for tests) |

## Auto-Detection of Test Mode

The application automatically detects when it's running in test mode by checking the `CARGO_TARGET_TMPDIR` environment variable, which is set by `cargo test`. In test mode:

1. Rate limits are increased to 60 requests per minute (vs. 3 in production)
2. `MAX_EVENTS` is set to 1 unless explicitly overridden
3. Test HTML is used instead of making API calls
4. Mock prices are generated instead of fetching real prices

## Mock Data

### Test HTML
The test uses the following sources for HTML data (in order of preference):
1. `tests/test_events.html` if it exists
2. A minimal generated HTML file with a test event if no file exists

### Mock Prices
Mock prices are generated with the following rules:
- Events with "test" in the ID get a price of "R$ 50,00 (TEST)"
- Other events get a price based on their ID length: `R$ {id_length*10.0},00 (TEST)`
- Every 5th event (by ID length) simulates a failure to test error handling

## Running Tests

To run all tests without making any API calls:
```bash
cargo test
```

To run tests with real API calls but mock prices:
```bash
TEST_HTML= cargo test
```

To run tests with both real API calls and real prices (use sparingly):
```bash
TEST_HTML= TEST_NO_PRICES= cargo test
```

## Adding New Tests

When adding new tests:
1. Use mock data whenever possible
2. Never make real API calls in CI/CD pipelines
3. Add new test HTML files to the `tests/` directory for specialized tests
4. Set `MAX_EVENTS=1` when testing to limit API usage

## PostgreSQL Testing

When testing PostgreSQL functionality:
1. Use the `--export postgres` or `--export both` flag to test database functionality
2. Before running tests with PostgreSQL, ensure the database is configured:
   ```bash
   # Set up test database
   PG_DATABASE=test_events cargo test
   ```

## Pre-commit Hooks

The project includes pre-commit hooks to ensure tests don't make unnecessary API calls:
1. Tests are automatically run with `TEST_HTML` and `TEST_NO_PRICES` set
2. A warning is shown if tests attempt to make real API calls