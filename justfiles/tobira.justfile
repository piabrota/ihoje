# Tobira (Gate of Truth) Justfile for iHoje WebAssembly

# Set working directory to tobira
_set-dir:
    cd "$(git rev-parse --show-toplevel)/tobira"
    
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
    @echo "=== Tobira (Gate of Truth) Commands ==="
    @echo ""
    @echo "Setup:"
    @echo "  setup-wasm  - Setup WebAssembly toolchain"
    @echo ""
    @echo "Building:"
    @echo "  build       - Build Tobira Gate"
    @echo "  clean       - Clean build artifacts"
    @echo ""
    @echo "Development (Docker Only):"
    @echo "  serve       - Serve Tobira locally (Docker only)"
    @echo "  dev         - Start dev server with auto-reload (Docker only)"
    @echo "  dev-mock    - Start dev server with mock data (Docker only)"
    @echo "  dev-docker  - Start dev server in Docker"
    @echo "  dev-docker-mock - Start dev server with mock data in Docker"
    @echo "  check       - Check for errors"
    @echo ""
    @echo "Docker:"
    @echo "  docker-build - Build Shinri no Tobira Docker image"
    @echo "  docker-clean - Remove Tobira Docker image"
    @echo "  restart-mock - Restart mock Tobira with latest changes (port 8080)"
    @echo "  restart-tobira - Restart Shinri no Tobira with latest changes (port 8081)"
    @echo "  redeploy-tobira - Redeploy both mock and Shinri no Tobira containers with separate ports"
    @echo ""
    @echo "Deployment:"
    @echo "  release     - Build optimized release"
    @echo "  bundle      - Create deployable bundle"
    @echo ""
    @echo "Testing:"
    @echo "  test        - Run Tobira tests"
    @echo "  lint        - Run linting"
    @echo ""

# Build Tobira
build: _set-dir
    #!/usr/bin/env bash
    cd "$(git rev-parse --show-toplevel)/tobira"
    echo "Building Tobira WebAssembly Gate..."
    
    # Make sure wasm-pack is installed
    if ! command -v wasm-pack &> /dev/null; then
        echo "wasm-pack not found, installing..."
        cargo install wasm-pack
    fi
    
    # Build the WebAssembly package
    wasm-pack build --target web --out-name ihoje_tobira --out-dir ./pkg
    
    # Create static directory if it doesn't exist
    mkdir -p ./dist/static
    
    # Copy static files
    cp -r ./src/static/* ./dist/static/ 2>/dev/null || true
    cp ./index.html ./dist/
    cp -r ./pkg ./dist/
    
    echo "Tobira Gate has been opened successfully!"

# Clean build artifacts
clean: _set-dir
    #!/usr/bin/env bash
    cd "$(git rev-parse --show-toplevel)/tobira"
    echo "Cleaning build artifacts..."
    rm -rf ./pkg
    rm -rf ./dist
    rm -rf ./target
    echo "Clean completed successfully!"

# Serve the Tobira locally (Docker only)
serve: dev-docker
    @echo "NOTE: Tobira serving is now Docker-only for consistency"

# Start dev server with auto-reload (Docker only)
dev: dev-docker
    @echo "NOTE: Tobira development is now Docker-only for consistency"

# Start dev server with mock data (Docker only)
dev-mock: dev-docker-mock
    @echo "NOTE: Tobira development is now Docker-only for consistency"

# Check for errors
check: _set-dir
    #!/usr/bin/env bash
    cd "$(git rev-parse --show-toplevel)/tobira"
    echo "Checking for errors..."
    cargo check

# Build optimized release
release: _set-dir
    #!/usr/bin/env bash
    cd "$(git rev-parse --show-toplevel)/tobira"
    echo "Building optimized Shinri no Tobira..."
    wasm-pack build --target web --out-name ihoje_tobira --out-dir ./pkg --release
    
    # Create static directory if it doesn't exist
    mkdir -p ./dist/static
    
    # Copy static files
    cp -r ./src/static/* ./dist/static/ 2>/dev/null || true
    cp ./index.html ./dist/
    cp -r ./pkg ./dist/
    
    echo "Shinri no Tobira release build completed successfully!"

# Create deployable bundle
bundle: _set-dir release
    #!/usr/bin/env bash
    cd "$(git rev-parse --show-toplevel)/tobira"
    echo "Creating Tobira deployable bundle..."
    zip -r shinri-no-tobira.zip dist
    echo "Bundle created at ./shinri-no-tobira.zip"

# Run Tobira tests
test: _set-dir
    #!/usr/bin/env bash
    cd "$(git rev-parse --show-toplevel)/tobira"
    echo "Running tests..."
    wasm-pack test --headless --chrome

# Run linting
lint: _set-dir
    #!/usr/bin/env bash
    cd "$(git rev-parse --show-toplevel)/tobira"
    echo "Running clippy lints..."
    cargo clippy -- -D warnings

# Build Tobira Docker image
docker-build:
    #!/usr/bin/env bash
    ROOT_DIR="$(git rev-parse --show-toplevel)"
    cd "$ROOT_DIR"
    echo "Building Shinri no Tobira Docker image..."
    
    # Detect if podman is available, otherwise use docker
    if command -v podman &> /dev/null; then
        CONTAINER_CMD="podman"
    else
        CONTAINER_CMD="docker"
    fi
    
    # Get current date in ISO format for Docker build
    BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
    
    echo "Using container command: $CONTAINER_CMD"
    # Build all Tobira images with correct timestamps
    $CONTAINER_CMD build -t shinri-no-tobira:dev -f tobira/Dockerfile --target dev --build-arg BUILD_DATE="$BUILD_DATE" .
    $CONTAINER_CMD build -t shinri-no-tobira:mock -f tobira/Dockerfile --target mock --build-arg BUILD_DATE="$BUILD_DATE" .
    $CONTAINER_CMD tag shinri-no-tobira:dev ihoje-tobira:latest

# Remove Tobira Docker images
docker-clean:
    #!/usr/bin/env bash
    echo "Removing Tobira Docker images..."
    
    # Detect if podman is available, otherwise use docker
    if command -v podman &> /dev/null; then
        CONTAINER_CMD="podman"
    else
        CONTAINER_CMD="docker"
    fi
    
    # Remove both dev and mock images
    $CONTAINER_CMD rmi shinri-no-tobira:dev 2>/dev/null || echo "No dev image to remove."
    $CONTAINER_CMD rmi shinri-no-tobira:mock 2>/dev/null || echo "No mock image to remove."
    $CONTAINER_CMD rmi ihoje-tobira:latest 2>/dev/null || echo "No latest image to remove."
    
# Restart mock Tobira with latest changes
restart-mock:
    #!/usr/bin/env bash
    ROOT_DIR="$(git rev-parse --show-toplevel)"
    cd "$ROOT_DIR/tobira"
    
    # Use bash directly to run the script to avoid permission issues
    bash docker-restart.sh mock
    
# Restart Shinri no Tobira with latest changes
restart-tobira:
    #!/usr/bin/env bash
    ROOT_DIR="$(git rev-parse --show-toplevel)"
    cd "$ROOT_DIR/tobira"
    
    # Build Tobira first
    echo "Building Shinri no Tobira..."
    just --justfile "$ROOT_DIR/justfiles/tobira.justfile" build
    
    # Use bash directly to run the script to avoid permission issues
    bash docker-restart.sh tobira
    
# Redeploy both mock and real Tobira containers
redeploy-tobira:
    #!/usr/bin/env bash
    ROOT_DIR="$(git rev-parse --show-toplevel)"
    
    echo "🔄 Redeploying both Tobira containers..."
    
    # Check if the run-both-tobiras.sh script exists
    if [ ! -f "$ROOT_DIR/tobira/run-both-tobiras.sh" ]; then
        echo "🔧 Setting up Docker Tobira with separate ports..."
        bash "$ROOT_DIR/setup-docker-tobiras.sh"
    fi
    
    # Make sure the script is executable
    chmod +x "$ROOT_DIR/tobira/run-both-tobiras.sh"
    
    # Run the script to deploy both frontends using bash to ensure it works
    cd "$ROOT_DIR/tobira" && bash ./run-both-tobiras.sh
    
    echo "✅ Both Tobira containers have been redeployed!"
    echo "📱 Mock Tobira: http://localhost:8080"
    echo "🧩 Shinri no Tobira: http://localhost:8081"
    
# Start dev server in Docker
dev-docker: docker-build
    #!/usr/bin/env bash
    echo "Opening the Gate of Truth in Docker on http://localhost:8080..."
    
    # Detect if podman is available, otherwise use docker
    if command -v podman &> /dev/null; then
        CONTAINER_CMD="podman"
    else
        CONTAINER_CMD="docker"
    fi
    
    ROOT_DIR="$(git rev-parse --show-toplevel)"
    # Start container with -t flag but don't require stdin
    $CONTAINER_CMD run --rm -t -p 8080:8080 \
        -v "$ROOT_DIR/tobira/src:/app/tobira/src:Z" \
        -v "$ROOT_DIR/tobira/index.html:/app/tobira/index.html:Z" \
        -v "$ROOT_DIR/ihoje_models:/app/ihoje_models:Z" \
        shinri-no-tobira:dev

# Start dev server with mock data in Docker
dev-docker-mock: docker-build
    #!/usr/bin/env bash
    echo "Opening the Mock Gate in Docker on http://localhost:8080..."
    
    # Detect if podman is available, otherwise use docker
    if command -v podman &> /dev/null; then
        CONTAINER_CMD="podman"
    else
        CONTAINER_CMD="docker"
    fi
    
    ROOT_DIR="$(git rev-parse --show-toplevel)"
    
    # Start container with -t flag but don't require stdin
    $CONTAINER_CMD run --rm -t -p 8080:8080 \
        -v "$ROOT_DIR/tobira/src:/app/tobira/src:Z" \
        -v "$ROOT_DIR/tobira/index.html:/app/tobira/index.html:Z" \
        -v "$ROOT_DIR/ihoje_models:/app/ihoje_models:Z" \
        shinri-no-tobira:mock
        
    # Display Docker images to show their creation time
    echo "Current Tobira Docker images:"
    $CONTAINER_CMD images shinri-no-tobira