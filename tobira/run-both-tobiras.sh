#!/bin/bash
# Script to run both mock and WebAssembly tobiras simultaneously
set -e

echo "Starting both tobiras in separate containers..."

# Stop any existing containers first
docker ps -a | grep ihoje-mock && docker stop ihoje-mock && docker rm ihoje-mock || true
docker ps -a | grep ihoje-wasm && docker stop ihoje-wasm && docker rm ihoje-wasm || true

# Copy the spa_server.py file to the current directory if it doesn't exist
if [ ! -f "spa_server.py" ]; then
  echo "Creating spa_server.py..."
  cat > spa_server.py << 'EOF'
#!/usr/bin/env python3
import http.server
import socketserver
import os
import sys

class SPAHandler(http.server.SimpleHTTPRequestHandler):
    # Override the default MIME types to ensure WebAssembly files are served correctly
    extensions_map = {
        **http.server.SimpleHTTPRequestHandler.extensions_map,
        ".wasm": "application/wasm",
    }
    
    def end_headers(self):
        # Add CORS headers to allow fetch requests
        self.send_header("Access-Control-Allow-Origin", "*")
        # Explicitly set WASM MIME type for all .wasm files
        if self.path.endswith('.wasm'):
            self.send_header("Content-Type", "application/wasm")
        http.server.SimpleHTTPRequestHandler.end_headers(self)
    
    def do_GET(self):
        print(f"GET request for: {self.path}")
        # For WASM files, add special handling
        if self.path.endswith('.wasm'):
            print(f"  -> Serving WASM file with application/wasm MIME type")
            # Ensure specific content type for .wasm files
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
        
        # Handle other files or SPA routing
        requested_path = self.path.lstrip('/')
        file_path = os.path.join(os.getcwd(), requested_path)
        
        # If file doesn't exist, serve index.html for SPA routing
        if requested_path and not os.path.exists(file_path):
            self.path = '/index.html'
            print(f"  -> File not found, serving index.html for SPA routing")
        
        return http.server.SimpleHTTPRequestHandler.do_GET(self)

def run_server(port=8081, directory="dist"):
    # Change to the specified directory
    if os.path.exists(directory):
        os.chdir(directory)
        print(f"Changed to directory: {os.getcwd()}")
    else:
        print(f"Error: Directory {directory} not found!")
        sys.exit(1)
    
    # Create and start the server
    handler = SPAHandler
    httpd = socketserver.TCPServer(("", port), handler)
    
    print(f"Starting SPA server on http://localhost:{port}")
    print(f"Serving files from: {os.getcwd()}")
    print(f"WebAssembly MIME type: application/wasm")
    print("Press Ctrl+C to stop the server")
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped by user")
    finally:
        httpd.server_close()

if __name__ == "__main__":
    port = 8081
    directory = "dist"
    
    # Parse command line arguments
    if len(sys.argv) > 1:
        try:
            port = int(sys.argv[1])
        except ValueError:
            print(f"Invalid port number: {sys.argv[1]}, using default: {port}")
    
    if len(sys.argv) > 2:
        directory = sys.argv[2]
    
    run_server(port, directory)
EOF
  chmod +x spa_server.py
fi

# Build and start mock tobira (port 8080)
echo "🏗️ Building and starting mock tobira on port 8080..."
# Simple mock version only needs to build from the tobira directory
docker build -t shinri-no-tobira:simple -f Dockerfile.simple .
docker run -d -p 8080:8080 --name ihoje-mock shinri-no-tobira:simple

# Build WebAssembly tobira with proper error handling
echo "🏗️ Building WebAssembly tobira on port 8081..."
echo "Note: This may take a few minutes for the first build."

# For WebAssembly, we need to be in the project root for the build to work correctly
cd ..
if docker build -t shinri-no-tobira:latest -f tobira/Dockerfile .; then
  echo "✅ WebAssembly build successful, starting container..."
  docker run -d -p 8081:8081 --name ihoje-wasm shinri-no-tobira:latest
  if [ $? -ne 0 ]; then
    echo "⚠️ Failed to run WebAssembly container, fixing port mapping..."
    # Try with different port mapping in case the container uses 8080 internally
    docker run -d -p 8081:8080 --name ihoje-wasm shinri-no-tobira:latest
  fi
else
  echo "⚠️ WebAssembly tobira build failed, only mock is available at http://localhost:8080"
fi

echo "✨ Both tobiras started!"
echo "📱 Mock tobira available at: http://localhost:8080"
echo "📱 WebAssembly tobira available at: http://localhost:8081"
echo ""
echo "📊 Container status:"
docker ps | grep ihoje

echo ""
echo "📝 To view logs: "
echo "  - Mock tobira: docker logs ihoje-mock"
echo "  - WebAssembly tobira: docker logs ihoje-wasm"
echo "🛑 To stop containers: "
echo "  - docker stop ihoje-mock ihoje-wasm"