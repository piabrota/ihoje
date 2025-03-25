#!/usr/bin/env bash
# Comprehensive script to install and configure mangekyou_v5

echo "Setting up mangekyou_v5 MCP server..."

# Determine if the server is running and get its port
if [ -f /tmp/ihoje_mangekyou.pid ]; then
    PID=$(cat /tmp/ihoje_mangekyou.pid)
    if kill -0 $PID 2>/dev/null; then
        echo "✅ Mangekyou server is already running (PID: $PID)"
        
        # Determine port
        if [ -f /tmp/ihoje_mangekyou_port ]; then
            PORT=$(cat /tmp/ihoje_mangekyou_port)
        else
            PORT=17892  # Default port based on current output
        fi
    else
        echo "❌ Stale PID file found, will start new server"
        rm -f /tmp/ihoje_mangekyou.pid
        /home/h0ffmann/Code/ihoje/scripts/ihoje-mcp/start_ihoje_mangekyou.sh
        sleep 2
        PORT=17892  # Default port based on current output
    fi
else
    echo "Starting Mangekyou server..."
    /home/h0ffmann/Code/ihoje/scripts/ihoje-mcp/start_ihoje_mangekyou.sh
    sleep 2
    PORT=17892  # Default port based on current output
fi

echo "Mangekyou server running on port: $PORT"

# Remove any existing mangekyou_v5 configuration
echo "Checking for existing mangekyou_v5 configuration..."
if claude mcp list | grep -q "mangekyou_v5"; then
    echo "Removing existing mangekyou_v5 configuration..."
    claude mcp remove mangekyou_v5
fi

# Add the new configuration
echo "Adding mangekyou_v5 configuration pointing to http://localhost:$PORT..."
claude mcp add mangekyou_v5 http://localhost:$PORT

# Verify configuration
echo "Verifying configuration..."
if claude mcp list | grep -q "mangekyou_v5"; then
    echo "✅ mangekyou_v5 successfully configured"
    echo "Configuration: $(claude mcp list | grep 'mangekyou_v5')"
else
    echo "❌ Failed to configure mangekyou_v5"
    exit 1
fi

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

echo "✅ mangekyou_v5 installation complete and verified"