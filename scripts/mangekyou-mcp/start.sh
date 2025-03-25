#!/bin/bash
# Start script for Mangekyou MCP
# This script starts the Mangekyou MCP server

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Activate virtual environment if it exists
if [ -d "$SCRIPT_DIR/venv" ]; then
    echo "Activating virtual environment..."
    source "$SCRIPT_DIR/venv/bin/activate"
fi

echo "Starting Mangekyou Sharingan MCP server..."
python -m mangekyou_mcp.server