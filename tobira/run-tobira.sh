#!/usr/bin/env bash
set -e

# Navigate to the tobira directory
cd "$(dirname "$0")"
echo "Starting Shinri no Tobira hot-reloading development server..."

# Port for the server
PORT=8080

# Ensure clean startup by checking port
echo "Checking port availability..."
if ! (echo "" > /dev/tcp/127.0.0.1/$PORT) 2>/dev/null; then
    echo "Port $PORT is in use, freeing it..."
    
    if command -v fuser &> /dev/null; then
        fuser -k $PORT/tcp 2>/dev/null || true
        echo "Process terminated"
        sleep 1
    else
        echo "⚠️ Cannot free port automatically"
        echo "Please manually run: fuser -k $PORT/tcp"
        exit 1
    fi
fi

# Create required directories
mkdir -p dist

# Find trunk (it should already be installed)
if command -v trunk &> /dev/null; then
    echo "Found trunk in PATH"
    TRUNK_CMD="trunk"
elif [ -f "$HOME/.cargo/bin/trunk" ]; then
    echo "Found trunk in cargo bin"
    TRUNK_CMD="$HOME/.cargo/bin/trunk"
else
    # For Nix and other environments
    echo "Trunk not found - assuming it's available in your environment"
    TRUNK_CMD="trunk"
fi

# Ensure env.js exists with WASM MIME type fix
if [ ! -f "env.js" ]; then
    echo "Creating env.js with WebAssembly MIME type fix..."
    cat > env.js << 'EOF'
// Environment variables for iHoje Tobira frontend
window.ENV = {
  API_URL: 'http://localhost:3000',
  DEBUG: false
};

// WebAssembly MIME type fix
console.log('Adding WebAssembly MIME type fix');
const originalFetch = window.fetch;
window.fetch = function(input, init) {
  return originalFetch(input, init).then(response => {
    if (typeof input === 'string' && input.endsWith('.wasm')) {
      // Clone the response and override the Content-Type header
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
EOF
fi

# Start trunk with hotreloading
echo "Starting trunk server on http://localhost:$PORT..."
$TRUNK_CMD serve --open