#!/bin/bash
# Setup script for iHoje MCP tools

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Create MCP configuration for Claude
CONFIG_FILE="$ROOT_DIR/.claude-mcp-config.json"

echo "Creating MCP configuration file at $CONFIG_FILE"

# Create the MCP configuration
cat > "$CONFIG_FILE" << EOF
{
  "mcpServers": {
    "brave-browser": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-brave-search"],
      "env": {
        "BRAVE_API_KEY": "\${BRAVE_API_KEY}"
      }
    },
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    },
    "ihoje-mangekyou": {
      "command": "bash",
      "args": ["scripts/ihoje-mcp/start_ihoje_mangekyou.sh"],
      "cwd": "\${PWD}",
      "env": {
        "PYTHONPATH": "\${PWD}",
        "IHOJE_ROOT": "\${PWD}"
      }
    }
  }
}
EOF

# Make sure the start script is executable
chmod +x "$ROOT_DIR/scripts/ihoje-mcp/start_ihoje_mangekyou.sh"

# Install required npm packages
echo "Installing required npm packages..."
npm install -g @modelcontextprotocol/server-brave-search @modelcontextprotocol/server-sequential-thinking

# Check for Brave API key
if [ -f "$ROOT_DIR/.env" ]; then
    if ! grep -q "BRAVE_API_KEY" "$ROOT_DIR/.env"; then
        echo "Adding BRAVE_API_KEY placeholder to .env file"
        echo "BRAVE_API_KEY=your_api_key_here" >> "$ROOT_DIR/.env"
    fi
else
    echo "Creating .env file with BRAVE_API_KEY placeholder"
    echo "BRAVE_API_KEY=your_api_key_here" > "$ROOT_DIR/.env"
fi

echo "MCP setup complete!"
echo "To use Brave Search, please update the BRAVE_API_KEY in your .env file"
echo "Start the iHoje Mangekyou server with: just mcp-start"