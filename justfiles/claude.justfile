# Claude Interaction Recipes
# This file contains Claude-specific commands

# Load .env file if present
set dotenv-load

# Show available recipes
default:
    @just --list

# Show Claude commands help
help:
    @echo "======= Claude Commands =======" 
    @echo ""
    @echo "Claude Interaction:"
    @echo "  just claude               - Standard Claude context (~1000 tokens)"
    @echo "  just claude-minimal       - Minimal Claude context (~500 tokens)"
    @echo "  just claude-micro         - Ultra-minimal context (~200 tokens)"
    @echo "  just dump-context         - Show all context files"
    @echo ""
    @echo "Context Management:"
    @echo "  just write OUTPUT         - Write context to file"
    @echo "  just reset                - Reset Claude bootstrap files"

# Open Claude Code with standard context (~1000 tokens)
claude *ARGS:
    @echo "Launching Claude with standard context..."
    @sh ../scripts/claude-standard.sh {{ARGS}}

# Open Claude with minimal context (~500 tokens)
claude-minimal *ARGS:
    @echo "Launching Claude with minimal context..."
    @sh ../scripts/claude-minimal.sh {{ARGS}}

# Open Claude with micro context (~200 tokens)
claude-micro *ARGS:
    @echo "Launching Claude with micro context..."
    @sh ../scripts/claude-micro.sh {{ARGS}}

# Dump context files to console
dump-context:
    @echo "========== README.md ==========" 
    @cat README.md
    @echo ""
    @echo "========== CLAUDE.md ==========" 
    @cat CLAUDE.md
    @echo ""
    @echo "========== CLAUDE_BOOTSTRAP.md ==========" 
    @cat CLAUDE_BOOTSTRAP.md

# Write context files to a single output file
write output="context.md":
    #!/usr/bin/env bash
    echo "Writing context files to {{output}}..."
    
    # Create header and write files with section markers
    {
        echo "# Project Context"
        echo ""
        echo "## README.md"
        echo "```markdown"
        cat README.md
        echo "```"
        echo ""
        echo "## CLAUDE.md"
        echo "```markdown"
        cat CLAUDE.md
        echo "```"
        echo ""
        echo "## CLAUDE_BOOTSTRAP.md"
        echo "```markdown"
        cat CLAUDE_BOOTSTRAP.md
        echo "```"
    } > {{output}}
    
    echo "Context written to {{output}}"

# Reset Claude files
reset:
    #!/usr/bin/env bash
    # Create bootstrap if missing
    if [ ! -f "CLAUDE_BOOTSTRAP.md" ]; then
        echo "Creating minimal bootstrap."
        echo -e "# Claude Bootstrap\n\n## Config\n- checkpoint_enabled: true\n- auto_resume: true\n- auto_proceed: true" > CLAUDE_BOOTSTRAP.md
    fi
    
    # Reset cache from template or create minimal one
    if [ -f "CLAUDE_CACHE_TEMPLATE.md" ]; then
        cp CLAUDE_CACHE_TEMPLATE.md CLAUDE_CACHE.md
    else
        echo -e "# Cache\n\n- task_name: none\n- task_description: No task in progress\n\n## Tasks" > CLAUDE_CACHE.md
    fi
    
    echo "Files reset to minimal state"