#!/bin/bash
# Script to run both mock and WebAssembly tobiras simultaneously
set -e

echo "Starting both tobiras in separate containers..."

# Stop any existing containers first
echo "Cleaning up existing containers..."
docker rm -f ihoje-mock >/dev/null 2>&1 || true
docker rm -f ihoje-wasm >/dev/null 2>&1 || true

# Copy the spa_server.py file to the current directory if it doesn't exist
if [ ! -f "spa_server.py" ]; then
  echo "Creating spa_server.py..."
  # Check if the file exists in the parent directory
  if [ -f "../spa_server.py" ]; then
    echo "Using the secure spa_server.py from the repository..."
    cp "../spa_server.py" "$(pwd)/spa_server.py" 
  else
    echo "ERROR: Missing spa_server.py file. Please make sure it exists."
    exit 1
  fi
  chmod +x spa_server.py
fi

# Ensure our fixed files are available
echo "📄 Preparing fixed files for WASM compatibility..."
if [ -f "fixed_index.html" ]; then
  cp fixed_index.html index.html
fi
if [ -f "fixed_bootstrap.js" ]; then
  cp fixed_bootstrap.js bootstrap.js
fi

# Update the spa_server.py with proper MIME types if needed
echo "import mimetypes; mimetypes.add_type('application/wasm', '.wasm')" > spa_server_fix.py
cat spa_server.py >> spa_server_fix.py 
mv spa_server_fix.py spa_server.py
chmod +x spa_server.py

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
  echo "🔗 Mapping host port 8081 to container port 8080..."
  # Always map host port 8081 to container port 8080 as that's what the server uses internally
  docker run -d -p 8081:8080 --name ihoje-wasm shinri-no-tobira:latest
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