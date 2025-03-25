#!/bin/bash
# Run the Nix-compatible Mangekyou MCP server

# Configuration
PORT=17891
HOST="127.0.0.1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="/tmp/mangekyou-pid.txt"

# Kill any existing Mangekyou processes
echo "Stopping any existing Mangekyou processes..."
pkill -f "python.*mangekyou" 2>/dev/null || true
if [ -f "$PID_FILE" ]; then
    pid=$(cat "$PID_FILE")
    if kill -0 "$pid" 2>/dev/null; then
        kill "$pid"
    fi
    rm -f "$PID_FILE"
fi

# Start the Nix-compatible Mangekyou server
echo "Starting Nix-compatible Mangekyou server..."
nohup "$SCRIPT_DIR/nix-compatible-mangekyou.py" > /tmp/mangekyou.log 2>&1 &
echo $! > "$PID_FILE"

# Wait for server to start
echo "Waiting for server to start..."
sleep 2

# Check if server is running
if [ -f "$PID_FILE" ]; then
    pid=$(cat "$PID_FILE")
    if kill -0 "$pid" 2>/dev/null; then
        echo "✅ Mangekyou server running on http://$HOST:$PORT (PID: $pid)"
        exit 0
    fi
fi

echo "❌ Failed to start Mangekyou server"
exit 1