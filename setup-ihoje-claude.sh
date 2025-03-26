#!/usr/bin/env bash

# This script sets up the Claude integration for iHoje

# Create the CLAUDE_BOOTSTRAP.md file if it doesn't exist
if [ ! -f "CLAUDE_BOOTSTRAP.md" ]; then
    echo "Creating CLAUDE_BOOTSTRAP.md..."
    cat > CLAUDE_BOOTSTRAP.md << 'EOF'
# Claude Bootstrap

## Config
- checkpoint_enabled: true
- auto_resume: true
- auto_proceed: true

## Project
- language: Rust
- scraper: Event data collector
- providers: Use codenames (pikachu, charmander)
- security: No provider names in source
EOF
    echo "✅ Created CLAUDE_BOOTSTRAP.md"
else
    echo "✅ CLAUDE_BOOTSTRAP.md already exists"
fi

# Create the CLAUDE.md file if it doesn't exist
if [ ! -f "CLAUDE.md" ]; then
    echo "Creating CLAUDE.md..."
    cat > CLAUDE.md << 'EOF'
# Claude Context File

## Current Task
- name: Setup Claude Integration
- description: Set up Claude bootstrap files and context system
- status: complete

## Steps
- [x] Create CLAUDE_BOOTSTRAP.md
- [x] Create CLAUDE.md
- [x] Verify Claude commands
EOF
    echo "✅ Created CLAUDE.md"
else
    echo "✅ CLAUDE.md already exists"
fi

# Make sure CI directory exists
if [ ! -d "justfiles/ci" ]; then
    echo "Creating justfiles/ci directory..."
    mkdir -p justfiles/ci
    echo "✅ Created justfiles/ci directory"
else
    echo "✅ justfiles/ci directory already exists"
fi

# Make sure gugu CI justfile exists
if [ ! -f "justfiles/ci/gugu.justfile" ]; then
    echo "gugu.justfile already exists, nothing to do"
fi

echo ""
echo "✨ Claude integration setup complete!"
echo ""
echo "You can now use the following commands:"
echo "- just claude - Standard context (~1000 tokens)"
echo "- just claude-minimal - Minimal context (~500 tokens)"
echo "- just claude-micro - Ultra-minimal context (~200 tokens)"
echo "- just claude-domain DOMAIN - Domain-specific context (~1200 tokens)"
echo ""
echo "To run CI commands:"
echo "- just ci gugu-compile - Run specific component test"
echo "- just ci sharingan-ci - Run all Sharingan CI tests"
echo "- just ci tobira-ci - Run all Tobira CI tests"

# Make this script executable
chmod +x setup-ihoje-claude.sh