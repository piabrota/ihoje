# CI Environment Setup Justfile
# Provides centralized environment setup for CI workflows

# Define environment variables
cargo_term_color := "always"
rustflags := "--deny=warnings"
skip_env_tests := "1"
test_db_url := "postgresql://postgres:postgres@localhost:5432/ihoje_test"
test_api_key := "ci_test_key"
test_city := "FL"
test_provider := "pikachu"
test_start_date := "2025-04-01"
test_end_date := "2025-04-30"

# Set default environment variables for CI
setup-env:
    #!/usr/bin/env bash
    # Export environment variables needed for tests
    export CARGO_TERM_COLOR={{cargo_term_color}}
    export RUSTFLAGS={{rustflags}}
    export SKIP_ENV_TESTS={{skip_env_tests}}
    
    # Set test database credentials
    export TEST_DB_URL={{test_db_url}}
    
    # Set test API credentials
    export TEST_API_KEY={{test_api_key}}
    export TEST_CITY={{test_city}}
    export TEST_PROVIDER={{test_provider}}
    
    # Set dates for date range tests  
    export TEST_START_DATE={{test_start_date}}
    export TEST_END_DATE={{test_end_date}}
    
    # Create a temporary .env file if it doesn't exist
    if [ ! -f .env ]; then
        echo "Creating temporary .env file for testing"
        echo "CARGO_TERM_COLOR={{cargo_term_color}}" > .env
        echo 'RUSTFLAGS="--deny=warnings"' >> .env
        echo "SKIP_ENV_TESTS={{skip_env_tests}}" >> .env
        echo "TEST_DB_URL={{test_db_url}}" >> .env
        echo "TEST_API_KEY={{test_api_key}}" >> .env
        echo "TEST_CITY={{test_city}}" >> .env
        echo "TEST_PROVIDER={{test_provider}}" >> .env
        echo "TEST_START_DATE={{test_start_date}}" >> .env
        echo "TEST_END_DATE={{test_end_date}}" >> .env
    fi
    
    echo "✅ Environment variables set for CI"

# Install Rust tools
setup-rust:
    #!/usr/bin/env bash
    # Check if we're in a Nix environment
    if [[ -n "$IN_NIX_SHELL" || -n "$NIX_PATH" ]]; then
        echo "Detected Nix environment, skipping Rust installation."
        echo "Required tools: rustup, clippy, rustfmt, wasm32 target, wasm-bindgen, trunk"
        echo "Make sure these are available in your Nix shell."
        
        # Verify required tools are available
        if ! command -v rustc > /dev/null; then
            echo "Warning: rustc not found in PATH"
        else
            echo "Found rustc: $(rustc --version)"
        fi
        
        if ! command -v wasm-bindgen > /dev/null; then
            echo "Warning: wasm-bindgen not found in PATH"
        else
            echo "Found wasm-bindgen: $(wasm-bindgen --version)"
        fi
        
        if ! command -v trunk > /dev/null; then
            echo "Warning: trunk not found in PATH"
        else
            echo "Found trunk: $(trunk --version)"
        fi
    else
        # Check if rustup is available
        if ! command -v rustup > /dev/null; then
            echo "Installing Rust..."
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
            source $HOME/.cargo/env
        fi
        
        # Install Rust components
        rustup component add clippy rustfmt
        
        # Install wasm target
        rustup target add wasm32-unknown-unknown
        
        # Install wasm tools
        if ! command -v wasm-bindgen > /dev/null; then
            echo "Installing wasm-bindgen-cli..."
            cargo install wasm-bindgen-cli
        fi
        
        if ! command -v trunk > /dev/null; then
            echo "Installing trunk..."
            cargo install trunk
        fi
    fi
    
    echo "✅ Rust tools installed"

# Install Python tools
setup-python:
    #!/usr/bin/env bash
    # Check if pip is available
    if ! command -v pip > /dev/null; then
        echo "Error: pip not found. Please install Python."
        exit 1
    fi
    
    # Check if we're in a Nix environment
    if [[ -n "$IN_NIX_SHELL" || -n "$NIX_PATH" ]]; then
        echo "Detected Nix environment, skipping Python package installation."
        echo "Required packages: pytest, pytest-cov, ruff, build, twine"
        echo "Use nix-shell with these packages if needed."
    else
        # Install Python packages
        pip install pytest pytest-cov ruff build twine
    fi
    
    echo "✅ Python tools installed"

# Install Scala tools
setup-scala:
    #!/usr/bin/env bash
    # Check if scala-cli is available
    if ! command -v scala-cli > /dev/null; then
        echo "Installing scala-cli..."
        if command -v brew > /dev/null; then
            brew install scala-cli
        elif command -v curl > /dev/null; then
            curl -sSLf https://scala-cli.virtuslab.org/get | sh
            export PATH="$HOME/.local/share/scala-cli/bin:$PATH"
        else
            echo "Error: Cannot install scala-cli. Please install manually."
            exit 1
        fi
    fi
    
    echo "✅ Scala tools installed"

# Setup PostgreSQL for testing
setup-postgres:
    #!/usr/bin/env bash
    # Check if docker is available
    if ! command -v docker > /dev/null; then
        echo "Error: Docker not found. Please install Docker."
        exit 1
    fi
    
    # Start PostgreSQL container if not running
    if ! docker ps | grep -q postgres; then
        echo "Starting PostgreSQL container..."
        docker run --name postgres-ihoje -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=ihoje_test -p 5432:5432 -d postgres:14
        
        # Wait for PostgreSQL to start
        echo "Waiting for PostgreSQL to start..."
        sleep 5
        
        # Initialize schema
        if [ -f db/postgres/schema.sql ]; then
            echo "Initializing database schema..."
            docker exec -i postgres-ihoje psql -U postgres -d ihoje_test < db/postgres/schema.sql
        fi
    fi
    
    echo "✅ PostgreSQL setup complete"

# Setup all environments for CI
setup-all:
    @just --justfile {{justfile()}} setup-env
    @just --justfile {{justfile()}} setup-rust
    @just --justfile {{justfile()}} setup-python
    @just --justfile {{justfile()}} setup-scala