#!/bin/bash
# Production-grade Mangekyou MCP server manager
# Manages the FastAPI-based Mangekyou MCP service

# Configuration
PORT=17891
HOST="127.0.0.1"
WORKERS=1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MANGEKYOU_DIR="$SCRIPT_DIR/mangekyou-mcp"
PID_FILE="/tmp/mangekyou-pid.txt"
LOG_FILE="/tmp/mangekyou.log"
PYTHON_SERVER="$SCRIPT_DIR/mangekyou.py"
VENV_DIR="/tmp/mangekyou-venv"
REQUIREMENTS_FILE="/tmp/mangekyou-requirements.txt"

# Create requirements file
create_requirements() {
    cat > "$REQUIREMENTS_FILE" << EOF
fastapi>=0.103.1
uvicorn[standard]>=0.23.2
pydantic>=2.4.2
EOF
}

# Create banner function
show_banner() {
    echo "=================================================="
    echo "  Mangekyou MCP - Production Server"
    echo "=================================================="
    echo ""
}

# Setup function - installs and registers Mangekyou
setup() {
    echo "Setting up Mangekyou MCP Production Server..."
    
    # Stop any existing instances
    stop_server quiet
    
    # Create virtual environment if it doesn't exist
    if [ ! -d "$VENV_DIR" ]; then
        echo "Creating virtual environment at $VENV_DIR..."
        python3 -m venv "$VENV_DIR"
    fi
    
    # Create requirements file
    create_requirements
    
    # Install dependencies
    echo "Installing dependencies..."
    "$VENV_DIR/bin/pip" install -r "$REQUIREMENTS_FILE"
    
    # Create run script
    cat > "$MANGEKYOU_DIR/run_mangekyou.sh" << EOF
#!/bin/bash
export MANGEKYOU_PORT=$PORT
export MANGEKYOU_HOST="$HOST"
export MANGEKYOU_WORKERS=$WORKERS

# Activate the virtual environment
source "$VENV_DIR/bin/activate"

# Start server
cd "$(dirname "\$0")/.."
exec "$VENV_DIR/bin/python" "$PYTHON_SERVER"
EOF
    chmod +x "$MANGEKYOU_DIR/run_mangekyou.sh"
    
    # Register with Claude MCP
    echo "Registering Mangekyou MCP with Claude..."
    if [ -n "$MCP_COMMAND" ]; then
        $MCP_COMMAND add mangekyou -s user "$MANGEKYOU_DIR/run_mangekyou.sh"
    else
        echo "⚠️ MCP_COMMAND environment variable not set. Using placeholder."
        echo "✅ Registration would run: mcp add mangekyou -s user $MANGEKYOU_DIR/run_mangekyou.sh"
    fi
    
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
    
    # Start server using virtual environment
    export MANGEKYOU_PORT=$PORT
    export MANGEKYOU_HOST="$HOST"
    export MANGEKYOU_WORKERS=$WORKERS
    
    # First ensure the environment exists
    if [ ! -d "$VENV_DIR" ]; then
        echo "Virtual environment not found. Running setup first..."
        setup
    fi
    
    # Start server in background
    nohup "$VENV_DIR/bin/python" "$PYTHON_SERVER" > "$LOG_FILE" 2>&1 &
    PID=$!
    echo $PID > "$PID_FILE"
    sleep 2
    
    # Check if started successfully
    if is_running; then
        echo "✅ Mangekyou server started successfully (PID: $PID)"
        echo "Server running at http://$HOST:$PORT"
        return 0
    else
        echo "❌ Failed to start Mangekyou server"
        echo "Check logs at $LOG_FILE for details"
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
            sleep 2
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

# Check server health
check_health() {
    if curl -s "http://$HOST:$PORT/health" | grep -q "ok"; then
        return 0  # Healthy
    else
        return 1  # Not healthy
    fi
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
        echo "Server URL: http://$HOST:$PORT"
        
        # Check health
        if check_health; then
            echo "Health check: ✅ OK"
        else
            echo "Health check: ❌ FAILING"
        fi
        
        # Check API
        if curl -s "http://$HOST:$PORT/mcp/v1/info" > /dev/null; then
            echo "API check: ✅ OK"
        else
            echo "API check: ❌ FAILING"
        fi
        
        # Check registration
        if [ -n "$MCP_COMMAND" ] && $MCP_COMMAND list 2>&1 | grep -q "mangekyou"; then
            echo "✅ Mangekyou is registered with MCP"
        else
            echo "ℹ️ Mangekyou MCP registration status not checked (set MCP_COMMAND env var to enable)"
        fi
        
        # Show log file size
        if [ -f "$LOG_FILE" ]; then
            LOG_SIZE=$(du -h "$LOG_FILE" | cut -f1)
            echo "Log file: $LOG_FILE ($LOG_SIZE)"
        fi
    else
        echo "❌ Mangekyou server is NOT running"
        
        # Check registration
        if [ -n "$MCP_COMMAND" ] && $MCP_COMMAND list 2>&1 | grep -q "mangekyou"; then
            echo "⚠️ Mangekyou is registered with MCP but not running"
        else
            echo "ℹ️ Mangekyou MCP registration status not checked (set MCP_COMMAND env var to enable)"
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
    logs)
        if [ -f "$LOG_FILE" ]; then
            tail -f "$LOG_FILE"
        else
            echo "❌ Log file not found: $LOG_FILE"
        fi
        ;;
    health)
        if check_health; then
            echo "✅ Server health check: OK"
        else
            echo "❌ Server health check: FAILED"
        fi
        ;;
    *)
        echo "Mangekyou MCP - Production-grade MCP Server"
        echo ""
        echo "Usage: ./mangekyou.sh [command]"
        echo ""
        echo "Commands:"
        echo "  setup   - Install and register Mangekyou MCP"
        echo "  start   - Start the Mangekyou server"
        echo "  stop    - Stop the Mangekyou server"
        echo "  restart - Restart the Mangekyou server"
        echo "  status  - Show server status"
        echo "  logs    - View server logs in real-time"
        echo "  health  - Check server health"
        echo ""
        echo "Environment Variables:"
        echo "  MANGEKYOU_PORT    - Server port (default: $PORT)"
        echo "  MANGEKYOU_HOST    - Server host (default: $HOST)"
        echo "  MANGEKYOU_WORKERS - Number of workers (default: $WORKERS)"
        echo "  MCP_COMMAND       - Command to use for MCP registration"
        echo ""
        echo "Example:"
        echo "  ./mangekyou.sh setup && ./mangekyou.sh start"
        ;;
esac