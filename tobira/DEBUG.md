# WebAssembly Frontend (Shinri no Tobira) Debugging

This guide explains how to fix and debug the WebAssembly frontend using the automated scripts.

## Quick Fix Scripts

We've created several specialized scripts to make debugging and fixing WebAssembly issues easier:

1. **fix-wasm-frontend.sh** - Apply all fixes to make WebAssembly work on port 8081
   ```bash
   ./fix-wasm-frontend.sh
   ./restart-wasm-tobira.sh
   ```

2. **restart-wasm-tobira.sh** - Just restart the WebAssembly container on port 8081
   ```bash
   ./restart-wasm-tobira.sh
   ```
   
3. **debug-wasm.sh** - Diagnose common WebAssembly loading issues
   ```bash
   ./debug-wasm.sh
   ```

4. **run-both-tobiras.sh** - Start both the mock (8080) and WebAssembly (8081) containers
   ```bash
   ./run-both-tobiras.sh
   ```

## WASM Loading Issues Addressed

The automated fix scripts address these common problems:

1. ✅ **MIME Type Configuration**: All .wasm files are now served with the correct `application/wasm` MIME type
2. ✅ **SRI Integrity Issues**: Removed the Supabase SRI integrity check that causes loading failures
3. ✅ **Filename Mapping**: Added code to map ihoje_frontend_bg.wasm to ihoje-tobira_bg.wasm
4. ✅ **Better Error Handling**: Enhanced bootstrap.js with improved error reporting
5. ✅ **Mock Data Fallback**: Improved error handling for the mock data function

### Port Mapping Issue Fixed

There was an issue with the port mapping for the WebAssembly container. The container was configured to expose port 8081 internally but the server was running on port 8080.

The fix was to update the Docker run command to properly map the host port 8081 to the container port 8080:

```bash
docker run -d -p 8081:8080 --name ihoje-wasm shinri-no-tobira:latest
```

This ensures that requests to http://localhost:8081 on the host are correctly forwarded to port 8080 inside the container.

## Important Files for Debugging

### Client-Side Files
- `/tobira/index.html` - Main HTML entry point
- `/tobira/env.js` - Environment configuration and WASM MIME type fixes
- `/tobira/auth-debug.js` - Authentication debugging utilities
- `/tobira/dist/bootstrap.js` - WebAssembly initialization script

### Server Files
- `/tobira/spa_server.py` - Main server with SPA routing and MIME type handling
- `/tobira/fixed_server.py` - Simplified server with enhanced error handling

### Docker Configuration
- `/tobira/Dockerfile` - WebAssembly container configuration
- `/tobira/Dockerfile.simple` - Mock frontend container configuration
- `/tobira/docker-restart.sh` - Container restart script
- `/tobira/run-both-tobiras.sh` - Script to run both containers

### Critical Rust Source Files
- `/tobira/src/main.rs` - WebAssembly entry point
- `/tobira/src/lib.rs` - Main library exports
- `/tobira/src/router.rs` - SPA routing configuration
- `/tobira/src/pages/login_page.rs` - Login functionality
- `/tobira/src/pages/admin/dashboard.rs` - Admin dashboard with database testing

## Using Debug Tools

### Collect debugging information for LLM analysis
This command dumps all critical files, Docker logs, and environment information:

```bash
just tobira debug-dump
```

The command creates a timestamped directory with:
- All critical frontend files
- Container logs and status
- Environment variables
- Network configuration
- File listings and permissions
- A combined file for easy analysis

### Focused WebAssembly debugging
For specific WebAssembly initialization issues:

```bash
just tobira debug-wasm
```

This command focuses on:
- WebAssembly file presence and location
- MIME type configurations
- File size and permissions
- Server response headers
- JavaScript initialization code

## Browser Console Diagnostics

When troubleshooting WebAssembly issues, run these commands in your browser console:

```javascript
// Check WebAssembly support
console.log('WebAssembly Support:', typeof WebAssembly);

// View environment configuration
console.log('Environment Variables:', window.ihoje_env); 

// Check authentication state
console.log('Auth State:', window.debugAuth?.getAuthState());

// Use mock admin authentication (for testing)
window.debugAuth?.setMockAdmin();
```

## Automated Debugging Workflow

For a fully automated debugging experience, follow these steps:

1. **Apply All Fixes First**
   ```bash
   ./fix-wasm-frontend.sh
   ```
   This script:
   - Creates backups of your current files
   - Updates index.html (removes SRI, adds filename mapping)
   - Updates bootstrap.js with better error handling
   - Ensures spa_server.py has the correct MIME type configuration

2. **Restart the WebAssembly Container**
   ```bash
   ./restart-wasm-tobira.sh
   ```
   This script:
   - Stops and removes the existing container
   - Builds and starts a new container on port 8081
   - Shows logs to help with debugging

3. **Diagnose Any Remaining Issues**
   ```bash
   ./debug-wasm.sh
   ```
   This script checks for:
   - Correct MIME types
   - File availability
   - JavaScript and WebAssembly loading issues
   - Supabase script issues

## Common Issues and Fixes

1. **MIME Type Problems**: Fixed by ensuring spa_server.py has `mimetypes.add_type('application/wasm', '.wasm')`
2. **File Name Inconsistencies**: Solved with JavaScript that maps `ihoje_frontend_bg.wasm` to `ihoje-tobira_bg.wasm`
3. **Supabase SRI Integrity**: Fixed by removing the integrity attribute from the Supabase script tag
4. **WebAssembly Initialization**: Added fallback code in bootstrap.js for browsers with different WebAssembly support
5. **Double Initialization**: Fixed by properly handling initialization with better error checking

## Quick Docker Commands Reference

```bash
# Check container logs
docker logs ihoje-wasm

# Check if container is running
docker ps | grep ihoje

# Manually check MIME type issue
curl -I http://localhost:8081/ihoje-tobira_bg.wasm

# Stop both containers
docker stop ihoje-mock ihoje-wasm

# Enter container shell for debugging
docker exec -it ihoje-wasm bash
```