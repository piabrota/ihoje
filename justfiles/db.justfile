# Database Management Recipes
# This file contains all database-related commands

# Load .env file if present
set dotenv-load

# Show available recipes
default:
    @just --list

# Show database commands help
help:
    @echo "======= Database Commands ======="
    @echo ""
    @echo "PostgreSQL Management:"
    @echo "  just start                - Start PostgreSQL container"
    @echo "  just stop                 - Stop PostgreSQL container"
    @echo "  just status               - Check database tables and row counts"
    @echo "  just info                 - Show connection information"
    @echo "  just psql                 - Connect to PostgreSQL with psql"
    @echo ""
    @echo "Database Operations:"
    @echo "  just migrate              - Apply database migrations"
    @echo "  just reset                - Reset database (drops all tables)"
    @echo "  just run-postgres         - Run app with PostgreSQL after ensuring DB is running"

# Ensure podman is running
ensure-podman:
    #!/usr/bin/env bash
    echo "Checking podman status..."
    if command -v podman &> /dev/null; then
        echo "Using Podman for containers"
        export CONTAINER_TOOL="podman"
    else
        echo "Error: Podman is not installed"
        exit 1
    fi

# Start PostgreSQL in container (respects env vars from .env)
start:
    #!/usr/bin/env bash
    # Check if podman is available
    just ensure-podman
    
    # Set container variables
    CONTAINER_TOOL="podman"
    COMPOSE_TOOL="podman-compose"
    
    echo "Starting PostgreSQL using ${COMPOSE_TOOL}..."
    ${COMPOSE_TOOL} up -d postgres
    
    # Wait for PostgreSQL to be ready
    echo "Waiting for PostgreSQL to be ready..."
    for i in {1..30}; do
        if ${CONTAINER_TOOL} exec ihoje-postgres pg_isready -U postgres &>/dev/null; then
            echo "PostgreSQL is ready!"
            exit 0
        fi
        echo -n "."
        sleep 1
    done
    echo "PostgreSQL failed to start in time."
    exit 1

# Stop PostgreSQL container and remove volumes
stop:
    #!/usr/bin/env bash
    # Set compose tool to podman-compose
    COMPOSE_TOOL="podman-compose"
    
    echo "Stopping PostgreSQL..."
    ${COMPOSE_TOOL} down postgres

# Get PostgreSQL connection info
info:
    #!/usr/bin/env bash
    # Use podman for container management
    CONTAINER_TOOL="podman"
    
    if ${CONTAINER_TOOL} ps | grep -q ihoje-postgres; then
        echo "PostgreSQL is running"
        echo "Connection info:"
        echo "  Host: localhost"
        echo "  Port: 5432"
        echo "  User: postgres"
        echo "  Password: postgres"
        echo "  Database: events"
        echo ""
        echo "Connection string: postgresql://postgres:postgres@localhost:5432/events"
        echo ""
        echo "To connect with psql:"
        echo "  ${CONTAINER_TOOL} exec -it ihoje-postgres psql -U postgres -d events"
    else
        echo "PostgreSQL is not running. Start it with 'just db start'"
    fi

# Apply migrations
migrate:
    #!/usr/bin/env bash
    # Use podman for container management
    CONTAINER_TOOL="podman"
    
    if ! ${CONTAINER_TOOL} ps | grep -q ihoje-postgres; then
        echo "PostgreSQL is not running. Starting it now..."
        just start
    fi
    
    echo "Applying migrations from db/postgres/schema.sql..."
    ${CONTAINER_TOOL} exec -i ihoje-postgres psql -U postgres -d events < db/postgres/schema.sql
    echo "Migrations applied successfully!"

# Run PostgreSQL commands
psql:
    #!/usr/bin/env bash
    # Use podman for container management
    CONTAINER_TOOL="podman"
    
    ${CONTAINER_TOOL} exec -it ihoje-postgres psql -U postgres -d events

# Check database status
status:
    #!/usr/bin/env bash
    # Use podman for container management
    CONTAINER_TOOL="podman"
    
    if ${CONTAINER_TOOL} ps | grep -q ihoje-postgres; then
        echo "PostgreSQL is running"
        echo ""
        echo "Tables in database:"
        ${CONTAINER_TOOL} exec ihoje-postgres psql -U postgres -d events -c '\dt'
        
        echo ""
        echo "Row counts:"
        ${CONTAINER_TOOL} exec ihoje-postgres psql -U postgres -d events -c 'SELECT table_name, count(*) FROM (SELECT table_name FROM information_schema.tables WHERE table_schema='\''public'\'') AS tables, (SELECT count(*) FROM public.events UNION ALL SELECT count(*) FROM public.failed_price_fetches) as counts GROUP BY table_name;'
    else
        echo "PostgreSQL is not running. Start it with 'just db start'"
    fi

# Reset database (drops all tables and reapplies migrations)
reset:
    #!/usr/bin/env bash
    # Use podman for container management
    CONTAINER_TOOL="podman"
    
    if ! ${CONTAINER_TOOL} ps | grep -q ihoje-postgres; then
        echo "PostgreSQL is not running. Starting it now..."
        just start
    fi
    
    echo "Resetting database..."
    ${CONTAINER_TOOL} exec ihoje-postgres psql -U postgres -d events -c 'DROP TABLE IF EXISTS events, failed_price_fetches CASCADE;'
    just migrate
    echo "Database reset complete!"

# Run with PostgreSQL export after ensuring database is running
run-postgres:
    #!/usr/bin/env bash
    # Use podman for container management
    CONTAINER_TOOL="podman"
    
    if ! ${CONTAINER_TOOL} ps | grep -q ihoje-postgres; then
        echo "PostgreSQL is not running. Starting it now..."
        just start
    fi
    
    export EXPORT_FORMAT=postgres
    export PG_HOST=localhost
    export PG_PORT=5432
    export PG_USER=postgres
    export PG_PASSWORD=postgres
    export PG_DATABASE=events
    
    echo "Running with PostgreSQL export..."
    cargo run