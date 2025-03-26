#!/bin/bash
# Script to fix the WebAssembly frontend in one command

set -e

cd "$(dirname "$0")"
cd ..

echo "🔧 Fixing Shinri no Tobira WebAssembly frontend..."

# Create output directories
mkdir -p dist
mkdir -p dist/static

# 1. First check if we can build the WebAssembly package
if command -v wasm-pack &> /dev/null; then
    echo "🔄 Building WebAssembly package with wasm-pack..."
    wasm-pack build --target web --out-name ihoje-tobira --out-dir ./pkg
    WASM_BUILD_SUCCESS=$?
else
    echo "⚠️ wasm-pack not found, will try to use existing WASM files if available"
    WASM_BUILD_SUCCESS=1
fi

# 2. Copy existing static files
echo "📂 Copying static files..."
if [ -d "src/static" ]; then
    cp -r src/static/* dist/static/
else
    echo "⚠️ No static files found in src/static"
    mkdir -p dist/static/images
    # Create fallback images
    for i in {1..4}; do
        echo '<svg xmlns="http://www.w3.org/2000/svg" width="800" height="450" viewBox="0 0 800 450"><rect width="800" height="450" fill="#7000ff" /><text x="400" y="225" font-family="Arial" font-size="48" text-anchor="middle" fill="white">Shinri no Tobira '$i'</text></svg>' > "dist/static/images/event$i.svg"
    done
fi

# 3. Copy and verify the fixed files
echo "📄 Setting up fixed frontend files..."
cp fixed_index.html dist/index.html
cp fixed_bootstrap.js dist/bootstrap.js
cp env.js dist/env.js
chmod +x fixed_server.py

# 4. Handle WebAssembly files
if [ $WASM_BUILD_SUCCESS -eq 0 ]; then
    echo "📦 Copying newly built WebAssembly files..."
    cp -r pkg/* dist/
else
    echo "🔍 Looking for existing WebAssembly files..."
    # Try to find and copy WebAssembly files from various locations
    if [ -d "pkg" ]; then
        cp -r pkg/* dist/
    elif [ -d "dist/pkg" ]; then
        cp -r dist/pkg/* dist/
    fi
fi

# 5. Fix file names if needed
echo "🔄 Ensuring consistent file naming..."
if [ -f "dist/ihoje_frontend_bg.wasm" ] && [ ! -f "dist/ihoje-tobira_bg.wasm" ]; then
    echo "  - Renaming WASM file: ihoje_frontend_bg.wasm → ihoje-tobira_bg.wasm"
    cp dist/ihoje_frontend_bg.wasm dist/ihoje-tobira_bg.wasm
fi

if [ -f "dist/ihoje_frontend.js" ] && [ ! -f "dist/ihoje-tobira.js" ]; then
    echo "  - Renaming JS file: ihoje_frontend.js → ihoje-tobira.js"
    cp dist/ihoje_frontend.js dist/ihoje-tobira.js
fi

# 6. Check if we have the necessary files
echo "✅ Verifying required files..."
missing_files=false

required_files=(
    "dist/index.html"
    "dist/bootstrap.js"
    "dist/env.js"
)

if [ ! -f "dist/ihoje-tobira.js" ] && [ ! -f "dist/ihoje_frontend.js" ]; then
    echo "❌ ERROR: No JavaScript entry point found!"
    missing_files=true
fi

if [ ! -f "dist/ihoje-tobira_bg.wasm" ] && [ ! -f "dist/ihoje_frontend_bg.wasm" ]; then
    echo "❌ ERROR: No WebAssembly file found!"
    missing_files=true
fi

for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ ERROR: $file not found!"
        missing_files=true
    fi
done

if [ "$missing_files" = true ]; then
    echo "⚠️ Some required files are missing. The WebAssembly frontend may not work correctly."
    echo "   You may need to rebuild with wasm-pack or check your file paths."
else
    echo "✅ All required files present."
fi

# 7. Start the server
echo ""
echo "🚀 WebAssembly frontend is ready!"
echo "   To start the server, run: python3 fixed_server.py 8081 dist"
echo ""
echo "   Or simply run: cd fix-scripts && ./launch-tobira.sh"