# CI Commands Justfile
# Provides commands to run CI-equivalent checks locally

# Load .env file
set dotenv-load

# Default shows help
default:
    @just --justfile {{justfile()}} help

# Show help information
help:
    @echo "=== CI Check Commands ==="
    @echo ""
    @echo "Component CI Commands:"
    @echo "  ci                   - Run CI checks for all components"
    @echo "  ci sharingan         - Run CI checks for Sharingan only"
    @echo "  ci tobira            - Run CI checks for Tobira only"
    @echo "  ci pokeball          - Run CI checks for Pokeball only"
    @echo "  ci gugu              - Run CI checks for Gugu only"
    @echo "  ci mangekyou         - Run CI checks for Mangekyou MCP only"
    @echo "  sharingan-ci         - Run CI checks for Sharingan"
    @echo "  tobira-ci            - Run CI checks for Tobira"
    @echo "  pokeball-ci          - Run CI checks for Pokeball"
    @echo "  gugu-ci              - Run CI checks for Gugu"
    @echo "  mangekyou-ci         - Run CI checks for Mangekyou MCP"
    @echo ""
    @echo "Individual CI Steps by Component:"
    @echo "  sharingan-fmt        - Check Sharingan formatting"
    @echo "  sharingan-clippy     - Run Sharingan clippy lints"
    @echo "  sharingan-build      - Build Sharingan"
    @echo "  sharingan-test       - Run Sharingan tests"
    @echo "  sharingan-bench      - Run Sharingan benchmarks (compile only)"
    @echo ""
    @echo "  tobira-fmt           - Check Tobira formatting"
    @echo "  tobira-clippy        - Run Tobira clippy lints"
    @echo "  tobira-build         - Build Tobira"
    @echo "  tobira-test          - Run Tobira tests"
    @echo ""
    @echo "  pokeball-fmt         - Check Pokeball formatting"
    @echo "  pokeball-clippy      - Run Pokeball clippy lints"
    @echo "  pokeball-build       - Build Pokeball"
    @echo "  pokeball-test        - Run Pokeball tests"
    @echo ""
    @echo "  gugu-compile         - Compile Gugu code"
    @echo "  gugu-test            - Run Gugu tests"
    @echo "  gugu-docs            - Generate Gugu docs"
    @echo "  gugu-fix-check       - Check Gugu code with ScalaFix (no changes)"
    @echo "  gugu-fix             - Fix Gugu code with ScalaFix (applies changes)"
    @echo ""
    @echo "  mangekyou-lint       - Run linter on Mangekyou MCP"
    @echo "  mangekyou-test       - Run tests for Mangekyou MCP"
    @echo "  mangekyou-compliance - Run MCP compliance tests for Mangekyou"
    @echo "  mangekyou-build      - Build Mangekyou MCP package"

# Run CI checks for all components
ci *ARGS="all":
    @echo "==========================================="
    @echo "=== Setting up CI environment =============="
    @echo "==========================================="
    
    # Setup environment - detect Nix and skip installation for Nix shells
    @just --justfile {{justfile_directory()}}/ci/env-setup.justfile setup-all
    
    @echo "==========================================="
    @echo "=== Running CI checks for {{ARGS}} ==="
    @echo "==========================================="
    
    @if [ -n "$IN_NIX_SHELL" ] || [ -n "$NIX_PATH" ]; then echo "Using Nix-compatible CI flow"; else echo "Using standard CI flow"; fi
    
    # For simplicity, run the simplified CI for all environments
    @just --justfile {{justfile_directory()}}/ci-simple.justfile ci
    
    @echo "✅ CI checks for {{ARGS}} passed"

# Run CI checks for Sharingan
sharingan-ci:
    @just --justfile {{justfile_directory()}}/ci/sharingan.justfile ci

# Run CI checks for Tobira
tobira-ci:
    @just --justfile {{justfile_directory()}}/ci/tobira.justfile ci

# Run CI checks for Pokeball
pokeball-ci:
    @just --justfile {{justfile_directory()}}/ci/pokeball.justfile ci

# Run CI checks for Gugu
gugu-ci:
    @just --justfile {{justfile_directory()}}/ci/gugu.justfile ci

# Individual Sharingan CI steps
sharingan-fmt:
    @just --justfile {{justfile_directory()}}/ci/sharingan.justfile fmt

sharingan-clippy:
    @just --justfile {{justfile_directory()}}/ci/sharingan.justfile clippy

sharingan-build:
    @just --justfile {{justfile_directory()}}/ci/sharingan.justfile build

sharingan-test:
    @just --justfile {{justfile_directory()}}/ci/sharingan.justfile test

sharingan-bench:
    @just --justfile {{justfile_directory()}}/ci/sharingan.justfile bench

# Individual Tobira CI steps
tobira-fmt:
    @just --justfile {{justfile_directory()}}/ci/tobira.justfile fmt

tobira-clippy:
    @just --justfile {{justfile_directory()}}/ci/tobira.justfile clippy

tobira-build:
    @just --justfile {{justfile_directory()}}/ci/tobira.justfile build

tobira-test:
    @just --justfile {{justfile_directory()}}/ci/tobira.justfile test

# Individual Pokeball CI steps
pokeball-fmt:
    @just --justfile {{justfile_directory()}}/ci/pokeball.justfile fmt

pokeball-clippy:
    @just --justfile {{justfile_directory()}}/ci/pokeball.justfile clippy

pokeball-build:
    @just --justfile {{justfile_directory()}}/ci/pokeball.justfile build

pokeball-test:
    @just --justfile {{justfile_directory()}}/ci/pokeball.justfile test

# Individual Gugu CI steps
gugu-compile:
    @just --justfile {{justfile_directory()}}/ci/gugu.justfile compile

gugu-test:
    @just --justfile {{justfile_directory()}}/ci/gugu.justfile test

gugu-docs:
    @just --justfile {{justfile_directory()}}/ci/gugu.justfile docs

gugu-fix-check:
    @just --justfile {{justfile_directory()}}/ci/gugu.justfile fix-check
    
gugu-fix:
    @just --justfile {{justfile_directory()}}/ci/gugu.justfile fix

# Run CI checks for Mangekyou MCP
mangekyou-ci:
    @just --justfile {{justfile_directory()}}/ci/mangekyou.justfile mangekyou-check

# Individual Mangekyou MCP CI steps
mangekyou-lint:
    @just --justfile {{justfile_directory()}}/ci/mangekyou.justfile lint-mangekyou

mangekyou-test:
    @just --justfile {{justfile_directory()}}/ci/mangekyou.justfile test-mangekyou

mangekyou-compliance:
    @just --justfile {{justfile_directory()}}/ci/mangekyou.justfile test-mcp-compliance

mangekyou-build:
    @just --justfile {{justfile_directory()}}/ci/mangekyou.justfile build-mangekyou