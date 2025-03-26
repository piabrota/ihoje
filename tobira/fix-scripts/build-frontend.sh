#!/bin/bash
# Build script for Shinri no Tobira WebAssembly frontend

set -e

# Change to the tobira directory
cd "$(dirname "$0")"
cd ..

# Create the output directory
mkdir -p dist

# Check if wasm-pack needs to be installed
if ! command -v wasm-pack &> /dev/null; then
    echo "Installing wasm-pack..."
    cargo install wasm-pack
fi

# Build WebAssembly package
echo "Building WebAssembly package..."
wasm-pack build --target web --out-name ihoje-tobira --out-dir ./pkg

# Copy files to dist directory
echo "Copying files to dist directory..."
cp -r src/static dist/
cp fixed_index.html dist/index.html
cp fixed_bootstrap.js dist/bootstrap.js
cp env.js dist/env.js
cp -r pkg/* dist/

# Make sure the WASM file has the correct name
if [ -f "dist/ihoje_frontend_bg.wasm" ] && [ ! -f "dist/ihoje-tobira_bg.wasm" ]; then
    echo "Renaming WASM file for compatibility..."
    cp dist/ihoje_frontend_bg.wasm dist/ihoje-tobira_bg.wasm
fi

echo "Build completed successfully. To start the server:"
echo "python3 fixed_server.py 8081 dist"
