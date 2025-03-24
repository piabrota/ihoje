#!/bin/bash
# Build a PEX file for Mangekyou that can run without any virtual environment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}/../dist"
STANDALONE_SCRIPT="${SCRIPT_DIR}/mangekyou_standalone.py"
PEX_FILE="${OUTPUT_DIR}/mangekyou.pex"

echo "Building Mangekyou PEX distribution..."
echo "Using standalone script: ${STANDALONE_SCRIPT}"

# Ensure the output directory exists
mkdir -p "${OUTPUT_DIR}"

# Check if pex is installed
if ! command -v pex &> /dev/null; then
    echo "PEX is not installed. Installing..."
    pip install pex
fi

# Create minimal requirements file
TEMP_REQ=$(mktemp)
echo "# Minimal requirements - standard library only" > "${TEMP_REQ}"

# Ensure standalone script is executable
chmod +x "${STANDALONE_SCRIPT}"

# Build the PEX file
echo "Building PEX file..."
pex -o "${PEX_FILE}" --script="${STANDALONE_SCRIPT}" -r "${TEMP_REQ}" --python-shebang="/usr/bin/env python3"

# Clean up
rm "${TEMP_REQ}"

# Make executable
chmod +x "${PEX_FILE}"

echo "✅ PEX file created: ${PEX_FILE}"
echo ""
echo "Usage:"
echo "  ${PEX_FILE}           - Start Mangekyou server"
echo "  ${PEX_FILE} register  - Register with Claude MCP"
echo "  ${PEX_FILE} status    - Check if server is running"
echo ""
echo "Or use these commands:"
echo "  just mangekyou-pex-run - Run the PEX file"