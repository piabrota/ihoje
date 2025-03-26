#!/bin/bash
# Script to restart only the WebAssembly tobira container (port 8081)
set -e

# Define colors for better visibility
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Restarting WebAssembly Tobira (port 8081) ===${NC}"

# Ensure our fixed files are available
echo -e "${YELLOW}📄 Copying fixed files for WASM compatibility...${NC}"

# Copy fixed index.html (this removes SRI integrity check that causes issues)
if [ -f "fixed_index.html" ]; then
  cp fixed_index.html index.html
  echo -e "${GREEN}✅ Using fixed index.html${NC}"
else
  echo -e "${RED}❌ fixed_index.html not found, using current index.html${NC}"
fi

# Copy fixed bootstrap.js with better WASM handling
if [ -f "fixed_bootstrap.js" ]; then
  cp fixed_bootstrap.js bootstrap.js
  echo -e "${GREEN}✅ Using fixed bootstrap.js${NC}"
else
  echo -e "${RED}❌ fixed_bootstrap.js not found, using current bootstrap.js${NC}"
fi

# Update the spa_server.py with proper MIME types if needed
echo -e "${YELLOW}📄 Ensuring WASM MIME type is configured...${NC}"
if ! grep -q "mimetypes.add_type('application/wasm'" spa_server.py; then
  echo "import mimetypes; mimetypes.add_type('application/wasm', '.wasm')" > spa_server_fix.py
  cat spa_server.py >> spa_server_fix.py 
  mv spa_server_fix.py spa_server.py
  chmod +x spa_server.py
  echo -e "${GREEN}✅ Added WASM MIME type to spa_server.py${NC}"
else
  echo -e "${GREEN}✅ WASM MIME type already configured${NC}"
fi

# Stop and remove the existing container
echo -e "${YELLOW}🛑 Stopping existing WebAssembly container...${NC}"
docker ps -a | grep ihoje-wasm && docker stop ihoje-wasm && docker rm ihoje-wasm || true

# Build and start WebAssembly tobira
echo -e "${YELLOW}🏗️ Building WebAssembly tobira...${NC}"

# Go to project root for the build
cd ..
if docker build -t shinri-no-tobira:latest -f tobira/Dockerfile .; then
  echo -e "${GREEN}✅ WebAssembly build successful, starting container...${NC}"
  # Always map host port 8081 to container port 8080
  docker run -d -p 8081:8080 --name ihoje-wasm shinri-no-tobira:latest
  
  # Give the container a moment to start
  sleep 3
  
  # Check if the container is running
  if docker ps | grep -q ihoje-wasm; then
    echo -e "${GREEN}✅ Container started successfully${NC}"
    echo -e "${BLUE}📱 WebAssembly tobira available at: http://localhost:8081${NC}"
    
    # Print container logs for debugging
    echo -e "${YELLOW}📋 Container logs:${NC}"
    docker logs ihoje-wasm | tail -10
  else
    echo -e "${RED}❌ Container failed to start${NC}"
  fi
else
  echo -e "${RED}❌ WebAssembly tobira build failed${NC}"
fi

echo -e "\n${BLUE}=== Commands for Debugging ===${NC}"
echo -e "• View logs: ${YELLOW}docker logs ihoje-wasm${NC}"
echo -e "• Access container: ${YELLOW}docker exec -it ihoje-wasm bash${NC}"
echo -e "• Check MIME types: ${YELLOW}curl -I http://localhost:8081/ihoje-tobira_bg.wasm${NC}"