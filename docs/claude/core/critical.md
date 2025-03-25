# CRITICAL ISSUE: Mangekyou Server Crash Causing NixOS Logout

## Issue Description
The `just mangekyou-all` command is causing system crashes that result in NixOS X server crashes and user logouts, requiring computer restart.

## Diagnosis Status

- [x] Identified mangekyou-all command in justfiles/mcp.justfile
- [x] Examined mangekyou server implementation
- [x] Checked process management issues
- [x] Verified port conflicts
- [x] Analyzed resource consumption
- [x] Tested background process handling
- [x] Identified crash cause: unbounded memory consumption crashing X server
- [x] Implemented solution with hard memory limits
- [ ] Verified fix

## Root Causes Identified

1. **Unbounded Memory Consumption**: The Mangekyou server had inadequate resource limits, causing system memory exhaustion that crashes the X server in NixOS.
2. **Port Conflict**: Multiple server instances could be started without properly checking for existing processes.
3. **Zombie Process Management**: Orphaned processes were not being properly terminated.
4. **Error Handling**: Poor error handling in subprocess calls could cause cascading failures.
5. **Lack of Timeouts**: No timeouts on potentially blocking operations.
6. **NixOS X Server Vulnerability**: The X server in NixOS is particularly vulnerable to memory pressure, causing user session logout.

## Solution Implemented

1. **Resource Limiting**:
   - [x] Added stronger system resource limits via `ulimit` commands (now 700MB max)
   - [x] Implemented Python-level resource constraints with `resource` module
   - [x] Added both virtual and resident memory caps to prevent system crashes
   - [x] Added PID cleanup to check for memory-hungry Python processes

2. **Process Management**:
   - [x] Created robust process cleanup in the `mangekyou-all` command
   - [x] Added a dedicated `stop-mangekyou` command
   - [x] Improved PID tracking with better error handling

3. **Error Handling**:
   - [x] Added comprehensive try/except blocks
   - [x] Implemented fallback mechanisms for critical functions
   - [x] Added detailed logging to track issues

4. **Timeouts**:
   - [x] Added watchdog timer to kill runaway processes
   - [x] Implemented timeouts on all subprocess calls
   - [x] Added global timeout on server process

5. **Graceful Shutdown**:
   - [x] Added signal handlers for clean termination
   - [x] Implemented resource cleanup on exit
   - [x] Fixed PID file management

## Summary of Fixes

### 1. In `justfiles/mcp.justfile`:
- Completely rewrote `mangekyou-all` with much stricter memory limits (700MB)
- Added aggressive process cleanup to prevent zombie processes
- Added checking for any high-memory Python processes
- Created a dedicated wrapper script with built-in Python memory limits
- Reduced global timeout from 60 to 30 seconds for safety
- Implemented both ulimit and Python resource limits for redundancy
- Added warning message about the critical issue at startup

### 2. In `scripts/mangekyou-mcp/mangekyou_mcp/server.py`:
- Added Python-level resource limits via the `resource` module
- Implemented a watchdog timer to prevent infinite loops
- Added signal handlers for graceful termination
- Made the `get_project_context` function more robust with timeouts
- Improved error handling throughout the server code
- Added better PID file management
- Enhanced the uvicorn server configuration with concurrency limits

### 3. In `scripts/mangekyou-mcp/run_mangekyou.sh`:
- Completely rewrote the script with resource limits
- Added logging for better diagnostics
- Implemented PID file management
- Added a global timeout to prevent runaway processes

These changes collectively address the critical issue by preventing unlimited resource consumption, ensuring proper process management, adding timeouts to prevent hanging, and implementing graceful shutdown procedures.

## How to Safely Use Mangekyou

1. **Starting the Server**:
   ```bash
   # The safe way to start Mangekyou (resource-limited, with timeouts)
   just mangekyou-all
   ```

2. **Checking Server Status**:
   ```bash
   # Check if the server is running (now uses port 17891)
   lsof -i:17891
   
   # Check the logs
   cat /tmp/mangekyou-server.log
   ```

3. **Stopping the Server**:
   ```bash
   # Always use this command to stop the server
   just stop-mangekyou
   ```

4. **If Issues Persist**:
   - The server will automatically stop after 30 seconds (reduced for safety)
   - If your system becomes unresponsive, try pressing Ctrl+C
   - In extreme cases, use a different terminal to run `pkill -9 -f mangekyou`
   - If experiencing NixOS X server crashes, consider using `stop-mangekyou` immediately after use

5. **Debugging**:
   ```bash
   # Check for any lingering processes
   ps aux | grep mangekyou
   
   # View detailed logs
   cat /tmp/mangekyou-mcp.log
   ```

IMPORTANT: Never run multiple instances of Mangekyou at the same time, and always use the `stop-mangekyou` command when you're done.

## Execution Cache

- [x] Improve process management in mangekyou-all
- [x] Add proper resource limiting in both shell and Python
- [x] Implement timeouts for all operations
- [x] Fix the get_project_context function
- [x] Add a watchdog timer to prevent infinite loops
- [x] Create a stop-mangekyou command
- [x] Improve server startup/shutdown handling
- [x] Update run_mangekyou.sh script with safety measures