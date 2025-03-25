# Run Commands (app execution recipes)
set dotenv-load

# Default city
default_city := "FL"

# [L] List recipes
default:
    @just --list

# [H] Show run commands help 
help:
    @echo "=== Run Commands ==="
    @echo "Basic:"
    @echo "  run [ARGS]           - Run with args"
    @echo "  run-city CITY        - Run with city"
    @echo "  run-city-args CITY   - Run with city and args"
    @echo "Date:"
    @echo "  run-date [ARGS]      - Run with date range"
    @echo "  run-date-print       - Print URL with date range"
    @echo "  run-date-city CITY   - Run with date and city"
    @echo "  run-custom DATE END  - Run with custom dates"
    @echo "Export:"
    @echo "  run-postgres [ARGS]  - Run with PostgreSQL"
    @echo "  run-both [ARGS]      - Run with both exports"
    @echo "Provider:"
    @echo "  run-provider NAME    - Run with specific provider"

# [R] Run application
# Usage: just run [ARGS]
run +args="":
    cargo run {{args}}

# [R] Run with city
# Usage: just run-city CITY
run-city city=default_city:
    CITY={{city}} cargo run

# [R] Run with city and args
# Usage: just run-city-args CITY ARGS...
run-city-args city *args:
    #!/usr/bin/env bash
    [ -z "{{city}}" ] && echo "Error: city required" && exit 1
    CITY={{city}} cargo run -- {{args}}

# [R] Run with 7-14 day date range
# Usage: just run-date [ARGS]
run-date +args="":
    #!/usr/bin/env bash
    START=$(date -d "+7 days" +"%Y-%m-%d")
    END=$(date -d "+14 days" +"%Y-%m-%d")
    echo "Using dates: ${START} to ${END}"
    START_DATE=${START} END_DATE=${END} cargo run {{args}}

# [R] Run with date range and print URL
run-date-print:
    #!/usr/bin/env bash
    START=$(date -d "+7 days" +"%Y-%m-%d")
    END=$(date -d "+14 days" +"%Y-%m-%d")
    START_DATE=${START} END_DATE=${END} cargo run -- --print-url

# [R] Run with date range and city
# Usage: just run-date-city CITY
run-date-city city:
    #!/usr/bin/env bash
    [ -z "{{city}}" ] && echo "Error: city required" && exit 1
    START=$(date -d "+7 days" +"%Y-%m-%d")
    END=$(date -d "+14 days" +"%Y-%m-%d")
    CITY={{city}} START_DATE=${START} END_DATE=${END} cargo run

# [R] Run with custom date range
# Usage: just run-custom START END [ARGS]
run-custom start="7" end="14" +args="":
    #!/usr/bin/env bash
    # Validate numeric params
    [[ ! "{{start}}" =~ ^[0-9]+$ ]] && echo "Error: start must be number" && exit 1
    [[ ! "{{end}}" =~ ^[0-9]+$ ]] && echo "Error: end must be number" && exit 1
    
    START=$(date -d "+{{start}} days" +"%Y-%m-%d")
    END=$(date -d "+{{end}} days" +"%Y-%m-%d")
    START_DATE=${START} END_DATE=${END} cargo run {{args}}

# [R] Run with PostgreSQL export
# Usage: just run-postgres [ARGS]
run-postgres +args="":
    EXPORT_FORMAT=postgres cargo run {{args}}

# [R] Run with both CSV and PostgreSQL
# Usage: just run-both [ARGS]
run-both +args="":
    EXPORT_FORMAT=both cargo run {{args}}

# [R] Run with specific provider
# Usage: just run-provider PROVIDER
run-provider provider="pikachu":
    #!/usr/bin/env bash
    [[ "{{provider}}" != "pikachu" && "{{provider}}" != "charmander" ]] && \
      echo "Error: provider must be pikachu or charmander" && exit 1
    PROVIDER={{provider}} cargo run

# [I] Show provider security info
provider-help:
    @echo "=== Provider Security ==="
    @echo "Providers:"
    @echo "  pikachu    - Provider 1"
    @echo "  charmander - Provider 2"
    @echo "Security:"
    @echo "  1. Don't commit URLs in code"
    @echo "  2. Use codenames only"
    @echo "  3. Store URLs in .env"
    @echo "  4. Run 'just scrub-providers' before commits"