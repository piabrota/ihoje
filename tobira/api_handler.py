#!/usr/bin/env python3
import json
import http.server
import socketserver
import os

class APIHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
        http.server.SimpleHTTPRequestHandler.end_headers(self)
    
    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()
    
    def do_GET(self):
        # Only handle API requests
        if not self.path.startswith('/api/'):
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b'{"error": "Not found"}')
            return
            
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        
        if self.path == '/api/events':
            events = [
                {
                    "id": "1",
                    "title": "Festival de Música",
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
            
        elif self.path == '/api/cities':
            cities = [
                {"id": "1", "name": "São Paulo"},
                {"id": "2", "name": "Rio de Janeiro"},
                {"id": "3", "name": "Belo Horizonte"}
            ]
            self.wfile.write(json.dumps(cities).encode())
            
        else:
            self.wfile.write(json.dumps({"error": "Unknown endpoint"}).encode())

PORT = 8081
Handler = APIHandler

if __name__ == "__main__":
    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        print(f"API server running at port {PORT}")
        httpd.serve_forever()