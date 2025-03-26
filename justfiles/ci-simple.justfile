# Simplified CI Commands Justfile

# Show all recipes
default:
    @just --list

# Run CI checks for Sharingan
ci-sharingan:
    @echo "=== Running Sharingan CI checks ==="
    cd {{justfile_directory()}}/../sharingan && cargo fmt --check
    cd {{justfile_directory()}}/../sharingan && cargo clippy --all-features -- -A clippy::manual_async_fn -A clippy::too_many_arguments
    cd {{justfile_directory()}}/../sharingan && RUSTFLAGS="" cargo build --verbose
    cd {{justfile_directory()}}/../sharingan && RUSTFLAGS="" SKIP_ENV_TESTS=1 cargo test --verbose
    @echo "✅ All Sharingan CI checks passed"

# Generic CI command that runs the Sharingan checks
ci:
    @echo "=== Running simplified CI check ==="
    @just --justfile {{justfile()}} ci-sharingan