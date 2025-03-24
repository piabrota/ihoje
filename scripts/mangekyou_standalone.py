#!/usr/bin/env python3
"""
Standalone Mangekyou MCP server with self-registration
This is a completely standalone file with no dependencies beyond the Python standard library
"""

import http.server
import socketserver
import json
import os
import sys
import subprocess
import signal
import time
import threading
from pathlib import Path

# Configuration
PORT = 17891
PID_FILE = "/tmp/mangekyou-pid.txt"
MCP_NAME = "mangekyou"

def write_pid():
    """Write PID to file for easy management"""
    with open(PID_FILE, "w") as f:
        f.write(str(os.getpid()))

def register_with_claude():
    """Register the server with Claude MCP using script mode only"""
    script_path = os.path.abspath(__file__)
    
    # First try to remove any existing registration
    try:
        subprocess.run(
            ["claude", "mcp", "remove", MCP_NAME],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
    except (subprocess.SubprocessError, FileNotFoundError):
        pass  # Ignore errors when removing
    
    # Create a simple wrapper script that calls the HTTP server directly
    wrapper_script = """#!/bin/bash
# Simple wrapper to test Mangekyou server
curl -s -X POST "http://localhost:17891/mcp/v1/mangekyou" \\
    -H "Content-Type: application/json" \\
    -d "{\\\"body\\\": {\\\"query\\\": \\\"$*\\\"}}"
"""
    
    wrapper_path = os.path.join(os.path.dirname(script_path), "mangekyou_wrapper.sh")
    try:
        with open(wrapper_path, "w") as f:
            f.write(wrapper_script)
        os.chmod(wrapper_path, 0o755)  # Make executable
        
        # Register using the wrapper script
        result = subprocess.run(
            ["claude", "mcp", "add", MCP_NAME, "-s", "user", wrapper_path],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=True
        )
        print(f"✅ Registered with Claude MCP: {result.stdout.strip()}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Failed to register with Claude MCP: {e.stderr}")
        
        # Fallback to direct script registration
        try:
            result = subprocess.run(
                ["claude", "mcp", "add", MCP_NAME, "-s", "user", f"{sys.executable} {script_path}"],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                check=True
            )
            print(f"✅ Registered with Claude MCP (fallback): {result.stdout.strip()}")
            return True
        except subprocess.CalledProcessError as e2:
            print(f"❌ All registration methods failed: {e2.stderr}")
            return False
    except (IOError, OSError) as e:
        print(f"❌ Error creating wrapper script: {e}")
        return False
    except FileNotFoundError:
        print("❌ Claude CLI not found. Please install it first.")
        return False

def unregister_from_claude():
    """Unregister from Claude MCP on exit"""
    try:
        subprocess.run(
            ["claude", "mcp", "remove", MCP_NAME],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        print(f"Unregistered from Claude MCP")
    except (subprocess.SubprocessError, FileNotFoundError):
        pass  # Ignore errors on cleanup

class MangekyouHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        """Handle GET requests."""
        if self.path == "/mcp/v1/info":
            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            info = {
                "name": MCP_NAME,
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
        if self.path == f"/mcp/v1/{MCP_NAME}":
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
    
    # Make the server quieter by not logging all requests
    def log_message(self, format, *args):
        return

def cleanup(server):
    """Clean up resources on exit"""
    print("\nShutting down Mangekyou server...")
    server.shutdown()
    if os.path.exists(PID_FILE):
        os.remove(PID_FILE)
    
    # Remove wrapper script if it exists
    wrapper_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "mangekyou_wrapper.sh")
    if os.path.exists(wrapper_path):
        try:
            os.remove(wrapper_path)
        except:
            pass
    
    unregister_from_claude()
    print("Goodbye!")

def show_banner():
    """Display welcome banner"""
    print("╔══════════════════════════════════════════════════════════╗")
    print("║                                                          ║")
    print("║  Mangekyou Sharingan MCP - Standalone Implementation     ║")
    print("║  No dependencies, no venv, just pure Python              ║")
    print("║                                                          ║")
    print("╚══════════════════════════════════════════════════════════╝")
    print("")

def check_if_already_running():
    """Check if another instance is already running"""
    if os.path.exists(PID_FILE):
        with open(PID_FILE, "r") as f:
            old_pid = f.read().strip()
            try:
                # Check if the process exists
                os.kill(int(old_pid), 0)
                print(f"⚠️ Another Mangekyou server is already running (PID: {old_pid})")
                print(f"   Use 'kill {old_pid}' to stop it first.")
                return True
            except (OSError, ValueError):
                # Process doesn't exist
                os.remove(PID_FILE)
    return False

def start_server():
    """Start the HTTP server"""
    if check_if_already_running():
        return False

    write_pid()
    
    try:
        # Create HTTP server
        server = socketserver.TCPServer(("", PORT), MangekyouHandler)
        
        # Setup signal handlers for graceful shutdown
        def handle_interrupt(sig, frame):
            cleanup(server)
            sys.exit(0)
        
        signal.signal(signal.SIGINT, handle_interrupt)
        signal.signal(signal.SIGTERM, handle_interrupt)
        
        # Start server in a separate thread
        server_thread = threading.Thread(target=server.serve_forever)
        server_thread.daemon = True
        server_thread.start()
        
        print(f"✅ Mangekyou server running at http://localhost:{PORT}")
        print("Press Ctrl+C to stop the server")
        
        # Register with Claude MCP
        register_with_claude()
        
        # Keep main thread alive but responsive to signals
        while True:
            time.sleep(1)
    
    except Exception as e:
        print(f"❌ Server error: {e}")
        if os.path.exists(PID_FILE):
            os.remove(PID_FILE)
        return False

def main():
    """Main entry point"""
    show_banner()
    
    if len(sys.argv) > 1:
        command = sys.argv[1].lower()
        if command == "register":
            register_with_claude()
            return
        elif command == "unregister":
            unregister_from_claude()
            return
        elif command == "status":
            if check_if_already_running():
                print(f"Status: Running")
                return
            else:
                print(f"Status: Not running")
                return
    
    # Default action is to start the server
    start_server()

if __name__ == "__main__":
    main()