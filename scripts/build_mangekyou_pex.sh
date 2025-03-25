#!/bin/bash
# Create a standalone Mangekyou executable that works without PEX in a Nix environment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}/../dist"
STANDALONE_SCRIPT="${SCRIPT_DIR}/mangekyou_standalone.py"
OUTPUT_SCRIPT="${OUTPUT_DIR}/mangekyou"

echo "Building Mangekyou standalone executable..."
echo "Using standalone script: ${STANDALONE_SCRIPT}"

# Ensure the output directory exists
mkdir -p "${OUTPUT_DIR}"

# Ensure standalone script is executable
chmod +x "${STANDALONE_SCRIPT}"

# Copy script to output directory
cp "${STANDALONE_SCRIPT}" "${OUTPUT_SCRIPT}"
chmod +x "${OUTPUT_SCRIPT}"

echo "✅ Standalone executable created: ${OUTPUT_SCRIPT}"
echo ""
echo "Usage:"
echo "  ${OUTPUT_SCRIPT}           - Start Mangekyou server"
echo "  ${OUTPUT_SCRIPT} register  - Register with Claude MCP"
echo "  ${OUTPUT_SCRIPT} status    - Check if server is running"
echo ""
echo "Or use this command:"
echo "  just mangekyou-pex-run     - Run the standalone script"