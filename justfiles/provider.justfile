# Provider Security Recipes
# This file contains provider-specific security commands

# Load .env file if present
set dotenv-load

# Show available recipes
default:
    @just --list

# Show provider commands help
help:
    @echo "======= Provider Security Commands =======" 
    @echo ""
    @echo "Provider Management:"
    @echo "  just scrub                - Remove provider URLs from code"
    @echo "  just help                 - Show provider security help"
    @echo "  just anonymize-logs       - Anonymize provider names in logs"
    @echo ""
    @echo "Running Providers:"
    @echo "  just run PROVIDER         - Run with specific provider"

# Remove all provider name references from codebase using external script
scrub:
    @echo "Scrubbing provider references from codebase..."
    @sh ../scripts/scrub-providers.sh
    
# One-time anonymization tool for scrubbing log files
anonymize-logs:
    #!/usr/bin/env bash
    echo "Anonymizing provider references in log files..."
    find . -type f -name "*.log" -o -name "*.csv" -o -name "*.html" | xargs grep -l "sympla\|shotgun" | xargs sed -i 's/sympla/provider1/g; s/Sympla/Provider1/g; s/SYMPLA/PROVIDER1/g; s/shotgun/provider2/g; s/Shotgun/Provider2/g; s/SHOTGUN/PROVIDER2/g'
    echo "Log files anonymized"

# Run with specific provider (pikachu or charmander)
run provider="pikachu":
    PROVIDER={{provider}} cargo run

# Show provider security help
info:
    @echo "======= Provider Security System =======" 
    @echo ""
    @echo "Provider Security System:"
    @echo "  just security setup-hooks   - Install provider security hooks"
    @echo "  just provider scrub         - Remove provider URLs and names from code"
    @echo "  just provider run pikachu   - Run with Pikachu provider"
    @echo "  just provider run charmander - Run with Charmander provider"
    @echo ""
    @echo "Provider Codenames:"
    @echo "  Pikachu = Provider 1"
    @echo "  Charmander = Provider 2"
    @echo ""
    @echo "Security Guidelines:"
    @echo "  1. Never commit provider URLs in source code"
    @echo "  2. Use codenames instead of actual provider names"
    @echo "  3. Keep provider URLs in .env only (not versioned)"
    @echo "  4. Run 'just provider scrub' before committing changes"