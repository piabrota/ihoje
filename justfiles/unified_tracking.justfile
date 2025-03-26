# Unified Task Tracking System
# Comprehensive task tracking that replaces the separate cache and checkpoints systems

# Load .env file
set dotenv-load

# Default show recipes
default:
    @just --list

# Show help for task tracking commands
help:
    @echo "=== Unified Task Tracking ==="
    @echo "Tasks:"
    @echo "  task-add NAME DESC     - Add new task"
    @echo "  task-complete TASK STEP - Mark step complete with optional info"
    @echo "  task-fail TASK STEP ERR - Mark step failed with error details"
    @echo "  task-show              - Show current task status"
    @echo "  task-list              - List all tasks"
    @echo "  task-switch NAME       - Switch to a different task"
    @echo "  task-archive NAME      - Archive a completed task"
    @echo "  task-reset NAME        - Reset task (clear progress)"
    @echo "  task-clean             - Clean tracking file but keep current task"
    @echo "  task-history           - Show command history"
    @echo "  task-init              - Initialize tracking system"

# File constants
TRACKING_FILE := "docs/claude/core/task_tracking.md"
TEMPLATE_FILE := "docs/claude/templates/tracking_template.md"

# Initialize tracking system
task-init:
    #!/usr/bin/env bash
    # Create template if not exists
    if [ ! -f "{{TEMPLATE_FILE}}" ]; then
        echo "Creating tracking template."
        mkdir -p docs/claude/templates
        echo -e "# Task Tracking\n\n- active_task: none\n- task_description: No task in progress\n\n## Tasks" > {{TEMPLATE_FILE}}
        echo "Created template at {{TEMPLATE_FILE}}"
    fi
    
    mkdir -p docs/claude/core
    cp {{TEMPLATE_FILE}} {{TRACKING_FILE}}
    echo "Initialized task tracking system."

# Add a new task
task-add task_name task_description:
    #!/usr/bin/env bash
    # Initialize if needed
    [ ! -f "{{TRACKING_FILE}}" ] && just task-init > /dev/null
    
    # Update active task
    sed -i "s/- active_task:.*$/- active_task: {{task_name}}/" {{TRACKING_FILE}}
    sed -i "s/- task_description:.*$/- task_description: {{task_description}}/" {{TRACKING_FILE}}
    
    # Add task if new
    if ! grep -q "^### {{task_name}}:" {{TRACKING_FILE}}; then
        TS=$(date -Iseconds)
        sed -i "/^## Tasks/a\\n### {{task_name}}: {{task_description}}\n- [x] Task started - $TS\n" {{TRACKING_FILE}}
        echo "Added task: {{task_name}}"
    else
        echo "Task already exists. Switched to: {{task_name}}"
    fi

# Mark a step as complete
task-complete task_name step_description info="":
    #!/usr/bin/env bash
    # Verify tracking file
    [ ! -f "{{TRACKING_FILE}}" ] && echo "Run 'just task-init' first." && exit 1
    
    TS=$(date -Iseconds)
    
    # Add step if task exists
    if grep -q "^### {{task_name}}:" {{TRACKING_FILE}}; then
        LINE=$(grep -n "^### {{task_name}}:" {{TRACKING_FILE}} | cut -d':' -f1)
        
        # With or without info
        if [ -z "{{info}}" ]; then
            sed -i "$((LINE+1))i- [x] {{step_description}} - $TS" {{TRACKING_FILE}}
        else
            sed -i "$((LINE+1))i- [x] {{step_description}} - $TS - \`{{info}}\`" {{TRACKING_FILE}}
        fi
        echo "Marked step complete: {{step_description}}"
    else
        echo "Task '{{task_name}}' not found."
        exit 1
    fi

# Mark a step as failed
task-fail task_name step_description error="Failed":
    #!/usr/bin/env bash
    # Verify tracking file
    [ ! -f "{{TRACKING_FILE}}" ] && echo "Run 'just task-init' first." && exit 1
    
    TS=$(date -Iseconds)
    
    # Add failed step if task exists
    if grep -q "^### {{task_name}}:" {{TRACKING_FILE}}; then
        LINE=$(grep -n "^### {{task_name}}:" {{TRACKING_FILE}} | cut -d':' -f1)
        sed -i "$((LINE+1))i- [!] {{step_description}} - $TS - {{error}}" {{TRACKING_FILE}}
        echo "Marked step failed: {{step_description}}"
    else
        echo "Task '{{task_name}}' not found."
        exit 1
    fi

# Show current task status
task-show:
    #!/usr/bin/env bash
    # Check tracking file
    [ ! -f "{{TRACKING_FILE}}" ] && echo "Run 'just task-init' first." && exit 1
    
    # Get active task
    TASK=$(grep "active_task:" {{TRACKING_FILE}} | head -1 | cut -d':' -f2- | xargs)
    DESC=$(grep "task_description:" {{TRACKING_FILE}} | head -1 | cut -d':' -f2- | xargs)
    
    # Exit if no task
    if [ "$TASK" = "none" ]; then
        echo "No active task"
        exit 0
    fi
    
    # Show current task
    echo "Active Task: $TASK - $DESC"
    echo ""
    
    # Show progress
    awk '/^### '"$TASK"':/ {in_task=1; print; next}
         /^###/ {if(in_task) exit; in_task=0}
         in_task {print}' {{TRACKING_FILE}}

# List all tasks
task-list:
    #!/usr/bin/env bash
    # Check tracking file
    [ ! -f "{{TRACKING_FILE}}" ] && echo "Run 'just task-init' first." && exit 1
    
    # Get active task
    ACTIVE_TASK=$(grep "active_task:" {{TRACKING_FILE}} | head -1 | cut -d':' -f2- | xargs)
    
    # List all tasks
    echo "Task List:"
    grep -o "^### [^:]*:" {{TRACKING_FILE}} | sed 's/^### //;s/://' | while read task; do
        if [ "$task" = "$ACTIVE_TASK" ]; then
            echo "* $task (active)"
        else
            echo "  $task"
        fi
    done

# Switch to a different task
task-switch task_name:
    #!/usr/bin/env bash
    # Check tracking file
    [ ! -f "{{TRACKING_FILE}}" ] && echo "Run 'just task-init' first." && exit 1
    
    # Check if task exists
    if grep -q "^### {{task_name}}:" {{TRACKING_FILE}}; then
        # Get task description
        DESC=$(grep -A 1 "^### {{task_name}}:" {{TRACKING_FILE}} | grep -o ": .*" | cut -c3-)
        
        # Update active task
        sed -i "s/- active_task:.*$/- active_task: {{task_name}}/" {{TRACKING_FILE}}
        sed -i "s/- task_description:.*$/- task_description: $DESC/" {{TRACKING_FILE}}
        
        echo "Switched to task: {{task_name}}"
    else
        echo "Task '{{task_name}}' not found."
        exit 1
    fi

# Archive a completed task
task-archive task_name:
    #!/usr/bin/env bash
    # Check tracking file
    [ ! -f "{{TRACKING_FILE}}" ] && echo "Run 'just task-init' first." && exit 1
    
    # Check if task exists
    if grep -q "^### {{task_name}}:" {{TRACKING_FILE}}; then
        # Create archives directory if needed
        mkdir -p docs/claude/archives
        
        # Append date to archive filename
        DATE=$(date +%Y%m%d)
        ARCHIVE_FILE="docs/claude/archives/{{task_name}}_$DATE.md"
        
        # Extract task content
        echo "# Archived Task: {{task_name}}" > "$ARCHIVE_FILE"
        echo "Archived on: $(date -Iseconds)" >> "$ARCHIVE_FILE"
        echo "" >> "$ARCHIVE_FILE"
        awk '/^### {{task_name}}:/ {in_task=1; print; next}
             /^###/ {if(in_task) exit; in_task=0}
             in_task {print}' {{TRACKING_FILE}} >> "$ARCHIVE_FILE"
        
        # Remove task from tracking file
        sed -i '/^### {{task_name}}:/,/^###/{ /^###/{/^### {{task_name}}:/d; :a; n; ba}; d}' {{TRACKING_FILE}}
        # Remove the last empty line that might remain
        sed -i '/^$/d' {{TRACKING_FILE}}
        
        # If this was the active task, reset active task
        ACTIVE_TASK=$(grep "active_task:" {{TRACKING_FILE}} | head -1 | cut -d':' -f2- | xargs)
        if [ "$ACTIVE_TASK" = "{{task_name}}" ]; then
            sed -i "s/- active_task:.*$/- active_task: none/" {{TRACKING_FILE}}
            sed -i "s/- task_description:.*$/- task_description: No task in progress/" {{TRACKING_FILE}}
        fi
        
        echo "Archived task '{{task_name}}' to $ARCHIVE_FILE"
    else
        echo "Task '{{task_name}}' not found."
        exit 1
    fi

# Reset a task (clear its progress)
task-reset task_name:
    #!/usr/bin/env bash
    # Check tracking file
    [ ! -f "{{TRACKING_FILE}}" ] && echo "Run 'just task-init' first." && exit 1
    
    # Check if task exists
    if grep -q "^### {{task_name}}:" {{TRACKING_FILE}}; then
        # Get task description
        DESC=$(grep "^### {{task_name}}:" {{TRACKING_FILE}} | grep -o ": .*" | cut -c3-)
        
        # Remove task content
        sed -i '/^### {{task_name}}:/,/^###/{ /^###/{/^### {{task_name}}:/d; :a; n; ba}; d}' {{TRACKING_FILE}}
        
        # Add the task back with just a start marker
        TS=$(date -Iseconds)
        sed -i "/^## Tasks/a\\n### {{task_name}}: $DESC\n- [x] Task reset - $TS\n" {{TRACKING_FILE}}
        
        echo "Reset task: {{task_name}}"
    else
        echo "Task '{{task_name}}' not found."
        exit 1
    fi

# Clean tracking file but keep current task
task-clean:
    #!/usr/bin/env bash
    # Backup current tracking file
    [ -f "{{TRACKING_FILE}}" ] && cp {{TRACKING_FILE}} {{TRACKING_FILE}}.bak
    
    # Extract active task info
    TASK=""
    DESC=""
    if [ -f "{{TRACKING_FILE}}" ]; then
        TASK=$(grep "active_task:" {{TRACKING_FILE}} | head -1 | cut -d':' -f2- | xargs)
        DESC=$(grep "task_description:" {{TRACKING_FILE}} | head -1 | cut -d':' -f2- | xargs)
    fi
    
    # Reset tracking file
    just task-init
    
    # Restore active task if exists
    if [ -n "$TASK" ] && [ "$TASK" != "none" ]; then
        sed -i "s/- active_task:.*$/- active_task: $TASK/" {{TRACKING_FILE}}
        sed -i "s/- task_description:.*$/- task_description: $DESC/" {{TRACKING_FILE}}
        
        # Extract and preserve task content if active task exists in backup
        if [ -f "{{TRACKING_FILE}}.bak" ] && grep -q "^### $TASK:" {{TRACKING_FILE}}.bak; then
            # Add the task section to the tracking file
            awk '/^### '"$TASK"':/ {in_task=1; print; next}
                 /^###/ {if(in_task) exit; in_task=0}
                 in_task {print}' {{TRACKING_FILE}}.bak >> {{TRACKING_FILE}}
            
            echo "Cleaned tracking file, preserving active task: $TASK"
        else
            # Add minimal task info
            sed -i "/^## Tasks/a\\n### $TASK: $DESC\n- [x] Task continued - $(date -Iseconds) - \`Tracking file cleaned\`\n" {{TRACKING_FILE}}
            
            echo "Cleaned tracking file, restarting active task: $TASK"
        fi
    else
        echo "Cleaned tracking file, no active task."
    fi

# Show command history
task-history:
    @[ -f "{{TRACKING_FILE}}" ] && grep -o "\`.*\`" {{TRACKING_FILE}} | sed 's/`//g' | sort | uniq || echo "No tracking file found."