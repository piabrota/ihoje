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
    @echo "Debugging:"
    @echo "  debug-dump  - Dump Tobira debugging information for LLM analysis"
    @echo "  debug-wasm  - Collect WebAssembly initialization logs and files"
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
dev:
    #!/usr/bin/env bash
    ROOT_DIR="$(git rev-parse --show-toplevel)"
    cd "$ROOT_DIR/tobira"
    
    # Check if docker-compose.yml exists
    if [ ! -f "docker-compose.yml" ]; then
        echo "Error: docker-compose.yml not found. Make sure you're in the right directory."
        exit 1
    fi
    
    # Run the docker-compose script to start/rebuild containers
    bash run-tobiras-docker-compose.sh
    
    # Wait for services to start
    echo "Waiting for WebAssembly Tobira to start..."
    sleep 3
    
    # Display URL
    echo "✅ WebAssembly Tobira is running at http://localhost:8081"

# Start dev server with mock data (Docker only)
dev-mock:
    #!/usr/bin/env bash
    ROOT_DIR="$(git rev-parse --show-toplevel)"
    cd "$ROOT_DIR/tobira"
    
    # Check if docker-compose.yml exists
    if [ ! -f "docker-compose.yml" ]; then
        echo "Error: docker-compose.yml not found. Make sure you're in the right directory."
        exit 1
    fi
    
    # Run the docker-compose script to start/rebuild containers
    bash run-tobiras-docker-compose.sh
    
    # Wait for services to start
    echo "Waiting for Mock Tobira to start..."
    sleep 3
    
    # Display URL
    echo "✅ Mock Tobira is running at http://localhost:8080"

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

# Dump Tobira debugging information for LLM analysis
debug-dump:
    #!/usr/bin/env bash
    set -e
    
    # Create timestamped directory for debug info
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    DEBUG_DIR="./tobira_debug_${TIMESTAMP}"
    mkdir -p "${DEBUG_DIR}"
    
    echo "Creating Tobira debug dump at ${DEBUG_DIR}..."
    
    # Function to copy file with header
    copy_with_header() {
        local file=$1
        local dest_file="${DEBUG_DIR}/$(basename ${file})"
        echo -e "\n\n# =============================================" > "${dest_file}"
        echo -e "# FILE: ${file}" >> "${dest_file}"
        echo -e "# =============================================\n" >> "${dest_file}"
        cat "${file}" >> "${dest_file}" 2>/dev/null || echo "# FILE NOT FOUND OR EMPTY" >> "${dest_file}"
        echo "Copied ${file}"
    }
    
    # Collect critical client-side files
    echo "Collecting client-side files..."
    CRITICAL_FILES=(
        "tobira/index.html"
        "tobira/env.js"
        "tobira/auth-debug.js"
        "tobira/dist/bootstrap.js"
        "tobira/fixed_server.py"
        "tobira/spa_server.py"
        "tobira/build.sh"
    )
    
    for file in "${CRITICAL_FILES[@]}"; do
        if [ -f "${file}" ]; then
            copy_with_header "${file}"
        else
            echo "Warning: ${file} not found, skipping"
        fi
    done
    
    # Collect Docker-related files
    echo "Collecting Docker files..."
    DOCKER_FILES=(
        "tobira/Dockerfile"
        "tobira/Dockerfile.simple"
        "tobira/docker-restart.sh"
        "tobira/run-both-tobiras.sh"
        "tobira/check-tobiras.sh"
    )
    
    for file in "${DOCKER_FILES[@]}"; do
        if [ -f "${file}" ]; then
            copy_with_header "${file}"
        else
            echo "Warning: ${file} not found, skipping"
        fi
    done
    
    # Collect important Rust source files
    echo "Collecting Rust source files..."
    RUST_FILES=(
        "tobira/src/main.rs"
        "tobira/src/lib.rs"
        "tobira/src/router.rs"
        "tobira/src/pages/login_page.rs"
        "tobira/src/pages/admin/dashboard.rs"
        "tobira/src/api/client.rs"
        "tobira/src/utils/config.rs"
    )
    
    for file in "${RUST_FILES[@]}"; do
        if [ -f "${file}" ]; then
            copy_with_header "${file}"
        else
            echo "Warning: ${file} not found, skipping"
        fi
    done
    
    # Collect Docker container information
    echo "Collecting Docker container information..."
    CONTAINER_INFO="${DEBUG_DIR}/container_info.txt"
    echo -e "# ==============================================" > "${CONTAINER_INFO}"
    echo -e "# DOCKER CONTAINER INFORMATION" >> "${CONTAINER_INFO}"
    echo -e "# ==============================================\n" >> "${CONTAINER_INFO}"
    
    if docker ps | grep -q "ihoje-wasm"; then
        echo -e "## Container Status\n" >> "${CONTAINER_INFO}"
        docker ps --filter "name=ihoje-wasm" --format 'table {{".ID"}}\t{{".Image"}}\t{{".Status"}}\t{{".Ports"}}' >> "${CONTAINER_INFO}"
        
        echo -e "\n\n## Container Logs\n" >> "${CONTAINER_INFO}"
        docker logs ihoje-wasm >> "${CONTAINER_INFO}" 2>&1
        
        echo -e "\n\n## Container Environment Variables\n" >> "${CONTAINER_INFO}"
        docker exec ihoje-wasm env | sort >> "${CONTAINER_INFO}" 2>&1
        
        echo -e "\n\n## Container Process List\n" >> "${CONTAINER_INFO}"
        docker exec ihoje-wasm ps -ef >> "${CONTAINER_INFO}" 2>&1
        
        echo -e "\n\n## Container Network Status\n" >> "${CONTAINER_INFO}"
        docker exec ihoje-wasm netstat -tuln >> "${CONTAINER_INFO}" 2>&1
        
        echo -e "\n\n## Container Disk Usage\n" >> "${CONTAINER_INFO}"
        docker exec ihoje-wasm du -sh /app/tobira/dist >> "${CONTAINER_INFO}" 2>&1
        
        echo -e "\n\n## Container File List\n" >> "${CONTAINER_INFO}"
        docker exec ihoje-wasm find /app/tobira/dist -type f | sort >> "${CONTAINER_INFO}" 2>&1
        
        echo "Collected container information"
    else
        echo "Warning: ihoje-wasm container not running, skipping container info"
        echo "Container 'ihoje-wasm' not running" >> "${CONTAINER_INFO}"
    fi
    
    # Generate instructions for browser console logs
    echo -e "# ==============================================" > "${DEBUG_DIR}/browser_console_instructions.md"
    echo -e "# BROWSER CONSOLE LOGGING INSTRUCTIONS" >> "${DEBUG_DIR}/browser_console_instructions.md"
    echo -e "# ==============================================\n" >> "${DEBUG_DIR}/browser_console_instructions.md"
    echo -e "To collect browser console logs:\n" >> "${DEBUG_DIR}/browser_console_instructions.md"
    echo -e "1. Open http://localhost:8081 in your browser" >> "${DEBUG_DIR}/browser_console_instructions.md"
    echo -e "2. Right-click and select 'Inspect' or press F12" >> "${DEBUG_DIR}/browser_console_instructions.md"
    echo -e "3. Go to the 'Console' tab" >> "${DEBUG_DIR}/browser_console_instructions.md"
    echo -e "4. Execute these diagnostic commands:\n" >> "${DEBUG_DIR}/browser_console_instructions.md"
    echo -e "   \`\`\`javascript" >> "${DEBUG_DIR}/browser_console_instructions.md}"
    echo -e "   console.log(\"WebAssembly Support:\", typeof WebAssembly);" >> "${DEBUG_DIR}/browser_console_instructions.md}"
    echo -e "   console.log(\"Environment Variables:\", window.ihoje_env);" >> "${DEBUG_DIR}/browser_console_instructions.md}"
    echo -e "   console.log(\"Auth State:\", window.debugAuth?.getAuthState());" >> "${DEBUG_DIR}/browser_console_instructions.md}"
    echo -e "   \`\`\`\n" >> "${DEBUG_DIR}/browser_console_instructions.md}"
    echo -e "5. Right-click in the console and select 'Save as...' to save the logs" >> "${DEBUG_DIR}/browser_console_instructions.md}"
    echo -e "6. Add these logs to ${DEBUG_DIR}/browser_console.txt" >> "${DEBUG_DIR}/browser_console_instructions.md}"
    
    # Create a combined file for easy LLM analysis
    echo "Creating combined file for LLM analysis..."
    COMBINED_FILE="${DEBUG_DIR}/tobira_debug_combined.txt"
    echo -e "# TOBIRA WEBASSEMBLY FRONTEND DEBUG DUMP\n" > "${COMBINED_FILE}"
    echo -e "Generated: $(date)\n" >> "${COMBINED_FILE}"
    echo -e "This file contains a comprehensive debug dump of the Tobira WebAssembly frontend.\n" >> "${COMBINED_FILE}"
    echo -e "## System Environment\n" >> "${COMBINED_FILE}"
    echo -e "- Host System: $(uname -a)" >> "${COMBINED_FILE}"
    echo -e "- Docker Version: $(docker --version)" >> "${COMBINED_FILE}"
    echo -e "- Working Directory: $(pwd)" >> "${COMBINED_FILE}"
    
    # Add all files to the combined file
    for file in "${DEBUG_DIR}"/*; do
        if [ "${file}" != "${COMBINED_FILE}" ]; then
            echo -e "\n\n=================================================================" >> "${COMBINED_FILE}"
            echo -e "CONTENT OF: $(basename ${file})" >> "${COMBINED_FILE}"
            echo -e "=================================================================\n" >> "${COMBINED_FILE}"
            cat "${file}" >> "${COMBINED_FILE}"
        fi
    done
    
    echo -e "\nDebug dump completed at ${DEBUG_DIR}"
    echo -e "Combined file: ${COMBINED_FILE}"
    echo -e "\nTo analyze with an LLM, upload the combined file ${COMBINED_FILE}"

# Collect WebAssembly initialization logs and files
debug-wasm:
    #!/usr/bin/env bash
    set -e
    
    echo "Collecting WebAssembly initialization information..."
    
    # Create a debug log directory if it doesn't exist
    mkdir -p ./wasm_debug
    DEBUG_FILE="./wasm_debug/wasm_debug_$(date +"%Y%m%d_%H%M%S").log"
    
    echo "# WEBASSEMBLY INITIALIZATION DEBUG LOG" > "${DEBUG_FILE}"
    echo "Generated: $(date)" >> "${DEBUG_FILE}"
    echo "" >> "${DEBUG_FILE}"
    
    # Function to append command output to log
    log_command() {
        local cmd=$1
        local title=$2
        echo -e "\n## ${title}\n" >> "${DEBUG_FILE}"
        echo -e "Command: ${cmd}\n" >> "${DEBUG_FILE}"
        eval "${cmd}" >> "${DEBUG_FILE}" 2>&1 || echo "Command failed with error code $?" >> "${DEBUG_FILE}"
    }
    
    # Check if the WASM container is running
    if docker ps | grep -q "ihoje-wasm"; then
        log_command "docker logs ihoje-wasm | grep -A 10 'WASM\|WebAssembly'" "WebAssembly Docker Logs"
        log_command "docker exec ihoje-wasm find /app/tobira/dist -name '*.wasm' -ls" "WASM Files in Container"
        log_command "docker exec ihoje-wasm cat /app/tobira/dist/bootstrap.js 2>/dev/null || echo 'File not found'" "Bootstrap.js Content"
        log_command "docker exec ihoje-wasm file /app/tobira/dist/*.wasm 2>/dev/null || echo 'No WASM files found'" "WASM File Info"
        log_command "docker exec ihoje-wasm ls -la /app/tobira/dist/ | grep -v total" "Files in dist directory"
    else
        echo "Container 'ihoje-wasm' is not running. Start it with 'just tobira-restart'." >> "${DEBUG_FILE}"
    fi
    
    # Check for local WASM files
    echo -e "\n## Local WebAssembly Files\n" >> "${DEBUG_FILE}"
    find ./tobira -name "*.wasm" -type f -exec ls -la {} \; >> "${DEBUG_FILE}" 2>/dev/null || echo "No local WASM files found" >> "${DEBUG_FILE}"
    
    # Check critical files
    log_command "cat ./tobira/env.js 2>/dev/null || echo 'File not found'" "env.js Content"
    log_command "cat ./tobira/dist/bootstrap.js 2>/dev/null || echo 'File not found'" "Local bootstrap.js Content"
    
    # Check for network errors
    log_command "docker exec ihoje-wasm curl -Is http://localhost:8080/ihoje-tobira_bg.wasm 2>/dev/null || echo 'File not accessible'" "WASM HTTP Headers Check"
    
    echo -e "\nWebAssembly debug information collected at ${DEBUG_FILE}"
    echo "To diagnose WebAssembly initialization issues:"
    echo "1. Check for proper MIME type ('application/wasm')"
    echo "2. Verify file naming consistency (ihoje_frontend_bg.wasm vs ihoje-tobira_bg.wasm)"
    echo "3. Look for JavaScript errors in browser console"
    echo "4. Verify WebAssembly.instantiateStreaming fallback mechanisms"
    
# Start dev server in Docker - Uses docker-compose for consistency
dev-docker:
    #!/usr/bin/env bash
    ROOT_DIR="$(git rev-parse --show-toplevel)"
    cd "$ROOT_DIR/tobira"
    
    # Check if docker-compose.yml exists
    if [ ! -f "docker-compose.yml" ]; then
        echo "Error: docker-compose.yml not found. Make sure you're in the right directory."
        exit 1
    fi
    
    # Stop any running containers with the same service name
    docker-compose stop tobira-wasm 2>/dev/null || true
    
    # Force rebuild and start just the WebAssembly container
    docker-compose up -d --build --force-recreate tobira-wasm
    
    # Wait for service to start
    echo "Waiting for WebAssembly Tobira to start..."
    sleep 3
    
    # Display URL
    echo "✅ WebAssembly Tobira is running at http://localhost:8081"
    
    # Show logs
    echo "To view logs: docker-compose logs -f tobira-wasm"

# Start dev server with mock data in Docker - Uses docker-compose for consistency
dev-docker-mock:
    #!/usr/bin/env bash
    ROOT_DIR="$(git rev-parse --show-toplevel)"
    cd "$ROOT_DIR/tobira"
    
    # Check if docker-compose.yml exists
    if [ ! -f "docker-compose.yml" ]; then
        echo "Error: docker-compose.yml not found. Make sure you're in the right directory."
        exit 1
    fi
    
    # Stop any running containers with the same service name
    docker-compose stop tobira-mock 2>/dev/null || true
    
    # Force rebuild and start just the mock container
    docker-compose up -d --build --force-recreate tobira-mock
    
    # Wait for service to start
    echo "Waiting for Mock Tobira to start..."
    sleep 3
    
    # Display URL
    echo "✅ Mock Tobira is running at http://localhost:8080"
    
    # Show logs
    echo "To view logs: docker-compose logs -f tobira-mock"