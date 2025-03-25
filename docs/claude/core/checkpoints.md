# Checkpoint System

This document explains the checkpoint system used in the iHoje codebase.

## Overview

The checkpoint system allows Claude to track progress on complex tasks that may span multiple sessions. It provides reliable resumability even when encountering errors.

## How It Works

1. Tasks are broken into discrete steps
2. Each step is tracked with completion status
3. On restart, Claude automatically continues from the first incomplete/failed step
4. Complete history is maintained for context

## Commands

### Creating Tasks

```bash
just add-task "task_name" "Task description here"
```

This creates a new task entry in the tracking system.

### Marking Progress

```bash
# Mark a step complete
just mark-step-complete "task_name" "step_description" "additional info"

# Mark a step failed
just mark-step-failed "task_name" "step_description" "error details"
```

### Viewing Progress

```bash
# Show current task status
just task-cache
```

## Auto-Resume Functionality

When `auto_resume` is enabled in your bootstrap configuration, Claude will:

1. Check for an active task
2. Locate the first uncompleted or failed step
3. Continue execution from that point
4. Maintain context from previously completed steps

## Best Practices

1. **Create Small, Discrete Steps** - Easier to track and resume
2. **Provide Clear Descriptions** - Makes error diagnosis easier
3. **Include Failure Details** - Capture errors for better resumability
4. **Use Consistent Naming** - For both tasks and steps
5. **Verify Completion** - Always mark steps when fully done

## Example Workflow

```
# Start a task
just add-task "api-implementation" "Implement REST API endpoints"

# Mark progress
just mark-step-complete "api-implementation" "Create route files" "Created basic structure"
just mark-step-complete "api-implementation" "Add user routes" "GET and POST endpoints"
just mark-step-failed "api-implementation" "Add auth middleware" "Token validation failing"

# Later sessions automatically resume at auth middleware step
```

## Implementation Details

The checkpoint system has two implementations:

1. **Markdown-based**: Simple tracking in markdown files
2. **SQLite-based**: More robust database tracking (preferred)

The system automatically detects which implementation to use.