// Debug helper for auth and WASM issues
console.log("Auth debug helper loaded");

// WebAssembly MIME type fix - must run before any other scripts
console.log("Adding robust WebAssembly MIME type fix");

// Patch the fetch API to fix WASM MIME types
const originalFetch = window.fetch;
window.fetch = function(input, init) {
    return originalFetch(input, init).then(response => {
        // For WASM files, ensure proper MIME type
        if (typeof input === 'string' && input.endsWith('.wasm')) {
            console.log("WASM fix applied to:", input);
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

console.log("WebAssembly support:", typeof WebAssembly === 'object');
console.log("WebAssembly.instantiate support:", typeof WebAssembly.instantiate === 'function');
console.log("WebAssembly.instantiateStreaming support:", typeof WebAssembly.instantiateStreaming === 'function');

// Add helper function to diagnose WASM loading issues
window.testWasmLoading = async function(url) {
    try {
        console.log("Testing WASM loading from:", url);
        const response = await fetch(url);
        console.log("Response status:", response.status);
        console.log("Response headers:", Object.fromEntries([...response.headers.entries()]));
        
        const arrayBuffer = await response.clone().arrayBuffer();
        console.log("ArrayBuffer size:", arrayBuffer.byteLength);
        console.log("First bytes:", new Uint8Array(arrayBuffer.slice(0, 8)).join(' '));
        
        // Check for WASM magic number
        const magic = new Uint8Array(arrayBuffer.slice(0, 4));
        const isMagicCorrect = magic[0] === 0 && magic[1] === 97 && magic[2] === 115 && magic[3] === 109; // "\0asm"
        console.log("WASM magic correct:", isMagicCorrect);
        
        if (!isMagicCorrect) {
            const text = await response.clone().text();
            console.log("Content starts with:", text.substring(0, 100));
            return {success: false, error: "Not a valid WASM file"};
        }
        
        return {success: true};
    } catch (error) {
        console.error("WASM testing error:", error);
        return {success: false, error: error.toString()};
    }
};