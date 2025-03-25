# Complex Recipe Examples

This document provides token-optimized examples for complex justfile recipes.

## 1. Date Range Processing Example

```just
# [R] Run with advanced date options
# Usage: just run-dates [OPTIONS]
# Options:
#   --range=N-M  N days start, M days end
#   --city=CITY  Specific city
#   --format=F   Export format (csv|postgres)
run-dates +args="":
    #!/usr/bin/env bash
    # Default settings
    START_DAYS=7
    END_DAYS=14
    CITY=${CITY:-FL}
    FORMAT=${EXPORT_FORMAT:-csv}
    
    # Parse args
    for arg in {{args}}; do
        case $arg in
            --range=*)
                RANGE=${arg#*=}
                START_DAYS=${RANGE%-*}
                END_DAYS=${RANGE#*-}
                # Validate numbers
                [[ ! "$START_DAYS" =~ ^[0-9]+$ ]] && echo "Error: start days must be number" && exit 1
                [[ ! "$END_DAYS" =~ ^[0-9]+$ ]] && echo "Error: end days must be number" && exit 1
                ;;
            --city=*)
                CITY=${arg#*=}
                ;;
            --format=*)
                FORMAT=${arg#*=}
                [[ "$FORMAT" != "csv" && "$FORMAT" != "postgres" && "$FORMAT" != "both" ]] && \
                  echo "Error: format must be csv, postgres, or both" && exit 1
                ;;
            *)
                echo "Warning: unknown option $arg"
                ;;
        esac
    done
    
    # Calculate dates
    START_DATE=$(date -d "+$START_DAYS days" +"%Y-%m-%d")
    END_DATE=$(date -d "+$END_DAYS days" +"%Y-%m-%d")
    
    # Run command
    echo "Running with dates $START_DATE to $END_DATE, city $CITY, format $FORMAT"
    CITY=$CITY START_DATE=$START_DATE END_DATE=$END_DATE EXPORT_FORMAT=$FORMAT cargo run
```

## 2. Database Management Example

```just
# [DB] Full database reset and reload
# Usage: just db-reset-reload [--no-backup] [--skip-migrate]
db-reset-reload +args="":
    #!/usr/bin/env bash
    # Default settings
    BACKUP=true
    MIGRATE=true
    
    # Parse args
    for arg in {{args}}; do
        case $arg in
            --no-backup)
                BACKUP=false
                ;;
            --skip-migrate)
                MIGRATE=false
                ;;
            *)
                echo "Warning: unknown option $arg"
                ;;
        esac
    done
    
    # Check if db is running
    echo "Checking database status..."
    if ! podman ps | grep -q ihoje-postgres; then
        echo "Starting database container..."
        just db-start
        [ $? -ne 0 ] && echo "Error starting database" && exit 1
    fi
    
    # Backup if needed
    if [ "$BACKUP" = true ]; then
        echo "Creating backup..."
        BACKUP_FILE="db_backup_$(date +%Y%m%d_%H%M%S).sql"
        podman exec ihoje-postgres pg_dump -U postgres -d events > $BACKUP_FILE
        echo "Backup created: $BACKUP_FILE"
    fi
    
    # Reset database
    echo "Resetting database..."
    podman exec ihoje-postgres psql -U postgres -d events -c 'DROP TABLE IF EXISTS events, failed_price_fetches CASCADE;'
    
    # Migrate if needed
    if [ "$MIGRATE" = true ]; then
        echo "Applying migrations..."
        just db-migrate
    fi
    
    echo "Database reset complete!"
```

## 3. Provider Validation Example

```just
# [S] Setup secure provider environment
# Usage: just setup-provider PROVIDER [--force] [--test-only]
setup-provider provider +args="":
    #!/usr/bin/env bash
    # Validate provider
    [[ "{{provider}}" != "pikachu" && "{{provider}}" != "charmander" ]] && \
      echo "Error: provider must be pikachu or charmander" && exit 1
    
    # Default settings
    FORCE=false
    TEST_ONLY=false
    
    # Parse args
    for arg in {{args}}; do
        case $arg in
            --force)
                FORCE=true
                ;;
            --test-only)
                TEST_ONLY=true
                ;;
            *)
                echo "Warning: unknown option $arg"
                ;;
        esac
    done
    
    # Set provider
    echo "Setting up {{provider}} provider..."
    
    # Check for .env file
    if [ ! -f .env ] && [ "$FORCE" != true ]; then
        echo "Error: .env file not found. Use --force to create new .env"
        exit 1
    fi
    
    # Create/update .env
    if [ ! -f .env ] || [ "$FORCE" = true ]; then
        # Create template with provider settings
        cat > .env << EOF
# Provider Configuration
PROVIDER={{provider}}
{{provider|upper}}_API_URL=https://example.com/api
EOF
        echo "Created .env with {{provider}} settings"
    else
        # Update existing .env
        sed -i 's/^PROVIDER=.*/PROVIDER={{provider}}/' .env
        echo "Updated .env with {{provider}} settings"
    fi
    
    # Run test if requested
    if [ "$TEST_ONLY" = true ]; then
        echo "Testing {{provider}} configuration..."
        PROVIDER={{provider}} TEST_ONLY=true cargo run -- --test-connection
    else
        echo "Setup complete! Run app with: just run-provider {{provider}}"
    fi
```

## 4. Combined Multi-step Operation

```just
# [OP] Complete workflow operation
# Usage: just workflow CITY [--export=FORMAT] [--days=N]
workflow city export="csv" days="7":
    #!/usr/bin/env bash
    # Validate params
    [ -z "{{city}}" ] && echo "Error: city required" && exit 1
    [[ "{{export}}" != "csv" && "{{export}}" != "postgres" && "{{export}}" != "both" ]] && \
      echo "Error: export must be csv, postgres, or both" && exit 1
    [[ ! "{{days}}" =~ ^[0-9]+$ ]] && echo "Error: days must be number" && exit 1
    
    # Stage 1: Ensure database
    echo "Stage 1: Preparing database..."
    if [ "{{export}}" = "postgres" ] || [ "{{export}}" = "both" ]; then
        # Start database if needed
        if ! podman ps | grep -q ihoje-postgres; then
            just db-start
            [ $? -ne 0 ] && echo "Error: failed to start database" && exit 1
        fi
    fi
    
    # Stage 2: Run the scraper
    echo "Stage 2: Running scraper for {{city}}..."
    END_DATE=$(date -d "+{{days}} days" +"%Y-%m-%d")
    CITY={{city}} END_DATE=$END_DATE EXPORT_FORMAT={{export}} cargo run
    [ $? -ne 0 ] && echo "Error: scraper failed" && exit 1
    
    # Stage 3: Process results
    echo "Stage 3: Processing results..."
    if [ "{{export}}" = "csv" ] || [ "{{export}}" = "both" ]; then
        CSV_FILE=$(find . -name "events_*.csv" -type f | sort -r | head -1)
        [ -z "$CSV_FILE" ] && echo "Warning: No CSV file found"
    fi
    
    if [ "{{export}}" = "postgres" ] || [ "{{export}}" = "both" ]; then
        ROW_COUNT=$(podman exec ihoje-postgres psql -U postgres -d events -c 'SELECT COUNT(*) FROM events;' -t | xargs)
        echo "Events found: $ROW_COUNT"
    fi
    
    echo "Workflow completed successfully!"
```

## 5. Cross-Platform Example

```just
# [X] Cross-platform run command
# Usage: just xrun [OPTIONS]
xrun +args="":
    #!/usr/bin/env bash
    # Detect platform
    PLATFORM="unknown"
    case "$(uname -s)" in
        Linux*)     PLATFORM="linux";;
        Darwin*)    PLATFORM="macos";;
        CYGWIN*)    PLATFORM="windows";;
        MINGW*)     PLATFORM="windows";;
        *)          PLATFORM="unknown";;
    esac
    
    # Platform-specific settings
    if [ "$PLATFORM" = "linux" ]; then
        export DATE_CMD="date"
        export CONTAINER_TOOL="podman"
    elif [ "$PLATFORM" = "macos" ]; then
        export DATE_CMD="gdate"  # requires coreutils
        export CONTAINER_TOOL="docker"
    elif [ "$PLATFORM" = "windows" ]; then
        export DATE_CMD="date"
        export CONTAINER_TOOL="docker"
    else
        echo "Error: unsupported platform"
        exit 1
    fi
    
    # Run with platform settings
    echo "Running on $PLATFORM platform..."
    if [ "$PLATFORM" = "windows" ]; then
        # Windows-specific path handling
        cargo run -- --platform=$PLATFORM {{args}}
    else
        # Unix platforms
        START_DATE=$($DATE_CMD -d "+7 days" +"%Y-%m-%d")
        END_DATE=$($DATE_CMD -d "+14 days" +"%Y-%m-%d")
        START_DATE=$START_DATE END_DATE=$END_DATE cargo run -- --platform=$PLATFORM {{args}}
    fi
```

## 6. Testing Workflow Example

```just
# [T] Run full test suite with reports
# Usage: just test-suite [--quick] [--skip=GROUPS]
test-suite +args="":
    #!/usr/bin/env bash
    # Default settings
    QUICK=false
    SKIP_GROUPS=""
    
    # Parse args
    for arg in {{args}}; do
        case $arg in
            --quick)
                QUICK=true
                ;;
            --skip=*)
                SKIP_GROUPS=${arg#*=}
                ;;
            *)
                echo "Warning: unknown option $arg"
                ;;
        esac
    done
    
    # Prepare test environment
    echo "Preparing test environment..."
    if [ "$QUICK" != true ]; then
        just clean
    fi
    
    # Create test data directory
    mkdir -p tests/data
    
    # Generate mock test data
    echo "Generating test data..."
    if [ "$QUICK" != true ]; then
        just create-test-data
    fi
    
    # Run tests with specific exclusions
    echo "Running test suite..."
    COMMAND="cargo test"
    if [ -n "$SKIP_GROUPS" ]; then
        for group in $(echo $SKIP_GROUPS | tr ',' ' '); do
            COMMAND="$COMMAND -- --skip $group"
        done
    fi
    
    # Execute tests
    echo "Executing: $COMMAND"
    eval $COMMAND
    
    # Generate report (only for full test)
    if [ "$QUICK" != true ]; then
        echo "Generating test report..."
        REPORT_FILE="test_report_$(date +%Y%m%d_%H%M%S).txt"
        echo "Test Report: $(date)" > $REPORT_FILE
        echo "Status: $([[ $? -eq 0 ]] && echo 'PASSED' || echo 'FAILED')" >> $REPORT_FILE
        echo "" >> $REPORT_FILE
        
        # Gather coverage data if possible
        if command -v grcov &> /dev/null; then
            echo "Running coverage analysis..."
            grcov . -s . --binary-path ./target/debug/ -t html --branch --ignore-not-existing -o ./coverage/
            echo "Coverage report: ./coverage/index.html" >> $REPORT_FILE
        fi
        
        echo "Test report saved to $REPORT_FILE"
    fi
```