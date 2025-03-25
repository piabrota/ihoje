#!/usr/bin/env bash
# Setup iHoje MCP implementation files

# Create directories
SCRIPT_DIR="/home/h0ffmann/Code/ihoje/scripts/ihoje-mcp"
mkdir -p "$SCRIPT_DIR"

# Create the Python implementation file
echo "Creating ihoje_mangekyou.py..."
cat > "$SCRIPT_DIR/ihoje_mangekyou.py" << 'EOF'
#!/usr/bin/env python3
# iHoje Mangekyou MCP Server
# Self-contained implementation for Claude Code

import http.server
import json
import socketserver
import sys
import os
import datetime
from urllib.parse import parse_qs

# Configuration
PORT = int(os.environ.get("IHOJE_MANGEKYOU_PORT", 17891))
HOST = os.environ.get("IHOJE_MANGEKYOU_HOST", "127.0.0.1")

class MangekyouHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"status": "ok", "service": "ihoje_mangekyou"}).encode())
        elif self.path == "/mcp/v1/info":
            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            info = {
                "name": "ihoje_mangekyou",
                "description": "iHoje Implementation Planning Service",
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
            self.wfile.write(json.dumps({"status": "ok", "service": "ihoje_mangekyou"}).encode())
    
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
        timestamp = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        message = f"[{timestamp}] {self.client_address[0]} - {format % args}"
        print(message)
        
        # Also log to file
        log_dir = os.environ.get("IHOJE_LOG_DIR", "/tmp")
        with open(f"{log_dir}/ihoje_mangekyou.log", "a") as f:
            f.write(message + "\n")

def detect_language(query):
    """Language detection based on query content"""
    query_lower = query.lower()
    
    if "rust" in query_lower:
        return "rust"
    elif "python" in query_lower:
        return "python"
    elif "javascript" in query_lower or "js" in query_lower or "node" in query_lower:
        return "javascript"
    else:
        # Check project context for default language
        if os.path.exists("Cargo.toml"):
            return "rust"
        elif os.path.exists("package.json"):
            return "javascript"
        elif os.path.exists("pyproject.toml") or os.path.exists("requirements.txt"):
            return "python"
        else:
            return "general"

def generate_plan(query, language):
    """Generate implementation plan based on language"""
    if language == "rust":
        return f"""# Rust Implementation Plan for: {query}

## Overview
This plan outlines how to implement this feature in the iHoje Rust codebase.

## Changes Needed
1. Update configuration in src/config.rs
2. Implement core functionality in src/
3. Add tests in tests/ directory
4. Update documentation

## Implementation Steps
1. [ ] Step 1: Create new module structure
2. [ ] Step 2: Implement error handling with anyhow
3. [ ] Step 3: Add logging with simplelog
4. [ ] Step 4: Implement async functions with tokio
5. [ ] Step 5: Write tests that use mock data

## Code Structure
```rust
// New module structure
use std::{{time::Duration, path::PathBuf}};
use anyhow::{{Context, Result}};
use log::{{info, error, warn}};

// Main implementation
pub struct NewFeature {{
    config: Config,
}}

impl NewFeature {{
    pub fn new(config: Config) -> Self {{
        Self {{ config }}
    }}
    
    pub async fn process(&self) -> Result<()> {{
        info!("Processing new feature");
        // Implementation here
        Ok(())
    }}
}}
```

## Testing Strategy
```rust
#[cfg(test)]
mod tests {{
    use super::*;
    use tokio::test;
    
    #[test]
    async fn test_new_feature() {{
        // Test implementation
    }}
}}
```
"""
    elif language == "python":
        return f"""# Python Implementation Plan for: {query}

## Overview
This plan outlines how to implement this feature in the iHoje Python components.

## Changes Needed
1. Add new data models
2. Create route handlers
3. Implement business logic
4. Add tests

## Implementation Steps
1. [ ] Step 1: Create new data models with Pydantic
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
        return {{"status": "success"}}
    except Exception as e:
        logging.error(f"Error: {{str(e)}}")
        raise HTTPException(status_code=500, detail=str(e))
```

## Testing Strategy
```python
import pytest
from fastapi.testclient import TestClient

def test_new_endpoint():
    # Test implementation
    response = client.post("/new-endpoint", json={{"field1": "test", "field2": 42}})
    assert response.status_code == 200
    assert response.json()["status"] == "success"
```
"""
    elif language == "javascript":
        return f"""# JavaScript Implementation Plan for: {query}

## Overview
This plan outlines how to implement this feature in the iHoje JavaScript components.

## Changes Needed
1. Add new modules/components
2. Implement service layer
3. Create UI components
4. Add tests

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
      // Component JSX goes here
    </div>
  );
}}
```

## Testing Strategy
```javascript
import {{ render, screen, fireEvent }} from '@testing-library/react';
import NewComponent from './NewComponent';

test('renders component correctly', () => {{
  render(NewComponent);
  // Test implementation
}});
```
"""
    else:
        return f"""# Implementation Plan for: {query}

## Overview
This plan outlines how to implement this feature in the iHoje codebase.

## Changes Needed
1. Update configuration files
2. Implement core functionality
3. Add tests
4. Update documentation

## Implementation Steps
1. [ ] Step 1: Design the feature
2. [ ] Step 2: Implement core code
3. [ ] Step 3: Test functionality
4. [ ] Step 4: Document changes
5. [ ] Step 5: Submit for review

## Testing Strategy
- Unit tests to verify individual components
- Integration tests to verify end-to-end functionality
- Performance tests for any critical paths
"""

def run_server():
    """Run the HTTP server"""
    # Create log directory if it doesn't exist
    log_dir = os.environ.get("IHOJE_LOG_DIR", "/tmp")
    os.makedirs(log_dir, exist_ok=True)
    
    # Try to bind to the specified port or find an available one
    current_port = PORT
    max_attempts = 5
    server = None
    
    for attempt in range(max_attempts):
        try:
            server_address = (HOST, current_port)
            # Allow reuse of the address to avoid "address in use" errors
            socketserver.TCPServer.allow_reuse_address = True
            server = socketserver.TCPServer(server_address, MangekyouHandler)
            # Successfully bound to a port
            break
        except OSError as e:
            print(f"Port {current_port} is already in use, trying next port")
            current_port += 1
            if attempt == max_attempts - 1:
                print(f"Failed to find an available port after {max_attempts} attempts")
                raise
    
    # Write port to a file for reference
    with open("/tmp/ihoje_mangekyou_port", "w") as port_file:
        port_file.write(str(current_port))
    
    print(f"Starting iHoje Mangekyou MCP server on {HOST}:{current_port}")
    print(f"Logs available at: {log_dir}/ihoje_mangekyou.log")
    print("Press Ctrl+C to stop")
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down server")
        server.server_close()

if __name__ == "__main__":
    run_server()
EOF

# Make the script executable
chmod +x "$SCRIPT_DIR/ihoje_mangekyou.py"

# Create launcher script
echo "Creating start_ihoje_mangekyou.sh..."
cat > "$SCRIPT_DIR/start_ihoje_mangekyou.sh" << 'EOF'
#!/usr/bin/env bash
# iHoje Mangekyou launcher

# Set environment variables
export IHOJE_MANGEKYOU_PORT=17891
export IHOJE_MANGEKYOU_HOST="127.0.0.1"
export IHOJE_LOG_DIR="/tmp"

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Kill any existing server
if [ -f /tmp/ihoje_mangekyou.pid ]; then
    OLD_PID=$(cat /tmp/ihoje_mangekyou.pid)
    if kill -0 $OLD_PID 2>/dev/null; then
        echo "Stopping existing Mangekyou server (PID: $OLD_PID)"
        kill $OLD_PID
        sleep 1
    fi
    rm -f /tmp/ihoje_mangekyou.pid
fi

# Remove port file if it exists
rm -f /tmp/ihoje_mangekyou_port

# Run the server in background
python3 "$SCRIPT_DIR/ihoje_mangekyou.py" > /tmp/ihoje_mangekyou_stdout.log 2>&1 &

# Save PID
echo $! > /tmp/ihoje_mangekyou.pid
EOF

# Make launcher executable
chmod +x "$SCRIPT_DIR/start_ihoje_mangekyou.sh"

echo "✅ Created implementation files:"
echo "- $SCRIPT_DIR/ihoje_mangekyou.py"
echo "- $SCRIPT_DIR/start_ihoje_mangekyou.sh"