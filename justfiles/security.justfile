# Security Recipes
# This file contains security-related commands

# Load .env file if present
set dotenv-load

# Show available recipes
default:
    @just --list

# Show security commands help
help:
    @echo "======= Security Commands =======" 
    @echo ""
    @echo "Git Hooks:"
    @echo "  just setup-precommit      - Install basic pre-commit hooks"
    @echo "  just setup-hooks          - Install provider security hooks"
    @echo ""
    @echo "Provider Security:"
    @echo "  just provider             - Run provider commands"
    @echo "  just provider-help        - Show provider commands help"
    @echo ""

# Install pre-commit hooks using external script
setup-precommit:
    @echo "Setting up pre-commit hooks..."
    @./scripts/setup-hooks.sh

# Run hooks commands
hooks +ARGS:
    @just --justfile hooks.justfile {{ARGS}}

# Show hooks commands help
hooks-help:
    @just --justfile hooks.justfile help

# Setup provider security hooks (shortcut for hooks setup-provider)
setup-hooks:
    @just --justfile hooks.justfile setup-provider

# Shortcut for provider commands
provider +ARGS:
    @just --justfile provider.justfile {{ARGS}}

# Show provider commands help
provider-help:
    @just --justfile provider.justfile help