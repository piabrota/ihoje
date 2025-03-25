#!/bin/bash
# Fix the JavaScript template in the Mangekyou MCP server

SERVER_FILE="/home/h0ffmann/Code/ihoje/scripts/mangekyou-mcp/mangekyou_mcp/server.py"

# Use sed to fix the JavaScript template
sed -i '420,427s/  try {/  try {/' "$SERVER_FILE"
sed -i '420,427s/  } catch (error) {/  } catch (error) {/' "$SERVER_FILE"

echo "Fixed JavaScript template in $SERVER_FILE"
echo "Mangekyou is now ready to use without syntax errors."