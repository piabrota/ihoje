#!/bin/bash
# Script to run both Tobira versions using docker-compose
set -e

# Define colors for better visibility
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Starting Tobira with Docker Compose ===${NC}"

# Add the WebAssembly MIME type to spa_server.py if not already there
if ! grep -q "mimetypes.add_type('application/wasm'" spa_server.py; then
  echo -e "${YELLOW}Adding WebAssembly MIME type to spa_server.py${NC}"
  TMP_FILE=$(mktemp)
  echo "#!/usr/bin/env python3" > $TMP_FILE
  echo "# Configure WASM MIME type - critical for proper WebAssembly loading" >> $TMP_FILE
  echo "import mimetypes; mimetypes.add_type('application/wasm', '.wasm')" >> $TMP_FILE
  cat spa_server.py | grep -v "mimetypes.add_type" >> $TMP_FILE
  mv $TMP_FILE spa_server.py
  chmod +x spa_server.py
fi

# Ensure fixed version of index.html is in place
if [ -f "fixed_index.html" ]; then
  echo -e "${YELLOW}Copying fixed_index.html to index.html to ensure proper WebAssembly loading${NC}"
  cp fixed_index.html index.html
fi

# Ensure fixed version of bootstrap.js is in place
if [ -f "fixed_bootstrap.js" ]; then
  echo -e "${YELLOW}Copying fixed_bootstrap.js to bootstrap.js to ensure proper WebAssembly loading${NC}"
  cp fixed_bootstrap.js bootstrap.js
fi

# Create logs directory if it doesn't exist
mkdir -p logs

# Check if we're restarting or starting fresh
if docker-compose ps | grep -q "tobira"; then
  echo -e "${YELLOW}Restarting Tobira containers...${NC}"
  docker-compose restart
else
  echo -e "${YELLOW}Starting Tobira containers...${NC}"
  docker-compose up -d --build
fi

# Wait for containers to start
echo -e "${YELLOW}Waiting for containers to initialize...${NC}"
sleep 5

# Run health check
echo -e "${BLUE}=== Checking container health ===${NC}"
./check-tobiras.sh

echo -e "\n${GREEN}Tobira is now running:${NC}"
echo -e "• Mock version: ${BLUE}http://localhost:8080/${NC}"
echo -e "• WebAssembly version: ${BLUE}http://localhost:8081/${NC}"
echo ""
echo -e "To check status: ${YELLOW}./check-tobiras.sh${NC}"
echo -e "To stop: ${YELLOW}docker-compose down${NC}"
echo -e "To view logs: ${YELLOW}docker-compose logs -f${NC}"