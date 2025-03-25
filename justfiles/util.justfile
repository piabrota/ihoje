# Utility Recipes
# This file contains miscellaneous utility commands

# Load .env file if present
set dotenv-load

# Show available recipes
default:
    @just --list

# Show utility commands help
help:
    @echo "======= Utility Commands =======" 
    @echo ""
    @echo "General Utilities:"
    @echo "  just dump-context         - Print all context files"
    @echo "  just context-file         - Save context to markdown file"
    @echo "  just fmt                  - Format Rust code"
    @echo "  just lint                 - Run Clippy linter"
    @echo ""
    @echo "Cleaning:"
    @echo "  just clean                - Clean build artifacts and logs"
    @echo "  just clean-all            - Clean everything including dependencies"
    @echo "  just clean-logs           - Clean log files"
    @echo ""
    @echo "Environment:"
    @echo "  just init-env             - Create template .env file"

# Dump context files to console
dump-context:
    @echo "========== README.md ==========" 
    @cat README.md
    @echo ""
    @echo "========== guidelines.md ==========" 
    @cat docs/claude/core/guidelines.md
    @echo ""
    @echo "========== bootstrap.md ==========" 
    @cat docs/claude/core/bootstrap.md
    
# Write context files to a single output file
context-file output="context.md":
    #!/usr/bin/env bash
    echo "Writing context files to {{output}}..."
    
    # Create header and write files with section markers
    {
        echo "# Project Context"
        echo ""
        echo "## README.md"
        echo "```markdown"
        cat README.md
        echo "```"
        echo ""
        echo "## guidelines.md"
        echo "```markdown"
        cat docs/claude/core/guidelines.md
        echo "```"
        echo ""
        echo "## bootstrap.md"
        echo "```markdown"
        cat docs/claude/core/bootstrap.md
        echo "```"
    } > {{output}}
    
    echo "Context written to {{output}}"

# Clean build artifacts and logs
clean:
    cargo clean --package rust-scraper
    just clean-logs

# Clean everything including dependencies
clean-all:
    cargo clean
    just clean-logs
    just clean-docker
    @echo "Cleaning root log files and CSV files..."
    @rm -f *.log *.csv

# Clean log files
clean-logs:
    @echo "Cleaning log files..."
    @find . -maxdepth 1 -name "scraper_*.log" -type f -delete
    @find . -name "scraper_custom_*.log" -delete
    @find . -name "scraper_*_no_dates_*.log" -delete
    @find . -name "scraper_FL_no_dates_*.log" -delete
    @find . -name "failures_*.csv" -delete
    @find . -name "browser-tools.log" -delete
    @find . -name "fetch.log" -delete
    @find . -name "filesystem.log" -delete
    @find . -name "puppeteer.log" -delete
    @find . -name "sequential-thinking.log" -delete
    @find . -name "*.log" -not -path "./node_modules/*" -not -path "./.venv/*" -not -path "./target/*" -delete
    @# Note: We exclude logs in node_modules, .venv, and target directories
    @echo "Log files cleaned successfully!"

# Clean Docker images
clean-docker:
    #!/usr/bin/env bash
    echo "Cleaning Docker images..."
    
    # Determine which container command to use
    if command -v podman &> /dev/null; then
        CONTAINER_CMD="podman"
    elif command -v docker &> /dev/null; then
        CONTAINER_CMD="docker"
    else
        echo "Neither docker nor podman is available, skipping Docker cleanup"
        exit 0
    fi
    
    # Stop and remove ihoje containers
    echo "Stopping and removing ihoje containers..."
    $CONTAINER_CMD ps -a | grep -E 'ihoje|shinri' | awk '{print $1}' | xargs -r $CONTAINER_CMD rm -f 2>/dev/null || true
    
    # Remove ihoje images
    echo "Removing ihoje images..."
    $CONTAINER_CMD images | grep -E 'ihoje|shinri' | awk '{print $3}' | xargs -r $CONTAINER_CMD rmi -f 2>/dev/null || true
    
    # Prune dangling images
    echo "Pruning dangling images..."
    $CONTAINER_CMD image prune -f
    
    echo "Docker images cleaned successfully!"

# Clean Scala build artifacts
clean-scala:
    @echo "Cleaning Scala build artifacts..."
    @if [ -d "gugu" ]; then \
        cd gugu && rm -rf target/ project/target/ project/project/target/ .bloop/ .metals/ 2>/dev/null || true; \
        echo "Scala build artifacts cleaned successfully!"; \
    else \
        echo "No Scala directory found, skipping"; \
    fi

# Clean Python artifacts
clean-python:
    @echo "Cleaning Python artifacts..."
    @find . -type d -name __pycache__ -exec rm -rf {} \; 2>/dev/null || true
    @find . -name "*.pyc" -delete 2>/dev/null || true
    @find . -name "*.pyo" -delete 2>/dev/null || true
    @find . -name "*.pyd" -delete 2>/dev/null || true
    @find . -type d -name ".pytest_cache" -exec rm -rf {} \; 2>/dev/null || true
    @find . -name ".coverage" -delete 2>/dev/null || true
    @find . -type d -name "htmlcov" -exec rm -rf {} \; 2>/dev/null || true
    @find . -type d -name ".tox" -exec rm -rf {} \; 2>/dev/null || true
    @find . -type d -name ".nox" -exec rm -rf {} \; 2>/dev/null || true
    @find . -type d -name ".hypothesis" -exec rm -rf {} \; 2>/dev/null || true
    @find . -type d -name "*.egg-info" -exec rm -rf {} \; 2>/dev/null || true
    @find . -name "*.egg" -delete 2>/dev/null || true
    @find . -name "*.so" -delete 2>/dev/null || true
    @find . -name "*.o" -delete 2>/dev/null || true
    @echo "Python artifacts cleaned successfully!"

# Format code
fmt:
    cargo fmt

# Run clippy linter
lint:
    cargo clippy

# Create template .env file
init-env:
    @echo "Creating template .env file..."
    @if [ -f ".env" ]; then \
        echo "WARNING: .env file already exists. Backing up to .env.bak"; \
        cp .env .env.bak; \
    fi
    @echo '# Database Configuration\nPG_HOST=localhost\nPG_PORT=5432\nPG_USER=postgres\nPG_PASSWORD=postgres\nPG_DATABASE=events\n\n# API Configuration\nMAX_EVENTS=100\nMAX_RETRIES=3\nRETRY_DELAY=1000\n\n# Export Settings\nEXPORT_FORMAT=csv  # Options: csv, postgres, both\n\n# Provider Configuration\nPROVIDER=pikachu   # Options: pikachu, charmander\nPIKACHU_API_URL=https://example.com/api\nCHARMANDER_API_URL=https://example.com/api\n\n# Rate Limiting\nRATE_LIMIT_REQUESTS=10\nRATE_LIMIT_WINDOW_MS=1000\n\n# MCP Tools\nBRAVE_API_KEY=your_api_key_here' > .env
    @echo ".env template created successfully"