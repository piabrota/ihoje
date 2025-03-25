#!/usr/bin/env bash
# Simplified script to check if the Mangekyou server is running
# Avoids direct calls to Claude binary

echo "Checking Mangekyou server status..."
echo "=================================="

# Check if the server is running
if [ -f /tmp/ihoje_mangekyou.pid ]; then
    PID=$(cat /tmp/ihoje_mangekyou.pid)
    if kill -0 $PID 2>/dev/null; then
        echo "✅ Mangekyou server is running (PID: $PID)"
        
        # Determine port
        if [ -f /tmp/ihoje_mangekyou_port ]; then
            PORT=$(cat /tmp/ihoje_mangekyou_port)
        else
            PORT=17891  # Default port
        fi
        
        echo "✅ Mangekyou server URL: http://localhost:$PORT"
        
        # Test the server connectivity
        if command -v curl >/dev/null 2>&1; then
            echo ""
            echo "Testing server connectivity..."
            HEALTH_RESPONSE=$(curl -s "http://localhost:$PORT/health" || echo "Connection failed")
            
            if [ "$HEALTH_RESPONSE" != "Connection failed" ]; then
                echo "✅ Server is responding to health check"
                echo "   Response: $HEALTH_RESPONSE"
            else
                echo "❌ Server is not responding to health check"
            fi
        else
            echo "❌ curl command not found, cannot test connectivity"
        fi
        
        echo ""
        echo "To register this server with Claude MCP, run:"
        echo "-----------------------------------------"
        echo "# For each version, run this command outside of Claude:"
        echo "claude mcp add \"mangekyou\" \"http://localhost:$PORT\""
        echo "claude mcp add \"mangekyou_v2\" \"http://localhost:$PORT\""
        echo "claude mcp add \"mangekyou_v3\" \"http://localhost:$PORT\""
        echo "claude mcp add \"mangekyou_v4\" \"http://localhost:$PORT\""
        echo "claude mcp add \"mangekyou_v5\" \"http://localhost:$PORT\""
        echo "claude mcp add \"mangekyou_v6\" \"http://localhost:$PORT\""
        echo "claude mcp add \"mangekyou_v7\" \"http://localhost:$PORT\""
        echo "-----------------------------------------"
        echo "✅ DO NOT run these commands from within Claude Code"
        echo "✅ Run them directly in your terminal"
    else
        echo "❌ Mangekyou server is not running (stale PID file)"
        rm -f /tmp/ihoje_mangekyou.pid
        echo "PID file removed. To start the server, run: just mcp-start"
    fi
else
    echo "❌ Mangekyou server is not running (no PID file)"
    echo "To start the server, run: just mcp-start"
fi