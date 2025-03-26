#\!/usr/bin/env python3
import http.server
import socketserver
import os
import sys

class SPAHandler(http.server.SimpleHTTPRequestHandler):
    # Override the default MIME types to ensure WebAssembly files are served correctly
    extensions_map = {
        **http.server.SimpleHTTPRequestHandler.extensions_map,
        ".wasm": "application/wasm",
    }
    
    def end_headers(self):
        # Add CORS headers to allow fetch requests
        self.send_header("Access-Control-Allow-Origin", "*")
        http.server.SimpleHTTPRequestHandler.end_headers(self)
    
    def do_GET(self):
        print(f"GET request for: {self.path}")
        
        # Special wasm file handling - rename if needed
        if self.path.endswith('ihoje_frontend_bg.wasm') and not os.path.exists(os.path.join(os.getcwd(), self.path.lstrip('/'))):
            print(f"  -> Redirecting WASM request to ihoje-tobira_bg.wasm")
            self.path = '/ihoje-tobira_bg.wasm'
        
        # Special handling for WebAssembly files
        if self.path.endswith('.wasm'):
            print(f"  -> Serving WASM file with application/wasm MIME type")
            filepath = os.path.join(os.getcwd(), self.path.lstrip("/"))
            if os.path.exists(filepath):
                with open(filepath, 'rb') as f:
                    content = f.read()
                    self.send_response(200)
                    self.send_header("Content-Type", "application/wasm")
                    self.send_header("Content-Length", str(len(content)))
                    self.end_headers()
                    self.wfile.write(content)
                    return
        
        # Special route handling - only handle specific admin paths
        if self.path == '/admin' or self.path.startswith('/admin/'):
            print(f"  -> Admin route detected: {self.path}")
            self.path = '/admin.html'
        elif self.path == '/login':
            print(f"  -> Login route detected")
            self.path = '/login.html'
        elif self.path == '/':
            # Only explicitly route home to index.html
            self.path = '/index.html'
        
        # Handle any other routes - for physical files, serve normally
        requested_path = self.path.lstrip('/')
        file_path = os.path.join(os.getcwd(), requested_path)
        
        # If file doesn't exist, try the home page
        if requested_path and not os.path.exists(file_path):
            print(f"  -> File not found: {requested_path}, serving index.html")
            self.path = '/index.html'
        
        return http.server.SimpleHTTPRequestHandler.do_GET(self)

def run_server(port=8081, directory="dist"):
    # Change to the specified directory
    if os.path.exists(directory):
        os.chdir(directory)
        print(f"Changed to directory: {os.getcwd()}")
    else:
        print(f"Error: Directory {directory} not found\!")
        sys.exit(1)
    
    # Create and start the server
    handler = SPAHandler
    httpd = socketserver.TCPServer(("", port), handler)
    
    print(f"Starting SPA server on http://localhost:{port}")
    print(f"Serving files from: {os.getcwd()}")
    print(f"WebAssembly MIME type: application/wasm")
    print("Press Ctrl+C to stop the server")
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped by user")
    finally:
        httpd.server_close()

if __name__ == "__main__":
    port = 8081
    directory = "dist"
    
    # Parse command line arguments
    if len(sys.argv) > 1:
        try:
            port = int(sys.argv[1])
        except ValueError:
            print(f"Invalid port number: {sys.argv[1]}, using default: {port}")
    
    if len(sys.argv) > 2:
        directory = sys.argv[2]
    
    run_server(port, directory)
