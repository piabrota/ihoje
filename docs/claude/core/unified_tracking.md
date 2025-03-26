# Unified Task Tracking System

This document describes the unified task tracking system that replaces the previous separate cache and checkpoints systems.

## Overview

The unified task tracking system provides a comprehensive way to track progress on complex tasks that may span multiple sessions. It offers:

1. **Task Progress Tracking**: Record tasks and their individual steps
2. **Auto-Resume Functionality**: Continue from incomplete steps when restarting 
3. **History Preservation**: Maintain a complete record of task progress
4. **Failure Recovery**: Document and recover from failed steps

## Configuration

The system is configured in `CLAUDE_BOOTSTRAP.md` with the following settings:

```
- tracking_enabled: true  # Enable unified task tracking
- auto_resume: true       # Resume from last failed/incomplete step
- auto_proceed: true      # Automatically continue with next steps
```

## Commands

### Creating Tasks

```bash
just task-add "task_name" "Task description here"
```

This creates a new task entry in the tracking system. Use descriptive task names and clear descriptions.

### Marking Progress

```bash
# Mark a step complete
just task-complete "task_name" "step_description" "additional info"

# Mark a step failed
just task-fail "task_name" "step_description" "error details"
```

Always provide detailed information about steps:
- For completed steps: describe what was accomplished
- For failed steps: include error details to aid recovery

### Viewing Progress

```bash
# Show current task status
just task-show
```

This displays:
- Current active task
- Completed steps
- Failed steps
- Pending steps (if defined)

### Managing Tasks

```bash
# List all tasks
just task-list

# Switch to a different task
just task-switch "task_name"

# Archive completed task
just task-archive "task_name"

# Reset task (clear progress)
just task-reset "task_name"
```

## Auto-Resume Functionality

When `auto_resume` is enabled:

1. Claude checks for an active task
2. Locates the first uncompleted or failed step
3. Continues execution from that point
4. Maintains context from previously completed steps

This allows seamless continuation of complex tasks across multiple sessions.

## Implementation

The unified tracking system stores task data in a structured format in `docs/claude/core/task_tracking.md`. This file is automatically managed by the task commands.

For performance reasons, a SQLite backend can also be used for larger projects. The system automatically detects and uses the appropriate storage method.

## Best Practices

1. **Break Tasks into Small Steps**: Smaller steps make tracking and recovery easier
2. **Use Consistent Naming**: Maintain consistent naming conventions
3. **Include Detailed Descriptions**: Provide context for future reference
4. **Document Failures Thoroughly**: Include error messages and state information
5. **Review Task History**: Periodically review task history for insights
6. **Archive Completed Tasks**: Keep the active task list clean

## Example Workflow

```bash
# Start a new task
just task-add "api-implementation" "Implement REST API endpoints"

# Track progress
just task-complete "api-implementation" "Create route files" "Created basic structure"
just task-complete "api-implementation" "Add user routes" "GET and POST endpoints" 
just task-fail "api-implementation" "Add auth middleware" "Token validation failing"

# Later sessions automatically resume at auth middleware step
```

## Integration with Context System

The task tracking system is integrated with Claude's context system:

- **Micro Context** (~200 tokens): Minimal task information
- **Minimal Context** (~500 tokens): Current task and immediate steps
- **Standard Context** (~1000 tokens): Full task history and next steps
- **Domain Context** (~1200 tokens): Domain-specific task context
- **Full Context** (~3000+ tokens): Complete task tracking information

This ensures Claude always has appropriate task context regardless of the context level used.