import mimetypes; mimetypes.add_type('application/wasm', '.wasm')
import mimetypes; mimetypes.add_type('application/wasm', '.wasm')
#!/usr/bin/env python3
# Configure WASM MIME type - critical for proper WebAssembly loading
import mimetypes; mimetypes.add_type('application/wasm', '.wasm')
import http.server
import socketserver
import os
import sys
import json
import urllib.parse
import re
import time
import threading
from collections import defaultdict

# Rate limiting setup
class RateLimiter:
    def __init__(self, max_requests=10, per_seconds=60, expiration=3600):
        self.max_requests = max_requests  # Maximum requests allowed
        self.per_seconds = per_seconds    # Time window in seconds
        self.expiration = expiration      # How long to keep IP in tracking
        self.requests = defaultdict(list) # IP -> list of timestamps
        self.blocked_ips = {}             # IP -> unblock time
        self.lock = threading.Lock()      # Thread safety
    
    def is_rate_limited(self, ip):
        """Check if an IP is currently rate limited"""
        with self.lock:
            # First, check if IP is blocked
            if ip in self.blocked_ips:
                if time.time() < self.blocked_ips[ip]:
                    return True  # Still blocked
                else:
                    # Block time expired, remove from blocked list
                    del self.blocked_ips[ip]
                    self.requests[ip] = []  # Reset request count
            
            # Clean up old requests
            now = time.time()
            self.requests[ip] = [t for t in self.requests[ip] if now - t < self.per_seconds]
            
            # Check if too many requests
            if len(self.requests[ip]) >= self.max_requests:
                # Block for a while (exponential backoff)
                block_time = min(30 * 2 ** (len(self.requests[ip]) // self.max_requests), 3600)
                self.blocked_ips[ip] = now + block_time
                print(f"SECURITY: Rate limiting {ip} for {block_time} seconds (excessive requests)")
                return True
            
            # Add this request
            self.requests[ip].append(now)
            return False
    
    def clean_up(self):
        """Clean up expired entries"""
        with self.lock:
            now = time.time()
            # Clean up blocked IPs
            expired_blocks = [ip for ip, t in self.blocked_ips.items() if now > t]
            for ip in expired_blocks:
                del self.blocked_ips[ip]
            
            # Clean up request history
            expired_requests = []
            for ip, times in self.requests.items():
                if not times or now - max(times) > self.expiration:
                    expired_requests.append(ip)
            
            for ip in expired_requests:
                del self.requests[ip]

# Create global rate limiter
login_rate_limiter = RateLimiter(max_requests=5, per_seconds=60)  # 5 login attempts per minute
api_rate_limiter = RateLimiter(max_requests=30, per_seconds=60)   # 30 API requests per minute
admin_rate_limiter = RateLimiter(max_requests=20, per_seconds=60) # 20 admin requests per minute

# Authentication helper functions
def check_auth_from_localStorage(headers, client_ip='127.0.0.1'):
    """
    Checks if the request contains admin credentials in localStorage via cookie
    This is a simple check for development purposes
    """
    auth_found = False
    is_admin = False
    
    # Check for localStorage access via JS
    if 'Cookie' in headers:
        try:
            # Parse cookies
            cookies = {}
            for cookie in headers['Cookie'].split(';'):
                if '=' in cookie:
                    name, value = cookie.strip().split('=', 1)
                    cookies[name] = value
            
            # Check for our auth token in cookie
            if 'ihoje_auth' in cookies:
                auth_data = urllib.parse.unquote(cookies['ihoje_auth'])
                auth_json = json.loads(auth_data)
                
                if isinstance(auth_json, dict) and 'role' in auth_json:
                    auth_found = True
                    is_admin = auth_json['role'] == 'admin'
                    
                    # Security logging for admin access
                    if is_admin:
                        print(f"SECURITY: Admin access granted for user {auth_json.get('email', 'unknown')} from {client_ip}")
        except Exception as e:
            print(f"Error parsing auth from cookie: {e}")
    
    return auth_found, is_admin

# URL validation for security
def is_safe_redirect(url):
    """
    Validate that a URL is safe for redirecting to prevent open redirect vulnerabilities
    """
    if not url:
        return False
        
    # Allow relative URLs
    if url.startswith('/'):
        # Don't allow redirects to protocol-relative URLs
        if url.startswith('//'):
            return False
        return True
    
    # For absolute URLs, validate they're to trusted domains
    parsed = urllib.parse.urlparse(url)
    allowed_domains = [
        'ihoje.app', 'www.ihoje.app', 'events.ihoje.app', 
        'admin.ihoje.app', 'localhost'
    ]
    
    return any(parsed.netloc == domain or parsed.netloc.endswith('.' + domain) 
               for domain in allowed_domains)

class SPAHandler(http.server.SimpleHTTPRequestHandler):
    # Override the default MIME types to ensure WebAssembly files are served correctly
    extensions_map = {
        **http.server.SimpleHTTPRequestHandler.extensions_map,
        ".wasm": "application/wasm",
    }
    
    def end_headers(self):
        # Production vs Development security settings
        is_production = 'IHOJE_ENVIRONMENT' in os.environ and os.environ['IHOJE_ENVIRONMENT'] == 'production'
        
        # Set security headers
        # Content Security Policy
        if is_production:
            # Strict CSP for production
            self.send_header(
                "Content-Security-Policy", 
                "default-src 'self'; "
                "script-src 'self' https://cdn.jsdelivr.net https://ihoje-supabase.supabase.co 'unsafe-inline'; "
                "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; "
                "img-src 'self' data: https:; "
                "font-src 'self' https://fonts.gstatic.com; "
                "connect-src 'self' https://ihoje-supabase.supabase.co https://*.supabase.co; "
                "frame-src 'self' https://accounts.google.com; "
                "base-uri 'self'; "
                "form-action 'self'"
            )
        else:
            # More permissive CSP for development
            self.send_header(
                "Content-Security-Policy", 
                "default-src 'self'; "
                "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.jsdelivr.net https://*.supabase.co; "
                "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; "
                "img-src 'self' data: https: blob:; "
                "font-src 'self' https://fonts.gstatic.com; "
                "connect-src 'self' http://localhost:* https://*.supabase.co; "
                "frame-src 'self' https://accounts.google.com"
            )
        
        # Anti-clickjacking header
        self.send_header("X-Frame-Options", "DENY")
        
        # MIME type sniffing prevention
        self.send_header("X-Content-Type-Options", "nosniff")
        
        # Referrer Policy
        self.send_header("Referrer-Policy", "strict-origin-when-cross-origin")
        
        # XSS Protection (although modern browsers use CSP)
        self.send_header("X-XSS-Protection", "1; mode=block")
        
        # CORS - more restrictive in production
        if is_production:
            allowed_origins = "https://ihoje.app https://events.ihoje.app https://admin.ihoje.app"
            self.send_header("Access-Control-Allow-Origin", allowed_origins)
        else:
            self.send_header("Access-Control-Allow-Origin", "*")
        
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
        
        # Explicitly set WASM MIME type for all .wasm files
        if self.path.endswith('.wasm'):
            self.send_header("Content-Type", "application/wasm")
            print("  -> Setting explicit Content-Type: application/wasm for", self.path)
            
        http.server.SimpleHTTPRequestHandler.end_headers(self)
    
    def do_GET(self):
        print(f"GET request for: {self.path}")
        
        # Get client IP for rate limiting
        client_ip = self.client_address[0]
        
        # Parse query parameters
        parsed_url = urllib.parse.urlparse(self.path)
        self.path = parsed_url.path
        query_params = urllib.parse.parse_qs(parsed_url.query)
        
        # Handle health check endpoint
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            
            # Get WASM file status
            wasm_files = [
                os.path.join(os.getcwd(), 'ihoje-tobira_bg.wasm'),
                os.path.join(os.getcwd(), 'ihoje_frontend_bg.wasm')
            ]
            wasm_status = any(os.path.exists(f) for f in wasm_files)
            
            # Build health data
            health_data = {
                'status': 'ok',
                'timestamp': time.time(),
                'server': 'Tobira SPA Server',
                'environment': os.environ.get('IHOJE_ENVIRONMENT', 'development'),
                'wasm_files_found': wasm_status,
                'mimetype_wasm': mimetypes.types_map.get('.wasm', 'not configured')
            }
            
            self.wfile.write(json.dumps(health_data, indent=2).encode('utf-8'))
            return
            self.end_headers()
            
            # Check if WASM files exist
            wasm_files = [
                os.path.join(os.getcwd(), 'ihoje-tobira_bg.wasm'),
                os.path.join(os.getcwd(), 'ihoje_frontend_bg.wasm')
            ]
            wasm_status = any(os.path.exists(f) for f in wasm_files)
            
            health_data = {
                'status': 'ok',
                'wasm_files_found': wasm_status,
                'timestamp': time.time(),
                'server': 'Tobira SPA Server',
                'environment': os.environ.get('TOBIRA_ENV', 'development')
            }
            
            self.wfile.write(json.dumps(health_data).encode('utf-8'))
            return
        
        # Security: Apply rate limiting based on path
        is_limited = False
        
        # Apply login rate limiting
        if self.path == '/login':
            is_limited = login_rate_limiter.is_rate_limited(client_ip)
            if is_limited:
                print(f"SECURITY: Login rate limit exceeded for IP: {client_ip}")
        
        # Apply admin rate limiting
        elif self.path.startswith('/admin'):
            is_limited = admin_rate_limiter.is_rate_limited(client_ip)
            if is_limited:
                print(f"SECURITY: Admin rate limit exceeded for IP: {client_ip}")
        
        # Apply general API rate limiting
        elif self.path.startswith('/api/'):
            is_limited = api_rate_limiter.is_rate_limited(client_ip)
            if is_limited:
                print(f"SECURITY: API rate limit exceeded for IP: {client_ip}")
                
        # Handle rate limiting response
        if is_limited:
            self.send_response(429)  # Too Many Requests
            self.send_header('Content-Type', 'text/html')
            self.send_header('Retry-After', '60')  # Suggest retry after 60 seconds
            self.end_headers()
            
            # Return a simple rate limit message
            rate_limit_message = """
            <!DOCTYPE html>
            <html>
            <head>
                <title>Rate Limit Exceeded</title>
                <style>
                    body { font-family: Arial, sans-serif; margin: 40px; line-height: 1.6; }
                    .container { max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 5px; }
                    h1 { color: #d9534f; }
                </style>
            </head>
            <body>
                <div class="container">
                    <h1>Rate Limit Exceeded</h1>
                    <p>You have made too many requests in a short period of time.</p>
                    <p>Please wait a moment before trying again.</p>
                </div>
            </body>
            </html>
            """
            self.wfile.write(rate_limit_message.encode('utf-8'))
            return
        
        # Security: Validate redirect parameters
        if 'redirect_to' in query_params:
            redirect_url = query_params['redirect_to'][0]
            if not is_safe_redirect(redirect_url):
                print(f"SECURITY: Blocked unsafe redirect to: {redirect_url}")
                # Replace with safe default
                query_params['redirect_to'] = ['/']
        
        # Handle WebAssembly file name mapping - support both potential names
        if self.path.endswith('ihoje_frontend_bg.wasm'):
            wasm_path = 'ihoje-tobira_bg.wasm'
            print(f"  -> Mapping WASM request to {wasm_path}")
            self.path = f"/{wasm_path}"
        
        # For WASM files, add special handling
        if self.path.endswith('.wasm'):
            print(f"  -> Serving WASM file with application/wasm MIME type")
            # Ensure specific content type for .wasm files
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
        
        # Handle Supabase OAuth callback
        if self.path == '/auth/callback':
            # Just serve index.html for the callback route
            # The Rust app will handle the auth logic
            self.path = '/index.html'
            print(f"  -> Auth callback, serving index.html")
        
        # Handle admin routes - check authentication
        elif self.path == '/admin' or self.path.startswith('/admin/'):
            # Look for auth data in localStorage (via cookie)
            auth_found, is_admin = check_auth_from_localStorage(self.headers)
            
            # If not authenticated or not admin, redirect to login page with redirect parameter
            if not auth_found or not is_admin:
                login_path = os.path.join(os.getcwd(), 'index.html')
                if os.path.exists(login_path):
                    # Encode requested path as a query parameter for redirect after login
                    redirect_to = urllib.parse.quote(self.path)
                    # Return the login page but preserve the admin path for redirect
                    self.send_response(302)  # Redirect
                    self.send_header('Location', f'/login?redirect_to={redirect_to}')
                    self.end_headers()
                    print(f"  -> Admin route requires login, redirecting to login page")
                    return
            
            # Authenticated as admin, use SPA routing
            self.path = '/index.html'
            print(f"  -> Admin route, authenticated, using SPA routing")
        
        # Handle login page
        elif self.path == '/login':
            # Standard SPA routing for login page
            self.path = '/index.html'
            print(f"  -> Login route, using SPA routing")
        
        # Handle other files or SPA routing
        requested_path = self.path.lstrip('/')
        file_path = os.path.join(os.getcwd(), requested_path)
        
        # If file doesn't exist, serve index.html for SPA routing
        if requested_path and not os.path.exists(file_path):
            self.path = '/index.html'
            print(f"  -> File not found, serving index.html for SPA routing")
        
        return http.server.SimpleHTTPRequestHandler.do_GET(self)
    
    def do_OPTIONS(self):
        """Handle OPTIONS requests for CORS preflight"""
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.end_headers()

def setup_security_logging():
    """Set up security logging to file"""
    import logging
    
    # Always create logs directory 
    log_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'logs')
    
    # Create logs directory if it doesn't exist
    if not os.path.exists(log_dir):
        os.makedirs(log_dir)
        
    # Set up both file and console logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s [%(levelname)s] - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S',
        handlers=[
            # Always log to a file for debugging
            logging.FileHandler(os.path.join(log_dir, 'server.log')),
            # Also log to console
            logging.StreamHandler()
        ]
    )
    
    # Log server startup details
    logging.info(f"Security server starting in {os.environ.get('IHOJE_ENVIRONMENT', 'unknown')} environment")
    logging.info(f"Current directory: {os.path.abspath(os.curdir)}")
    
    # Get network interfaces for debugging
    import socket
    try:
        hostname = socket.gethostname()
        local_ip = socket.gethostbyname(hostname)
        logging.info(f"Server hostname: {hostname}, Local IP: {local_ip}")
    except Exception as e:
        logging.warning(f"Could not get network info: {e}")
    
    # Redirect print statements related to security to the log file
    original_print = print
    def enhanced_print(*args, **kwargs):
        message = " ".join(str(arg) for arg in args)
        if message.startswith("SECURITY:"):
            logging.warning(message)
        else:
            # Log everything to the file
            logging.info(message)
            # But also print normally
            original_print(*args, **kwargs)
            
    # Replace the builtin print with our custom function
    globals()['print'] = enhanced_print
    
    return logging

def run_periodic_cleanup():
    """Run periodic cleanup of rate limiters"""
    login_rate_limiter.clean_up()
    api_rate_limiter.clean_up()
    admin_rate_limiter.clean_up()
    
    # Schedule next cleanup
    threading.Timer(300, run_periodic_cleanup).start()  # Every 5 minutes

def run_server(port=8081, directory="dist"):
    # Set up security logging
    logger = setup_security_logging()
    
    # Start periodic cleanup
    run_periodic_cleanup()
    
    # Change to the specified directory
    if os.path.exists(directory):
        os.chdir(directory)
        print(f"Changed to directory: {os.getcwd()}")
    else:
        print(f"Error: Directory {directory} not found!")
        sys.exit(1)
    
    # Create and start the server
    handler = SPAHandler
    
    # Set server to allow address reuse
    socketserver.TCPServer.allow_reuse_address = True
    
    # Create the HTTP server - binding to all interfaces (0.0.0.0) not just localhost
    # This is critical for container environments
    httpd = socketserver.TCPServer(("0.0.0.0", port), handler)
    
    print(f"Server binding to 0.0.0.0:{port} (all interfaces)")
    
    # Security banner
    security_banner = """
    ================================================================
    🔐 SECURITY CONFIGURATION 🔐
    ----------------------------------------------------------------
    ✅ Content Security Policy enabled
    ✅ X-Frame-Options set to DENY
    ✅ X-Content-Type-Options set to nosniff
    ✅ Referrer Policy enabled
    ✅ XSS Protection enabled
    ✅ Rate limiting enabled
    ✅ Redirect validation enabled
    ✅ Security logging configured
    ================================================================
    """
    print(security_banner)
    
    print(f"Starting SPA server on http://localhost:{port}")
    print(f"Serving files from: {os.getcwd()}")
    print(f"WebAssembly MIME type: application/wasm")
    print("Press Ctrl+C to stop the server")
    
    if logger:
        logger.info(f"Server started on port {port} with enhanced security")
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped by user")
        if logger:
            logger.info("Server stopped by user")
    except Exception as e:
        print(f"Error: {e}")
        if logger:
            logger.error(f"Server error: {e}")
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