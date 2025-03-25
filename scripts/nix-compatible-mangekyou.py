#!/usr/bin/env python3
# Nix-compatible Mangekyou MCP server (standalone)
# This is a self-contained implementation that works in any environment

import http.server
import json
import socketserver
import sys
import os
from urllib.parse import parse_qs

# Configuration
PORT = int(os.environ.get("MANGEKYOU_PORT", 17891))
HOST = os.environ.get("MANGEKYOU_HOST", "127.0.0.1")

class MangekyouHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"status": "ok"}).encode())
        elif self.path == "/mcp/v1/info":
            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            info = {
                "name": "mangekyou",
                "description": "Implementation planning via MCP (Nix compatible version)",
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
                "version": "1.0.0"
            }
            self.wfile.write(json.dumps(info).encode())
        else:
            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"status": "ok"}).encode())
    
    def do_POST(self):
        content_length = int(self.headers["Content-Length"])
        post_data = self.rfile.read(content_length)
        
        try:
            data = json.loads(post_data.decode("utf-8"))
            query = data.get("body", {}).get("query", "Implementation Request")
        except:
            query = "Implementation Request"
        
        # Determine language based on query content
        language = detect_language(query)
        
        # Generate plan based on language
        plan = generate_plan(query, language)
        
        self.send_response(200)
        self.send_header("Content-type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        
        response = {"response": plan}
        self.wfile.write(json.dumps(response).encode())
    
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "X-Requested-With, Content-Type, X-MCP-Version")
        self.end_headers()
        
    def log_message(self, format, *args):
        """Override log_message to include timestamp"""
        import datetime
        print(f"[{datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {self.client_address[0]} - {format % args}")

def detect_language(query):
    """Simple language detection based on query content"""
    query_lower = query.lower()
    
    if "rust" in query_lower:
        return "rust"
    elif "python" in query_lower:
        return "python"
    elif "javascript" in query_lower or "js" in query_lower:
        return "javascript"
    else:
        return "general"

def generate_plan(query, language):
    """Generate implementation plan based on language"""
    if language == "rust":
        return f"""# Rust Implementation Plan for: {query}

## Changes Needed
1. Update configuration in src/config.rs
2. Implement core functionality in src/
3. Add tests in tests/ directory

## Implementation Steps
1. [ ] Step 1: Create new module structure
2. [ ] Step 2: Implement error handling with anyhow
3. [ ] Step 3: Add logging with simplelog
4. [ ] Step 4: Implement async functions with proper error propagation
5. [ ] Step 5: Write tests that use mock data

## Code Structure
```rust
// New module structure
use std::{{time::Duration, path::PathBuf}};
use anyhow::{{Context, Result}};

// Main implementation
pub struct NewFeature {{
    config: Config,
}}

impl NewFeature {{
    pub fn new(config: Config) -> Self {{
        Self {{ config }}
    }}
    
    pub async fn process(&self) -> Result<()> {{
        // Implementation here
        Ok(())
    }}
}}
```
"""
    elif language == "python":
        return f"""# Python Implementation Plan for: {query}

## Changes Needed
1. Add new route handlers
2. Create data models with Pydantic
3. Implement unit tests

## Implementation Steps
1. [ ] Step 1: Create new data models
2. [ ] Step 2: Implement route handlers
3. [ ] Step 3: Add error handling and validation
4. [ ] Step 4: Set up logging
5. [ ] Step 5: Write tests with pytest

## Code Structure
```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import logging

# New models
class RequestModel(BaseModel):
    field1: str
    field2: int

# Route handlers
@app.post("/new-endpoint")
async def handle_request(request: RequestModel):
    try:
        # Implementation here
        return {"status": "success"}
    except Exception as e:
        logging.error(f"Error: {{str(e)}}")
        raise HTTPException(status_code=500, detail=str(e))
```
"""
    elif language == "javascript":
        return f"""# JavaScript Implementation Plan for: {query}

## Changes Needed
1. Add new components/modules
2. Update service layer
3. Implement unit tests

## Implementation Steps
1. [ ] Step 1: Create new modules/components
2. [ ] Step 2: Implement core functionality
3. [ ] Step 3: Add error handling and validation
4. [ ] Step 4: Set up logging
5. [ ] Step 5: Write tests

## Code Structure
```javascript
// New module structure
import {{ useEffect, useState }} from 'react';

// Service implementation
const newService = async (params) => {{
  try {{
    // Implementation here
    return {{ success: true }};
  }} catch (error) {{
    console.error(`Error: ${{error.message}}`);
    throw error;
  }}
}};

// Component implementation
function NewComponent({{ props }}) {{
  const [state, setState] = useState(null);
  
  useEffect(() => {{
    // Implementation here
  }}, []);
  
  return (
    <div>
      {{/* Component JSX */}}
    </div>
  );
}}
```
"""
    else:
        return f"""# Implementation Plan for: {query}

## Changes Needed
1. Update configuration files
2. Implement core functionality
3. Add tests
4. Update documentation

## Steps
1. [ ] Step 1: Design the feature
2. [ ] Step 2: Implement core code
3. [ ] Step 3: Test functionality
4. [ ] Step 4: Document changes
5. [ ] Step 5: Submit for review
"""

def run_server():
    """Run the HTTP server"""
    server_address = (HOST, PORT)
    httpd = socketserver.TCPServer(server_address, MangekyouHandler)
    
    print(f"Starting Nix-compatible Mangekyou MCP server on {HOST}:{PORT}")
    print("Press Ctrl+C to stop")
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down server")
        httpd.server_close()

if __name__ == "__main__":
    run_server()