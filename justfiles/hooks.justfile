# Security Hooks Recipes
# This file contains git hook setup commands

# Load .env file if present
set dotenv-load

# Show available recipes
default:
    @just --list

# Show hooks commands help
help:
    @echo "======= Security Hooks Commands =======" 
    @echo ""
    @echo "Git Hooks:"
    @echo "  just setup-precommit      - Install basic pre-commit hooks"
    @echo "  just setup-provider       - Install provider security hooks"

# Install pre-commit hooks
setup-precommit:
    @echo "Setting up pre-commit hooks..."
    @./scripts/setup-hooks.sh

# Setup provider security hooks and scripts
setup-provider:
    @echo "Setting up provider security hooks..."
    @./scripts/setup-provider-hooks.sh