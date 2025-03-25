# Plan for Simplifying Mangekyou MCP Installation and Usage

This plan outlines how to refactor the Mangekyou MCP installation and usage process to be as simple as possible.

## Current State Assessment

Currently, the Mangekyou MCP setup is spread across multiple scripts and involves several steps:

1. Installation via `install-mangekyou.sh`
2. Registration via `register-mangekyou.sh`
3. Starting via `start-mangekyou.sh`
4. Running via `run-mangekyou.sh`

Issues with the current approach:
- Multiple scripts with overlapping functionality
- Hard-coded paths
- Complex setup with potential for errors
- Separate steps that could be combined
- Redundant code between scripts

## Proposed Solution

### 1. Create a single unified script: `mangekyou.sh`

This script will combine all functionality with a simple command interface:

```
./mangekyou.sh [setup|start|stop|status]
```

- `setup`: Install and register in one step
- `start`: Start the server
- `stop`: Stop the server
- `status`: Show if the server is running

### 2. Simplify the justfile commands

Reduce to just two primary commands:
- `just mangekyou`: Single command to setup and start
- `just mangekyou-stop`: Stop the server

### 3. Technical Implementation

Key improvements:
- Use relative paths instead of hard-coded paths
- Single script with command handling
- Store configuration in one place
- Simplified user interface
- Automatic error handling and recovery

## Implementation Steps

1. Create the unified `mangekyou.sh` script
2. Simplify the Python server code
3. Update the justfile commands
4. Test the new workflow
5. Remove the old scripts

## Benefits

- Simpler user experience
- Reduced complexity
- More maintainable code
- Fewer potential points of failure
- Easier debugging