#!/bin/bash
# Script for launching Claude with minimal context (~500 tokens)

if ! command -v claude &> /dev/null; then
    echo "Claude CLI not found. Install with 'pip install claude-cli'"
    exit 1
fi

# Prepare temporary context file
TEMP_CONTEXT=$(mktemp)

# Create ultra-minimal bootstrap content
{
    echo "# Claude Bootstrap (Minimal)"
    echo ""
    echo "## Config"
    echo "- checkpoint_enabled: true"
    echo "- auto_resume: true"
    echo "- auto_proceed: true"
    echo ""
    echo "## Commands"
    echo "- \`just run\` - Run app"
    echo "- \`just dump-context\` - Show full context"
    echo "- \`just help\` - Show help"
    echo ""
    echo "---CACHE---"
    
    # Include only active task if it exists
    if [ -f "docs/claude/core/cache.md" ]; then
        TASK_NAME=$(grep "task_name:" docs/claude/core/cache.md | head -1 | cut -d':' -f2- | xargs)
        if [ ! -z "$TASK_NAME" ] && [ "$TASK_NAME" != "none" ]; then
            grep "task_name:" docs/claude/core/cache.md | head -1
            grep "task_description:" docs/claude/core/cache.md | head -1
            echo ""
            echo "## Active Task"
            awk '/^### '"$TASK_NAME"':/{print; exit}' docs/claude/core/cache.md
            # Only first incomplete step
            awk '/^### '"$TASK_NAME"':/{in_task=1; next} /^###/{in_task=0} in_task && (/\[ \]/ || /\[!\]/)' docs/claude/core/cache.md | head -1
        else
            echo "- task_name: none"
            echo "- task_description: No task in progress"
        fi
    else
        echo "- task_name: none" 
        echo "- task_description: No task in progress"
    fi
    
    # Add note about Claude Code being an interactive shell
    echo ""
    echo "## Claude Code Notes"
    echo "- Claude Code is an interactive shell environment"
    echo "- Always use 'exit' or 'quit' when finished to properly close the session"
    echo "- Start a new Claude Code session explicitly when needed"
} > "$TEMP_CONTEXT"

# Show command preview
echo -e "\n===============================\nPreparing to launch Claude Code with minimal context\n===============================\n"
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
echo "Start a new session with 'just claude-minimal' when needed."