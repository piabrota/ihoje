// Environment variables for iHoje Tobira frontend
window.ENV = {
  API_URL: 'http://localhost:3000',
  DEBUG: true
};

// Enhanced WASM loading debug
console.log("ENV.js loaded with API_URL:", window.ENV.API_URL);

// Helper to log WASM loading attempts
let wasmAttempts = [];
let originalXHROpen = XMLHttpRequest.prototype.open;
XMLHttpRequest.prototype.open = function() {
  const url = arguments[1];
  if (typeof url === 'string' && url.endsWith('.wasm')) {
    console.log("XHR requesting WASM file:", url);
    wasmAttempts.push({
      time: new Date().toISOString(),
      url,
      method: arguments[0]
    });
  }
  return originalXHROpen.apply(this, arguments);
};

// Expose helper function to check WASM requests
window.getWasmAttempts = function() {
  return wasmAttempts;
};