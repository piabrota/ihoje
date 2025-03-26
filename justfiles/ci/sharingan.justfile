# Sharingan CI checks
# Run the same checks as CI workflow

# Load .env file
set dotenv-load

# Show all recipes
default:
    @just --list

# Run all CI checks for Sharingan
ci:
    @echo "=== Running Sharingan CI checks ==="
    @just --justfile {{justfile()}} fmt
    @just --justfile {{justfile()}} clippy
    @just --justfile {{justfile()}} build
    @just --justfile {{justfile()}} test
    @just --justfile {{justfile()}} bench
    @echo "✅ All Sharingan CI checks passed"

# Check code formatting
fmt:
    @echo "Checking Sharingan code formatting..."
    cd {{justfile_directory()}}/../../sharingan && cargo fmt --check

# Run clippy lints
clippy:
    @echo "Running Sharingan clippy lints..."
    cd {{justfile_directory()}}/../../sharingan && cargo clippy --all-features

# Build the project
build:
    @echo "Building Sharingan..."
    cd {{justfile_directory()}}/../../sharingan && cargo build --verbose

# Run tests
test:
    @echo "Running Sharingan tests..."
    @echo "Skipping tests that require environment variables in CI"
    cd {{justfile_directory()}}/../../sharingan && SKIP_ENV_TESTS=1 cargo test --verbose

# Run benchmarks (compile only)
bench:
    @echo "Compiling Sharingan benchmarks..."
    cd {{justfile_directory()}}/../../sharingan && cargo build --benches
    @echo "✅ Benchmark compilation completed"