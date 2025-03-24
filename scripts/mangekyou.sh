#!/bin/bash
# Unified Mangekyou MCP script - combines all functionality into a single file
# Usage: ./mangekyou.sh [setup|start|stop|status]

# Configuration
PORT=17891
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MANGEKYOU_DIR="$SCRIPT_DIR/mangekyou-mcp"
PID_FILE="/tmp/mangekyou-pid.txt"
PYTHON_SERVER="$SCRIPT_DIR/mangekyou.py"

# Ensure the directory exists
mkdir -p "$MANGEKYOU_DIR/mangekyou_mcp"

# Create banner function
show_banner() {
    echo "=================================================="
    echo "  Mangekyou MCP - Simplicity is the ultimate form"
    echo "=================================================="
    echo ""
}

# Setup function - installs and registers Mangekyou
setup() {
    echo "Setting up Mangekyou MCP..."
    
    # Stop any existing instances
    stop_server quiet
    
    # Create __init__.py if it doesn't exist
    if [ ! -f "$MANGEKYOU_DIR/mangekyou_mcp/__init__.py" ]; then
        echo "# Mangekyou MCP Package" > "$MANGEKYOU_DIR/mangekyou_mcp/__init__.py"
    fi
    
    # Create run script
    cat > "$MANGEKYOU_DIR/run_mangekyou.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")/.."
python3 mangekyou.py
EOF
    chmod +x "$MANGEKYOU_DIR/run_mangekyou.sh"
    
    # Register with Claude MCP
    echo "Registering Mangekyou MCP with Claude..."
    claude mcp add mangekyou -s user "$MANGEKYOU_DIR/run_mangekyou.sh"
    
    echo "✅ Mangekyou MCP setup complete!"
}

# Start server function
start_server() {
    echo "Starting Mangekyou MCP server..."
    
    # Check if already running
    if is_running; then
        echo "⚠️ Mangekyou server is already running (PID: $(cat $PID_FILE))"
        echo "Use './mangekyou.sh stop' to stop it first"
        return 1
    fi
    
    # Start server
    nohup python3 "$PYTHON_SERVER" > /tmp/mangekyou.log 2>&1 &
    PID=$!
    echo $PID > "$PID_FILE"
    sleep 1
    
    # Check if started successfully
    if is_running; then
        echo "✅ Mangekyou server started successfully (PID: $PID)"
        echo "Server running at http://localhost:$PORT"
        return 0
    else
        echo "❌ Failed to start Mangekyou server"
        return 1
    fi
}

# Stop server function
stop_server() {
    # Handle quiet mode
    if [ "$1" = "quiet" ]; then
        QUIET=true
    else
        QUIET=false
        echo "Stopping Mangekyou MCP server..."
    fi
    
    # Check PID file
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p $PID > /dev/null; then
            kill $PID 2>/dev/null
            sleep 1
            if ps -p $PID > /dev/null; then
                kill -9 $PID 2>/dev/null
            fi
            $QUIET || echo "Stopped server process (PID: $PID)"
        elif ! $QUIET; then
            echo "Process not found for PID: $PID"
        fi
        rm -f "$PID_FILE"
    fi
    
    # Check for port usage
    PORT_PID=$(lsof -t -i:$PORT 2>/dev/null)
    if [ ! -z "$PORT_PID" ]; then
        kill $PORT_PID 2>/dev/null
        sleep 1
        kill -9 $PORT_PID 2>/dev/null 2>&1
        $QUIET || echo "Killed process using port $PORT (PID: $PORT_PID)"
    fi
    
    # Find any Python processes containing 'mangekyou'
    PYTHON_PIDS=$(ps aux | grep "[p]ython.*mangekyou" | awk '{print $2}')
    if [ ! -z "$PYTHON_PIDS" ]; then
        for pid in $PYTHON_PIDS; do
            kill $pid 2>/dev/null
            sleep 1
            kill -9 $pid 2>/dev/null
            $QUIET || echo "Killed Python mangekyou process (PID: $pid)"
        done
    fi
    
    $QUIET || echo "✅ Mangekyou server stopped"
}

# Check if server is running
is_running() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p $PID > /dev/null; then
            return 0  # Running
        fi
    fi
    
    # Check port
    if lsof -i:$PORT > /dev/null 2>&1; then
        return 0  # Port in use
    fi
    
    return 1  # Not running
}

# Show status
show_status() {
    echo "Checking Mangekyou MCP status..."
    
    if is_running; then
        PID=$(cat "$PID_FILE" 2>/dev/null || echo "Unknown")
        PORT_PID=$(lsof -t -i:$PORT 2>/dev/null || echo "Unknown")
        echo "✅ Mangekyou server is RUNNING"
        echo "PID: $PID"
        echo "Port: $PORT (PID: $PORT_PID)"
        echo "Server URL: http://localhost:$PORT"
        
        # Check registration
        if claude mcp list 2>&1 | grep -q "mangekyou"; then
            echo "✅ Mangekyou is registered with Claude MCP"
        else
            echo "❌ Mangekyou is NOT registered with Claude MCP"
        fi
    else
        echo "❌ Mangekyou server is NOT running"
        
        # Check registration
        if claude mcp list 2>&1 | grep -q "mangekyou"; then
            echo "⚠️ Mangekyou is registered with Claude MCP but not running"
        else
            echo "❌ Mangekyou is NOT registered with Claude MCP"
        fi
    fi
}

# Main command handler
show_banner

case "$1" in
    setup)
        setup
        ;;
    start)
        start_server
        ;;
    stop)
        stop_server
        ;;
    status)
        show_status
        ;;
    restart)
        stop_server
        start_server
        ;;
    *)
        echo "Mangekyou MCP - Unified script for all Mangekyou operations"
        echo ""
        echo "Usage: ./mangekyou.sh [command]"
        echo ""
        echo "Commands:"
        echo "  setup   - Install and register Mangekyou MCP"
        echo "  start   - Start the Mangekyou server"
        echo "  stop    - Stop the Mangekyou server"
        echo "  restart - Restart the Mangekyou server"
        echo "  status  - Show server status"
        echo ""
        echo "Example:"
        echo "  ./mangekyou.sh setup && ./mangekyou.sh start"
        ;;
esac