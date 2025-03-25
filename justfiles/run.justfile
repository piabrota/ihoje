# Run Commands
# Optimized for token usage

# Load .env file
set dotenv-load

# Default city
default_city := "FL"

# Show available recipes
default:
    @just --list

# Show help
help:
    @echo "=== Run Commands ==="
    @echo "Basic:"
    @echo "  app [ARGS]           - Run with args"
    @echo "  city CITY            - Run with city"
    @echo "  city-args CITY ARGS  - Run with city and args"
    @echo "Date:"
    @echo "  date [ARGS]          - Run with date range"
    @echo "  date-city CITY       - Run with date and city"
    @echo "  custom-date N M      - Run with days ahead N-M"
    @echo "Export:"
    @echo "  postgres [ARGS]      - Run with PostgreSQL"
    @echo "  both [ARGS]          - Run with CSV and PostgreSQL"
    @echo "Provider:"
    @echo "  provider NAME        - Run with specific provider"
    @echo "Static Mode:"
    @echo "  download-site URL FOLDER [PROVIDER] - Download site with httrack"
    @echo "  run-static FOLDER [PROVIDER] [CITY] - Run with static HTML files"
    @echo "  e2e-static-test [PROVIDER] [CITY]   - Run complete end-to-end test"

# Run app with args
app +ARGS="":
    cargo run -p sharingan {{ARGS}}

# Run with city
city city=default_city:
    CITY={{city}} cargo run -p sharingan

# Run with city and args
city-args city *ARGS:
    CITY={{city}} cargo run -p sharingan -- {{ARGS}}

# Run with date range (7-14 days)
date +ARGS="":
    #!/usr/bin/env bash
    START=$(date -d "+7 days" +"%Y-%m-%d")
    END=$(date -d "+14 days" +"%Y-%m-%d")
    echo "Using dates: ${START} to ${END}"
    START_DATE=${START} END_DATE=${END} cargo run -p sharingan {{ARGS}}

# Run with date and city
date-city city:
    #!/usr/bin/env bash
    START=$(date -d "+7 days" +"%Y-%m-%d")
    END=$(date -d "+14 days" +"%Y-%m-%d")
    CITY={{city}} START_DATE=${START} END_DATE=${END} cargo run -p sharingan

# Run with custom date range
custom-date start="7" end="14" +ARGS="":
    #!/usr/bin/env bash
    [[ ! "{{start}}" =~ ^[0-9]+$ ]] && echo "Error: start must be number" && exit 1
    [[ ! "{{end}}" =~ ^[0-9]+$ ]] && echo "Error: end must be number" && exit 1
    
    START=$(date -d "+{{start}} days" +"%Y-%m-%d")
    END=$(date -d "+{{end}} days" +"%Y-%m-%d")
    START_DATE=${START} END_DATE=${END} cargo run -p sharingan {{ARGS}}

# Run with PostgreSQL export
postgres +ARGS="":
    EXPORT_FORMAT=postgres cargo run -p sharingan {{ARGS}}

# Run with both exports
both +ARGS="":
    EXPORT_FORMAT=both cargo run -p sharingan {{ARGS}}

# Run with provider
provider provider="pikachu":
    #!/usr/bin/env bash
    [[ "{{provider}}" != "pikachu" && "{{provider}}" != "charmander" ]] && \
      echo "Error: provider must be pikachu or charmander" && exit 1
    PROVIDER={{provider}} cargo run -p sharingan
    
# Run with static extraction mode (using local HTML files)
run-static folder provider="pikachu" city="FL":
    #!/usr/bin/env bash
    if [ ! -d "{{folder}}" ]; then
        echo "Error: Extraction folder '{{folder}}' does not exist"
        exit 1
    fi
    
    [[ "{{provider}}" != "pikachu" && "{{provider}}" != "charmander" ]] && \
      echo "Error: provider must be pikachu or charmander" && exit 1
      
    # Set up required environment variables for static mode
    export EXTRACTION_MODE=static
    export EXTRACTION_FOLDER="{{folder}}"
    export PROVIDER={{provider}}
    export CITY={{city}}
    
    # Set a dummy API URL since we won't be using FireCrawler
    if [ "{{provider}}" = "pikachu" ]; then
        export PIKACHU_API_URL="https://example.com"
    elif [ "{{provider}}" = "charmander" ]; then
        export CHARMANDER_API_URL="https://example.com"
    fi
    
    echo "Running in static extraction mode with folder: {{folder}}"
    echo "Provider: {{provider}} | City: {{city}}"
    cargo run -p sharingan -- --skip-db-test --export gcp
    
# Run httrack to extract website for static mode
download-site url folder provider="pikachu":
    #!/usr/bin/env bash
    if [ -z "$(which httrack)" ]; then
        echo "Error: httrack is not installed. Please install it with:"
        echo "  sudo apt-get install httrack    # Debian/Ubuntu"
        echo "  sudo dnf install httrack        # Fedora"
        echo "  brew install httrack            # macOS with Homebrew"
        exit 1
    fi
    
    # Create extraction folder if it doesn't exist
    mkdir -p "{{folder}}"
    
    echo "Downloading website: {{url}} to folder: {{folder}}"
    httrack "{{url}}" -O "{{folder}}" --disable-security-limits -v
    
    echo "Download complete. To use this data, run:"
    echo "just run-static {{folder}} {{provider}}"

# Create an end-to-end test for static extraction mode
e2e-static-test provider="pikachu" city="FL":
    #!/usr/bin/env bash
    set -e  # Exit on any error
    
    # Set test folder
    TEST_FOLDER="./static_extraction_test"
    
    # Set target URL based on provider
    if [ "{{provider}}" = "pikachu" ]; then
        TARGET_URL="https://www.sympla.com.br/eventos/florianopolis-sc"
    elif [ "{{provider}}" = "charmander" ]; then
        TARGET_URL="https://shotgun.live/pt-br/cities/florianopolis"
    else
        echo "Error: provider must be pikachu or charmander"
        exit 1
    fi
    
    echo "==== Running End-to-End Test for Static Extraction Mode ===="
    echo "Provider: {{provider}} | City: {{city}}"
    echo "Target URL: $TARGET_URL"
    echo ""
    
    # Create test directory if it doesn't exist
    mkdir -p "$TEST_FOLDER"

    # Skip download if folder exists and has content
    if [ -z "$(ls -A "$TEST_FOLDER" 2>/dev/null)" ]; then
        # Step 1: Download site with HTTrack
        echo "Step 1: Downloading website with HTTrack..."
        if command -v httrack &> /dev/null; then
            httrack "$TARGET_URL" -O "$TEST_FOLDER" --disable-security-limits -v
        else
            echo "Warning: httrack not found, creating sample test files instead"
            echo "<html><body><h1>Test Event</h1></body></html>" > "$TEST_FOLDER/index.html"
        fi
    else
        echo "Using existing files in $TEST_FOLDER"
    fi
    
    # Step 2: Run the application in static mode
    echo ""
    echo "Step 2: Running application with static extraction..."
    
    # Set up required environment variables for static mode
    export EXTRACTION_MODE=static
    export EXTRACTION_FOLDER="$TEST_FOLDER"
    export PROVIDER={{provider}}
    export CITY={{city}}
    
    # Set a dummy API URL since we won't be using FireCrawler
    if [ "{{provider}}" = "pikachu" ]; then
        export PIKACHU_API_URL="https://example.com"
    elif [ "{{provider}}" = "charmander" ]; then
        export CHARMANDER_API_URL="https://example.com"
    fi
    
    # Create a test environment
    # We'll set a mock bucket name for GCP to avoid the error
    export GCP_BUCKET_NAME=mock-bucket
    
    # Skip database connection check
    export SKIP_DB=true
    
    echo "Running in static extraction mode with folder: $TEST_FOLDER"
    echo "Provider: {{provider}} | City: {{city}}"
    # Skip database check and explicitly set export format
    cargo run -p sharingan -- --skip-db-test --export gcp
    
    echo ""
    echo "==== End-to-End Test Completed ===="
    echo "Extraction folder: $TEST_FOLDER"
    echo "To run again with the same data: just run-static $TEST_FOLDER {{provider}} {{city}}"

# Run both frontend and backend
fullstack:
    #!/usr/bin/env bash
    echo "Starting iHoje full-stack application..."
    
    # Build the frontend
    cd "$(git rev-parse --show-toplevel)"
    echo "Building WebAssembly frontend..."
    just frontend-build
    
    # Start the API server
    echo "Starting API server on port 8080..."
    cargo run -p sharingan -- --api
    
    echo "Full-stack application started. Visit http://localhost:8080"