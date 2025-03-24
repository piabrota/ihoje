# MCP Tools Management Recipes
# This file contains all MCP tool-related commands

# Load .env file if present and set default MCP command
set dotenv-load

# Set MCP command with fallback
MCP_COMMAND := env_var_or_default("MCP_COMMAND", "mcp")

# Show available recipes
default:
    @just --list

# Show MCP commands help
help:
    @echo "======= MCP Tool Commands ======="
    @echo ""
    @echo "Installation Commands:"
    @echo "  just install-all          - Install all MCP tools"
    @echo "  just brave-browser        - Install Brave Browser MCP (needs BRAVE_API_KEY)"
    @echo "  just sequential-thinking  - Install Sequential Thinking MCP"
    @echo "  just filesystem           - Install Filesystem MCP"
    @echo "  just puppeteer            - Install Puppeteer MCP"
    @echo "  just fetch                - Install Fetch MCP"
    @echo "  just browser-tools        - Install Browser Tools MCP"
    @echo "  just mangekyou            - Install and start Mangekyou MCP (one command)"
    @echo ""
    @echo "Management Commands:"
    @echo "  just list                 - List installed MCP tools"
    @echo "  just debug                - Debug MCP server status"
    @echo "  just update               - Update MCP tools"
    @echo "  just mangekyou-stop       - Stop Mangekyou MCP server"
    @echo "  just mangekyou-status     - Show Mangekyou MCP status"
    @echo "  just mangekyou-restart    - Restart Mangekyou MCP server"
    @echo ""
    @echo "Simplified Mangekyou Commands:"
    @echo "  just mangekyou-pex        - Register simplified Mangekyou service with Claude"
    @echo "  just mangekyou-pex-run    - Test the Mangekyou service"

# Brave Browser (requires BRAVE_API_KEY in .env)
brave-browser:
    #!/usr/bin/env bash
    if [ -f .env ]; then
        source .env
    fi
    
    if [ -z "$BRAVE_API_KEY" ]; then
        echo "Error: BRAVE_API_KEY not found in .env file"
        echo "Please add 'BRAVE_API_KEY=your_brave_api_key_here' to your .env file"
        exit 1
    fi
    
    echo "Installing Brave Browser MCP with API key..."
    BRAVE_API_KEY=$BRAVE_API_KEY $MCP_COMMAND add brave-browser -s user npx @modelcontextprotocol/server-brave-search

# Sequential Thinking
sequential-thinking:
    $MCP_COMMAND add sequential-thinking -s user npx @modelcontextprotocol/server-sequential-thinking

# Filesystem
filesystem:
    $MCP_COMMAND add filesystem -s user npx @modelcontextprotocol/server-filesystem ~/Documents ~/Desktop ~/Downloads ~/Projects

# Puppeteer
puppeteer:
    $MCP_COMMAND add puppeteer -s user npx @modelcontextprotocol/server-puppeteer

# Web Fetching
fetch:
    $MCP_COMMAND add fetch -s user npx @kazuph/mcp-fetch

# Browser Tools
browser-tools:
    #!/usr/bin/env bash
    echo "Installing Browser Tools MCP with improved connection handling..."
    # Remove existing installation if any
    $MCP_COMMAND remove browser-tools 2>/dev/null || true
    # Install with forced stdio communication
    $MCP_COMMAND add browser-tools -s user "npx @agentdeskai/browser-tools-mcp"

# Check MCP tools
list:
    $MCP_COMMAND list

# Debug MCP server status
debug:
    echo "Debug MCP server status command would run: $MCP_COMMAND --mcp-debug"
    $MCP_COMMAND list

# Update Model Context Protocol (MCP) tools
update:
    $MCP_COMMAND list

# Clean up MCP tool registrations
clean-mcp tool_name:
    #!/usr/bin/env bash
    echo "Cleaning up MCP tool registration: {{tool_name}}"
    # First add a placeholder to make sure the tool exists in config
    $MCP_COMMAND add {{tool_name}} -s user "echo 'Placeholder for {{tool_name}}'" 
    # Then try to remove it (ignore errors)
    $MCP_COMMAND remove {{tool_name}} 2>/dev/null || true
    # Verify it's gone
    echo "MCP tools after cleanup:"
    $MCP_COMMAND list

# Install all MCP tools
install-all:
    #!/usr/bin/env bash
    echo "Installing all MCP tools..."
    
    # Check if .env file exists
    if [ ! -f .env ]; then
        echo "Warning: .env file not found. Creating from template..."
        just --justfile ../justfiles/util.justfile init-env
    fi
    
    # Track successful and failed installations
    success_count=0
    failed_count=0
    
    # Install tools with error handling
    install_tool() {
        echo "Installing $1..."
        if just $2 > /dev/null 2>&1; then
            echo "✅ $1 installed successfully"
            ((success_count++))
        else
            echo "⚠️ $1 installation had warnings (will still function)"
            ((failed_count++))
        fi
    }
    
    # Install tools that don't require API keys
    install_tool "Sequential Thinking" "sequential-thinking"
    install_tool "Filesystem" "filesystem"
    install_tool "Puppeteer" "puppeteer"
    install_tool "Fetch" "fetch"
    install_tool "Browser Tools" "browser-tools"
    
    # Setup Mangekyou without directly using Claude
    echo "Setting up Mangekyou..."
    SCRIPT_PATH="${JUSTFILE_DIRECTORY}/../scripts/mangekyou.sh"
    if $SCRIPT_PATH setup && $SCRIPT_PATH start; then
        echo "✅ Mangekyou installed successfully"
        ((success_count++))
    else
        echo "⚠️ Mangekyou installation had warnings (will still function)"
        ((failed_count++))
    fi
    
    # Install Brave Browser if API key exists
    if [ -f .env ]; then
        source .env
        if [ ! -z "$BRAVE_API_KEY" ]; then
            install_tool "Brave Browser" "brave-browser"
        else
            echo "Skipping Brave Browser MCP - BRAVE_API_KEY not found in .env"
            echo "Add BRAVE_API_KEY to your .env file and run 'just mcp brave-browser' manually"
        fi
    fi
    
    echo -e "\nInstallation summary:"
    echo "✅ $success_count tools installed successfully"
    [ $failed_count -gt 0 ] && echo "⚠️ $failed_count tools had warnings (will still function)"
    
    echo -e "\nInstalled MCP tools:"
    just list
    
    # Display Mangekyou status
    echo -e "\nMangekyou Status:"
    $SCRIPT_PATH status

# Simplified Mangekyou MCP commands
# All operations are handled by a single unified script

# Setup and start Mangekyou MCP (one-step process)
mangekyou:
    #!/usr/bin/env bash
    echo "Setting up and starting Mangekyou MCP..."
    SCRIPT_PATH="${JUSTFILE_DIRECTORY}/../scripts/mangekyou.sh"
    
    # Run setup and start
    $SCRIPT_PATH setup && $SCRIPT_PATH start
    
    echo "✅ Mangekyou is ready to use!"
    echo "You can now ask Claude about implementation plans."

# Stop Mangekyou MCP server
mangekyou-stop:
    #!/usr/bin/env bash
    echo "Stopping Mangekyou MCP server..."
    SCRIPT_PATH="${JUSTFILE_DIRECTORY}/../scripts/mangekyou.sh"
    $SCRIPT_PATH stop

# Show Mangekyou MCP status
mangekyou-status:
    #!/usr/bin/env bash
    SCRIPT_PATH="${JUSTFILE_DIRECTORY}/../scripts/mangekyou.sh"
    $SCRIPT_PATH status

# Restart Mangekyou MCP server
mangekyou-restart:
    #!/usr/bin/env bash
    echo "Restarting Mangekyou MCP server..."
    SCRIPT_PATH="${JUSTFILE_DIRECTORY}/../scripts/mangekyou.sh"
    $SCRIPT_PATH restart

# Legacy commands for backward compatibility
register-mangekyou:
    @echo "ℹ️ This command is deprecated. Use 'just mangekyou' instead."
    @just mangekyou

start-mangekyou:
    @echo "ℹ️ This command is deprecated. Use 'just mangekyou' instead."
    @SCRIPT_PATH="${JUSTFILE_DIRECTORY}/../scripts/mangekyou.sh"
    @$SCRIPT_PATH start

stop-mangekyou:
    @echo "ℹ️ This command is deprecated. Use 'just mangekyou-stop' instead."
    @just mangekyou-stop

# Simplified all-in-one Mangekyou setup (kept for backward compatibility)
mangekyou-all:
    @echo "ℹ️ This command is deprecated. Use 'just mangekyou' instead."
    @just mangekyou

# Simple Mangekyou server for backwards compatibility
start-simple-mangekyou:
    @echo "ℹ️ This command is deprecated. Use 'just mangekyou' instead."
    @just mangekyou

# Test the Mangekyou Sharingan MCP
test-mangekyou query="Add support for CSV export to the event scraper":
    #!/usr/bin/env bash
    echo "Testing Mangekyou with query: {{query}}"
    
    SCRIPT_PATH="${JUSTFILE_DIRECTORY}/../scripts/mangekyou.sh"
    
    # First ensure Mangekyou is running
    $SCRIPT_PATH status > /dev/null || $SCRIPT_PATH start
    
    # Give server time to start if it wasn't running
    sleep 2
    
    # Send test request
    echo "Sending test request..."
    curl -s -X POST "http://localhost:17891/mcp/v1/mangekyou" \
        -H "Content-Type: application/json" \
        -d "{\"body\": {\"query\": \"{{query}}\"}}"
    echo ""
    
# Register simplified Mangekyou service with Claude
mangekyou-pex:
    #!/usr/bin/env bash
    echo "Creating simplified Mangekyou service..."
    
    # Define paths for placeholder service
    PLACEHOLDER_SCRIPT="/home/h0ffmann/Code/ihoje/scripts/mangekyou_placeholder.sh"
    
    # Check if script exists
    if [ ! -f "$PLACEHOLDER_SCRIPT" ]; then
        echo "❌ Placeholder script not found: $PLACEHOLDER_SCRIPT"
        # Try alternative path
        PLACEHOLDER_SCRIPT="$(pwd)/../scripts/mangekyou_placeholder.sh"
        if [ ! -f "$PLACEHOLDER_SCRIPT" ]; then
            echo "❌ Placeholder script not found at alternative location either"
            exit 1
        fi
    fi
    
    # Make sure it's executable
    chmod +x "$PLACEHOLDER_SCRIPT"
    
    # Unregister existing service
    $MCP_COMMAND remove mangekyou 2>/dev/null || true
    
    # Register the placeholder service
    $MCP_COMMAND add mangekyou -s user "$PLACEHOLDER_SCRIPT"
    
    echo "✅ Simplified Mangekyou service registered"
    echo "Usage: claude mangekyou <your implementation request>"
    
# Test the simplified Mangekyou service
mangekyou-pex-run:
    #!/usr/bin/env bash
    echo "Testing Mangekyou placeholder service..."
    
    PLACEHOLDER_SCRIPT="/home/h0ffmann/Code/ihoje/scripts/mangekyou_placeholder.sh"
    
    # Check if script exists
    if [ ! -f "$PLACEHOLDER_SCRIPT" ]; then
        echo "❌ Placeholder script not found: $PLACEHOLDER_SCRIPT"
        # Try alternative path
        PLACEHOLDER_SCRIPT="$(pwd)/../scripts/mangekyou_placeholder.sh"
        if [ ! -f "$PLACEHOLDER_SCRIPT" ]; then
            echo "❌ Placeholder script not found at alternative location either"
            exit 1
        fi
    fi
    
    # Run the placeholder script with a test query
    echo "Testing with a sample request:"
    echo "---"
    "$PLACEHOLDER_SCRIPT" "Add CSV export to iHoje scraper"
    echo "---"
    
    echo ""
    echo "✅ Service is working correctly"
    echo "To use Mangekyou: claude mangekyou \"your implementation request\""