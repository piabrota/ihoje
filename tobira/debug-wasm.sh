#!/bin/bash
# Script to debug WebAssembly loading issues on port 8081
set -e

# Define colors for better visibility
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== WebAssembly Loading Diagnostics ===${NC}"

# Check if port 8081 is running
if ! curl -s -o /dev/null -w "%{http_code}" http://localhost:8081/ | grep -q "200"; then
  echo -e "${RED}❌ Port 8081 is not responding${NC}"
  echo "Run ./restart-wasm-tobira.sh to restart the container"
  exit 1
fi

echo -e "${GREEN}✅ Port 8081 is responding${NC}"

# Check for WASM files
echo -e "\n${YELLOW}Checking WebAssembly files...${NC}"

# Check ihoje-tobira_bg.wasm
WASM_FILE="ihoje-tobira_bg.wasm"
WASM_STATUS=$(curl -s -I "http://localhost:8081/$WASM_FILE" | grep -i "HTTP")
MIME_TYPE=$(curl -s -I "http://localhost:8081/$WASM_FILE" | grep -i "Content-Type")

if [[ "$WASM_STATUS" == *"200"* ]]; then
  echo -e "${GREEN}✅ $WASM_FILE is accessible${NC}"
  
  if [[ "$MIME_TYPE" == *"application/wasm"* ]]; then
    echo -e "${GREEN}✅ $WASM_FILE has correct MIME type: $MIME_TYPE${NC}"
  else
    echo -e "${RED}❌ $WASM_FILE has incorrect MIME type: $MIME_TYPE${NC}"
    echo "   Ensure spa_server.py has 'mimetypes.add_type(\"application/wasm\", \".wasm\")'"
  fi
else
  echo -e "${RED}❌ $WASM_FILE is not accessible: $WASM_STATUS${NC}"
fi

# Check JS file
JS_FILE="ihoje-tobira.js"
JS_STATUS=$(curl -s -I "http://localhost:8081/$JS_FILE" | grep -i "HTTP")

if [[ "$JS_STATUS" == *"200"* ]]; then
  echo -e "${GREEN}✅ $JS_FILE is accessible${NC}"
else
  echo -e "${RED}❌ $JS_FILE is not accessible: $JS_STATUS${NC}"
fi

# Check for SRI integrity issues
echo -e "\n${YELLOW}Checking for SRI integrity issues...${NC}"
if curl -s "http://localhost:8081/" | grep -q "integrity="; then
  echo -e "${RED}❌ Integrity attribute found in HTML${NC}"
  echo "   This may cause Supabase loading failures"
  echo "   Fix by using fixed_index.html without integrity attributes"
else
  echo -e "${GREEN}✅ No integrity attributes found${NC}"
fi

# Check filename mapping
echo -e "\n${YELLOW}Checking for filename mapping...${NC}"
if curl -s "http://localhost:8081/" | grep -q "ihoje_frontend_bg.wasm.*ihoje-tobira_bg.wasm"; then
  echo -e "${GREEN}✅ WASM filename mapping is present in HTML${NC}"
else
  echo -e "${RED}❌ WASM filename mapping is missing${NC}"
  echo "   This may cause 404 errors when loading WASM"
fi

# Check for common errors in logs
echo -e "\n${YELLOW}Checking container logs for common errors...${NC}"
if docker logs ihoje-wasm 2>&1 | grep -i "error"; then
  echo -e "${RED}⚠️ Errors found in container logs${NC}"
else
  echo -e "${GREEN}✅ No obvious errors in container logs${NC}"
fi

echo -e "\n${BLUE}=== Recommendations ===${NC}"
echo "If you still have issues:"
echo "1. Restart the WebAssembly container: ./restart-wasm-tobira.sh"
echo "2. Ensure index.html and bootstrap.js have proper WASM loading code"
echo "3. Check browser console for more detailed JavaScript errors"