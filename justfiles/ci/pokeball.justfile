# Pokeball CI checks
# Run the same checks as CI workflow

# Load .env file
set dotenv-load

# Show all recipes
default:
    @just --list

# Run all CI checks for Pokeball
ci:
    @echo "=== Running Pokeball CI checks ==="
    @just --justfile {{justfile()}} fmt
    @just --justfile {{justfile()}} clippy
    @just --justfile {{justfile()}} build
    @just --justfile {{justfile()}} test
    @echo "✅ All Pokeball CI checks passed"

# Check code formatting
fmt:
    @echo "Checking Pokeball code formatting..."
    cd {{justfile_directory()}}/../../pokeball && cargo fmt --check

# Run clippy lints
clippy:
    @echo "Running Pokeball clippy lints..."
    cd {{justfile_directory()}}/../../pokeball && cargo clippy --all-features

# Build the project
build:
    @echo "Building Pokeball..."
    cd {{justfile_directory()}}/../../pokeball && cargo build --verbose

# Run tests
test:
    @echo "Running Pokeball tests..."
    cd {{justfile_directory()}}/../../pokeball && cargo test --verbose