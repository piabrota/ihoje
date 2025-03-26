# Tobira CI checks
# Run the same checks as CI workflow

# Load .env file
set dotenv-load

# Show all recipes
default:
    @just --list

# Run all CI checks for Tobira
ci:
    @echo "=== Running Tobira CI checks ==="
    @just --justfile {{justfile()}} fmt
    @just --justfile {{justfile()}} clippy
    @just --justfile {{justfile()}} build
    @just --justfile {{justfile()}} test
    @echo "✅ All Tobira CI checks passed"

# Check code formatting
fmt:
    @echo "Checking Tobira code formatting..."
    cd {{justfile_directory()}}/../../tobira && cargo fmt --check

# Run clippy lints
clippy:
    @echo "Running Tobira clippy lints..."
    #!/usr/bin/env bash
    # Check if wasm32 target is installed
    if ! rustup target list | grep "wasm32-unknown-unknown (installed)" > /dev/null; then
        echo "Installing wasm32-unknown-unknown target..."
        rustup target add wasm32-unknown-unknown
    fi
    cd {{justfile_directory()}}/../../tobira && cargo clippy --target wasm32-unknown-unknown
    echo "✅ Clippy completed"

# Build the project
build:
    @echo "Building Tobira..."
    #!/usr/bin/env bash
    # Check if wasm32 target is installed
    if ! rustup target list | grep "wasm32-unknown-unknown (installed)" > /dev/null; then
        echo "Installing wasm32-unknown-unknown target..."
        rustup target add wasm32-unknown-unknown
    fi
    
    # Check if trunk is available
    if ! command -v trunk > /dev/null; then
        echo "Installing trunk..."
        cargo install trunk
    fi
    
    # Check if wasm-bindgen-cli is available
    if ! command -v wasm-bindgen > /dev/null; then
        echo "Installing wasm-bindgen-cli..."
        cargo install wasm-bindgen-cli
    fi
    
    cd {{justfile_directory()}}/../../tobira && cargo build --target wasm32-unknown-unknown
    echo "✅ Build completed"

# Run tests
test:
    @echo "Running Tobira tests..."
    #!/usr/bin/env bash
    # Check if wasm32 target is installed
    if ! rustup target list | grep "wasm32-unknown-unknown (installed)" > /dev/null; then
        echo "Installing wasm32-unknown-unknown target..."
        rustup target add wasm32-unknown-unknown
    fi
    cd {{justfile_directory()}}/../../tobira && cargo test --target wasm32-unknown-unknown
    echo "✅ Tests completed"