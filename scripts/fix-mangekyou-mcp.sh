#!/bin/bash
# Fix Mangekyou MCP registration for Claude Code

set -e

# Check if the server is running
PORT=$(cat /tmp/ihoje_mangekyou_port 2>/dev/null || echo "17891")
echo "Detected Mangekyou server on port: $PORT"

# Get repo root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.."; pwd)"
REGISTRATION_DIR="$REPO_ROOT/.mcp-registration"
mkdir -p "$REGISTRATION_DIR"

# Create a proper MCP registration file
CONFIG_FILE="$REGISTRATION_DIR/mangekyou_v7.json"
cat > "$CONFIG_FILE" << EOL
{
  "name": "mangekyou_v7",
  "url": "http://localhost:$PORT/mcp/v1"
}
EOL

echo "Created MCP registration file at: $CONFIG_FILE"
echo ""
echo "Registration Commands:"
echo "Run these commands from your terminal (NOT from Claude Code):"
echo ""
echo "claude mcp add \"mangekyou_v7\" \"http://localhost:$PORT/mcp/v1\""
echo ""
echo "Or using the JSON file:"
echo ""
echo "claude mcp add --from-file \"$CONFIG_FILE\""
echo ""
echo "To test connectivity, run this in a new terminal:"
echo "curl -v http://localhost:$PORT/mcp/v1/healthz"
