#!/bin/bash
set -e

# Environment variables with defaults
ENVIRONMENT=${IHOJE_ENVIRONMENT:-"development"}
API_URL=${IHOJE_API_URL:-"http://localhost:8080/api"}
USE_MOCK_DATA=${IHOJE_USE_MOCK_DATA:-"true"}

echo "Building iHoje WebAssembly tobira for ${ENVIRONMENT} environment..."
echo "API URL: ${API_URL}"
echo "Use mock data: ${USE_MOCK_DATA}"

# Make sure tools are installed
if ! command -v wasm-pack &> /dev/null; then
    echo "wasm-pack not found, installing..."
    cargo install wasm-pack
fi

if ! command -v trunk &> /dev/null && [ "${USE_TRUNK:-false}" = "true" ]; then
    echo "trunk not found, installing..."
    cargo install trunk
fi

# Run security scan before building
if [ "${SKIP_SECURITY_SCAN:-false}" != "true" ]; then
    echo "Running security scan..."
    bash ./scripts/security-scan.sh || {
        echo "Security scan failed. Fix the issues or use SKIP_SECURITY_SCAN=true to bypass."
        exit 1
    }
fi

# Build method selection
if [ "${USE_TRUNK:-false}" = "true" ]; then
    # Build with trunk
    echo "Building with trunk..."
    trunk build --release
else
    # Build the WebAssembly package with wasm-pack
    echo "Building WebAssembly package with wasm-pack..."
    wasm-pack build --target web --out-name ihoje_tobira --out-dir ./pkg

    # Create static directory if it doesn't exist
    mkdir -p ./dist/static

    # Copy static files
    echo "Copying static files..."
    cp -r ./src/static/* ./dist/static/ || echo "No static files to copy"
    cp ./index.html ./dist/
    cp -r ./pkg ./dist/
fi

# Create environment configuration script
echo "Creating environment configuration script..."
NODE_ENV="${ENVIRONMENT}" node ./scripts/inject-env.js

# Verify security headers
echo "Verifying security headers..."
if ! grep -q "Content-Security-Policy" ./dist/index.html; then
    echo "WARNING: Content-Security-Policy header not found in index.html"
fi

echo "Build completed successfully!"
echo "To serve the application, run: cd dist && python3 -m http.server 8080"