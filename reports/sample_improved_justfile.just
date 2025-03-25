# Sample Improved Justfile
# This is a demonstration of the standardized format

# Load .env file if present
set dotenv-load

# [LIST]: Show all available recipes
default:
    @just --list

# [HELP]: Show command help for this category
help:
    @echo "======= Sample Commands =======" 
    @echo ""
    @echo "Basic Commands:"
    @echo "  just run                  - Run the application"
    @echo "  just run-city CITY        - Run with specific city"
    @echo "  just run-date DAYS        - Run with date offset"
    @echo ""
    @echo "Advanced Commands:"
    @echo "  just complex-task NAME    - Run a complex task"
    @echo "  just validate-param PARAM - Validate a parameter"

# [RUN]: Run the application with optional arguments
#
# Usage:
#   just run [ARGS]
#
# Params:
#   args: Arguments to pass to the command (default: "")
run +args="":
    cargo run {{args}}

# [RUN]: Run the application with a specific city
#
# Usage:
#   just run-city CITY
#
# Params:
#   city: City code to use (default: "FL")
run-city city="FL":
    CITY={{city}} cargo run

# [RUN]: Run with date offset from today
#
# Usage:
#   just run-date DAYS
#
# Params:
#   days: Number of days ahead (must be a number)
run-date days="7":
    #!/usr/bin/env bash
    # Validate parameter
    if ! [[ "{{days}}" =~ ^[0-9]+$ ]]; then
        echo "Error: 'days' must be a number"
        exit 1
    fi
    
    # Calculate date
    DATE=$(date -d "+{{days}} days" +"%Y-%m-%d")
    echo "Using date: ${DATE}"
    
    # Run with date
    START_DATE=${DATE} cargo run
    
    # Check success
    if [ $? -eq 0 ]; then
        echo "Run completed successfully"
    else
        echo "Run failed"
        exit 1
    fi

# [SCRIPT]: Run a complex operation with validation
#
# Usage:
#   just complex-task NAME [VALUE]
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
    
    # Stage 1
    echo "Stage 1: Starting operation..."
    mkdir -p tmp/{{name}}
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create directory"
        exit 1
    fi
    
    # Stage 2
    echo "Stage 2: Writing file..."
    echo "{{value}}" > tmp/{{name}}/data.txt
    if [ $? -ne 0 ]; then
        echo "Error: Failed to write file"
        # Cleanup from stage 1
        rmdir tmp/{{name}}
        exit 1
    fi
    
    echo "Operation completed successfully"

# [TEST]: Validate parameter against allowed values
#
# Usage:
#   just validate-param PARAM
#
# Params:
#   param: Parameter to validate (must be one of: "option1", "option2", "option3")
validate-param param:
    #!/usr/bin/env bash
    # Validate parameter
    if [[ "{{param}}" != "option1" && "{{param}}" != "option2" && "{{param}}" != "option3" ]]; then
        echo "Error: 'param' must be one of: option1, option2, option3"
        exit 1
    fi
    
    echo "Parameter '{{param}}' is valid"

# [FORWARD]: Run commands from another justfile
#
# Usage:
#   just forward-to ARGS
#
# Params:
#   args: Arguments to pass to the other justfile (default: "")
forward-to +args="":
    @just --justfile justfiles/util.justfile {{args}}

# [CLEAN]: Remove temporary files
clean:
    #!/usr/bin/env bash
    echo "Cleaning temporary files..."
    if [ -d "tmp" ]; then
        rm -rf tmp
        echo "Temporary files removed"
    else
        echo "No temporary files to clean"
    fi