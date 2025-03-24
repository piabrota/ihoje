# MCP Tools Management Recipes
# This file contains all MCP tool-related commands

# Load .env file if present
set dotenv-load

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
    @echo "Standalone Executables:"
    @echo "  just mangekyou-pex        - Create standalone executable (no venv needed)"
    @echo "  just mangekyou-pex-run    - Run Mangekyou from standalone executable"

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
    BRAVE_API_KEY=$BRAVE_API_KEY claude mcp add brave-browser -s user npx @modelcontextprotocol/server-brave-search

# Sequential Thinking
sequential-thinking:
    claude mcp add sequential-thinking -s user npx @modelcontextprotocol/server-sequential-thinking

# Filesystem
filesystem:
    claude mcp add filesystem -s user npx @modelcontextprotocol/server-filesystem ~/Documents ~/Desktop ~/Downloads ~/Projects

# Puppeteer
puppeteer:
    claude mcp add puppeteer -s user npx @modelcontextprotocol/server-puppeteer

# Web Fetching
fetch:
    claude mcp add fetch -s user npx @kazuph/mcp-fetch

# Browser Tools
browser-tools:
    #!/usr/bin/env bash
    echo "Installing Browser Tools MCP with improved connection handling..."
    # Remove existing installation if any
    claude mcp remove browser-tools 2>/dev/null || true
    # Install with forced stdio communication
    claude mcp add browser-tools -s user "npx @agentdeskai/browser-tools-mcp"

# Check MCP tools
list:
    claude mcp list

# Debug MCP server status
debug:
    claude --mcp-debug

# Update Model Context Protocol (MCP) tools
update:
    claude mcp list

# Clean up MCP tool registrations
clean-mcp tool_name:
    #!/usr/bin/env bash
    echo "Cleaning up MCP tool registration: {{tool_name}}"
    # First add a placeholder to make sure the tool exists in config
    claude mcp add {{tool_name}} -s user "echo 'Placeholder for {{tool_name}}'" 
    # Then try to remove it (ignore errors)
    claude mcp remove {{tool_name}} 2>/dev/null || true
    # Verify it's gone
    echo "MCP tools after cleanup:"
    claude mcp list

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
    install_tool "Mangekyou" "mangekyou"
    
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
    
# Create standalone Mangekyou executable
mangekyou-pex:
    #!/usr/bin/env bash
    echo "Creating standalone Mangekyou executable..."
    
    # Define paths
    STANDALONE_SCRIPT="/home/h0ffmann/Code/ihoje/scripts/mangekyou_standalone.py"
    OUTPUT_DIR="/home/h0ffmann/Code/ihoje/dist"
    OUTPUT_SCRIPT="${OUTPUT_DIR}/mangekyou"
    
    # Check if script exists
    if [ ! -f "$STANDALONE_SCRIPT" ]; then
        echo "❌ Source script not found: $STANDALONE_SCRIPT"
        # Try alternative path
        STANDALONE_SCRIPT="$(pwd)/../scripts/mangekyou_standalone.py"
        if [ ! -f "$STANDALONE_SCRIPT" ]; then
            echo "❌ Source script not found at alternative location either"
            exit 1
        fi
    fi
    
    # Ensure output directory exists
    mkdir -p "$OUTPUT_DIR"
    
    # Copy script to output directory
    cp "$STANDALONE_SCRIPT" "$OUTPUT_SCRIPT"
    chmod +x "$OUTPUT_SCRIPT"
    
    echo "✅ Standalone executable created: $OUTPUT_SCRIPT"
    echo "Usage: just mcp mangekyou-pex-run"
    
# Run Mangekyou from standalone executable
mangekyou-pex-run:
    #!/usr/bin/env bash
    echo "Running Mangekyou standalone executable..."
    
    # Use absolute path for reliability
    SCRIPT_PATH="/home/h0ffmann/Code/ihoje/dist/mangekyou"
    
    if [ ! -f "$SCRIPT_PATH" ]; then
        echo "❌ Standalone executable not found: $SCRIPT_PATH"
        # Try alternative path
        SCRIPT_PATH="$(pwd)/../dist/mangekyou"
        if [ ! -f "$SCRIPT_PATH" ]; then
            echo "❌ Standalone executable not found at alternative location either"
            echo "Please build it first with: just mcp mangekyou-pex"
            exit 1
        fi
    fi
    
    # Run the standalone script
    "$SCRIPT_PATH"