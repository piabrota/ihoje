#!/usr/bin/env python3
import http.server
import socketserver
import os

class SPAHandler(http.server.SimpleHTTPRequestHandler):
    # Add MIME types for WebAssembly
    extensions_map = {
        **http.server.SimpleHTTPRequestHandler.extensions_map,
        ".wasm": "application/wasm",
    }
    
    def end_headers(self):
        # Add CORS headers to allow fetch requests
        self.send_header("Access-Control-Allow-Origin", "*")
        # Explicitly set WASM MIME type for all .wasm files
        if self.path.endswith(".wasm"):
            self.send_header("Content-Type", "application/wasm")
        http.server.SimpleHTTPRequestHandler.end_headers(self)
    
    def do_GET(self):
        print(f"GET request for: {self.path}")
        # For WASM files, add special handling
        if self.path.endswith(".wasm"):
            print(f"  -> Serving WASM file with application/wasm MIME type")
            # Ensure specific content type for .wasm files
            filepath = os.path.join(os.getcwd(), self.path.lstrip("/"))
            if os.path.exists(filepath):
                with open(filepath, "rb") as f:
                    content = f.read()
                    self.send_response(200)
                    self.send_header("Content-Type", "application/wasm")
                    self.send_header("Content-Length", str(len(content)))
                    self.end_headers()
                    self.wfile.write(content)
                    return
        
        # Handle SPA routing - serve index.html for non-existent paths
        if not os.path.exists(os.path.join("/app/web", self.path.lstrip("/"))):
            self.path = "/index.html"
        return http.server.SimpleHTTPRequestHandler.do_GET(self)

handler = SPAHandler
port = 8080

print(f"Starting SPA server on port {port}")
with socketserver.TCPServer(("", port), handler) as httpd:
    os.chdir("/app/web")
    print(f"Serving SPA at http://localhost:{port}")
    print(f"WebAssembly MIME type: application/wasm")
    httpd.serve_forever()