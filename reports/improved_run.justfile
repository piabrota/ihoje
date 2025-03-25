# Run Commands Recipes
# This file contains application run commands with different parameters

# Load .env file if present
set dotenv-load

# Set default city
default_city := "FL"

# [LIST]: Show all available recipes
default:
    @just --list

# [HELP]: Show run commands help
help:
    @echo "======= Run Commands ======="
    @echo ""
    @echo "Basic Run Commands:"
    @echo "  just run [ARGS]           - Run the application with arguments"
    @echo "  just run-city CITY        - Run with specific city"
    @echo "  just run-city-args CITY ARGS - Run with city and arguments"
    @echo ""
    @echo "Date Range Commands:"
    @echo "  just run-date [ARGS]      - Run with 7-14 day date range"
    @echo "  just run-date-print       - Run with date range and print URL"
    @echo "  just run-date-city CITY   - Run with date range and city"
    @echo "  just run-date-city-print CITY - Print URL for city with date range"
    @echo "  just run-custom-date 7 14 - Run with custom days ahead range"
    @echo ""
    @echo "Export Commands:"
    @echo "  just run-postgres [ARGS]  - Run with PostgreSQL export"
    @echo "  just run-both [ARGS]      - Run with both CSV and PostgreSQL export"
    @echo "  just run-postgres-date    - Run with PostgreSQL export and date range"
    @echo ""
    @echo "Provider Commands:"
    @echo "  just run-provider PROVIDER - Run with specific provider"

# [RUN]: Run the application with arguments
#
# Usage:
#   just run [ARGS]
# 
# Params:
#   args: Arguments to pass to the command (default: "")
run +args="":
    cargo run {{args}}

# [RUN]: Run the application with a specific city
#
# Usage:
#   just run-city CITY
#
# Params:
#   city: City code to use (default: "FL")
run-city city=default_city:
    CITY={{city}} cargo run

# [RUN]: Run the application with specific city and arguments
#
# Usage:
#   just run-city-args CITY ARGS...
#
# Params:
#   city: City code to use (required)
#   args: Additional arguments to pass to the app
run-city-args city *args:
    #!/usr/bin/env bash
    # Validate parameters
    if [ -z "{{city}}" ]; then
        echo "Error: 'city' parameter is required"
        exit 1
    fi
    
    CITY={{city}} cargo run -- {{args}}

# [RUN]: Run with date range (7 days ahead to 14 days ahead)
#
# Usage:
#   just run-date [ARGS]
#
# Params:
#   args: Optional arguments to pass to the app (default: "")
run-date +args="":
    #!/usr/bin/env bash
    # Calculate start date (today + 7 days)
    START_DATE=$(date -d "+7 days" +"%Y-%m-%d")
    # Calculate end date (today + 14 days)
    END_DATE=$(date -d "+14 days" +"%Y-%m-%d")
    
    echo "Using date range: ${START_DATE} to ${END_DATE}"
    START_DATE=${START_DATE} END_DATE=${END_DATE} cargo run {{args}}
    
    # Check success
    if [ $? -eq 0 ]; then
        echo "Run completed successfully"
    else
        echo "Run failed"
        exit 1
    fi

# [RUN]: Run with date range and print URL only
#
# Usage:
#   just run-date-print
run-date-print:
    #!/usr/bin/env bash
    # Calculate start date (today + 7 days)
    START_DATE=$(date -d "+7 days" +"%Y-%m-%d")
    # Calculate end date (today + 14 days)
    END_DATE=$(date -d "+14 days" +"%Y-%m-%d")
    
    echo "Using date range: ${START_DATE} to ${END_DATE}"
    START_DATE=${START_DATE} END_DATE=${END_DATE} cargo run -- --print-url
    
    # Check success
    if [ $? -eq 0 ]; then
        echo "URL generated successfully"
    else
        echo "Failed to generate URL"
        exit 1
    fi

# [RUN]: Run with date range and specific city
#
# Usage:
#   just run-date-city CITY
#
# Params:
#   city: City code to use (required)
run-date-city city:
    #!/usr/bin/env bash
    # Validate parameters
    if [ -z "{{city}}" ]; then
        echo "Error: 'city' parameter is required"
        exit 1
    fi
    
    # Calculate start date (today + 7 days)
    START_DATE=$(date -d "+7 days" +"%Y-%m-%d")
    # Calculate end date (today + 14 days)
    END_DATE=$(date -d "+14 days" +"%Y-%m-%d")
    
    echo "Using date range: ${START_DATE} to ${END_DATE} for city {{city}}"
    CITY={{city}} START_DATE=${START_DATE} END_DATE=${END_DATE} cargo run
    
    # Check success
    if [ $? -eq 0 ]; then
        echo "Run completed successfully"
    else
        echo "Run failed"
        exit 1
    fi

# [RUN]: Print URL for specific city with date range
#
# Usage:
#   just run-date-city-print CITY
#
# Params:
#   city: City code to use (required)
run-date-city-print city:
    #!/usr/bin/env bash
    # Validate parameters
    if [ -z "{{city}}" ]; then
        echo "Error: 'city' parameter is required"
        exit 1
    fi
    
    # Calculate start date (today + 7 days)
    START_DATE=$(date -d "+7 days" +"%Y-%m-%d")
    # Calculate end date (today + 14 days)
    END_DATE=$(date -d "+14 days" +"%Y-%m-%d")
    
    echo "Using date range: ${START_DATE} to ${END_DATE} for city {{city}}"
    CITY={{city}} START_DATE=${START_DATE} END_DATE=${END_DATE} cargo run -- --print-url
    
    # Check success
    if [ $? -eq 0 ]; then
        echo "URL generated successfully"
    else
        echo "Failed to generate URL"
        exit 1
    fi

# [RUN]: Run with custom date range (days ahead from now)
#
# Usage:
#   just run-custom-date START_DAYS END_DAYS [ARGS]
#
# Params:
#   start_days: Number of days ahead for start date (must be a number, default: "7")
#   end_days: Number of days ahead for end date (must be a number, default: "14")
#   args: Optional arguments to pass to the app (default: "")
run-custom-date start_days="7" end_days="14" +args="":
    #!/usr/bin/env bash
    # Validate parameters
    if ! [[ "{{start_days}}" =~ ^[0-9]+$ ]]; then
        echo "Error: 'start_days' must be a number"
        exit 1
    fi
    
    if ! [[ "{{end_days}}" =~ ^[0-9]+$ ]]; then
        echo "Error: 'end_days' must be a number"
        exit 1
    fi
    
    # Calculate start date (today + start_days)
    START_DATE=$(date -d "+{{start_days}} days" +"%Y-%m-%d")
    # Calculate end date (today + end_days)
    END_DATE=$(date -d "+{{end_days}} days" +"%Y-%m-%d")
    
    echo "Using custom date range: ${START_DATE} to ${END_DATE}"
    START_DATE=${START_DATE} END_DATE=${END_DATE} cargo run {{args}}
    
    # Check success
    if [ $? -eq 0 ]; then
        echo "Run completed successfully"
    else
        echo "Run failed"
        exit 1
    fi

# [RUN]: Run with PostgreSQL export
#
# Usage:
#   just run-postgres [ARGS]
#
# Params:
#   args: Optional arguments to pass to the app (default: "")
run-postgres +args="":
    EXPORT_FORMAT=postgres cargo run {{args}}

# [RUN]: Run with both CSV and PostgreSQL export
#
# Usage:
#   just run-both [ARGS]
#
# Params:
#   args: Optional arguments to pass to the app (default: "")
run-both +args="":
    EXPORT_FORMAT=both cargo run {{args}}

# [RUN]: Run with PostgreSQL export and date range
#
# Usage:
#   just run-postgres-date
run-postgres-date:
    #!/usr/bin/env bash
    # Calculate start date (today + 7 days)
    START_DATE=$(date -d "+7 days" +"%Y-%m-%d")
    # Calculate end date (today + 14 days)
    END_DATE=$(date -d "+14 days" +"%Y-%m-%d")
    
    echo "Using date range: ${START_DATE} to ${END_DATE} with PostgreSQL export"
    EXPORT_FORMAT=postgres START_DATE=${START_DATE} END_DATE=${END_DATE} cargo run
    
    # Check success
    if [ $? -eq 0 ]; then
        echo "Run completed successfully"
    else
        echo "Run failed"
        exit 1
    fi

# [RUN]: Run with specific provider
#
# Usage:
#   just run-provider PROVIDER
#
# Params:
#   provider: Provider to use (must be "pikachu" or "charmander", default: "pikachu")
run-provider provider="pikachu":
    #!/usr/bin/env bash
    # Validate provider parameter
    if [[ "{{provider}}" != "pikachu" && "{{provider}}" != "charmander" ]]; then
        echo "Error: 'provider' must be one of: pikachu, charmander"
        exit 1
    fi
    
    echo "Running with provider: {{provider}}"
    PROVIDER={{provider}} cargo run
    
    # Check success
    if [ $? -eq 0 ]; then
        echo "Run completed successfully"
    else
        echo "Run failed"
        exit 1
    fi

# [INFO]: Show provider security help
provider-help:
    @echo "======= Provider Security System ======="
    @echo ""
    @echo "Provider Security System:"
    @echo "  just util setup-provider-hooks - Install provider security hooks"
    @echo "  just util scrub-providers      - Remove provider URLs and names from code"
    @echo "  just run-provider pikachu      - Run with Pikachu provider"
    @echo "  just run-provider charmander   - Run with Charmander provider"
    @echo ""
    @echo "Provider Codenames:"
    @echo "  Pikachu = Provider 1"
    @echo "  Charmander = Provider 2"
    @echo ""
    @echo "Security Guidelines:"
    @echo "  1. Never commit provider URLs in source code"
    @echo "  2. Use codenames instead of actual provider names"
    @echo "  3. Keep provider URLs in .env only (not versioned)"
    @echo "  4. Run 'just util scrub-providers' before committing changes"