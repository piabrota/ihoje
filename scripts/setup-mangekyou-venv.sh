#!/bin/bash
# Setup a dedicated virtual environment for Mangekyou

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MANGEKYOU_DIR="$SCRIPT_DIR/mangekyou-mcp"
VENV_DIR="$REPO_ROOT/.venv"
LOG_FILE="/tmp/mangekyou-setup.log"

# Create banner function
show_banner() {
    echo "====================================================="
    echo "  Mangekyou MCP - Python Virtual Environment Setup"
    echo "====================================================="
    echo ""
}

# Main setup function
setup_environment() {
    echo "Setting up Python virtual environment for Mangekyou MCP..."
    
    # Check if Python 3 is available
    if ! command -v python3 &> /dev/null; then
        echo "❌ Error: Python 3 is required but not found."
        echo "Please install Python 3.8 or higher and try again."
        exit 1
    fi
    
    # Get Python version
    PYTHON_VERSION=$(python3 --version | awk '{print $2}')
    echo "Found Python $PYTHON_VERSION"
    
    # Create virtual environment if it doesn't exist
    if [ ! -d "$VENV_DIR" ]; then
        echo "Creating virtual environment at $VENV_DIR..."
        python3 -m venv "$VENV_DIR" 2> >(tee -a "$LOG_FILE") || {
            echo "❌ Failed to create virtual environment. See $LOG_FILE for details."
            echo "Trying with --system-site-packages flag..."
            python3 -m venv "$VENV_DIR" --system-site-packages 2> >(tee -a "$LOG_FILE") || {
                echo "❌ Failed to create virtual environment with system packages."
                echo "Please check your Python installation and permissions."
                exit 1
            }
        }
    else
        echo "Using existing virtual environment at $VENV_DIR"
    fi
    
    # Activate the virtual environment
    source "$VENV_DIR/bin/activate" || {
        echo "❌ Failed to activate virtual environment."
        exit 1
    }
    
    # Install/upgrade pip
    echo "Upgrading pip..."
    python -m pip install --upgrade pip 2> >(tee -a "$LOG_FILE")
    
    # Install Mangekyou in development mode
    echo "Installing Mangekyou MCP in development mode..."
    cd "$MANGEKYOU_DIR" && pip install -e . 2> >(tee -a "$LOG_FILE") || {
        echo "❌ Failed to install Mangekyou dependencies."
        echo "Error details saved to $LOG_FILE"
        exit 1
    }
    
    # Create activation script for easy use
    cat > "$REPO_ROOT/activate-mangekyou.sh" << EOF
#!/bin/bash
# Activate Mangekyou virtual environment

VENV_DIR="$VENV_DIR"
source "\$VENV_DIR/bin/activate" || {
    echo "❌ Failed to activate virtual environment."
    exit 1
}

echo "✅ Mangekyou virtual environment activated."
echo "Run 'python -m mangekyou_mcp.server' to start the server directly."
echo "Or use 'just mcp-start' to start and register with MCP."
EOF

    chmod +x "$REPO_ROOT/activate-mangekyou.sh"
    
    echo "✅ Setup complete! You can activate the environment with:"
    echo "source ./activate-mangekyou.sh"
    
    # Provide instructions for running Mangekyou
    echo ""
    echo "To start Mangekyou:"
    echo "1. Activate the environment: source ./activate-mangekyou.sh"
    echo "2. Run with 'just' command: just mcp-start"
    
    # Deactivate virtual environment
    deactivate
}

# Run the setup
show_banner
setup_environment