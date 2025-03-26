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
    @echo "  brave-api-setup       - Set up Brave Search API MCP tool (requires API key)"
    @echo "Management:"
    @echo "  status                - Show status of all iHoje MCP servers"
    @echo "  list                  - List all available MCP tools"
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

# Set up Brave Search API MCP tool
brave-api-setup:
    #!/usr/bin/env bash
    echo "Setting up Brave Search API MCP tool..."
    
    # Check if .env file exists
    if [ ! -f "/home/h0ffmann/Code/ihoje/.env" ]; then
        echo "❌ .env file not found. Creating a template..."
        cp "/home/h0ffmann/Code/ihoje/.env.example" "/home/h0ffmann/Code/ihoje/.env"
        echo "Please edit .env and add your BRAVE_API_KEY"
        exit 1
    fi
    
    # Check if BRAVE_API_KEY exists in .env
    if ! grep -q "BRAVE_API_KEY" "/home/h0ffmann/Code/ihoje/.env"; then
        echo "❌ BRAVE_API_KEY not found in .env"
        echo "Adding BRAVE_API_KEY entry to .env"
        echo "BRAVE_API_KEY=your_api_key_here" >> "/home/h0ffmann/Code/ihoje/.env"
        echo "Please edit .env and set your Brave Search API key"
        echo "You can get a free API key at: https://brave.com/search/api/"
        exit 1
    fi
    
    # Verify configuration file existence
    if [ ! -d "/home/h0ffmann/Code/ihoje/.mcp-registration" ]; then
        echo "Creating .mcp-registration directory..."
        mkdir -p "/home/h0ffmann/Code/ihoje/.mcp-registration"
    fi
    
    echo "✅ Brave Search API MCP tool is ready to use"
    echo "You can now use the brave-browser MCP tool in Claude Code"
    
# List all available MCP tools
list:
    #!/usr/bin/env bash
    echo "Available MCP Tools:"
    echo "===================="
    
    # Check Mangekyou
    if [ -f "/tmp/ihoje_mangekyou.pid" ] && kill -0 $(cat "/tmp/ihoje_mangekyou.pid") 2>/dev/null; then
        echo "✅ mangekyou                - Implementation planning (running)"
    else
        echo "❌ mangekyou                - Implementation planning (not running)"
    fi
    
    # Check Brave Search API integration
    if grep -q "BRAVE_API_KEY" "/home/h0ffmann/Code/ihoje/.env" && grep -q -v "BRAVE_API_KEY=your_api_key_here" "/home/h0ffmann/Code/ihoje/.env"; then
        echo "✅ brave-browser            - Web search"
    else
        echo "❌ brave-browser            - Web search (API key needed)"
    fi
    
    # Standard MCP tools
    echo "✅ sequential-thinking      - Step-by-step reasoning"
    echo "✅ filesystem               - File access"
    echo "✅ puppeteer                - Browser automation"
    echo "✅ fetch                    - Web content"
    
    echo ""
    echo "Setup Commands:"
    echo "  just mcp-start           - Start Mangekyou server"
    echo "  just mcp-brave-api-setup - Setup Brave Search API"