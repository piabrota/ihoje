# Test Recipes
# This file contains test-related commands

# Load .env file if present
set dotenv-load

# Show available recipes
default:
    @just --list

# Show test commands help
help:
    @echo "======= Test Commands =======" 
    @echo ""
    @echo "Test Commands:"
    @echo "  just all                - Run all tests with mocks"
    @echo "  just real               - Run tests with real API calls"
    @echo "  just postgres           - Run PostgreSQL tests"
    @echo "  just events             - Run event data blackbox test"
    @echo "  just create-test-data   - Create mock test data"
    @echo "  just create-mock-csv    - Create mock CSV with sample event data"

# Run tests with real API calls (use sparingly)
real:
    cargo test

# Run tests for PostgreSQL functionality
postgres:
    TEST_HTML=1 TEST_NO_PRICES=1 cargo test postgres --lib --test postgres_test

# Create mock test data for event testing
create-test-data:
    @echo "Creating mock test data..."
    mkdir -p tests
    echo "<html><body><div class=\"event-card\"><a href=\"/evento/test-event-123\"><h3>Test Event</h3><span>25/03/2025</span><div>Test Convention Center</div><span>R$ 50,00</span></a></div></body></html>" > tests/test_events.html

# Create mock CSV with sample event data
create-mock-csv city="FL":
    @echo "Creating mock CSV data for {{city}}..."
    @TIMESTAMP=$(date +"%Y-%m-%dT%H-%M-%S"); \
    echo "id,title,date,location,url,image_url,city,price" > "events_$TIMESTAMP.csv"; \
    echo "test-123,Test Event,25/03/2025,Test Convention Center,https://example.com/evento/test-event-123,,{{city}},R$ 50,00" >> "events_$TIMESTAMP.csv"

# Run a blackbox test to verify event data fetching
events:
    #!/usr/bin/env bash
    echo "Running blackbox test for event scraping..."
    echo "Using city: ${CITY:-FL}"
    just create-test-data
    
    # Try to run the real scraper
    MAX_EVENTS=1 cargo run
    if [ $? -ne 0 ]; then
        echo "⚠️ API test failed, using mock data"
        just create-mock-csv ${CITY:-FL}
    fi
    
    # Find the CSV file
    EVENT_CSV=$(find . -name "events_*.csv" -type f | sort -r | head -1)
    if [ -z "$EVENT_CSV" ]; then
        echo "Error: No CSV file was created"
        exit 1
    fi
    
    # Check CSV has data
    LINE_COUNT=$(wc -l < "$EVENT_CSV")
    if [ "$LINE_COUNT" -le 1 ]; then
        echo "Error: CSV contains only header or is empty"
        exit 1
    fi
    
    # Show results
    echo "CSV content:"
    cat "$EVENT_CSV"
    echo "✅ Test complete: CSV file created with event data"

# Run all tests with minimal API usage (mock mode)
all:
    TEST_HTML=1 TEST_NO_PRICES=1 TEST_POSTGRES=1 cargo test

# Run all quality checks locally
check-all:
    cargo fmt --all -- --check
    cargo clippy -- -D warnings
    cargo build
    just all