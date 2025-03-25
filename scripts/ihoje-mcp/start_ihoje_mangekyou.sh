#!/usr/bin/env bash
# iHoje Mangekyou launcher

# Set environment variables
export IHOJE_MANGEKYOU_PORT=17891
export IHOJE_MANGEKYOU_HOST="127.0.0.1"
export IHOJE_LOG_DIR="/tmp"

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Kill any existing server
if [ -f /tmp/ihoje_mangekyou.pid ]; then
    OLD_PID=$(cat /tmp/ihoje_mangekyou.pid)
    if kill -0 $OLD_PID 2>/dev/null; then
        echo "Stopping existing Mangekyou server (PID: $OLD_PID)"
        kill $OLD_PID
        sleep 1
    fi
    rm -f /tmp/ihoje_mangekyou.pid
fi

# Remove port file if it exists
rm -f /tmp/ihoje_mangekyou_port

# Run the server in background
python3 "$SCRIPT_DIR/ihoje_mangekyou.py" > /tmp/ihoje_mangekyou_stdout.log 2>&1 &

# Save PID
echo $! > /tmp/ihoje_mangekyou.pid
