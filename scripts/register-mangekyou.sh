#!/bin/bash
# Register Mangekyou Sharingan MCP with Claude
# This script creates registration files for ALL Mangekyou versions

set -e  # Exit immediately if a command exits with a non-zero status

# Get the absolute path to the repository root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_DIR="$REPO_ROOT/scripts/mangekyou-mcp"

# Define all version names to register
VERSIONS=("mangekyou" "mangekyou_v2" "mangekyou_v3" "mangekyou_v4" "mangekyou_v5" "mangekyou_v6" "mangekyou_v7")
SERVER_PORT=17891

echo "===== Mangekyou MCP Registration Helper ====="
echo "Repository root: $REPO_ROOT"

# Check if server is running
if ! command -v curl &> /dev/null || ! curl -s "http://localhost:$SERVER_PORT/health" &> /dev/null; then
    echo "⚠️ Mangekyou server is not running at http://localhost:$SERVER_PORT"
    echo "Starting the server..."
    
    # Start server if needed
    if [ -f "$REPO_ROOT/scripts/ihoje-mcp/start_ihoje_mangekyou.sh" ]; then
        bash "$REPO_ROOT/scripts/ihoje-mcp/start_ihoje_mangekyou.sh"
        sleep 2
        
        # Check if we can read the port
        if [ -f /tmp/ihoje_mangekyou_port ]; then
            SERVER_PORT=$(cat /tmp/ihoje_mangekyou_port)
        fi
    else
        echo "❌ Could not find the server startup script"
        echo "Please run 'just mcp-start' before registering"
        exit 1
    fi
fi

# Create a directory for registration files
REGISTRATION_DIR="$REPO_ROOT/.mcp-registration"
mkdir -p "$REGISTRATION_DIR"

echo ""
echo "===== Creating Registration Files ====="
echo "Registration directory: $REGISTRATION_DIR"
echo ""

# Create registration files for each version
for version in "${VERSIONS[@]}"; do
    CONFIG_FILE="$REGISTRATION_DIR/$version.json"
    
    # Create MCP registration JSON file
    cat > "$CONFIG_FILE" << EOL
{
  "name": "$version",
  "url": "http://localhost:$SERVER_PORT"
}
EOL
    
    echo "Created registration file for $version at $CONFIG_FILE"
done

echo ""
echo "===== Registration Commands ====="
echo "To register ALL versions, run the following commands in your terminal:"
echo "(DO NOT run these commands from within Claude Code!)"
echo ""

for version in "${VERSIONS[@]}"; do
    echo "claude mcp add \"$version\" \"http://localhost:$SERVER_PORT\""
done

echo ""
echo "Or individually using the JSON files:"
echo ""

for version in "${VERSIONS[@]}"; do
    echo "claude mcp add --from-file \"$REGISTRATION_DIR/$version.json\""
done

echo ""
echo "===== Server Health Check ====="
echo "Testing server connection:"
curl -s "http://localhost:$SERVER_PORT/health"
echo ""
echo ""
echo "✅ Once registered, you can use Mangekyou directly in Claude by asking:"
echo "   \"Can you create an implementation plan for adding CSV export?\""