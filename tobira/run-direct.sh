#!/bin/bash
# Direct run script that serves the Tobira app using a Python server with proper MIME types
set -e

# Default port
PORT=8081
DIRECTORY="$(dirname "$0")/dist"

# Kill any process running on the port
kill_port() {
  local port=$1
  local pid=$(lsof -ti :$port 2>/dev/null)
  if [ -n "$pid" ]; then
    echo "Killing process $pid on port $port"
    kill -9 $pid 2>/dev/null || true
    sleep 1
  fi
}

# Create a simple SPA server python file
create_server_file() {
  cat > /tmp/wasm_server.py << 'EOF'
#!/usr/bin/env python3
import http.server
import socketserver
import os
import sys

class WasmHandler(http.server.SimpleHTTPRequestHandler):
    # Override MIME types
    extensions_map = {
        **http.server.SimpleHTTPRequestHandler.extensions_map,
        ".wasm": "application/wasm",
    }
    
    def end_headers(self):
        # Add CORS headers
        self.send_header("Access-Control-Allow-Origin", "*")
        # Force correct MIME type for WASM
        if self.path.endswith('.wasm'):
            self.send_header("Content-Type", "application/wasm")
        http.server.SimpleHTTPRequestHandler.end_headers(self)
    
    def do_GET(self):
        print(f"GET: {self.path}")
        # Special handling for WASM files
        if self.path.endswith('.wasm'):
            print(f"Serving WASM file with application/wasm MIME type")
            # Get the actual file path
            filepath = os.path.join(os.getcwd(), self.path.lstrip("/"))
            if os.path.exists(filepath):
                with open(filepath, 'rb') as f:
                    content = f.read()
                    self.send_response(200)
                    self.send_header("Content-Type", "application/wasm")
                    self.send_header("Content-Length", str(len(content)))
                    self.end_headers()
                    self.wfile.write(content)
                    return
        
        # SPA routing - serve index.html for any non-existent path
        file_path = os.path.join(os.getcwd(), self.path.lstrip("/"))
        if self.path != "/" and not os.path.exists(file_path):
            self.path = '/index.html'
        
        return http.server.SimpleHTTPRequestHandler.do_GET(self)

def main():
    # Get command line arguments
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8081
    directory = sys.argv[2] if len(sys.argv) > 2 else '.'
    
    # Change to the specified directory
    try:
        os.chdir(directory)
        print(f"Serving files from: {os.getcwd()}")
    except:
        print(f"Error: Could not change to directory {directory}")
        sys.exit(1)
    
    # Set up the server
    handler = WasmHandler
    server = socketserver.TCPServer(("", port), handler)
    
    print(f"Starting server on http://localhost:{port}")
    print("WebAssembly MIME type: application/wasm")
    print("Press Ctrl+C to stop")
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped")
    finally:
        server.server_close()

if __name__ == "__main__":
    main()
EOF
  chmod +x /tmp/wasm_server.py
}

# Ensure the directory exists
if [ ! -d "$DIRECTORY" ]; then
  echo "Creating dist directory"
  mkdir -p "$DIRECTORY"
fi

# Create a basic HTML file if not exists
if [ ! -f "$DIRECTORY/index.html" ]; then
  echo "Creating basic index.html"
  cat > "$DIRECTORY/index.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Tobira - WebAssembly App</title>
  <script>
    window.ENV = {
      API_URL: 'http://localhost:3000',
      DEBUG: true
    };
    
    // WebAssembly MIME type fix
    const originalFetch = window.fetch;
    window.fetch = function(input, init) {
      return originalFetch(input, init).then(response => {
        if (typeof input === 'string' && input.endsWith('.wasm')) {
          return response.clone().blob().then(blob => {
            return new Response(blob, {
              status: response.status,
              statusText: response.statusText,
              headers: new Headers({
                'Content-Type': 'application/wasm'
              })
            });
          });
        }
        return response;
      });
    };
  </script>
</head>
<body>
  <div id="app">
    <h1>Tobira - Loading...</h1>
    <div class="loading-spinner"></div>
  </div>
</body>
</html>
EOF
fi

# Kill any existing process on the port
kill_port $PORT

# Create the server file
create_server_file

# Start the server
echo "Starting Tobira server on http://localhost:$PORT"
python3 /tmp/wasm_server.py $PORT "$DIRECTORY"