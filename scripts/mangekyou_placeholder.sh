#!/bin/bash
# Ultra-simple Mangekyou placeholder service that works in Nix environments
# This provides basic compatibility with the main MCP server without Python dependencies

# Configuration
PORT=17891
HOST="127.0.0.1"
LOG_FILE="/tmp/mangekyou.log"

# For HTTP server functionality
start_server() {
  # Check if netcat or socat is available
  if command -v nc &> /dev/null; then
    echo "Starting simple HTTP server with netcat on $HOST:$PORT"
    
    # Create a named pipe for communication
    PIPE="/tmp/mangekyou-pipe"
    rm -f "$PIPE"
    mkfifo "$PIPE"
    
    # Start HTTP server in background
    while true; do
      nc -l "$HOST" "$PORT" < "$PIPE" | (
        while read line; do
          # Wait for empty line (end of headers)
          if [[ -z "$line" ]]; then break; fi
        done
        
        # Parse request body if Content-Length is provided
        QUERY="Implementation Plan"
        CONTENT_LENGTH=$(grep -i "Content-Length:" | cut -d' ' -f2)
        
        if [[ ! -z "$CONTENT_LENGTH" ]]; then
          # Read the request body
          BODY=$(head -c "$CONTENT_LENGTH")
          
          # Extract query from JSON if possible
          QUERY=$(echo "$BODY" | grep -o '"query"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
        fi
        
        # Generate response
        HTTP_RESPONSE="HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: *\r\n\r\n"
        JSON_RESPONSE="{\"response\": \"# Implementation Plan for: $QUERY\\n\\n## Changes Needed\\n1. Update configuration in src/config.rs\\n2. Implement core functionality in src/\\n3. Add tests\\n\\n## Steps\\n1. [ ] Step 1: Design the feature\\n2. [ ] Step 2: Implement core code\\n3. [ ] Step 3: Test functionality\\n4. [ ] Step 4: Document changes\\n\\n## Note\\nThis is using the simplified placeholder implementation for Nix environments.\"}"
        
        echo -e "$HTTP_RESPONSE$JSON_RESPONSE" > "$PIPE"
      )
    done &
    
    # Save PID
    echo $! > "/tmp/mangekyou-placeholder.pid"
    echo "Server running in background (PID: $!)"
    
  elif command -v python3 &> /dev/null; then
    # Try to use Python's simple HTTP server as a fallback
    echo "Starting simple HTTP server with Python on $HOST:$PORT"
    
    # Create a minimal Python HTTP server script
    cat > /tmp/mangekyou_http.py << 'EOL'
import http.server
import json
import socketserver
from urllib.parse import parse_qs

class MangekyouHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"status": "ok"}).encode())
        elif self.path == "/mcp/v1/info":
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            info = {
                "name": "mangekyou",
                "description": "Implementation planning via MCP (Nix compatible version)",
                "schema": {
                    "type": "object",
                    "properties": {
                        "query": {
                            "type": "string", 
                            "description": "The implementation request"
                        }
                    },
                    "required": ["query"]
                },
                "version": "1.0.0"
            }
            self.wfile.write(json.dumps(info).encode())
        else:
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"status": "ok"}).encode())

    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        
        try:
            data = json.loads(post_data.decode('utf-8'))
            query = data.get('body', {}).get('query', 'Implementation Request')
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

## Note
This is using the simplified placeholder implementation for Nix environments."""
        
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        
        response = {"response": plan}
        self.wfile.write(json.dumps(response).encode())
    
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'X-Requested-With, Content-Type, X-MCP-Version')
        self.end_headers()

print(f"Starting Mangekyou Placeholder on port {PORT}")
httpd = socketserver.TCPServer(("127.0.0.1", PORT), MangekyouHandler)
httpd.serve_forever()
EOL
    
    # Start the server
    python3 /tmp/mangekyou_http.py > "$LOG_FILE" 2>&1 &
    echo $! > "/tmp/mangekyou-placeholder.pid"
    echo "Server running in background with Python (PID: $!)"
    
  else
    echo "Error: Neither netcat nor Python available for HTTP server"
    echo "Falling back to CLI-only mode"
    
    # Get the query from command-line args
    QUERY="$*"
    
    # If no query was provided, show help
    if [ -z "$QUERY" ]; then
      echo "Usage: $0 <implementation request>"
      exit 1
    fi
    
    # Output a simple fixed implementation plan
    cat << EOF
# Implementation Plan for: $QUERY

## Changes Needed
1. Update configuration in src/config.rs
2. Implement core functionality in src/
3. Add tests

## Steps
1. [ ] Step 1: Design the feature
2. [ ] Step 2: Implement core code
3. [ ] Step 3: Test functionality
4. [ ] Step 4: Document changes

## Note
This is using the simplified placeholder implementation for Nix environments.
EOF
    exit 0
  fi
}

stop_server() {
  echo "Stopping Mangekyou placeholder server..."
  
  if [ -f "/tmp/mangekyou-placeholder.pid" ]; then
    PID=$(cat "/tmp/mangekyou-placeholder.pid")
    if kill -0 "$PID" 2>/dev/null; then
      kill "$PID"
      echo "Server stopped (PID: $PID)"
    else
      echo "Server not running with PID: $PID"
    fi
    rm -f "/tmp/mangekyou-placeholder.pid"
  fi
  
  # Check for port usage
  PORT_PID=$(lsof -ti:$PORT 2>/dev/null || echo "")
  if [ ! -z "$PORT_PID" ]; then
    kill "$PORT_PID" 2>/dev/null
    echo "Killed process using port $PORT (PID: $PORT_PID)"
  fi
}

check_status() {
  echo "Checking Mangekyou placeholder status..."
  
  if [ -f "/tmp/mangekyou-placeholder.pid" ]; then
    PID=$(cat "/tmp/mangekyou-placeholder.pid")
    if kill -0 "$PID" 2>/dev/null; then
      echo "Server running with PID: $PID"
      echo "Listening on http://$HOST:$PORT"
      return 0
    else
      echo "Server not running (stale PID file)"
      return 1
    fi
  else
    echo "Server not running (no PID file)"
    return 1
  fi
}

# Command handling
case "$1" in
  start)
    start_server
    ;;
  stop)
    stop_server
    ;;
  status)
    check_status
    ;;
  restart)
    stop_server
    start_server
    ;;
  *)
    # No command or query mode - start server if not running
    if [ -z "$1" ]; then
      if ! check_status > /dev/null; then
        start_server
      else
        echo "Server already running"
      fi
    else
      # Get the query from command-line args
      QUERY="$*"
      
      # Output a simple fixed implementation plan
      cat << EOF
# Implementation Plan for: $QUERY

## Changes Needed
1. Update configuration in src/config.rs
2. Implement core functionality in src/
3. Add tests

## Steps
1. [ ] Step 1: Design the feature
2. [ ] Step 2: Implement core code
3. [ ] Step 3: Test functionality
4. [ ] Step 4: Document changes

## Note
This is using the simplified placeholder implementation for Nix environments.
EOF
    fi
    ;;
esac