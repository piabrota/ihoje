#!/bin/bash
# Script to set up Docker tobiras with separate ports
set -e

echo "Setting up iHoje Docker Tobiras"
echo "==============================="

# Ensure script runs from the project root
cd "$(dirname "$0")"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Error: Docker is not installed. Please install Docker first."
    exit 1
fi

# Make the tobira scripts executable
echo "Making tobira scripts executable..."
chmod +x tobira/run-both-tobiras.sh
chmod +x tobira/docker-restart.sh
chmod +x tobira/restart-mock.sh
chmod +x tobira/run-tobira.sh

echo "Setting up Docker tobiras..."
echo "Mock tobira will run on port 8080"
echo "WebAssembly tobira will run on port 8081"

# Ask if they want to run the tobiras now
read -p "Do you want to start the tobiras now? (y/n): " start_now

if [[ "$start_now" =~ ^[Yy]$ ]]; then
    echo "Starting both tobiras..."
    ROOT_DIR="$(dirname "$0")"
    TOBIRA_DIR="${ROOT_DIR}/tobira"
    cd "${TOBIRA_DIR}" && bash run-both-tobiras.sh
else
    echo "To start the tobiras later, run:"
    echo "  cd tobira && bash run-both-tobiras.sh"
    echo ""
    echo "Or to start them individually:"
    echo "  cd tobira && bash restart-mock.sh        # For the mock tobira (port 8080)"
    echo "  cd tobira && bash docker-restart.sh wasm # For the WebAssembly tobira (port 8081)"
fi

echo ""
echo "✅ Setup complete!"