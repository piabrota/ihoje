# iHoje MCP Tools Management
# Simplified, standalone implementation

# Default action
default:
    @just --list

# Show help information
help:
    @echo "=== iHoje MCP Tools ==="
    @echo "Installation:"
    @echo "  install-all           - Setup and start all iHoje MCP tools"
    @echo "  setup-implementations - Create necessary implementation files"
    @echo "  setup-ihoje           - Setup iHoje domain-specific MCP tools"
    @echo "  install               - Install Mangekyou with auto-versioning"
    @echo "  register              - Generate registration files for all Mangekyou versions"
    @echo "Management:"
    @echo "  status                - Show status of all iHoje MCP servers"
    @echo "  check                 - Check Mangekyou configuration and status"
    @echo "  start                 - Start Mangekyou server"
    @echo "  stop                  - Stop Mangekyou server"
    @echo "  restart               - Restart Mangekyou server"
    @echo "  logs                  - View Mangekyou logs"
    @echo "  health                - Check Mangekyou health endpoint"
    @echo "  uninstall-all         - Stop and clean up all MCP tools"
    @echo "  reset-all             - Uninstall and reinstall all MCP tools"

# Setup server implementations
setup-implementations:
    @bash /home/h0ffmann/Code/ihoje/scripts/setup-ihoje-mcp.sh
    
# Setup iHoje MCP tools
setup-ihoje:
    @bash /home/h0ffmann/Code/ihoje/scripts/mcp-setup-ihoje.sh

# Install all MCP tools
install-all:
    @echo "Installing all iHoje MCP tools..."
    @bash /home/h0ffmann/Code/ihoje/scripts/setup-ihoje-mcp.sh
    @bash /home/h0ffmann/Code/ihoje/scripts/mcp-setup-ihoje.sh
    @bash /home/h0ffmann/Code/ihoje/scripts/ihoje-mcp/start_ihoje_mangekyou.sh
    @sleep 2
    @echo "✅ Mangekyou server started"
    
    # Check the actual port
    @if [ -f /tmp/ihoje_mangekyou_port ]; then \
        echo "   - Service running at: http://localhost:$(cat /tmp/ihoje_mangekyou_port)"; \
    else \
        echo "   - Service running at: http://localhost:17891 (default)"; \
    fi
    
    @echo "   - View logs with: just mcp-logs"
    @echo ""
    @echo "Next steps:"
    @echo "1. Generate registration files:     just mcp-register"
    @echo "2. Check server health:             just mcp-health"

# Show status
status:
    #!/usr/bin/env bash
    echo "iHoje MCP Status:"
    echo "=================="
    echo ""
    echo "Mangekyou Server:"
    if [ -f /tmp/ihoje_mangekyou.pid ] && kill -0 $(cat /tmp/ihoje_mangekyou.pid) 2>/dev/null; then
        echo "  ✅ Running (PID: $(cat /tmp/ihoje_mangekyou.pid))"
        if [ -f /tmp/ihoje_mangekyou_port ]; then
            PORT=$(cat /tmp/ihoje_mangekyou_port)
            echo "  ✅ URL: http://localhost:${PORT}"
        else
            echo "  ✅ URL: http://localhost:17891 (default)"
        fi
        if [ -f /tmp/ihoje_mangekyou.log ]; then
            echo "  ✅ Log: /tmp/ihoje_mangekyou.log"
        else
            echo "  ❌ Log file not found"
        fi
    else
        echo "  ❌ Not running"
    fi

# Start server
start:
    #!/usr/bin/env bash
    if [ -f /tmp/ihoje_mangekyou.pid ] && kill -0 $(cat /tmp/ihoje_mangekyou.pid) 2>/dev/null; then
        echo "Server already running (PID: $(cat /tmp/ihoje_mangekyou.pid))"
    else
        echo "Starting server..."
        bash /home/h0ffmann/Code/ihoje/scripts/ihoje-mcp/start_ihoje_mangekyou.sh
        sleep 2
        if [ -f /tmp/ihoje_mangekyou.pid ] && kill -0 $(cat /tmp/ihoje_mangekyou.pid) 2>/dev/null; then
            echo "✅ Server started (PID: $(cat /tmp/ihoje_mangekyou.pid))"
        else
            echo "❌ Failed to start server"
        fi
    fi

# Stop server
stop:
    #!/usr/bin/env bash
    if [ -f /tmp/ihoje_mangekyou.pid ]; then
        PID=$(cat /tmp/ihoje_mangekyou.pid);
        if kill -0 $PID 2>/dev/null; then
            echo "Stopping server (PID: $PID)..."
            kill $PID
            rm /tmp/ihoje_mangekyou.pid
            echo "✅ Server stopped"
        else
            echo "Server not running"
            rm /tmp/ihoje_mangekyou.pid
        fi
    else
        echo "No server running"
    fi

# Restart server
restart:
    #!/usr/bin/env bash
    if [ -f /tmp/ihoje_mangekyou.pid ]; then
        PID=$(cat /tmp/ihoje_mangekyou.pid);
        if kill -0 $PID 2>/dev/null; then
            echo "Stopping server (PID: $PID)..."
            kill $PID
            rm /tmp/ihoje_mangekyou.pid
            echo "Server stopped"
        else
            echo "Server not running"
            rm /tmp/ihoje_mangekyou.pid
        fi
    else
        echo "No server running"
    fi
    
    sleep 1
    echo "Starting server..."
    bash /home/h0ffmann/Code/ihoje/scripts/ihoje-mcp/start_ihoje_mangekyou.sh
    sleep 2
    if [ -f /tmp/ihoje_mangekyou.pid ] && kill -0 $(cat /tmp/ihoje_mangekyou.pid) 2>/dev/null; then
        echo "✅ Server started (PID: $(cat /tmp/ihoje_mangekyou.pid))"
    else
        echo "❌ Failed to start server"
    fi

# View logs
logs:
    #!/usr/bin/env bash
    if [ -f /tmp/ihoje_mangekyou.log ]; then
        echo "Last 30 log entries:"
        echo "--------------------"
        tail -n 30 /tmp/ihoje_mangekyou.log
    else
        echo "No log file found at /tmp/ihoje_mangekyou.log"
    fi

# Check health
health:
    #!/usr/bin/env bash
    echo "Checking server health..."
    
    # Determine port to use
    if [ -f /tmp/ihoje_mangekyou_port ]; then
        PORT=$(cat /tmp/ihoje_mangekyou_port)
    else
        PORT=17891
    fi
    
    if command -v curl >/dev/null 2>&1; then
        echo "Testing connection to http://localhost:${PORT}/health"
        response=$(curl -s http://localhost:${PORT}/health)
        if [ -n "$response" ]; then
            echo "✅ Server is responding"
            echo "Response: $response"
        else
            echo "❌ No response from server"
        fi
    else
        echo "❌ curl command not found, cannot check health"
    fi

# Uninstall all MCP tools
uninstall-all:
    #!/usr/bin/env bash
    echo "Uninstalling all iHoje MCP tools..."
    
    # Stop Mangekyou server if running
    if [ -f /tmp/ihoje_mangekyou.pid ]; then
        PID=$(cat /tmp/ihoje_mangekyou.pid)
        if kill -0 $PID 2>/dev/null; then
            echo "Stopping Mangekyou server (PID: $PID)..."
            kill $PID
            rm /tmp/ihoje_mangekyou.pid
            echo "✅ Mangekyou server stopped"
        else
            echo "Mangekyou server not running"
            rm /tmp/ihoje_mangekyou.pid
        fi
    fi
    
    # Clean up logs
    if [ -f /tmp/ihoje_mangekyou.log ]; then
        rm /tmp/ihoje_mangekyou.log
        echo "✅ Mangekyou logs cleaned up"
    fi
    
    echo "✅ All iHoje MCP tools uninstalled"

# Reset all MCP tools (uninstall and reinstall)
reset-all:
    @just --justfile /home/h0ffmann/Code/ihoje/justfiles/mcp.justfile uninstall-all
    @echo "Reinstalling all iHoje MCP tools..."
    @just --justfile /home/h0ffmann/Code/ihoje/justfiles/mcp.justfile install-all

# Check any Mangekyou configuration
check:
    @/home/h0ffmann/Code/ihoje/scripts/check-mangekyou.sh

# Install Mangekyou with auto-versioning
install:
    @/home/h0ffmann/Code/ihoje/scripts/install-mangekyou.sh

# Register all Mangekyou versions with Claude MCP
register:
    @/home/h0ffmann/Code/ihoje/scripts/register-mangekyou.sh
    
# Fix MCP registration for Claude Code
fix-registration:
    @/home/h0ffmann/Code/ihoje/scripts/fix-mangekyou-mcp.sh

# Legacy v5 check command (for backward compatibility)
check-v5:
    @echo "Warning: Using deprecated command. Please use 'just mcp-check' instead."
    @/home/h0ffmann/Code/ihoje/scripts/check-mangekyou.sh

# Legacy v5 install command (for backward compatibility)
install-v5:
    @echo "Warning: Using deprecated command. Please use 'just mcp-install' instead."
    @/home/h0ffmann/Code/ihoje/scripts/install-mangekyou.sh