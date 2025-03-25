# Cross-Platform Compatibility Justfile
# This justfile provides cross-platform helpers and functions

# Load .env file if present
set dotenv-load

# Platform detection variables
platform := `uname -s | tr '[:upper:]' '[:lower:]'`
is_windows := `if [[ "$(uname -s)" =~ MINGW|CYGWIN|MSYS ]]; then echo "true"; else echo "false"; fi`
is_macos := `if [[ "$(uname -s)" == "Darwin" ]]; then echo "true"; else echo "false"; fi`
is_linux := `if [[ "$(uname -s)" == "Linux" ]]; then echo "true"; else echo "false"; fi`

# Container tech based on platform
container_tool := if is_windows == "true" {
    "docker"
} else if is_macos == "true" {
    "docker"
} else {
    "podman"
}

# Date command with GNU date compatibility
date_cmd := if is_macos == "true" {
    "gdate"
} else {
    "date"
}

# Cross platform directory listing
list_cmd := if is_windows == "true" {
    "dir"
} else {
    "ls -la"
}

# [L] List cross-platform recipes
default:
    @just --list

# [H] Show cross-platform help
help:
    @echo "=== Cross-Platform Tools ==="
    @echo ""
    @echo "Platform: {{platform}}"
    @echo "Container: {{container_tool}}" 
    @echo "Date cmd: {{date_cmd}}"
    @echo ""
    @echo "Usage:"
    @echo "  just run-platform [ARGS]       - Run app with platform detection"
    @echo "  just container-run [ARGS]      - Run with platform container"
    @echo "  just date-calc DAYS            - Calculate date with platform support"
    @echo "  just platform-info             - Show platform information"
    @echo "  just setup-platform            - Setup platform-specific dependencies"
    @echo ""
    @echo "Import:"
    @echo "  platform := `uname -s | tr '[:upper:]' '[:lower:]'`"
    @echo "  container_tool := from cross_platform.just"

# [R] Run with platform-specific settings
# 
# Usage: just run-platform [ARGS]
run-platform +args="":
    #!/usr/bin/env bash
    echo "Running on {{platform}} platform..."
    
    # Platform-specific settings
    if [ "{{is_windows}}" = "true" ]; then
        echo "Windows-specific settings applied"
        # Windows-style paths and commands
        export PATH_SEPARATOR=";"
        export PLATFORM="windows"
    elif [ "{{is_macos}}" = "true" ]; then
        echo "MacOS-specific settings applied"
        # Check for GNU tools on Mac
        if ! command -v {{date_cmd}} &> /dev/null; then
            echo "Error: {{date_cmd}} not found. Install with: brew install coreutils"
            exit 1
        fi
        export PATH_SEPARATOR=":"
        export PLATFORM="macos"
    else
        echo "Linux-specific settings applied"
        export PATH_SEPARATOR=":"
        export PLATFORM="linux"
    fi
    
    # Calculate dates with platform compatible command
    if [ "{{is_macos}}" = "true" ]; then
        START_DATE=$(gdate -d "+7 days" +"%Y-%m-%d")
        END_DATE=$(gdate -d "+14 days" +"%Y-%m-%d")
    else
        START_DATE=$(date -d "+7 days" +"%Y-%m-%d")
        END_DATE=$(date -d "+14 days" +"%Y-%m-%d")
    fi
    
    # Run with platform settings
    echo "Platform: $PLATFORM"
    echo "Date range: $START_DATE to $END_DATE"
    echo "Running with args: {{args}}"
    
    # Use platform variable to run appropriate command
    if [ "$PLATFORM" = "windows" ]; then
        export START_DATE=$START_DATE
        export END_DATE=$END_DATE
        cmd.exe /C "cargo run -- {{args}}"
    else
        START_DATE=$START_DATE END_DATE=$END_DATE cargo run -- {{args}}
    fi

# [R] Run with platform container
#
# Usage: just container-run [ARGS]
container-run +args="":
    #!/usr/bin/env bash
    echo "Running with {{container_tool}}..."
    
    # Build image if needed
    if ! {{container_tool}} image exists ihoje:latest; then
        echo "Building container image..."
        {{container_tool}} build -t ihoje:latest .
    fi
    
    # Platform-specific container settings
    if [ "{{is_windows}}" = "true" ]; then
        VOLUME_OPTS="-v $(pwd):/app:rw"
    elif [ "{{is_macos}}" = "true" ]; then
        VOLUME_OPTS="-v $(pwd):/app:rw"
    else
        VOLUME_OPTS="-v $(pwd):/app:rw,Z"
    fi
    
    # Run container with platform options
    {{container_tool}} run --rm -it $VOLUME_OPTS ihoje:latest {{args}}

# [U] Calculate date with cross-platform support
#
# Usage: just date-calc DAYS
date-calc days="7":
    #!/usr/bin/env bash
    # Validate days parameter
    if ! [[ "{{days}}" =~ ^[0-9]+$ ]]; then
        echo "Error: days must be a number"
        exit 1
    fi
    
    # Platform-specific date calculation
    if [ "{{is_macos}}" = "true" ]; then
        if command -v gdate &> /dev/null; then
            # Use GNU date if available
            gdate -d "+{{days}} days" +"%Y-%m-%d"
        else
            # Fallback to MacOS date
            date -v+{{days}}d +"%Y-%m-%d"
        fi
    else
        # Linux/Windows (msys)
        date -d "+{{days}} days" +"%Y-%m-%d"
    fi

# [I] Show platform information
platform-info:
    @echo "Platform Details:"
    @echo "  OS: {{platform}}"
    @echo "  Windows: {{is_windows}}"
    @echo "  MacOS: {{is_macos}}"
    @echo "  Linux: {{is_linux}}"
    @echo "  Container: {{container_tool}}"
    @echo "  Date command: {{date_cmd}}"
    @echo ""
    @echo "Environment:"
    @uname -a
    @echo ""
    @echo "Available tools:"
    @if command -v {{container_tool}} > /dev/null; then echo "  {{container_tool}}: ✅"; else echo "  {{container_tool}}: ❌"; fi
    @if command -v {{date_cmd}} > /dev/null; then echo "  {{date_cmd}}: ✅"; else echo "  {{date_cmd}}: ❌"; fi
    @if command -v cargo > /dev/null; then echo "  cargo: ✅"; else echo "  cargo: ❌"; fi

# [S] Setup platform-specific dependencies
setup-platform:
    #!/usr/bin/env bash
    echo "Setting up platform-specific dependencies..."
    
    if [ "{{is_windows}}" = "true" ]; then
        echo "Setting up Windows dependencies..."
        # Check for package manager (this example uses chocolatey)
        if command -v choco &> /dev/null; then
            echo "Installing via Chocolatey..."
            # Example: choco install rust docker
        else
            echo "Warning: Chocolatey not found. Manual installation required."
            echo "Please install: Rust, Docker Desktop"
        fi
    elif [ "{{is_macos}}" = "true" ]; then
        echo "Setting up MacOS dependencies..."
        # Check for brew
        if command -v brew &> /dev/null; then
            echo "Installing via Homebrew..."
            if ! command -v gdate &> /dev/null; then
                brew install coreutils
            fi
            # Check for container tools
            if ! command -v docker &> /dev/null; then
                brew install docker
            fi
            # Check for rust
            if ! command -v cargo &> /dev/null; then
                brew install rustup-init
            fi
        else
            echo "Warning: Homebrew not found. Manual installation required."
            echo "Please install: Homebrew, then run this command again"
        fi
    else
        echo "Setting up Linux dependencies..."
        # Check for package manager (this example uses apt)
        if command -v apt &> /dev/null; then
            echo "Installing via apt..."
            # Example: apt install podman rust cargo
        elif command -v dnf &> /dev/null; then
            echo "Installing via dnf..."
            # Example: dnf install podman rust cargo
        else
            echo "Warning: No supported package manager found. Manual installation required."
            echo "Please install: Podman, Rust, Cargo"
        fi
    fi
    
    echo "Platform setup complete!"