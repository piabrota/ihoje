// Environment variables for iHoje Tobira frontend
window.ihoje_env = {
  IHOJE_ENVIRONMENT: "development",
  IHOJE_API_URL: "http://localhost:8080/api",
  IHOJE_USE_MOCK_DATA: "true",
  IHOJE_SUPABASE_URL: "https://xyzsupabase.supabase.co",
  IHOJE_SUPABASE_ANON_KEY: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRlc3QiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTY3MDc2OTQ5OSwiZXhwIjoxOTg2MzQ1NDk5fQ.example_test_key"
};

// Access env vars helper
window.get_env_var = function(name) {
  return (window.ihoje_env && window.ihoje_env[name]) || "";
};

// WebAssembly MIME type fix and filename compatibility - must run before other scripts
console.log("Adding robust WebAssembly compatibility fixes");

// Patch the fetch API to fix WASM MIME types and handle filename inconsistencies
const originalFetch = window.fetch;
window.fetch = function(input, init) {
  // Fix the WASM file name inconsistency between 'ihoje_frontend_bg.wasm' and 'ihoje-tobira_bg.wasm'
  if (typeof input === 'string') {
    if (input.endsWith('ihoje_frontend_bg.wasm')) {
      console.log("Fixing WASM file name reference:", input);
      input = input.replace('ihoje_frontend_bg.wasm', 'ihoje-tobira_bg.wasm');
    } else if (input.endsWith('ihoje_frontend.js')) {
      console.log("Fixing JS file name reference:", input);
      input = input.replace('ihoje_frontend.js', 'ihoje-tobira.js');
    }
  }
  
  return originalFetch(input, init).then(response => {
    // For WASM files, ensure proper MIME type
    if (typeof input === 'string' && input.endsWith('.wasm')) {
      console.log("WASM MIME type fix applied to:", input);
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

// Also fix WebAssembly.instantiateStreaming if it exists
if (typeof WebAssembly !== 'undefined' && WebAssembly.instantiateStreaming) {
  const originalInstantiateStreaming = WebAssembly.instantiateStreaming;
  WebAssembly.instantiateStreaming = function(responsePromise, importObject) {
    return responsePromise
      .then(response => {
        const contentType = response.headers.get('Content-Type');
        if (!contentType || !contentType.includes('application/wasm')) {
          console.log("Converting response to arrayBuffer for WebAssembly.instantiateStreaming");
          return WebAssembly.instantiate(response.clone().arrayBuffer(), importObject);
        }
        return originalInstantiateStreaming(Promise.resolve(response), importObject);
      })
      .catch(error => {
        console.error("WebAssembly.instantiateStreaming error:", error);
        // Try to recover using the slower instantiate method
        return responsePromise
          .then(response => response.arrayBuffer())
          .then(buffer => WebAssembly.instantiate(buffer, importObject));
      });
  };
}

// Add a post-processing hook to initialize WASM correctly
window.addEventListener('DOMContentLoaded', function() {
  console.log("DOM loaded, ensuring WebAssembly is correctly initialized");
  
  // Create a bootstrap script to handle WASM loading with proper error handling
  if (!document.querySelector('script[data-wasm-bootstrap]')) {
    const script = document.createElement('script');
    script.setAttribute('data-wasm-bootstrap', 'true');
    script.setAttribute('type', 'module');
    script.innerHTML = `
      // Try to dynamically import the WASM module
      try {
        console.log("Importing WASM module...");
        // Try both potential module names
        import('./ihoje-tobira.js')
          .then(module => {
            console.log("WASM module loaded, initializing...");
            return module.default();
          })
          .then(wasm => {
            console.log("WASM initialized successfully");
            // Enable mock data if available
            if (typeof wasm.enable_mock_data === "function") {
              wasm.enable_mock_data();
              console.log("✅ Mock data enabled");
            }
          })
          .catch(error => {
            console.error("Failed to initialize ihoje-tobira.js, trying alternative:", error);
            // Try the alternative module name if the first one fails
            import('./ihoje_frontend.js')
              .then(module => {
                console.log("Alternative WASM module loaded, initializing...");
                return module.default();
              })
              .then(wasm => {
                console.log("Alternative WASM initialized successfully");
                if (typeof wasm.enable_mock_data === "function") {
                  wasm.enable_mock_data();
                  console.log("✅ Mock data enabled (alternative module)");
                }
              })
              .catch(altError => {
                console.error("Both WASM initialization attempts failed:", altError);
                document.body.innerHTML += \`
                  <div style="background: #ffeeee; border: 1px solid #ff0000; padding: 20px; margin: 20px;">
                    <h3>WebAssembly Error</h3>
                    <p>Initial error: \${error.message}</p>
                    <p>Alternative error: \${altError.message}</p>
                  </div>
                \`;
              });
          });
      } catch (e) {
        console.error("Error in WASM bootstrap:", e);
      }
    `;
    document.body.appendChild(script);
  }
});

console.log("WebAssembly support:", typeof WebAssembly === 'object');
console.log("WebAssembly.instantiate support:", typeof WebAssembly.instantiate === 'function');
console.log("WebAssembly.instantiateStreaming support:", typeof WebAssembly.instantiateStreaming === 'function');