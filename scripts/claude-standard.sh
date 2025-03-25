#!/bin/bash
# Script for launching Claude with standard context (~1000 tokens)

# Check if Claude CLI is installed
if ! command -v claude &> /dev/null; then
    echo "Claude CLI not found. Install with 'pip install claude-cli'"
    exit 1
fi

# Prepare context file
TEMP_CONTEXT=$(mktemp)

# Start with bootstrap file if exists
if [ -f "docs/claude/core/bootstrap.md" ]; then
    cat docs/claude/core/bootstrap.md > "$TEMP_CONTEXT"
    echo -e "\n---CACHE---" >> "$TEMP_CONTEXT"
else
    echo "# Bootstrap" > "$TEMP_CONTEXT"
    echo "- checkpoint_enabled: true" >> "$TEMP_CONTEXT"
    echo "- auto_resume: true" >> "$TEMP_CONTEXT"
    echo -e "\n---CACHE---" >> "$TEMP_CONTEXT"
fi

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

# Show command preview
echo -e "\n===============================\nPreparing to launch Claude Code with context\n===============================\n"
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
echo "Start a new session with 'just claude' when needed."