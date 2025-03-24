# Main justfile that loads all commands from submodules
# Updated format compatible with just version 1.13+

# Load .env file if present
set dotenv-load

# Show all available recipes by forwarding to master justfile
default:
    @just --justfile justfile.master

# Build the Rust application
build:
    cargo build

# Run the application with default settings
run +ARGS="":
    cargo run {{ARGS}}

# Run the application with a specific city
run-city city="FL":
    CITY={{city}} cargo run

# Run all tests (shortcut for test all)
test-all:
    @just --justfile justfiles/test.justfile all

# Explicitly define all module commands to forward
claude:
    @just --justfile justfiles/claude.justfile claude

# Claude with minimal context
claude-minimal:
    @just --justfile justfiles/claude.justfile claude-minimal

# Claude with micro context  
claude-micro:
    @just --justfile justfiles/claude.justfile claude-micro

# Claude help command
claude-help:
    @just --justfile justfiles/claude.justfile help

db *ARGS:
    @just --justfile justfiles/db.justfile {{ARGS}}

mcp *ARGS:
    @just --justfile justfiles/mcp.justfile {{ARGS}}

podman *ARGS:
    @just --justfile justfiles/podman.justfile {{ARGS}}

provider *ARGS:
    @just --justfile justfiles/provider.justfile {{ARGS}}

runner *ARGS:
    @just --justfile justfiles/run.justfile {{ARGS}}

security *ARGS:
    @just --justfile justfiles/security.justfile {{ARGS}}

task *ARGS:
    @just --justfile justfiles/task.justfile {{ARGS}}

tester *ARGS:
    @just --justfile justfiles/test.justfile {{ARGS}}

util *ARGS:
    @just --justfile justfiles/util.justfile {{ARGS}}

hooks *ARGS:
    @just --justfile justfiles/hooks.justfile {{ARGS}}

# Find and apply justfile best practices
improve-just:
    @sh scripts/improve-justfiles.sh
    
# Find and apply Rust best practices
improve-rust:
    @sh scripts/improve-rust.sh
    
# Find and apply Python best practices
improve-python:
    @sh scripts/improve-python.sh

# Create improvement plan without execution
plan-improvement task description:
    @bash scripts/improvement-plan.sh "{{task}}" "{{description}}"

# Mangekyou Sharingan MCP simplified commands
mangekyou:
    @just mcp mangekyou

mangekyou-stop:
    @just mcp mangekyou-stop
    
mangekyou-status:
    @just mcp mangekyou-status
    
mangekyou-restart:
    @just mcp mangekyou-restart
    
test-mangekyou query="Add support for CSV export to the event scraper":
    @just mcp test-mangekyou "{{query}}"
    
# Standalone PEX commands for Mangekyou
mangekyou-pex:
    @just mcp mangekyou-pex
    
mangekyou-pex-run:
    @just mcp mangekyou-pex-run