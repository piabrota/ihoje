#!/usr/bin/env python3
"""Ultra simple Mangekyou MCP server"""

import http.server
import socketserver
import json
import os

PORT = 17891

class MangekyouHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        """Handle GET requests."""
        if self.path == "/mcp/v1/info":
            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            info = {
                "name": "mangekyou",
                "description": "Simple Mangekyou implementation planner",
                "schema": {
                    "type": "object",
                    "properties": {
                        "query": {
                            "type": "string",
                            "description": "The implementation request"
                        }
                    },
                    "required": ["query"]
                },
                "version": "0.1.0"
            }
            self.wfile.write(json.dumps(info).encode())
        elif self.path == "/health":
            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"status": "ok"}).encode())
        else:
            self.send_response(404)
            self.end_headers()
    
    def do_POST(self):
        """Handle POST requests."""
        if self.path == "/mcp/v1/mangekyou":
            content_length = int(self.headers.get("Content-Length", 0))
            post_data = self.rfile.read(content_length).decode("utf-8")
            
            try:
                data = json.loads(post_data)
                body = data.get("body", {})
                query = body.get("query", "")
                
                if not query:
                    self.send_error(400, "Missing query parameter")
                    return
                
                # Generate a simple implementation plan
                plan = f"""
# Implementation Plan for: {query}

## Changes Needed
1. Update configuration in src/config.rs
2. Implement core functionality in src/
3. Add tests

## Steps
1. [ ] Step 1: Design the feature
2. [ ] Step 2: Implement core code
3. [ ] Step 3: Test functionality
4. [ ] Step 4: Document changes
                """
                
                # Send response
                self.send_response(200)
                self.send_header("Content-type", "application/json")
                self.end_headers()
                response = {"response": plan}
                self.wfile.write(json.dumps(response).encode())
                
            except Exception as e:
                self.send_error(500, f"Error: {str(e)}")
        else:
            self.send_response(404)
            self.end_headers()

if __name__ == "__main__":
    print(f"Starting Mangekyou server on port {PORT}...")
    
    try:
        # Create HTTP server with address reuse to avoid "Address already in use" errors
        socketserver.TCPServer.allow_reuse_address = True
        server = socketserver.TCPServer(("localhost", PORT), MangekyouHandler)
        print(f"Server running at http://localhost:{PORT}")
        print(f"MCP tool endpoint: http://localhost:{PORT}/mcp/v1/mangekyou")
        server.serve_forever()
    except KeyboardInterrupt:
        print("Server stopped by user")
    except Exception as e:
        print(f"Error: {e}")