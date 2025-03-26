#\!/usr/bin/env python3
import http.server
import socketserver
import os
import sys
import json
import mimetypes

# Ensure WebAssembly files are served with correct MIME type
mimetypes.add_type("application/wasm", ".wasm")

class DebugHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, format, *args):
        print(f"[{self.log_date_time_string()}] {format % args}")
    
    def end_headers(self):
        # Add CORS headers
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
        http.server.SimpleHTTPRequestHandler.end_headers(self)
    
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.end_headers()
    
    def send_json_response(self, data):
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode('utf-8'))
    
    def do_GET(self):
        print(f"GET request for: {self.path}")
        
        # Handle API endpoints
        if self.path.startswith('/api/'):
            return self.handle_api_request()
        
        # Serve static files
        return http.server.SimpleHTTPRequestHandler.do_GET(self)
    
    def handle_api_request(self):
        """Handle API requests with mock data"""
        events = [
            {
                "id": "1",
                "title": "Festival de Música",
                "description": "Um grande festival de música com artistas locais",
                "date": "2025-05-01T19:00:00",
                "location": "São Paulo, SP",
                "image_url": "/static/images/event1.svg",
                "category": "Música",
                "price": 50,
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
                "price": 35,
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
                "price": 0,
                "city_id": "3"
            }
        ]
        
        cities = [
            {"id": "1", "name": "São Paulo"},
            {"id": "2", "name": "Rio de Janeiro"},
            {"id": "3", "name": "Belo Horizonte"}
        ]
        
        health_data = {
            "status": "ok",
            "version": "1.0.0",
            "environment": "development",
            "timestamp": "2025-03-26T00:00:00Z"
        }
        
        if self.path == '/api/events':
            return self.send_json_response(events)
        
        elif self.path.startswith('/api/events/'):
            event_id = self.path.split('/')[-1]
            event = next((e for e in events if e["id"] == event_id), None)
            if event:
                return self.send_json_response(event)
            else:
                self.send_error(404, f"Event with ID {event_id} not found")
        
        elif self.path == '/api/cities':
            return self.send_json_response(cities)
        
        elif self.path == '/api/health':
            return self.send_json_response(health_data)
        
        elif self.path == '/api/admin/events':
            return self.send_json_response(events)
        
        else:
            self.send_error(404, f"API endpoint not found: {self.path}")

def run_server(port=8080):
    handler = DebugHandler
    httpd = socketserver.TCPServer(("0.0.0.0", port), handler)
    
    print(f"Starting Debug Server on port {port}")
    print(f"Server URL: http://localhost:{port}")
    print("Available endpoints:")
    print("  - /api/events")
    print("  - /api/events/[id]")
    print("  - /api/cities")
    print("  - /api/health")
    print("  - /api/admin/events")
    print("Press Ctrl+C to stop the server")
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped by user")
    finally:
        httpd.server_close()

if __name__ == "__main__":
    port = 8080
    if len(sys.argv) > 1:
        try:
            port = int(sys.argv[1])
        except ValueError:
            print(f"Invalid port number: {sys.argv[1]}, using default: {port}")
    
    run_server(port)
