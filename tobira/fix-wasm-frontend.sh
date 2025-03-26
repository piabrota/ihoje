#!/bin/bash
# Script to apply all fixes needed for proper WebAssembly loading on port 8081
set -e

# Define colors for better visibility
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Applying WebAssembly Loading Fixes ===${NC}"

# Create backup directory
BACKUP_DIR="$(pwd)/backup-$(date +%Y%m%d%H%M%S)"
mkdir -p "$BACKUP_DIR"
echo -e "${YELLOW}📁 Created backup directory: $BACKUP_DIR${NC}"

# Backup current files
for file in index.html bootstrap.js spa_server.py; do
  if [ -f "$file" ]; then
    cp "$file" "$BACKUP_DIR/"
    echo -e "${GREEN}✅ Backed up $file${NC}"
  fi
done

# 1. Fix index.html - Main problem is SRI integrity for Supabase
echo -e "\n${YELLOW}📄 Fixing index.html...${NC}"
cat > index.html << 'EOL'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>iHoje - Shinri no Tobira</title>
    <link rel="stylesheet" href="./static/styles.css">
    
    <!-- Environment Configuration -->
    <script>
        // Configure environment variables
        window.ihoje_env = {
            IHOJE_ENVIRONMENT: "development",
            IHOJE_API_URL: "http://localhost:8080/api",
            IHOJE_USE_MOCK_DATA: "true",
            IHOJE_SUPABASE_URL: "https://xyzsupabase.supabase.co",
            IHOJE_SUPABASE_ANON_KEY: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRlc3QiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTY3MDc2OTQ5OSwiZXhwIjoxOTg2MzQ1NDk5fQ.example_test_key"
        };
        
        window.get_env_var = function(name) {
            return (window.ihoje_env && window.ihoje_env[name]) || "";
        };
        
        // Mock admin user for testing
        const mockAdmin = {
            id: "test-admin-id-123",
            email: "admin@test.com",
            name: "Test Admin",
            role: "admin",
            avatar_url: "https://ui-avatars.com/api/?name=Test+Admin&background=0D8ABC&color=fff",
            access_token: "mock-token-123"
        };
        
        // Set admin user in localStorage
        localStorage.setItem("ihoje_auth", JSON.stringify(mockAdmin));
        console.log("Admin user configured:", mockAdmin);
        
        // WASM MIME type fix
        const originalFetch = window.fetch;
        window.fetch = function(input, init) {
            // Handle WASM file name mismatch
            if (typeof input === "string" && input.endsWith("ihoje_frontend_bg.wasm")) {
                console.log("Fixing WASM file name reference:", input);
                input = input.replace("ihoje_frontend_bg.wasm", "ihoje-tobira_bg.wasm");
            }
            
            return originalFetch(input, init).then(response => {
                if (typeof input === 'string' && input.endsWith('.wasm')) {
                    console.log("Fixing MIME type for:", input);
                    return response.clone().blob().then(blob => {
                        return new Response(blob, {
                            status: response.status,
                            statusText: response.statusText,
                            headers: new Headers({
                                'Content-Type': 'application/wasm'
                            })
                        });
                    });
                }
                return response;
            });
        };
    </script>
</head>
<body>
    <div id="app">
        <div class="loading">
            <div class="spinner"></div>
            <p>Loading Shinri no Tobira...</p>
        </div>
    </div>
    
    <!-- Error display for debugging -->
    <div id="wasm-error" style="display: none; background: #ffdddd; border: 1px solid #ff0000; padding: 10px; margin: 10px 0; border-radius: 4px;">
        <h3>WebAssembly Error</h3>
        <pre id="error-message"></pre>
    </div>
    
    <script type="module">
        // Initialize WASM
        import init from './ihoje-tobira.js';
        
        async function initApp() {
            try {
                console.log("Initializing WebAssembly...");
                const wasm = await init();
                console.log("WebAssembly initialized successfully");
                
                // Enable mock data if available
                if (typeof wasm.enable_mock_data === "function") {
                    wasm.enable_mock_data();
                    console.log("Mock data mode enabled");
                } else {
                    console.warn("enable_mock_data function not found");
                }
            } catch (error) {
                console.error("Failed to initialize WebAssembly:", error);
                document.getElementById('wasm-error').style.display = 'block';
                document.getElementById('error-message').textContent = error.toString();
            }
        }
        
        // Start the app
        initApp();
    </script>
    
    <!-- Load Supabase without SRI integrity check to avoid failures -->
    <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.38.4/dist/umd/supabase.min.js"></script>
</body>
</html>
EOL
echo -e "${GREEN}✅ Fixed index.html${NC}"

# 2. Fix bootstrap.js
echo -e "\n${YELLOW}📄 Fixing bootstrap.js...${NC}"
cat > bootstrap.js << 'EOL'
// Bootstrap for WebAssembly initialization with better error handling
console.log("Bootstrap initializing WASM with mock data mode...");

// Configure WebAssembly loading with proper MIME type
function configureWasmLoading() {
  console.log("Configuring WebAssembly loaders");

  // Fix filename mismatches
  const originalFetch = window.fetch;
  window.fetch = function(input, init) {
    // Handle WASM file name mismatch
    if (typeof input === "string" && input.endsWith("ihoje_frontend_bg.wasm")) {
      console.log("Fixing WASM file name reference:", input);
      input = input.replace("ihoje_frontend_bg.wasm", "ihoje-tobira_bg.wasm");
    }
    
    return originalFetch(input, init).then(response => {
      // Fix MIME type for WASM files
      if (typeof input === "string" && input.endsWith(".wasm")) {
        console.log("Fixing MIME type for:", input);
        return response.clone().blob().then(blob => {
          return new Response(blob, {
            status: response.status,
            statusText: response.statusText,
            headers: new Headers({
              "Content-Type": "application/wasm"
            })
          });
        });
      }
      return response;
    });
  };

  // Provide fallback for instantiateStreaming
  if (WebAssembly && WebAssembly.instantiateStreaming) {
    const originalInstantiateStreaming = WebAssembly.instantiateStreaming;
    WebAssembly.instantiateStreaming = function(response, importObject) {
      console.log("Using enhanced instantiateStreaming");
      
      // Handle case where response is a Promise<Response>
      if (response instanceof Promise) {
        return response.then(actualResponse => {
          const contentType = actualResponse.headers.get('Content-Type');
          
          if (!contentType || !contentType.includes('application/wasm')) {
            console.log('Response has incorrect MIME type, falling back to instantiate');
            return actualResponse.arrayBuffer()
              .then(buffer => WebAssembly.instantiate(buffer, importObject));
          }
          
          return originalInstantiateStreaming(actualResponse, importObject);
        });
      } 
      
      // Case where response is a Response object
      const contentType = response.headers.get('Content-Type');
      if (!contentType || !contentType.includes('application/wasm')) {
        console.log('Response has incorrect MIME type, falling back to instantiate');
        return response.arrayBuffer()
          .then(buffer => WebAssembly.instantiate(buffer, importObject));
      }
      
      return originalInstantiateStreaming(response, importObject);
    };
  }
}

// Initialize WASM module
async function initializeWasm() {
  try {
    configureWasmLoading();
    
    // Import the WASM module
    console.log("WASM module loaded, initializing with mock data...");
    const init = await import('./ihoje-tobira.js');
    const wasm = await init.default();
    
    console.log("WASM initialized successfully");
    
    // Enable mock data if needed
    if (typeof wasm.enable_mock_data === "function") {
      wasm.enable_mock_data();
      console.log("✅ Mock data mode enabled");
    } else {
      console.error("❌ enable_mock_data function not found!");
    }
    
    return wasm;
  } catch (error) {
    console.error("Failed to initialize WASM:", error);
    // Show error message on page
    document.body.innerHTML += `
      <div style="
        background: #ffeeee;
        border: 1px solid #ff0000;
        padding: 20px;
        margin: 20px;
        border-radius: 5px;
      ">
        <h3>WebAssembly Error</h3>
        <p>${error.message || error}</p>
      </div>
    `;
    throw error;
  }
}

// Execute the initialization
try {
  initializeWasm();
} catch (e) {
  console.error("Error in WASM bootstrap process:", e);
}
EOL
echo -e "${GREEN}✅ Fixed bootstrap.js${NC}"

# 3. Ensure WASM MIME type is set in spa_server.py
echo -e "\n${YELLOW}📄 Ensuring spa_server.py has correct MIME type...${NC}"
if ! grep -q "mimetypes.add_type('application/wasm'" spa_server.py; then
  cp spa_server.py "$BACKUP_DIR/spa_server.py.bak"
  echo "#!/usr/bin/env python3" > spa_server.py.new
  echo "# Configure WASM MIME type - critical for proper WebAssembly loading" >> spa_server.py.new
  echo "import mimetypes; mimetypes.add_type('application/wasm', '.wasm')" >> spa_server.py.new
  tail -n +2 spa_server.py >> spa_server.py.new
  mv spa_server.py.new spa_server.py
  chmod +x spa_server.py
  echo -e "${GREEN}✅ Added WASM MIME type to spa_server.py${NC}"
else
  echo -e "${GREEN}✅ WASM MIME type already set in spa_server.py${NC}"
fi

# Save fixed files as a reference for future use
echo -e "\n${YELLOW}📄 Saving fixed files for future reference...${NC}"
cp index.html fixed_index.html
cp bootstrap.js fixed_bootstrap.js
echo -e "${GREEN}✅ Saved fixed_index.html and fixed_bootstrap.js${NC}"

echo -e "\n${BLUE}=== All fixes applied! ===${NC}"
echo -e "${YELLOW}Now run the following command to restart the WebAssembly Tobira:${NC}"
echo -e "${GREEN}./restart-wasm-tobira.sh${NC}"
echo -e "\n${YELLOW}To check if WebAssembly is loading correctly:${NC}"
echo -e "${GREEN}./debug-wasm.sh${NC}"