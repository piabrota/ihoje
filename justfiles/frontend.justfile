# Frontend Justfile for iHoje WebAssembly

# Set working directory to frontend
_set-dir:
    cd "$(git rev-parse --show-toplevel)/frontend"
    
# Setup WebAssembly toolchain
setup-wasm:
    #!/usr/bin/env bash
    echo "Setting up WebAssembly target..."
    cd "$(git rev-parse --show-toplevel)"
    rustup target add wasm32-unknown-unknown || echo "rustup not available, make sure to add wasm32-unknown-unknown target manually"
    cargo install wasm-pack || echo "wasm-pack installation skipped, make sure it's already installed"
    echo "WebAssembly setup complete! Make sure LLD linker is installed"

# Default task shows help
default:
    @just --justfile {{justfile()}} help

# Help information
help:
    @echo "=== Frontend Commands ==="
    @echo ""
    @echo "Setup:"
    @echo "  setup-wasm  - Setup WebAssembly toolchain"
    @echo ""
    @echo "Building:"
    @echo "  build       - Build WebAssembly frontend"
    @echo "  clean       - Clean build artifacts"
    @echo ""
    @echo "Development:"
    @echo "  serve       - Serve the frontend locally"
    @echo "  dev         - Start dev server with auto-reload"
    @echo "  dev-mock    - Start dev server with mock data"
    @echo "  dev-docker  - Start dev server in Docker"
    @echo "  dev-docker-mock - Start dev server with mock data in Docker"
    @echo "  check       - Check for errors"
    @echo ""
    @echo "Docker:"
    @echo "  docker-build - Build frontend Docker image"
    @echo "  docker-clean - Remove frontend Docker image"
    @echo "  restart-mock - Restart mock frontend with latest changes (port 8080)"
    @echo "  restart-wasm - Restart WebAssembly frontend with latest changes (port 8081)"
    @echo "  redeploy-frontend - Redeploy both mock and WebAssembly frontend containers with separate ports"
    @echo ""
    @echo "Deployment:"
    @echo "  release     - Build optimized release"
    @echo "  bundle      - Create deployable bundle"
    @echo ""
    @echo "Testing:"
    @echo "  test        - Run frontend tests"
    @echo "  lint        - Run linting"
    @echo ""

# Build frontend
build: _set-dir
    #!/usr/bin/env bash
    cd "$(git rev-parse --show-toplevel)/frontend"
    echo "Building WebAssembly frontend..."
    
    # Make sure wasm-pack is installed
    if ! command -v wasm-pack &> /dev/null; then
        echo "wasm-pack not found, installing..."
        cargo install wasm-pack
    fi
    
    # Build the WebAssembly package
    wasm-pack build --target web --out-name ihoje_frontend --out-dir ./pkg
    
    # Create static directory if it doesn't exist
    mkdir -p ./dist/static
    
    # Copy static files
    cp -r ./src/static/* ./dist/static/ 2>/dev/null || true
    cp ./index.html ./dist/
    cp -r ./pkg ./dist/
    
    echo "Build completed successfully!"

# Clean build artifacts
clean: _set-dir
    #!/usr/bin/env bash
    cd "$(git rev-parse --show-toplevel)/frontend"
    echo "Cleaning build artifacts..."
    rm -rf ./pkg
    rm -rf ./dist
    rm -rf ./target
    echo "Clean completed successfully!"

# Serve the frontend locally
serve: _set-dir build
    #!/usr/bin/env bash
    cd "$(git rev-parse --show-toplevel)/frontend"
    echo "Serving frontend on http://localhost:8080..."
    cd dist && python3 -m http.server 8080

# Start dev server with auto-reload
dev: _set-dir
    #!/usr/bin/env bash
    cd "$(git rev-parse --show-toplevel)/frontend"
    
    # Use the direct script for more reliable execution
    ./run-frontend-direct.sh

# Start dev server with mock data
dev-mock: _set-dir
    #!/usr/bin/env bash
    cd "$(git rev-parse --show-toplevel)/frontend"
    
    # Use the direct script with mock data flag
    ./run-frontend-direct.sh --mock

# Check for errors
check: _set-dir
    #!/usr/bin/env bash
    cd "$(git rev-parse --show-toplevel)/frontend"
    echo "Checking for errors..."
    cargo check

# Build optimized release
release: _set-dir
    #!/usr/bin/env bash
    cd "$(git rev-parse --show-toplevel)/frontend"
    echo "Building optimized release..."
    wasm-pack build --target web --out-name ihoje_frontend --out-dir ./pkg --release
    
    # Create static directory if it doesn't exist
    mkdir -p ./dist/static
    
    # Copy static files
    cp -r ./src/static/* ./dist/static/ 2>/dev/null || true
    cp ./index.html ./dist/
    cp -r ./pkg ./dist/
    
    echo "Release build completed successfully!"

# Create deployable bundle
bundle: _set-dir release
    #!/usr/bin/env bash
    cd "$(git rev-parse --show-toplevel)/frontend"
    echo "Creating deployable bundle..."
    zip -r ihoje-frontend.zip dist
    echo "Bundle created at ./ihoje-frontend.zip"

# Run frontend tests
test: _set-dir
    #!/usr/bin/env bash
    cd "$(git rev-parse --show-toplevel)/frontend"
    echo "Running tests..."
    wasm-pack test --headless --chrome

# Run linting
lint: _set-dir
    #!/usr/bin/env bash
    cd "$(git rev-parse --show-toplevel)/frontend"
    echo "Running clippy lints..."
    cargo clippy -- -D warnings

# Build frontend Docker image
docker-build:
    #!/usr/bin/env bash
    ROOT_DIR="$(git rev-parse --show-toplevel)"
    cd "$ROOT_DIR"
    echo "Building frontend Docker image..."
    
    # Detect if podman is available, otherwise use docker
    if command -v podman &> /dev/null; then
        CONTAINER_CMD="podman"
    else
        CONTAINER_CMD="docker"
    fi
    
    # Get current date in ISO format for Docker build
    BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
    
    echo "Using container command: $CONTAINER_CMD"
    # Build all frontend images with correct timestamps
    $CONTAINER_CMD build -t ihoje-frontend:dev -f frontend/Dockerfile --target dev --build-arg BUILD_DATE="$BUILD_DATE" .
    $CONTAINER_CMD build -t ihoje-frontend:mock -f frontend/Dockerfile --target mock --build-arg BUILD_DATE="$BUILD_DATE" .

# Remove frontend Docker images
docker-clean:
    #!/usr/bin/env bash
    echo "Removing frontend Docker images..."
    
    # Detect if podman is available, otherwise use docker
    if command -v podman &> /dev/null; then
        CONTAINER_CMD="podman"
    else
        CONTAINER_CMD="docker"
    fi
    
    # Remove both dev and mock images
    $CONTAINER_CMD rmi ihoje-frontend:dev 2>/dev/null || echo "No dev image to remove."
    $CONTAINER_CMD rmi ihoje-frontend:mock 2>/dev/null || echo "No mock image to remove."
    
# Restart mock frontend with latest changes
restart-mock:
    #!/usr/bin/env bash
    ROOT_DIR="$(git rev-parse --show-toplevel)"
    cd "$ROOT_DIR/frontend"
    
    # Use bash directly to run the script to avoid permission issues
    bash docker-restart.sh mock
    
# Restart WebAssembly frontend with latest changes
restart-wasm:
    #!/usr/bin/env bash
    ROOT_DIR="$(git rev-parse --show-toplevel)"
    cd "$ROOT_DIR/frontend"
    
    # Build WebAssembly frontend first
    echo "Building WebAssembly frontend..."
    just --justfile "$ROOT_DIR/justfiles/frontend.justfile" build
    
    # Use bash directly to run the script to avoid permission issues
    bash docker-restart.sh wasm
    
# Redeploy both mock and WebAssembly frontend containers
redeploy-frontend:
    #!/usr/bin/env bash
    ROOT_DIR="$(git rev-parse --show-toplevel)"
    
    echo "🔄 Redeploying both frontend containers..."
    
    # Check if the run-both-frontends.sh script exists
    if [ ! -f "$ROOT_DIR/frontend/run-both-frontends.sh" ]; then
        echo "🔧 Setting up Docker frontends with separate ports..."
        bash "$ROOT_DIR/setup-docker-frontends.sh"
    fi
    
    # Make sure the script is executable
    chmod +x "$ROOT_DIR/frontend/run-both-frontends.sh"
    
    # Run the script to deploy both frontends using bash to ensure it works
    cd "$ROOT_DIR/frontend" && bash ./run-both-frontends.sh
    
    echo "✅ Both frontend containers have been redeployed!"
    echo "📱 Mock frontend: http://localhost:8080"
    echo "🧩 WebAssembly frontend: http://localhost:8081"
    
# Start dev server in Docker
dev-docker: docker-build
    #!/usr/bin/env bash
    echo "Starting frontend dev server in Docker on http://localhost:8080..."
    
    # Detect if podman is available, otherwise use docker
    if command -v podman &> /dev/null; then
        CONTAINER_CMD="podman"
    else
        CONTAINER_CMD="docker"
    fi
    
    ROOT_DIR="$(git rev-parse --show-toplevel)"
    # Start container with -t flag but don't require stdin
    $CONTAINER_CMD run --rm -t -p 8080:8080 \
        -v "$ROOT_DIR/frontend/src:/app/frontend/src:Z" \
        -v "$ROOT_DIR/frontend/index.html:/app/frontend/index.html:Z" \
        -v "$ROOT_DIR/ihoje_models:/app/ihoje_models:Z" \
        ihoje-frontend:dev

# Start dev server with mock data in Docker
dev-docker-mock: docker-build
    #!/usr/bin/env bash
    echo "Starting frontend dev server with mock data in Docker on http://localhost:8080..."
    
    # Detect if podman is available, otherwise use docker
    if command -v podman &> /dev/null; then
        CONTAINER_CMD="podman"
    else
        CONTAINER_CMD="docker"
    fi
    
    ROOT_DIR="$(git rev-parse --show-toplevel)"
    
    # Start container with -t flag but don't require stdin
    $CONTAINER_CMD run --rm -t -p 8080:8080 \
        -v "$ROOT_DIR/frontend/src:/app/frontend/src:Z" \
        -v "$ROOT_DIR/frontend/index.html:/app/frontend/index.html:Z" \
        -v "$ROOT_DIR/ihoje_models:/app/ihoje_models:Z" \
        ihoje-frontend:mock
        
    # Display Docker images to show their creation time
    echo "Current frontend Docker images:"
    $CONTAINER_CMD images ihoje-frontend