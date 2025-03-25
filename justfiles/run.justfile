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