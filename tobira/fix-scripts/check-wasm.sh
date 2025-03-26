#!/bin/bash
# WASM validation script for Shinri no Tobira

set -e

# Change to the tobira directory
cd "$(dirname "$0")"
cd ..

echo "Checking WebAssembly configuration..."

# Check if dist directory exists
if [ ! -d "dist" ]; then
    echo "❌ ERROR: dist directory not found!"
    echo "Run ./fix-scripts/build-frontend.sh first"
    exit 1
fi

# Check for required files
required_files=(
    "dist/index.html"
    "dist/bootstrap.js"
    "dist/env.js"
    "dist/ihoje-tobira.js"
)

wasm_files=(
    "dist/ihoje-tobira_bg.wasm"
    "dist/ihoje_frontend_bg.wasm"
)

# Check required files
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ ERROR: $file not found!"
        missing_files=true
    else
        echo "✅ $file exists"
    fi
done

# Check that at least one WASM file exists
wasm_found=false
for file in "${wasm_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ WASM file found: $file"
        wasm_found=true
    fi
done

if [ "$wasm_found" = false ]; then
    echo "❌ ERROR: No WASM file found!"
    missing_files=true
fi

# Exit if files are missing
if [ "$missing_files" = true ]; then
    echo "Missing required files. Run ./fix-scripts/build-frontend.sh"
    exit 1
fi

# Check MIME type handling in server
echo "Checking server MIME type handling..."
if grep -q 'application/wasm' fixed_server.py; then
    echo "✅ Server correctly configures WebAssembly MIME type"
else
    echo "❌ Server doesn't properly handle WebAssembly MIME type"
fi

# Check JavaScript bootstrap
echo "Checking JavaScript WASM bootstrap..."
if grep -q 'import.*ihoje-tobira.js' dist/bootstrap.js || grep -q 'import.*ihoje-tobira.js' dist/index.html; then
    echo "✅ JavaScript correctly imports WebAssembly module"
else
    echo "❌ JavaScript doesn't properly import WebAssembly module"
fi

echo "✨ Check completed"
echo "To start the server, run: python3 fixed_server.py 8081 dist"
