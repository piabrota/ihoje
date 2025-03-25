# iHoje Master Justfile
# Simplified and optimized for token usage

# Load .env file
set dotenv-load

# Default city
default_city := "FL"

# Show all recipes
default:
    @just --list

# Show help with common commands
help:
    @echo "=== iHoje Commands ==="
    @echo ""
    @echo "App Commands:"
    @echo "  run [ARGS]           - Run app with args"
    @echo "  run-api [PORT]       - Run API server (default port 8080)"
    @echo "  run-fullstack        - Run both tobira and API server"
    @echo "  run-city CITY        - Run with specific city"
    @echo "  run-date             - Run with 7-14 day range"
    @echo "  run-custom START END - Run with custom date range"
    @echo "  run-provider NAME    - Run with specific provider"
    @echo "  build                - Build application"
    @echo "  test                 - Run all tests"
    @echo ""
    @echo "Cleaning:"
    @echo "  clean                - Clean build artifacts and logs"
    @echo "  clean-all            - Clean everything (logs, builds, Docker)"
    @echo "  clean-logs           - Clean only log files"
    @echo "  clean-docker         - Clean Docker containers and images"
    @echo "  clean-scala          - Clean Scala build artifacts"
    @echo "  clean-python         - Clean Python artifacts"
    @echo ""
    @echo "Tobira Commands:"
    @echo "  tobira-build         - Build Tobira (Gate of Truth) WebAssembly interface"
    @echo "  tobira-serve         - Serve Tobira locally"
    @echo "  tobira-dev           - Run Tobira dev server with auto-reload"
    @echo "  tobira-dev-mock      - Run Tobira dev server with mock data"
    @echo "  tobira-dev-docker    - Run Tobira dev server in Docker"
    @echo "  tobira-dev-docker-mock - Run Tobira dev server with mock data in Docker"
    @echo "  tobira-restart-mock  - Restart mock Tobira with latest changes"
    @echo "  tobira-restart       - Restart Shinri no Tobira with latest changes"
    @echo "  tobira-redeploy      - Redeploy both mock and Shinri no Tobira containers"
    @echo "  tobira-setup-docker  - Setup Docker Tobiras with separate ports" 
    @echo "  tobira-help          - Show Tobira (Gate of Truth) commands"
    @echo ""
    @echo "Export Commands:"
    @echo "  run-postgres         - Run with PostgreSQL export"
    @echo "  run-both             - Run with both CSV and PostgreSQL"
    @echo ""
    @echo "Database Commands:"
    @echo "  db-start             - Start PostgreSQL container"
    @echo "  db-status            - Check DB status"
    @echo "  db-psql              - Connect to PostgreSQL CLI"
    @echo ""
    @echo "Task Management:"
    @echo "  add-task NAME DESC   - Add new task"
    @echo "  mark-step-complete TASK STEP - Mark step complete"
    @echo "  task-show            - Show task progress"
    @echo ""
    @echo "Dependency Management:"
    @echo "  update-deps          - Update all dependencies to latest versions"
    @echo "  outdated             - Check for outdated dependencies"
    @echo ""
    @echo "Claude Commands:"
    @echo "  claude               - Standard context (~1000 tokens)"
    @echo "  claude-minimal       - Minimal context (~500 tokens)"
    @echo "  claude-micro         - Ultra-minimal context (~200 tokens)"
    @echo ""
    @echo "MCP Tools:"
    @echo "  mcp-install-all      - Install all iHoje MCP tools"
    @echo "  mcp-status           - Show status of all iHoje MCP tools"
    @echo "  mcp-install          - Install Mangekyou with auto-versioning"
    @echo "  mcp-check            - Check Mangekyou configuration and status"
    @echo "  mcp-start            - Start Mangekyou server"
    @echo "  mcp-stop             - Stop specific server"
    @echo "  mcp-uninstall-all    - Uninstall all iHoje MCP tools"
    @echo ""
    @echo "For more help: just CATEGORY-help"
    @echo "For full list: just --list"

# Run app
run +ARGS="":
    cargo run -p sharingan {{ARGS}}
    
# Run API server
run-api port="8080":
    cargo run -p sharingan -- --api --port {{port}}
    
# Run both tobira and backend
run-fullstack:
    @just --justfile justfiles/run.justfile fullstack

# Run with city
run-city city=default_city:
    CITY={{city}} cargo run -p sharingan

# Run with date range (7-14 days)
run-date +ARGS="":
    #!/usr/bin/env bash
    START=$(date -d "+7 days" +"%Y-%m-%d")
    END=$(date -d "+14 days" +"%Y-%m-%d")
    echo "Using dates: ${START} to ${END}"
    START_DATE=${START} END_DATE=${END} cargo run -p sharingan {{ARGS}}

# Run with custom date range
run-custom start="7" end="14" +ARGS="":
    #!/usr/bin/env bash
    [[ ! "{{start}}" =~ ^[0-9]+$ ]] && echo "Error: start must be number" && exit 1
    [[ ! "{{end}}" =~ ^[0-9]+$ ]] && echo "Error: end must be number" && exit 1
    
    START=$(date -d "+{{start}} days" +"%Y-%m-%d")
    END=$(date -d "+{{end}} days" +"%Y-%m-%d")
    START_DATE=${START} END_DATE=${END} cargo run -p sharingan {{ARGS}}

# Run with provider
run-provider provider="pikachu":
    #!/usr/bin/env bash
    [[ "{{provider}}" != "pikachu" && "{{provider}}" != "charmander" ]] && \
      echo "Error: provider must be pikachu or charmander" && exit 1
    PROVIDER={{provider}} cargo run -p sharingan

# Build app
build:
    cargo build --workspace

# Build specific package
build-sharingan:
    cargo build -p sharingan

# Build Tobira
build-tobira:
    cargo build -p ihoje_tobira  # Note: This crate hasn't been renamed yet to maintain backward compatibility

# Build models
build-pokeball:
    cargo build -p pokeball

# Run tests
test:
    cargo test --workspace

# Run tests for specific package
test-sharingan:
    cargo test -p sharingan

# Run tests for pokeball
test-pokeball:
    cargo test -p pokeball

# Show test help
test-help:
    @just --justfile justfiles/test.justfile help

# Run with PostgreSQL export
run-postgres +ARGS="":
    EXPORT_FORMAT=postgres cargo run -p sharingan {{ARGS}}

# Run with both exports
run-both +ARGS="":
    EXPORT_FORMAT=both cargo run -p sharingan {{ARGS}}

# Start PostgreSQL container
db-start:
    @just --justfile justfiles/db.justfile start

# Check DB status
db-status:
    @just --justfile justfiles/db.justfile status

# Connect to PostgreSQL
db-psql:
    @just --justfile justfiles/db.justfile psql

# Database help
db-help:
    @just --justfile justfiles/db.justfile help

# Add task
add-task task_name task_description:
    @just --justfile justfiles/task.justfile add {{task_name}} {{task_description}}

# Mark step complete
mark-step-complete task_name step_description info="":
    @just --justfile justfiles/task.justfile complete {{task_name}} {{step_description}} {{info}}

# Mark step failed
mark-step-failed task_name step_description error="Failed":
    @just --justfile justfiles/task.justfile fail {{task_name}} {{step_description}} {{error}}

# Show task progress
task-show:
    @just --justfile justfiles/task.justfile show

# Task help
task-help:
    @just --justfile justfiles/task.justfile help

# Update all dependencies
update-deps:
    @scripts/update-dependencies.sh

# Check for outdated dependencies
outdated:
    @cargo outdated

# Claude standard
claude *ARGS="":
    @cat CLAUDE_BOOTSTRAP.md README.md CLAUDE.md | claude code {{ARGS}}

# Claude minimal
claude-minimal *ARGS="":
    @just --justfile justfiles/claude.justfile claude-minimal {{ARGS}}

# Claude micro
claude-micro *ARGS="":
    @just --justfile justfiles/claude.justfile claude-micro {{ARGS}}

# Claude help
claude-help:
    @just --justfile justfiles/claude.justfile help

# Install all MCP tools
mcp-install-all:
    @just --justfile justfiles/mcp.justfile install-all

# Show status of all iHoje MCP tools
mcp-status:
    @just --justfile justfiles/mcp.justfile status

# Start Mangekyou server
mcp-start:
    @just --justfile justfiles/mcp.justfile start

# Stop Mangekyou server
mcp-stop:
    @just --justfile justfiles/mcp.justfile stop

# Restart Mangekyou server
mcp-restart:
    @just --justfile justfiles/mcp.justfile restart

# View server logs
mcp-logs:
    @just --justfile justfiles/mcp.justfile logs

# Check server health
mcp-health:
    @just --justfile justfiles/mcp.justfile health

# List MCP tools
mcp-list:
    #!/usr/bin/env bash
    echo "iHoje MCP Tools:"
    echo "---------------"
    echo "ihoje_mangekyou   - Implementation planning at http://localhost:17891"
    
    # Find all mangekyou instances and their latest version
    if command -v claude >/dev/null 2>&1; then
        mangekyou_instances=$(claude mcp list | grep -o "mangekyou_v[0-9]\+" || echo "")
        if [ -n "$mangekyou_instances" ]; then
            latest_version=$(echo "$mangekyou_instances" | grep -o "v[0-9]\+" | sort -V | tail -n 1)
            echo "mangekyou${latest_version} - Auto-versioned tool (latest)"
            echo ""
            echo "All installed versions:"
            echo "$mangekyou_instances" | sort -V
        else
            echo "No mangekyou instances found. Run 'just mcp-install' to create one."
        fi
    else
        echo "Can't check mangekyou instances: 'claude' command not found"
    fi

# MCP help
mcp-help:
    @just --justfile justfiles/mcp.justfile help

# Setup MCP implementations
mcp-setup-implementations:
    @just --justfile justfiles/mcp.justfile setup-implementations

# Uninstall all MCP tools
mcp-uninstall-all:
    @just --justfile justfiles/mcp.justfile uninstall-all

# Uninstall MCP tool (cleans up server process)
mcp-uninstall:
    @just --justfile justfiles/mcp.justfile stop

# Reset all MCP tools (uninstall and reinstall)
mcp-reset-all:
    @just --justfile justfiles/mcp.justfile reset-all

# Check Mangekyou configuration
mcp-check:
    @just --justfile justfiles/mcp.justfile check

# Install Mangekyou with auto-versioning
mcp-install:
    @just --justfile justfiles/mcp.justfile install

# Legacy: Check Mangekyou v5 configuration
mcp-check-v5:
    @just --justfile justfiles/mcp.justfile check-v5

# Legacy: Install Mangekyou v5
mcp-install-v5:
    @just --justfile justfiles/mcp.justfile install-v5

# Dump context for Claude
dump-context:
    @just --justfile justfiles/claude.justfile dump-context

# Provider management
provider-help:
    @echo "=== Provider Security ==="
    @echo "Providers:"
    @echo "  pikachu    - Provider 1"
    @echo "  charmander - Provider 2"
    @echo "Security:"
    @echo "  1. Don't commit URLs in code"
    @echo "  2. Use codenames only"
    @echo "  3. Store URLs in .env"

# Security commands if secrets justfile exists
secrets:
    @if [ -f justfiles/secrets.justfile ]; then \
        just --justfile justfiles/secrets.justfile help; \
    else \
        echo "No secrets.justfile found. Create one for security commands."; \
    fi

# Find potential provider name exposures
detect-providers:
    @if [ -f justfiles/secrets.justfile ]; then \
        just --justfile justfiles/secrets.justfile detect-providers; \
    else \
        echo "No secrets.justfile found. Create one for security commands."; \
    fi

# Scrub provider names from a file
scrub-providers file:
    @if [ -f justfiles/secrets.justfile ]; then \
        just --justfile justfiles/secrets.justfile scrub-providers {{file}}; \
    else \
        echo "No secrets.justfile found. Create one for security commands."; \
    fi

# Run specialized command
podman +ARGS:
    @just --justfile justfiles/podman.justfile {{ARGS}}

# Run specialized command
hooks +ARGS:
    @just --justfile justfiles/hooks.justfile {{ARGS}}

# Run specialized command  
security +ARGS:
    @just --justfile justfiles/security.justfile {{ARGS}}

# Run specialized command
util +ARGS:
    @just --justfile justfiles/util.justfile {{ARGS}}
    
# Clean build artifacts and logs
clean:
    @just --justfile justfiles/util.justfile clean

# Clean all artifacts, logs, and Docker images
clean-all:
    @just --justfile justfiles/util.justfile clean-all
    
# Clean just log files
clean-logs:
    @just --justfile justfiles/util.justfile clean-logs
    
# Clean Docker images and containers
clean-docker:
    @just --justfile justfiles/util.justfile clean-docker
    
# Clean Scala build artifacts
clean-scala:
    @just --justfile justfiles/util.justfile clean-scala
    
# Clean Python artifacts
clean-python:
    @just --justfile justfiles/util.justfile clean-python

# Tobira commands
tobira-build:
    @just --justfile justfiles/tobira.justfile build

# Serve Tobira
tobira-serve:
    @just --justfile justfiles/tobira.justfile serve

# Run Tobira dev server
tobira-dev:
    @just --justfile justfiles/tobira.justfile dev

# Run Tobira dev server with mock data
tobira-dev-mock:
    @just --justfile justfiles/tobira.justfile dev-mock

# Run Tobira dev server in Docker
tobira-dev-docker:
    @just --justfile justfiles/tobira.justfile dev-docker

# Run Tobira dev server with mock data in Docker
tobira-dev-docker-mock:
    @just --justfile justfiles/tobira.justfile dev-docker-mock

# Tobira help
tobira-help:
    @just --justfile justfiles/tobira.justfile help
    
# Restart mock Tobira with latest changes
tobira-restart-mock:
    @just --justfile justfiles/tobira.justfile restart-mock

# Restart Shinri no Tobira with latest changes
tobira-restart:
    @just --justfile justfiles/tobira.justfile restart-tobira

# Redeploy both Tobira containers
tobira-redeploy:
    @just --justfile justfiles/tobira.justfile redeploy-tobira

# Setup Docker Tobiras with separate ports
tobira-setup-docker:
    @bash setup-docker-tobiras.sh

# Run specialized Tobira command
tobira +ARGS:
    @just --justfile justfiles/tobira.justfile {{ARGS}}

# Legacy frontend commands (deprecated)
frontend-build:
    @echo "⚠️ Warning: frontend commands are deprecated. Please use tobira-build instead."
    @just tobira-build

frontend-serve:
    @echo "⚠️ Warning: frontend commands are deprecated. Please use tobira-serve instead."
    @just tobira-serve

frontend-dev:
    @echo "⚠️ Warning: frontend commands are deprecated. Please use tobira-dev instead."
    @just tobira-dev

frontend-dev-mock:
    @echo "⚠️ Warning: frontend commands are deprecated. Please use tobira-dev-mock instead."
    @just tobira-dev-mock

frontend-help:
    @echo "⚠️ Warning: frontend commands are deprecated. Please use tobira-help instead."
    @just tobira-help
    
frontend-restart-mock:
    @echo "⚠️ Warning: frontend commands are deprecated. Please use tobira-restart-mock instead."
    @just tobira-restart-mock

frontend-restart-wasm:
    @echo "⚠️ Warning: frontend commands are deprecated. Please use tobira-restart instead."
    @just tobira-restart

frontend-redeploy:
    @echo "⚠️ Warning: frontend commands are deprecated. Please use tobira-redeploy instead."
    @just tobira-redeploy

# Legacy setup command (deprecated)
frontend-setup-docker:
    @echo "⚠️ Warning: frontend commands are deprecated. Please use tobira-setup-docker instead."
    @just tobira-setup-docker

# Run specialized frontend command (deprecated)
frontend +ARGS:
    @echo "⚠️ Warning: frontend commands are deprecated. Please use tobira instead."
    @just --justfile justfiles/tobira.justfile {{ARGS}}