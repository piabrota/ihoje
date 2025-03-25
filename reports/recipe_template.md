# Standardized Justfile Recipe Template

This document defines the standardized format for all justfile recipes in the iHoje project, addressing the inconsistencies found in the current structure.

## Recipe Template Overview

Each recipe should follow this general structure:

```just
# Short one-line description of what the recipe does
recipe-name param1="default" param2="default":
    # Recipe implementation
```

## Recipe Documentation Template

For better consistency, recipes should be documented as follows:

```just
# [ACTION]: Short description of what the recipe does
# 
# Usage:
#   just recipe-name PARAM1 PARAM2
#
# Params:
#   param1: Description of parameter (default: "default_value")
#   param2: Description of parameter (default: "default_value")
recipe-name param1="default_value" param2="default_value":
    # Recipe implementation
```

## Standard Recipe Types and Formats

### 1. Simple Command Recipe

```just
# [RUN]: Run a simple command
#
# Usage:
#   just command ARGS
#
# Params:
#   args: Arguments to pass to the command (default: "")
command +args="":
    command_binary {{args}}
```

### 2. Bash Script Recipe

```just
# [SCRIPT]: Run a complex operation
#
# Usage:
#   just complex-task NAME VALUE
#
# Params:
#   name: Name parameter (required)
#   value: Value to use (default: "default")
complex-task name value="default":
    #!/usr/bin/env bash
    # Validate parameters
    if [ -z "{{name}}" ]; then
        echo "Error: 'name' parameter is required"
        exit 1
    fi
    
    # Log operation
    echo "Running complex task {{name}} with value {{value}}..."
    
    # Perform operation
    # [implementation]
    
    # Check success
    if [ $? -eq 0 ]; then
        echo "Operation completed successfully"
    else
        echo "Operation failed"
        exit 1
    fi
```

### 3. Help Recipe

```just
# [HELP]: Show command help for this category
help:
    @echo "======= Category Commands =======" 
    @echo ""
    @echo "Group 1:"
    @echo "  just command1            - Short description"
    @echo "  just command2 PARAM      - Short description"
    @echo ""
    @echo "Group 2:"
    @echo "  just command3            - Short description"
    @echo "  just command4            - Short description"
```

### 4. Default Recipe

```just
# [LIST]: Show all available recipes
default:
    @just --list
```

### 5. Forwarding Recipe

```just
# [FORWARD]: Run commands from another justfile
#
# Usage:
#   just category ARGS
#
# Params:
#   args: Arguments to pass to the other justfile (default: "")
category +args="":
    @just --justfile path/to/category.justfile {{args}}
```

## Parameter Validation Patterns

### Simple Validation Pattern

```just
if [ -z "{{param}}" ]; then
    echo "Error: 'param' is required"
    exit 1
fi
```

### Enum Validation Pattern

```just
if [[ "{{param}}" != "value1" && "{{param}}" != "value2" ]]; then
    echo "Error: 'param' must be one of: value1, value2"
    exit 1
fi
```

### Numeric Validation Pattern

```just
if ! [[ "{{param}}" =~ ^[0-9]+$ ]]; then
    echo "Error: 'param' must be a number"
    exit 1
fi
```

### File Existence Validation Pattern

```just
if [ ! -f "{{file}}" ]; then
    echo "Error: File '{{file}}' does not exist"
    exit 1
fi
```

## Error Handling Patterns

### Standard Error Handling Pattern

```just
# Attempt command and handle error
if ! command args; then
    echo "Error: Failed to execute command"
    exit 1
fi
```

### Multi-Stage Error Handling Pattern

```just
# Stage 1
echo "Stage 1: Starting operation..."
if ! stage1_command; then
    echo "Error: Failed at stage 1"
    exit 1
fi

# Stage 2
echo "Stage 2: Continuing operation..."
if ! stage2_command; then
    echo "Error: Failed at stage 2"
    # Cleanup from stage 1
    cleanup_command
    exit 1
fi

echo "Operation completed successfully"
```

## Recipe Categories and Tagging

Each recipe should be tagged with an action category to make its purpose clear:

- `[RUN]`: Execute an application or command
- `[BUILD]`: Build or compile code
- `[TEST]`: Run tests
- `[SETUP]`: Configure or initialize something
- `[CLEAN]`: Remove artifacts or clean up
- `[INFO]`: Display information
- `[HELP]`: Show help text
- `[FORWARD]`: Forward to another justfile
- `[LIST]`: List available commands
- `[CREATE]`: Generate or create something
- `[MODIFY]`: Change or update something
- `[SCRIPT]`: Execute a complex script

## Implementation Guidelines

1. Always add parameter validation for required parameters
2. Use consistent error messaging that clearly identifies the issue
3. Include operation status feedback with clear success/failure indications
4. Properly handle error states with appropriate exit codes
5. Use `@` to suppress command echo when appropriate
6. Use consistent indentation (4 spaces recommended)