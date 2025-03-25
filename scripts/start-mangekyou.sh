#!/bin/bash
# Ultra-simple all-in-one script to setup, register and start Mangekyou

echo "Setting up and starting Mangekyou (ultra-simplified)..."

# Simple cleanup
echo "Cleaning up any running processes..."
pkill -f "python.*mangekyou" 2>/dev/null || true
rm -f /tmp/mangekyou-pid.txt

# Setup
echo "Setting up Mangekyou..."
/home/h0ffmann/Code/ihoje/scripts/install-mangekyou.sh

# Register
echo "Registering with MCP..."

# Use environment variable for MCP registration command
if [ -n "$MCP_COMMAND" ]; then
    $MCP_COMMAND add mangekyou -s user "/home/h0ffmann/Code/ihoje/scripts/mangekyou-mcp/run_mangekyou.sh"
else
    echo "⚠️ MCP_COMMAND environment variable not set. Using placeholder."
    echo "✅ Registration would run: mcp add mangekyou -s user /home/h0ffmann/Code/ihoje/scripts/mangekyou-mcp/run_mangekyou.sh"
fi

# Start server
echo "Starting Mangekyou server..."
/home/h0ffmann/Code/ihoje/scripts/mangekyou-mcp/run_mangekyou.sh