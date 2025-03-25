# Task Management
# Optimized for token usage

# Load .env file
set dotenv-load

# Show available recipes
default:
    @just --list

# Show help
help:
    @echo "=== Task Management ==="
    @echo "Tasks:"
    @echo "  add NAME DESC        - Add new task"
    @echo "  complete TASK STEP   - Mark step complete"
    @echo "  fail TASK STEP ERR   - Mark step failed"
    @echo "  show                 - Show progress"
    @echo "Cache:"
    @echo "  init                 - Init cache template"
    @echo "  clean                - Clean but keep task"
    @echo "  history              - Show cmd history"

# Initialize cache
init:
    #!/usr/bin/env bash
    if [ ! -f "docs/claude/templates/cache_template.md" ]; then
        echo "Creating minimal template."
        mkdir -p docs/claude/templates
        echo -e "# Cache\n\n- task_name: none\n- task_description: No task in progress" > docs/claude/templates/cache_template.md
    fi
    
    mkdir -p docs/claude/core
    cp docs/claude/templates/cache_template.md docs/claude/core/cache.md

# Add task
add task_name task_description:
    #!/usr/bin/env bash
    # Init if needed
    [ ! -f "docs/claude/core/cache.md" ] && just init > /dev/null
    
    # Update metadata
    sed -i "s/- task_name:.*$/- task_name: {{task_name}}/" docs/claude/core/cache.md
    sed -i "s/- task_description:.*$/- task_description: {{task_description}}/" docs/claude/core/cache.md
    
    # Add Tasks section if missing
    grep -q "^## Tasks" docs/claude/core/cache.md || echo -e "\n## Tasks" >> docs/claude/core/cache.md
    
    # Add task if new
    if ! grep -q "^### {{task_name}}:" docs/claude/core/cache.md; then
        TS=$(date -Iseconds)
        sed -i "/^## Tasks/a\\n### {{task_name}}: {{task_description}}\n- [x] Task started - $TS\n" docs/claude/core/cache.md
    fi

# Mark step complete
complete task_name step_description info="":
    #!/usr/bin/env bash
    # Verify cache
    [ ! -f "docs/claude/core/cache.md" ] && echo "Run 'just task init' first." && exit 1
    
    TS=$(date -Iseconds)
    
    # Add step if task exists
    if grep -q "^### {{task_name}}:" docs/claude/core/cache.md; then
        LINE=$(grep -n "^### {{task_name}}:" docs/claude/core/cache.md | cut -d':' -f1)
        
        # With or without info
        if [ -z "{{info}}" ]; then
            sed -i "$((LINE+1))i- [x] {{step_description}} - $TS" docs/claude/core/cache.md
        else
            sed -i "$((LINE+1))i- [x] {{step_description}} - $TS - \`{{info}}\`" docs/claude/core/cache.md
        fi
    else
        echo "Task '{{task_name}}' not found"
        exit 1
    fi

# Mark step failed
fail task_name step_description error="Failed":
    #!/usr/bin/env bash
    # Verify cache
    [ ! -f "docs/claude/core/cache.md" ] && echo "Run 'just task init' first." && exit 1
    
    TS=$(date -Iseconds)
    
    # Add failed step if task exists
    if grep -q "^### {{task_name}}:" docs/claude/core/cache.md; then
        LINE=$(grep -n "^### {{task_name}}:" docs/claude/core/cache.md | cut -d':' -f1)
        sed -i "$((LINE+1))i- [!] {{step_description}} - $TS - {{error}}" docs/claude/core/cache.md
    else
        echo "Task '{{task_name}}' not found"
        exit 1
    fi

# Show task progress
show:
    #!/usr/bin/env bash
    # Check cache
    [ ! -f "docs/claude/core/cache.md" ] && echo "Run 'just task init' first." && exit 1
    
    # Get task info
    TASK=$(grep "task_name:" docs/claude/core/cache.md | head -1 | cut -d':' -f2- | xargs)
    DESC=$(grep "task_description:" docs/claude/core/cache.md | head -1 | cut -d':' -f2- | xargs)
    
    # Exit if no task
    [ "$TASK" = "none" ] && echo "No active task" && exit 0
    
    # Show current task
    echo "Task: $TASK - $DESC"
    
    # Show progress
    awk '/^### '"$TASK"':/ {in_task=1; print; next}
         /^###/ {if(in_task) exit; in_task=0}
         in_task {print}' docs/claude/core/cache.md

# Clean cache but keep task
clean:
    #!/usr/bin/env bash
    # Backup current cache
    [ -f "docs/claude/core/cache.md" ] && cp docs/claude/core/cache.md docs/claude/core/cache.md.bak
    
    # Extract task info
    TASK=""
    DESC=""
    if [ -f "docs/claude/core/cache.md" ]; then
        TASK=$(grep "task_name:" docs/claude/core/cache.md | head -1 | cut -d':' -f2- | xargs)
        DESC=$(grep "task_description:" docs/claude/core/cache.md | head -1 | cut -d':' -f2- | xargs)
    fi
    
    # Reset cache
    just init
    
    # Restore task if exists
    if [ ! -z "$TASK" ] && [ "$TASK" != "none" ]; then
        sed -i "s/- task_name:.*$/- task_name: $TASK/" docs/claude/core/cache.md
        sed -i "s/- task_description:.*$/- task_description: $DESC/" docs/claude/core/cache.md
        
        # Add minimal task info
        echo -e "\n## Tasks" >> docs/claude/core/cache.md
        echo -e "### $TASK: $DESC" >> docs/claude/core/cache.md
        TS=$(date -Iseconds)
        echo -e "- [x] Task continued - $TS - \`Cache cleaned\`" >> docs/claude/core/cache.md
    fi

# Show command history
history:
    @[ -f "docs/claude/core/cache.md" ] && grep -o "\`.*\`" docs/claude/core/cache.md | sed 's/`//g' | sort | uniq || echo "No cache found."