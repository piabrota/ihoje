#!/bin/bash
# A simple direct script to run Tobira with proper WASM MIME type handling
set -e

PORT=8081
DIR="$(dirname "$0")/dist"
WASM_PATH="$DIR/pkg"

# Kill any process running on the port
function kill_port() {
  local pid=$(lsof -ti :$PORT 2>/dev/null)
  if [ -n "$pid" ]; then
    echo "Killing process $pid on port $PORT"
    kill -9 $pid 2>/dev/null || true
    sleep 1
  fi
}

# Ensure pkg directory exists
if [ ! -d "$WASM_PATH" ]; then
  echo "Creating pkg directory"
  mkdir -p "$WASM_PATH"
fi

# Check for minimal WASM file
if [ ! -f "$WASM_PATH/ihoje_frontend_bg.wasm" ]; then
  echo "WARNING: No WASM file found in $WASM_PATH"
  echo "Creating minimal placeholder WASM file"
  # Create a minimal valid WASM module
  printf "\0asm\1\0\0\0" > "$WASM_PATH/ihoje_frontend_bg.wasm"
  echo '// Placeholder JavaScript for WASM module
export default async function init() {
  console.log("This is a placeholder WASM module");
  return { instance: { exports: {} } };
}' > "$WASM_PATH/ihoje_frontend.js"
fi

# Create auth-debug.js if not exists
if [ ! -f "$DIR/auth-debug.js" ]; then
  cp -f "$(dirname "$0")/auth-debug.js" "$DIR/" 2>/dev/null || {
    echo "Creating auth-debug.js"
    cat > "$DIR/auth-debug.js" << 'EOF'
// Debug helper for auth and WASM issues
console.log("Auth debug helper loaded");

// WebAssembly MIME type fix - must run before any other scripts
console.log("Adding robust WebAssembly MIME type fix");

// Patch the fetch API to fix WASM MIME types
const originalFetch = window.fetch;
window.fetch = function(input, init) {
    return originalFetch(input, init).then(response => {
        // For WASM files, ensure proper MIME type
        if (typeof input === 'string' && input.endsWith('.wasm')) {
            console.log("WASM fix applied to:", input);
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

// Also fix WebAssembly.instantiateStreaming if it exists
if (typeof WebAssembly !== 'undefined' && WebAssembly.instantiateStreaming) {
    const originalInstantiateStreaming = WebAssembly.instantiateStreaming;
    WebAssembly.instantiateStreaming = function(responsePromise, importObject) {
        return responsePromise
            .then(response => {
                const contentType = response.headers.get('Content-Type');
                if (!contentType || !contentType.includes('application/wasm')) {
                    console.log("Converting response to arrayBuffer for WebAssembly.instantiateStreaming");
                    return WebAssembly.instantiate(response.clone().arrayBuffer(), importObject);
                }
                return originalInstantiateStreaming(Promise.resolve(response), importObject);
            })
            .catch(error => {
                console.error("WebAssembly.instantiateStreaming error:", error);
                // Try to recover using the slower instantiate method
                return responsePromise
                    .then(response => response.arrayBuffer())
                    .then(buffer => WebAssembly.instantiate(buffer, importObject));
            });
    };
}

console.log("WebAssembly support:", typeof WebAssembly === 'object');
console.log("WebAssembly.instantiate support:", typeof WebAssembly.instantiate === 'function');
console.log("WebAssembly.instantiateStreaming support:", typeof WebAssembly.instantiateStreaming === 'function');

// Add helper function to diagnose WASM loading issues
window.testWasmLoading = async function(url) {
    try {
        console.log("Testing WASM loading from:", url);
        const response = await fetch(url);
        console.log("Response status:", response.status);
        console.log("Response headers:", Object.fromEntries([...response.headers.entries()]));
        
        const arrayBuffer = await response.clone().arrayBuffer();
        console.log("ArrayBuffer size:", arrayBuffer.byteLength);
        console.log("First bytes:", new Uint8Array(arrayBuffer.slice(0, 8)).join(' '));
        
        // Check for WASM magic number
        const magic = new Uint8Array(arrayBuffer.slice(0, 4));
        const isMagicCorrect = magic[0] === 0 && magic[1] === 97 && magic[2] === 115 && magic[3] === 109; // "\0asm"
        console.log("WASM magic correct:", isMagicCorrect);
        
        if (!isMagicCorrect) {
            const text = await response.clone().text();
            console.log("Content starts with:", text.substring(0, 100));
            return {success: false, error: "Not a valid WASM file"};
        }
        
        return {success: true};
    } catch (error) {
        console.error("WASM testing error:", error);
        return {success: false, error: error.toString()};
    }
};
EOF
  }
fi

# Create env.js if not exists
if [ ! -f "$DIR/env.js" ]; then
  cp -f "$(dirname "$0")/env.js" "$DIR/" 2>/dev/null || {
    echo "Creating env.js"
    cat > "$DIR/env.js" << 'EOF'
// Environment variables for iHoje Tobira frontend
window.ENV = {
  API_URL: 'http://localhost:3000',
  DEBUG: true
};

// Enhanced WASM loading debug
console.log("ENV.js loaded with API_URL:", window.ENV.API_URL);

// Helper to log WASM loading attempts
let wasmAttempts = [];
let originalXHROpen = XMLHttpRequest.prototype.open;
XMLHttpRequest.prototype.open = function() {
  const url = arguments[1];
  if (typeof url === 'string' && url.endsWith('.wasm')) {
    console.log("XHR requesting WASM file:", url);
    wasmAttempts.push({
      time: new Date().toISOString(),
      url,
      method: arguments[0]
    });
  }
  return originalXHROpen.apply(this, arguments);
};

// Expose helper function to check WASM requests
window.getWasmAttempts = function() {
  return wasmAttempts;
};
EOF
  }
fi

# Create bootstrap.js if it doesn't exist
if [ ! -f "$DIR/bootstrap.js" ]; then
  echo "Creating bootstrap.js"
  cat > "$DIR/bootstrap.js" << 'EOF'
// Bootstrap WebAssembly initialization
import init from './pkg/ihoje_frontend.js';

// Add error handling to catch and report issues
try {
  console.log("Initializing WebAssembly module...");
  init()
    .then(wasm => {
      console.log("WebAssembly module initialized successfully!");
      // Check if we need to enable mock data
      if (window.ENV && window.ENV.DEBUG) {
        if (typeof wasm.enable_mock_data === 'function') {
          console.log("Enabling mock data mode...");
          wasm.enable_mock_data();
        } else {
          console.log("Mock data function not available");
        }
      }
    })
    .catch(err => {
      console.error("Error initializing WebAssembly:", err);
      document.getElementById('app').innerHTML = `
        <div style="padding: 2rem; color: #d00; background: #fff2f2; border: 1px solid #faa; border-radius: 0.5rem; margin: 2rem;">
          <h2>WebAssembly Error</h2>
          <p>${err.toString()}</p>
          <p>Check the browser console for more details.</p>
        </div>
      `;
    });
} catch (err) {
  console.error("Critical error loading WebAssembly:", err);
}
EOF
fi

# Kill any existing process on the port
kill_port

# Create a simple Python server that correctly handles MIME types
cat > "/tmp/wasm_server_$PORT.py" << 'EOF'
#!/usr/bin/env python3
import http.server
import socketserver
import os
import sys

class WasmHandler(http.server.SimpleHTTPRequestHandler):
    # Define MIME types
    extensions_map = {
        **http.server.SimpleHTTPRequestHandler.extensions_map,
        ".wasm": "application/wasm",
        ".js": "application/javascript",
        ".css": "text/css",
        ".html": "text/html",
        ".svg": "image/svg+xml",
        ".json": "application/json",
    }
    
    def end_headers(self):
        # Add CORS headers
        self.send_header("Access-Control-Allow-Origin", "*")
        # Force correct MIME type for WASM
        if self.path.endswith('.wasm'):
            self.send_header("Content-Type", "application/wasm")
        # Add other common headers
        self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
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
        
        # SPA routing - serve index.html for any path that doesn't exist
        file_path = os.path.join(os.getcwd(), self.path.lstrip("/"))
        if self.path != "/" and not os.path.exists(file_path) and not "." in self.path:
            print(f"SPA routing: {self.path} -> /index.html")
            self.path = '/index.html'
        
        return http.server.SimpleHTTPRequestHandler.do_GET(self)

# Get port from command line or use default
port = int(sys.argv[1]) if len(sys.argv) > 1 else 8081
directory = sys.argv[2] if len(sys.argv) > 2 else '.'

# Change to the specified directory
if os.path.exists(directory):
    os.chdir(directory)
    print(f"Serving files from: {os.getcwd()}")
else:
    print(f"Error: Directory {directory} not found!")
    sys.exit(1)

# Set up and start the server
handler = WasmHandler
httpd = socketserver.TCPServer(("", port), handler)

print(f"Starting server on http://localhost:{port}")
print(f"WebAssembly MIME type: application/wasm")
print("Press Ctrl+C to stop the server")

try:
    httpd.serve_forever()
except KeyboardInterrupt:
    print("\nServer stopped by user")
finally:
    httpd.server_close()
EOF

chmod +x "/tmp/wasm_server_$PORT.py"

# Start the server
echo "Starting Tobira on http://localhost:$PORT"
echo "Serving files from: $DIR"
python3 "/tmp/wasm_server_$PORT.py" $PORT "$DIR"