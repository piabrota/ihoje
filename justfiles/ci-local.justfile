# CI local testing
# A simpler version of CI justfile for local testing

# Show all recipes
default:
    @just --list

# Run a simplified CI check
ci:
    @echo "=== Running simplified CI check ==="
    
    # Run format check
    @echo "Checking formatting..."
    cd {{justfile_directory()}}/../sharingan && cargo fmt --check
    
    # Run clippy
    @echo "Running clippy lints..."
    cd {{justfile_directory()}}/../sharingan && cargo clippy --all-features
    
    # Build
    @echo "Building project..."
    cd {{justfile_directory()}}/../sharingan && cargo build --verbose
    
    # Run tests with environment variables set directly
    @echo "Running tests..."
    cd {{justfile_directory()}}/../sharingan && SKIP_ENV_TESTS=1 cargo test --verbose
    
    @echo "✅ All CI checks passed"