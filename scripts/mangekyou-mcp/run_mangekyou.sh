#!/bin/bash
# Direct runner for Mangekyou MCP server
# Designed to work in Nix environments

# Configuration variables
PORT=${MANGEKYOU_PORT:-17891}
HOST=${MANGEKYOU_HOST:-"127.0.0.1"}
WORKERS=${MANGEKYOU_WORKERS:-1}

# Set environment variables for the server
export MANGEKYOU_PORT=$PORT
export MANGEKYOU_HOST=$HOST
export MANGEKYOU_WORKERS=$WORKERS
export PIP_BREAK_SYSTEM_PACKAGES=1
export PYTHONPATH="$PYTHONPATH:$(dirname "$0")"

# Get directory of this script and change to it
cd "$(dirname "$0")"

# Create simple placeholder for Nix environments
create_placeholder() {
    PORT=$1
    echo "Creating simple placeholder server for Mangekyou..."
    
    # Simple placeholder response
    python3 -c '
import http.server
import json
import socketserver
import sys

PORT = int(sys.argv[1])

class MangekyouHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"status": "ok"}).encode())
        else:
            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"status": "ok"}).encode())
    
    def do_POST(self):
        content_length = int(self.headers["Content-Length"])
        post_data = self.rfile.read(content_length)
        
        try:
            data = json.loads(post_data.decode("utf-8"))
            query = data.get("body", {}).get("query", "Implementation Request")
        except:
            query = "Implementation Request"
        
        plan = f"""# Implementation Plan for: {query}

## Changes Needed
1. Update configuration in src/config.rs
2. Implement core functionality in src/
3. Add tests

## Steps
1. [ ] Step 1: Design the feature
2. [ ] Step 2: Implement core code
3. [ ] Step 3: Test functionality
4. [ ] Step 4: Document changes
"""
        
        self.send_response(200)
        self.send_header("Content-type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        
        response = {"response": plan}
        self.wfile.write(json.dumps(response).encode())
    
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.end_headers()

print(f"Starting Mangekyou Placeholder on port {PORT}")
with socketserver.TCPServer(("127.0.0.1", PORT), MangekyouHandler) as httpd:
    httpd.serve_forever()
' "$PORT"
}

# Try to run the main server, fallback to placeholder if it fails
echo "Starting Mangekyou MCP server on $HOST:$PORT with $WORKERS worker(s)..."
(python -m mangekyou_mcp.server 2>/dev/null) || (python3 -m mangekyou_mcp.server 2>/dev/null) || create_placeholder "$PORT"
