#!/bin/bash
# Script for launching Claude with micro context (~200 tokens)

if ! command -v claude &> /dev/null; then
    echo "Claude CLI not found. Install with 'pip install claude-cli'"
    exit 1
fi

# Prepare temporary context file
TEMP_CONTEXT=$(mktemp)

# Create bare minimum content (under 200 tokens)
{
    echo "# Quick Mode"
    echo "- Run: \`just run\`"
    echo "- Help: \`just help\`"
    echo "- Context: \`just dump-context\`"
    
    # Only include task name if exists
    if [ -f "docs/claude/core/cache.md" ]; then
        TASK=$(grep "task_name:" docs/claude/core/cache.md | head -1 | cut -d':' -f2- | xargs)
        [ "$TASK" != "none" ] && echo "- Task: $TASK"
    fi
    
    # Add minimalist note about Claude Code being an interactive shell
    echo "- Claude Code is an interactive shell - use 'exit' when done"
} > "$TEMP_CONTEXT"

# Show command preview
echo -e "\n===============================\nPreparing to launch Claude Code with micro context\n===============================\n"
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
echo "Start a new session with 'just claude-micro' when needed."