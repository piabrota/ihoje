#!/bin/bash
# Script for launching Claude with domain-specific context

# Usage help
if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    echo "Usage: $0 [domain] [additional claude args]"
    echo "  domain: The specific domain context to load (sharingan, frontend, mangekyou)"
    echo "  If no domain is specified, will prompt for selection"
    exit 0
fi

# Check if Claude CLI is installed
if ! command -v claude &> /dev/null; then
    echo "Claude CLI not found. Install with 'pip install claude-cli'"
    exit 1
fi

# Determine domain
DOMAIN=""
if [ -n "$1" ] && [[ "$1" != -* ]]; then
    DOMAIN="$1"
    shift
else
    echo "Select domain context:"
    echo "1) sharingan - Event scraping and pattern recognition"
    echo "2) frontend - Yew/WASM frontend components"
    echo "3) mangekyou - Implementation planning"
    echo "4) all - Load all domains (higher token usage)"
    read -p "Enter selection [1-4]: " SELECTION
    
    case $SELECTION in
        1) DOMAIN="sharingan" ;;
        2) DOMAIN="frontend" ;;
        3) DOMAIN="mangekyou" ;;
        4) DOMAIN="all" ;;
        *) echo "Invalid selection"; exit 1 ;;
    esac
fi

# Validate domain
if [[ "$DOMAIN" != "sharingan" && "$DOMAIN" != "frontend" && "$DOMAIN" != "mangekyou" && "$DOMAIN" != "all" ]]; then
    echo "Invalid domain: $DOMAIN"
    echo "Valid domains: sharingan, frontend, mangekyou, all"
    exit 1
fi

# Prepare context file
TEMP_CONTEXT=$(mktemp)

# Start with bootstrap file
if [ -f "docs/claude/core/bootstrap.md" ]; then
    cat docs/claude/core/bootstrap.md > "$TEMP_CONTEXT"
else
    echo "# Bootstrap" > "$TEMP_CONTEXT"
    echo "- checkpoint_enabled: true" >> "$TEMP_CONTEXT"
    echo "- auto_resume: true" >> "$TEMP_CONTEXT"
fi

# Add domain-specific context
if [ "$DOMAIN" == "all" ]; then
    echo -e "\n## Sharingan Context" >> "$TEMP_CONTEXT"
    if [ -f "docs/claude/domain/sharingan.md" ]; then
        # Extract key sections but not the full file
        sed -n '/^## Core Concepts/,/^## Components/p' docs/claude/domain/sharingan.md >> "$TEMP_CONTEXT"
        sed -n '/^## Common Patterns/,/^## Code Examples/p' docs/claude/domain/sharingan.md >> "$TEMP_CONTEXT"
    fi
    
    echo -e "\n## Frontend Context" >> "$TEMP_CONTEXT"
    if [ -f "docs/claude/domain/tobira.md" ]; then
        # Extract key sections but not the full file
        sed -n '/^## Core Concepts/,/^## Components/p' docs/claude/domain/tobira.md >> "$TEMP_CONTEXT"
        sed -n '/^## Common Patterns/,/^## Code Examples/p' docs/claude/domain/tobira.md >> "$TEMP_CONTEXT"
    fi
    
    echo -e "\n## Mangekyou Context" >> "$TEMP_CONTEXT"
    if [ -f "docs/claude/domain/mangekyou.md" ]; then
        # Extract key sections but not the full file
        sed -n '/^## Core Concepts/,/^## Components/p' docs/claude/domain/mangekyou.md >> "$TEMP_CONTEXT"
        sed -n '/^## Common Patterns/,/^## Code Examples/p' docs/claude/domain/mangekyou.md >> "$TEMP_CONTEXT"
    fi
else
    # Map domain to file path
    case "$DOMAIN" in
        "sharingan") CONTEXT_FILE="docs/claude/domain/sharingan.md" ;;
        "frontend") CONTEXT_FILE="docs/claude/domain/tobira.md" ;;
        "mangekyou") CONTEXT_FILE="docs/claude/domain/mangekyou.md" ;;
        *) CONTEXT_FILE="" ;;
    esac
    
    if [ -f "$CONTEXT_FILE" ]; then
        cat "$CONTEXT_FILE" >> "$TEMP_CONTEXT"
    else
        echo "Warning: Domain context file $CONTEXT_FILE not found"
    fi
fi

# Add cache marker
echo -e "\n---CACHE---" >> "$TEMP_CONTEXT"

# If cache exists, add task info
if [ -f "docs/claude/core/cache.md" ]; then
    # Get current task name and description
    TASK_NAME=$(grep "task_name:" docs/claude/core/cache.md | head -1 | cut -d':' -f2- | xargs)
    grep "task_name:" docs/claude/core/cache.md | head -1 >> "$TEMP_CONTEXT"
    grep "task_description:" docs/claude/core/cache.md | head -1 >> "$TEMP_CONTEXT"
    
    # Add task progress if task exists
    if [ ! -z "$TASK_NAME" ] && [ "$TASK_NAME" != "none" ]; then
        echo -e "\n## Tasks" >> "$TEMP_CONTEXT"
        
        # Add task header
        grep -A1 "^### $TASK_NAME:" docs/claude/core/cache.md | head -1 >> "$TEMP_CONTEXT"
        
        # Add incomplete steps
        grep -A20 "^### $TASK_NAME:" docs/claude/core/cache.md | grep -E "\[ \]|\[!\]" | head -5 >> "$TEMP_CONTEXT"
        
        # Add last 3 completed steps
        grep -A20 "^### $TASK_NAME:" docs/claude/core/cache.md | grep "\[x\]" | head -3 >> "$TEMP_CONTEXT"
    fi
else
    # Add minimal info if no cache
    echo "- task_name: none" >> "$TEMP_CONTEXT"
    echo "- task_description: No task in progress" >> "$TEMP_CONTEXT"
fi

# Add note about Claude Code being an interactive shell
echo -e "\n## Claude Code Notes" >> "$TEMP_CONTEXT"
echo "- Claude Code is an interactive shell environment" >> "$TEMP_CONTEXT"
echo "- Always use 'exit' or 'quit' when finished to properly close the session" >> "$TEMP_CONTEXT"
echo "- Start a new Claude Code session explicitly when needed" >> "$TEMP_CONTEXT"

# Calculate approximate token count (rough estimate)
WORD_COUNT=$(wc -w < "$TEMP_CONTEXT")
TOKEN_ESTIMATE=$((WORD_COUNT * 4 / 3)) # Approximate tokens as 4/3 of word count

# Show command preview
echo -e "\n===============================\nPreparing to launch Claude Code with $DOMAIN context\n===============================\n"
echo "Domain: $DOMAIN"
echo "Estimated token count: ~$TOKEN_ESTIMATE tokens"
echo "Claude Code is an interactive shell environment."
echo "Use 'exit' or 'quit' when finished to properly close the session."
echo "You will need to restart Claude Code explicitly for a new session."
echo -e "\nPress Enter to continue or Ctrl+C to cancel..."
read -r

# Launch Claude with the context
cat "$TEMP_CONTEXT" | claude code "$@"

# Clean up
rm "$TEMP_CONTEXT"

echo -e "\n===============================\nClaude Code session ended\n===============================\n"
echo "The Claude Code session has closed."
echo "Start a new session with 'just claude-domain $DOMAIN' when needed."