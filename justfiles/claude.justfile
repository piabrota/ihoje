# Claude Commands
# Optimized for token usage

# Load environment
set dotenv-load

# Constants
CRITICAL_FILE := "../docs/claude/core/critical.md"
BOOTSTRAP_FILE := "../docs/claude/core/bootstrap.md"
README_FILE := "../README.md"
GUIDELINES_FILE := "../docs/claude/core/guidelines.md"
CACHE_FILE := "../docs/claude/core/cache.md"
CACHE_TEMPLATE := "../docs/claude/templates/cache_template.md"

# Show available commands
default:
    @just --list

# Show help
help:
    @echo "=== Claude Commands ==="
    @echo "Core:"
    @echo "  claude               - Standard context (~1000 tokens)"
    @echo "  claude-minimal       - Minimal context (~500 tokens)"
    @echo "  claude-micro         - Ultra-minimal context (~200 tokens)"
    @echo "  claude-critical      - Critical mode with high priority"
    @echo "Domain-specific:"
    @echo "  claude-domain DOMAIN - Domain-specific context (sharingan, frontend, mangekyou)"
    @echo "Context:"
    @echo "  dump-context         - Show all context files"
    @echo "  write OUTPUT         - Write context to file"
    @echo "  reset                - Reset Claude bootstrap files"
    @echo "  token-usage          - Analyze token usage of context files"
    @echo "Improvement:"
    @echo "  improve-just         - Apply justfile best practices"
    @echo "  improve-rust         - Apply Rust best practices"
    @echo "  improve-python       - Apply Python best practices"

# Standard context (~1000 tokens)
claude:
    #!/usr/bin/env bash
    cd ..
    if [ -f "docs/claude/core/critical.md" ]; then
        (echo "# CRITICAL MODE"; cat docs/claude/core/critical.md docs/claude/core/bootstrap.md) | claude code
    else
        cat docs/claude/core/bootstrap.md README.md docs/claude/core/guidelines.md | claude code
    fi

# Minimal context (~500 tokens)
claude-minimal *ARGS="":
    @cd .. && cat docs/claude/core/bootstrap.md | claude code {{ARGS}}

# Micro context (~200 tokens)
claude-micro *ARGS="":
    @cd .. && bash scripts/claude-micro.sh {{ARGS}}

# Domain-specific context
claude-domain DOMAIN="sharingan" *ARGS="":
    @cd .. && bash scripts/claude-domain.sh {{DOMAIN}} {{ARGS}}

# Critical mode
claude-critical *ARGS="":
    #!/usr/bin/env bash
    cd ..
    if [ -f "docs/claude/core/critical.md" ]; then
        (echo "# CRITICAL MODE"; cat docs/claude/core/critical.md docs/claude/core/bootstrap.md) | claude code {{ARGS}}
    else
        cat docs/claude/core/bootstrap.md README.md docs/claude/core/guidelines.md | claude code {{ARGS}}
    fi

# Dump context
dump-context:
    @echo "========== README.md ==========" 
    @cat ../README.md
    @echo "\n========== guidelines.md ==========" 
    @cat ../docs/claude/core/guidelines.md
    @echo "\n========== bootstrap.md ==========" 
    @cat ../docs/claude/core/bootstrap.md
    @if [ -f "../docs/claude/core/critical.md" ]; then \
        echo "\n========== critical.md =========="; \
        cat ../docs/claude/core/critical.md; \
    fi
    @echo "\n========== sharingan.md ==========" 
    @cat ../docs/claude/domain/sharingan.md
    @echo "\n========== tobira.md ==========" 
    @cat ../docs/claude/domain/tobira.md
    @echo "\n========== mangekyou.md ==========" 
    @cat ../docs/claude/domain/mangekyou.md

# Write context to file
write output="context.md":
    #!/usr/bin/env bash
    cd ..
    {
        echo "# Project Context"
        echo ""
        
        # Check for critical file first
        if [ -f "docs/claude/core/critical.md" ]; then
            echo "## ⚠️ Critical Issue"
            echo "```markdown"
            cat docs/claude/core/critical.md
            echo "```"
            echo ""
        fi
        
        echo "## README.md"
        echo "```markdown"
        cat README.md
        echo "```"
        echo ""
        echo "## Guidelines"
        echo "```markdown"
        cat docs/claude/core/guidelines.md
        echo "```"
        echo ""
        echo "## Bootstrap"
        echo "```markdown"
        cat docs/claude/core/bootstrap.md
        echo "```"
        echo ""
        
        # Add domain-specific context files
        echo "## Sharingan"
        echo "```markdown"
        cat docs/claude/domain/sharingan.md
        echo "```"
        echo ""
        
        echo "## Tobira"
        echo "```markdown"
        cat docs/claude/domain/tobira.md
        echo "```"
        echo ""
        
        echo "## Mangekyou"
        echo "```markdown"
        cat docs/claude/domain/mangekyou.md
        echo "```"
        echo ""
    } > {{output}}
    
    echo "Context written to {{output}}"

# Reset Claude files
reset:
    #!/usr/bin/env bash
    cd ..
    # Create bootstrap if missing
    if [ ! -f "docs/claude/core/bootstrap.md" ]; then
        echo "Creating minimal bootstrap."
        mkdir -p docs/claude/core
        echo -e "# Claude Bootstrap\n\n## Config\n- checkpoint_enabled: true\n- auto_resume: true\n- auto_proceed: true" > docs/claude/core/bootstrap.md
    fi
    
    # Reset cache from template or create minimal one
    if [ -f "docs/claude/templates/cache_template.md" ]; then
        cp docs/claude/templates/cache_template.md docs/claude/core/cache.md
    else
        mkdir -p docs/claude/core
        echo -e "# Cache\n\n- task_name: none\n- task_description: No task in progress\n\n## Tasks" > docs/claude/core/cache.md
    fi
    
    echo "Files reset to minimal state"

# Find and apply justfile best practices
improve-just:
    @cd .. && bash scripts/improve-justfiles.sh

# Find and apply Rust best practices
improve-rust:
    #!/usr/bin/env bash
    cd .. && bash scripts/improve-rust.sh
    
    # Final compilation step
    cargo check && cargo build
    
    if [ $? -eq 0 ]; then
        echo "✅ Compilation successful"
    else
        echo "❌ Compilation failed"
        exit 1
    fi

# Find and apply Python best practices
improve-python:
    #!/usr/bin/env bash
    cd .. && bash scripts/improve-python.sh
    
    # Check if python is available
    if command -v python3 >/dev/null 2>&1; then
        echo "Running Python syntax check..."
        find scripts -name "*.py" -type f -exec python3 -m py_compile {} \; 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo "✅ Python syntax check successful"
        else
            echo "❌ Python syntax check failed"
            exit 1
        fi
    else
        echo "⚠️ Python validation skipped"
    fi

# Create improvement plan
plan-improvement task description:
    @cd .. && bash scripts/improve-plan.sh "{{task}}" "{{description}}"

# Analyze token usage
token-usage *FILES="":
    @cd .. && bash scripts/claude-token-tracker.sh {{FILES}}