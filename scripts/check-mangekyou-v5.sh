#!/usr/bin/env bash
# Script to check if mangekyou_v5 is configured and running

echo "Checking Mangekyou v5 configuration..."

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
        
        # Check the Claude MCP configuration
        if command -v claude >/dev/null 2>&1; then
            echo "Checking Claude MCP configuration..."
            echo "Full MCP server list:"
            claude mcp list
            
            echo ""
            echo "Checking for mangekyou_v5 configuration..."
            if claude mcp list | grep -q "mangekyou_v5"; then
                echo "✅ mangekyou_v5 is configured in Claude MCP"
                echo "   Configuration: $(claude mcp list | grep 'mangekyou_v5')"
            else
                echo "❌ mangekyou_v5 is not configured in Claude MCP"
                echo "   To add it, run:"
                echo "   claude mcp add mangekyou_v5 http://localhost:$PORT"
            fi
        else
            echo "❌ claude command not found, cannot check MCP configuration"
        fi
        
        # Test the server connectivity
        if command -v curl >/dev/null 2>&1; then
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
    else
        echo "❌ Mangekyou server is not running (stale PID file)"
        rm -f /tmp/ihoje_mangekyou.pid
    fi
else
    echo "❌ Mangekyou server is not running (no PID file)"
fi