// Single bootstrap entry point that correctly loads WASM
console.log("Bootstrap.js loaded - initializing WASM...");

// Configure WebAssembly loading with proper MIME type
function configureWasmLoading() {
  console.log("Configuring WebAssembly loaders");

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
    const init = await import('./ihoje-tobira.js');
    const wasm = await init.default();
    
    console.log("WASM initialization successful!");
    
    // Enable mock data if needed
    if (typeof wasm.enable_mock_data === "function") {
      wasm.enable_mock_data();
      console.log("✅ Mock data mode enabled");
    }
    
    return wasm;
  } catch (error) {
    console.error("Error initializing WASM:", error);
    // Show error message on page
    document.body.innerHTML += `
      <div style="
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        background: #f44336;
        color: white;
        padding: 10px;
        text-align: center;
        z-index: 9999;
      ">
        Failed to load WebAssembly: ${error.message}
      </div>
    `;
    throw error;
  }
}

// Execute the initialization
initializeWasm();