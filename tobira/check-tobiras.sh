#!/bin/bash
# Enhanced script to check Tobira containers and diagnose WASM loading problems

set -e

# Define colors for better visibility
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Tobira Container Health Check ===${NC}"
echo "Checking status of Tobira containers and diagnosing issues..."
echo ""

# Check if Docker is running
if ! docker info &>/dev/null; then
    echo -e "${RED}❌ Docker is not running or not accessible${NC}"
    exit 1
fi

# Temp files for diagnostics
TEMP_DIR="/tmp/tobira-check"
mkdir -p $TEMP_DIR

# Check both containers
CONTAINERS=("ihoje-mock" "ihoje-wasm")
PORTS=(8080 8081)

# Function to check WASM and JS files
check_wasm_files() {
    local PORT=$1
    echo -e "\n${YELLOW}Checking WebAssembly files on port $PORT...${NC}"
    
    # Check WASM file availability and MIME type
    if curl -s -I "http://localhost:$PORT/ihoje-tobira_bg.wasm" -o "$TEMP_DIR/wasm-headers-$PORT.txt"; then
        if grep -qi "content-type: application/wasm" "$TEMP_DIR/wasm-headers-$PORT.txt"; then
            echo -e "${GREEN}✅ ihoje-tobira_bg.wasm has correct MIME type${NC}"
        else
            echo -e "${RED}❌ ihoje-tobira_bg.wasm has wrong MIME type:${NC}"
            grep -i "content-type" "$TEMP_DIR/wasm-headers-$PORT.txt" || echo "No Content-Type header found"
        fi
    else
        echo -e "${RED}❌ ihoje-tobira_bg.wasm not found${NC}"
    fi
    
    # Check JavaScript file
    if curl -s -I "http://localhost:$PORT/ihoje-tobira.js" -o "$TEMP_DIR/js-headers-$PORT.txt"; then
        echo -e "${GREEN}✅ ihoje-tobira.js is available${NC}"
    else
        echo -e "${RED}❌ ihoje-tobira.js not found${NC}"
    fi
}

# Function to check HTML and Supabase integrity issues
check_html_issues() {
    local PORT=$1
    echo -e "\n${YELLOW}Checking HTML issues on port $PORT...${NC}"
    
    # Download the HTML
    curl -s "http://localhost:$PORT/" -o "$TEMP_DIR/index-$PORT.html"
    
    # Check for Supabase script
    if grep -q "supabase.*\.js" "$TEMP_DIR/index-$PORT.html"; then
        echo -e "${GREEN}✅ Supabase script is included${NC}"
        
        # Check for integrity attribute
        if grep -q "integrity=" "$TEMP_DIR/index-$PORT.html"; then
            echo -e "${RED}❌ Integrity attribute found (may cause loading issues)${NC}"
            echo "   Fix: Remove integrity attribute from Supabase script tag"
        else
            echo -e "${GREEN}✅ No integrity attribute found (good)${NC}"
        fi
    else
        echo -e "${RED}❌ Supabase script is missing${NC}"
    fi
    
    # Check for WASM file name handling
    if grep -q "ihoje_frontend_bg.wasm.*ihoje-tobira_bg.wasm" "$TEMP_DIR/index-$PORT.html"; then
        echo -e "${GREEN}✅ WASM filename mapping is present${NC}"
    else
        echo -e "${YELLOW}⚠️ WASM filename mapping may be missing${NC}"
    fi
}

for i in "${!CONTAINERS[@]}"; do
    CONTAINER="${CONTAINERS[$i]}"
    PORT="${PORTS[$i]}"
    
    echo -e "\n${BLUE}=== 🔍 Checking $CONTAINER (port $PORT) ===${NC}"
    
    if ! docker ps -q --filter "name=$CONTAINER" | grep -q .; then
        echo -e "${RED}❌ Container $CONTAINER is not running${NC}"
        echo "   To start it: cd tobira && bash run-both-tobiras.sh"
        echo ""
        continue
    fi
    
    # Check if container is healthy
    if docker ps --filter "name=$CONTAINER" --format "{{.Status}}" | grep -q "Up"; then
        echo -e "${GREEN}✅ Container $CONTAINER is running${NC}"
        
        # Check if responding to HTTP requests
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT/ -m 5 | grep -q "200"; then
            echo -e "${GREEN}✅ HTTP server is responding on port $PORT${NC}"
            
            # Check WebAssembly and JavaScript files
            check_wasm_files $PORT
            
            # Check HTML issues
            check_html_issues $PORT
            
            # Run debug script inside container
            echo -e "\n${YELLOW}Running container diagnostics...${NC}"
            if docker exec "$CONTAINER" bash -c "[ -f /app/debug.sh ] && /app/debug.sh" > "$TEMP_DIR/debug-$PORT.log" 2>&1; then
                echo -e "${GREEN}✅ Container diagnostics completed${NC}"
                # Check for specific issues in diagnostics
                if grep -q "Error" "$TEMP_DIR/debug-$PORT.log"; then
                    echo -e "${RED}⚠️ Errors found in diagnostics:${NC}"
                    grep -i "error" "$TEMP_DIR/debug-$PORT.log" | head -5
                fi
            else
                echo -e "${RED}⚠️ Container diagnostics had issues${NC}"
            fi
        else
            echo -e "${RED}❌ HTTP server is not responding on port $PORT${NC}"
            echo -e "${YELLOW}📝 Container logs:${NC}"
            docker logs "$CONTAINER" | tail -10
        fi
    else
        echo -e "${RED}❌ Container $CONTAINER is not healthy${NC}"
        echo -e "${YELLOW}📝 Container logs:${NC}"
        docker logs "$CONTAINER" | tail -10
    fi
    
    echo ""
done

echo -e "${BLUE}=== Troubleshooting Tips ===${NC}"
echo "1. If WASM MIME type is wrong, check that spa_server.py has 'application/wasm' type set"
echo "2. If page loads but stays in loading state, the Supabase integrity check might be failing"
echo "3. To fix Supabase integrity issues, edit index.html and remove the integrity attribute"
echo "4. To fix WASM file name issues, ensure index.html has code to map filenames correctly"
echo "5. For the WebAssembly version (port 8081), check bootstrap.js for proper error handling"

echo -e "\n${BLUE}=== Quick Fixes ===${NC}"
echo "1. To restart all containers: ./run-both-tobiras.sh"
echo "2. To manually fix files: cp fixed_index.html index.html && cp fixed_bootstrap.js bootstrap.js"
echo "3. To view container logs: docker logs <container-id>"

echo -e "\n${GREEN}✨ Health check completed!${NC}"

# Cleanup
rm -rf $TEMP_DIR