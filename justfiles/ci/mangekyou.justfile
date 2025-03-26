# Mangekyou MCP CI justfile
# Provides commands for running CI checks locally

# Run lint checks against Mangekyou MCP code
lint-mangekyou:
    @echo "Running ruff linter..."
    #!/usr/bin/env bash
    
    # Check if ruff is available, install if not
    if ! command -v ruff > /dev/null; then
        echo "Installing ruff..."
        pip install ruff
    fi
    
    cd {{justfile_directory()}}/../../scripts/mangekyou-mcp && ruff check .
    echo "✅ Lint checks completed successfully!"

# Run tests for Mangekyou MCP
test-mangekyou:
    @echo "Running pytest with coverage..."
    #!/usr/bin/env bash
    
    # Check if pytest and coverage are available, install if not
    if ! command -v pytest > /dev/null; then
        echo "Installing pytest and coverage..."
        pip install pytest pytest-cov
    fi
    
    cd {{justfile_directory()}}/../../scripts/mangekyou-mcp && pytest --cov=mangekyou_mcp
    echo "✅ Tests completed successfully!"

# Run MCP compliance tests
test-mcp-compliance:
    @echo "Running MCP compliance tests..."
    #!/usr/bin/env bash
    
    # Check if required packages are available
    if ! command -v pytest > /dev/null; then
        echo "Installing test dependencies..."
        pip install pytest requests jsonschema
    fi
    
    cd {{justfile_directory()}}/../../scripts/mangekyou-mcp && \
    pytest -xvs tests/test_mcp_compliance.py
    echo "✅ MCP compliance tests completed successfully!"

# Build Python package
build-mangekyou:
    @echo "Building Python package..."
    #!/usr/bin/env bash
    
    # Check if build tools are available
    if ! command -v pip > /dev/null; then
        echo "Error: pip not found"
        exit 1
    fi
    
    # Install build tools if needed
    if ! python -c "import build" 2>/dev/null; then
        echo "Installing build package..."
        pip install build
    fi
    
    cd {{justfile_directory()}}/../../scripts/mangekyou-mcp && python -m build
    echo "✅ Package built successfully!"

# Run all CI checks locally
mangekyou-check: lint-mangekyou test-mangekyou test-mcp-compliance build-mangekyou

# Set up development environment
setup-mangekyou-dev:
    @echo "Setting up development environment..."
    cd {{justfile_directory()}}/../../scripts/mangekyou-mcp && python -m pip install -e ".[dev]"
    @echo "Development environment set up successfully!"