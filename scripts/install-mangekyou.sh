#!/usr/bin/env bash
# Simplified Mangekyou installation script
# Starts the server but avoids direct Claude API calls

echo "===== Mangekyou MCP Server Installation ====="

# Determine server status and port
if [ -f /tmp/ihoje_mangekyou.pid ]; then
    PID=$(cat /tmp/ihoje_mangekyou.pid)
    if kill -0 $PID 2>/dev/null; then
        echo "✅ Mangekyou server is already running (PID: $PID)"
        
        # Determine port
        if [ -f /tmp/ihoje_mangekyou_port ]; then
            PORT=$(cat /tmp/ihoje_mangekyou_port)
        else
            PORT=17891  # Default port
        fi
    else
        echo "❌ Stale PID file found, starting new server"
        rm -f /tmp/ihoje_mangekyou.pid
        /home/h0ffmann/Code/ihoje/scripts/ihoje-mcp/start_ihoje_mangekyou.sh
        sleep 2
        
        if [ -f /tmp/ihoje_mangekyou_port ]; then
            PORT=$(cat /tmp/ihoje_mangekyou_port)
        else
            PORT=17891  # Default port
        fi
    fi
else
    echo "Starting Mangekyou server..."
    /home/h0ffmann/Code/ihoje/scripts/ihoje-mcp/start_ihoje_mangekyou.sh
    sleep 2
    
    if [ -f /tmp/ihoje_mangekyou_port ]; then
        PORT=$(cat /tmp/ihoje_mangekyou_port)
    else
        PORT=17891  # Default port
    fi
fi

echo "Mangekyou server running on port: $PORT"

# Test server connectivity
echo "Testing server connectivity..."
HEALTH_RESPONSE=$(curl -s "http://localhost:$PORT/health" || echo "Connection failed")
    
if [ "$HEALTH_RESPONSE" != "Connection failed" ]; then
    echo "✅ Server is responding to health check"
    echo "Response: $HEALTH_RESPONSE"
else
    echo "❌ Server is not responding to health check"
    exit 1
fi

echo ""
echo "===== Next Steps ====="
echo "To register the server with Claude MCP, run:"
echo "just mcp-register"
echo ""
echo "This will create registration files and display commands you can run"
echo "outside of a Claude session to register all Mangekyou versions."
echo ""
echo "To check server status at any time, run:"
echo "just mcp-check"