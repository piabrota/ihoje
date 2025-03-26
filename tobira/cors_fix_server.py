#!/usr/bin/env python3
import mimetypes
mimetypes.add_type('application/wasm', '.wasm')

import http.server
import socketserver
import os
import sys
import json

class CORSFixHandler(http.server.SimpleHTTPRequestHandler):
    # Override the default MIME types to ensure WebAssembly files are served correctly
    extensions_map = {
        **http.server.SimpleHTTPRequestHandler.extensions_map,
        ".wasm": "application/wasm",
    }
    
    def _set_cors_headers(self):
        """Set the CORS headers - just once per header to avoid duplication"""
        # Remove any existing CORS headers to prevent duplicates
        self.headers._headers = [h for h in self.headers._headers if not h[0].lower().startswith("access-control")]
        
        # Set fresh CORS headers
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
    
    def end_headers(self):
        self._set_cors_headers()
        http.server.SimpleHTTPRequestHandler.end_headers(self)
    
    def do_OPTIONS(self):
        """Handle preflight OPTIONS requests for CORS"""
        self.send_response(200)
        self._set_cors_headers()  
        self.end_headers()
    
    def do_GET(self):
        print(f"GET request for: {self.path}")
        
        # Handle API requests with mock data
        if self.path.startswith("/api/"):
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self._set_cors_headers()
            self.end_headers()
            
            # Serve mock data based on endpoint
            if self.path == "/api/events":
                # Generate some mock events
                events = [
                    {
                        "id": "1",
                        "title": "Evento de Música",
                        "description": "Um grande festival de música com artistas locais",
                        "date": "2025-05-01T19:00:00",
                        "location": "São Paulo, SP",
                        "image_url": "/static/images/event1.svg",
                        "category": "Música",
                        "price": 50.0,
                        "city_id": "1"
                    },
                    {
                        "id": "2",
                        "title": "Workshop de Dança",
                        "description": "Aprenda diferentes estilos de dança com os melhores professores",
                        "date": "2025-05-10T14:00:00",
                        "location": "Rio de Janeiro, RJ",
                        "image_url": "/static/images/event2.svg",
                        "category": "Dança",
                        "price": 35.0,
                        "city_id": "2"
                    },
                    {
                        "id": "3",
                        "title": "Feira Gastronômica",
                        "description": "Experimente pratos de diferentes culinárias",
                        "date": "2025-05-15T11:00:00",
                        "location": "Belo Horizonte, MG",
                        "image_url": "/static/images/event3.svg",
                        "category": "Gastronomia",
                        "price": 0.0,
                        "city_id": "3"
                    }
                ]
                self.wfile.write(json.dumps(events).encode())
                return
            
            elif self.path == "/api/cities":
                # Generate mock cities
                cities = [
                    {"id": "1", "name": "São Paulo"},
                    {"id": "2", "name": "Rio de Janeiro"},
                    {"id": "3", "name": "Belo Horizonte"}
                ]
                self.wfile.write(json.dumps(cities).encode())
                return
            
            # Default response for unknown API endpoints
            self.wfile.write(json.dumps({"error": "Endpoint not found"}).encode())
            return
        
        # Handle WebAssembly file name mapping
        if self.path.endswith('ihoje_frontend_bg.wasm'):
            print(f"  -> Mapping WASM request to ihoje-tobira_bg.wasm")
            self.path = '/ihoje-tobira_bg.wasm'
        
        # For WASM files, add special handling for MIME type
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
        
        # Handle all files or SPA routing
        requested_path = self.path.lstrip('/')
        file_path = os.path.join(os.getcwd(), requested_path)
        
        # If file doesn't exist, serve index.html for SPA routing
        if requested_path and not os.path.exists(file_path):
            self.path = '/index.html'
            print(f"  -> File not found, serving index.html for SPA routing")
        
        return http.server.SimpleHTTPRequestHandler.do_GET(self)

def run_server(port=8081, directory="dist"):
    # Change to the specified directory
    if os.path.exists(directory):
        os.chdir(directory)
        print(f"Changed to directory: {os.getcwd()}")
    else:
        print(f"Error: Directory {directory} not found!")
        sys.exit(1)
    
    # Create and start the server
    handler = CORSFixHandler
    
    # Allow address reuse to prevent "Address already in use" errors on restart
    socketserver.TCPServer.allow_reuse_address = True
    
    # Create the HTTP server - binding to all interfaces for compatibility
    httpd = socketserver.TCPServer(("0.0.0.0", port), handler)
    
    print(f"Server binding to 0.0.0.0:{port} (all interfaces)")
    print(f"Starting SPA server on http://localhost:{port}")
    print(f"Serving files from: {os.getcwd()}")
    print(f"WebAssembly MIME type: {mimetypes.types_map.get('.wasm')}")
    print("Press Ctrl+C to stop the server")
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped by user")
    finally:
        httpd.server_close()

if __name__ == "__main__":
    port = 8080
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