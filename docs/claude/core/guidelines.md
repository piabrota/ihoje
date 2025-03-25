# Rust Event Scraper Guidelines

## File Size Limits
- Justfiles: 200 lines maximum
- Rust code: 100 lines maximum
- Python code: 200 lines maximum

## Script Organization
- Large bash scripts should be extracted to separate .sh files in the scripts/ directory
- Justfiles should only contain small recipes or call external scripts
- This reduces context size and improves maintainability

## Token Optimization
For detailed token optimization strategies and context management, see docs/claude/core/optimization.md, which includes:
- Multi-tiered context system (micro, minimal, standard, domain-specific)
- Domain-specific contexts (sharingan, frontend, mangekyou)
- Token usage tracking
- MCP tool integration
- Example workflows for different domains

## Modular Justfiles
Commands are organized into specialized justfiles:
- `justfile.master` - Main entry point (~155 lines)
- `justfiles/podman.justfile` - Container management (~110 lines)
- `justfiles/db.justfile` - Database operations (~175 lines)
- `justfiles/mcp.justfile` - MCP tool management (~130 lines)
- `justfiles/run.justfile` - Run commands (~140 lines)
- `justfiles/task.justfile` - Task tracking (~175 lines)
- `justfiles/test.justfile` - Test commands (~85 lines)
- `justfiles/security.justfile` - Security commands (~45 lines)
- `justfiles/hooks.justfile` - Git hooks setup (~25 lines)
- `justfiles/provider.justfile` - Provider management (~50 lines)
- `justfiles/claude.justfile` - Claude AI interaction (~95 lines)
- `justfiles/util.justfile` - General utilities (~130 lines)

## Claude Code Usage

### Important: Claude Code is an Interactive Shell
- Claude Code is an interactive shell environment
- Similar to bash, python, or other interactive consoles
- Always use `exit` or `quit` when finished to properly close the session
- Start a new Claude Code session explicitly when needed
- Never run multiple Claude Code sessions at once
- If Claude Code is not responding, you may need to exit and start a new session

## Script Files
Complex scripts are stored in the scripts/ directory:
- `scripts/setup-provider-hooks.sh` - Provider security hooks setup
- `scripts/scrub-providers.sh` - Provider name scrubbing
- `scripts/setup-hooks.sh` - Git hooks installation
- `scripts/claude-standard.sh` - Claude standard context script
- `scripts/claude-minimal.sh` - Claude minimal context script
- `scripts/claude-micro.sh` - Claude micro context script

## Checkpoint System
Optimized checkpoint system with minimal token usage:

1. Start a task:
   ```
   just add-task "name" "description"
   ```

2. Track progress:
   ```
   just mark-step-complete "task" "step" "info"
   just mark-step-failed "task" "step" "error"
   ```

3. On "retake", Claude will:
   - Find first unchecked/failed step
   - Resume from there
   - Track progress automatically

## Key Commands
- App: `just run` `just run-city RJ` `just build` `just test`
- Date: `just run-date` `just run-custom-date 1 30`
- Tasks: `just add-task "x" "y"` `just task-cache` `just claude`
- Clean: `just clean` `just clean-logs` `just clean-cache`
- MCP: `just mcp-install-all`

## Config Options
- `checkpoint_enabled: true|false` - Enable checkpoints
- `auto_resume: true|false` - Auto-resume from last step
- `auto_proceed: true|false` - Auto-proceed without confirmation

## Justfile Token Optimization

### Optimized Claude Commands
Four options available with different token usage levels:

1. `just claude` - Standard optimized startup (~1000 tokens):
   - Loads bootstrap + active task
   - Shows only current task steps
   - Includes last 3 completed steps
   - Efficient for daily usage

2. `just claude-minimal` - Ultra-minimal startup (~500 tokens):
   - Uses bare-minimum bootstrap
   - Shows only first pending step
   - Minimal documentation
   - Best for typical tasks with lower costs

3. `just claude-micro` - Absolute minimal context (~200 tokens):
   - Bare essential context only
   - No documentation or configuration
   - Only active task name if one exists
   - Perfect for quick questions or high-cost API tiers

4. `just dump-context` - Full context (high token usage ~3000+ tokens):
   - Displays all context files
   - Shows complete documentation
   - Use only when context needed for complex work

### Token Usage Comparison
| Command             | Tokens | Cost*   | Best Used For                    |
|---------------------|--------|---------|----------------------------------|
| claude-micro        | ~200   | Lowest  | Quick questions, simple tasks    |
| claude-minimal      | ~500   | Low     | Focused tasks, limited context   |
| claude              | ~1000  | Medium  | Daily development, most tasks    |
| dump-context        | ~3000+ | Highest | Complex tasks requiring context  |

*Relative API cost based on token usage (exact costs vary by Claude API pricing tier)

### Token Optimization Strategies
1. **Document Organization**:
   - Keep documentation focused and minimal
   - Use hierarchical structure with concise bullet points
   - Break large files into modules with cross-references

2. **Command Line Arguments**:
   - Pass context directly in command: `just claude-micro "add user login"`
   - Use for simple, context-free tasks

3. **Checkpoint System**:
   - Use task checkpoints to maintain context without full history
   - `just mark-step-complete` only when needed

4. **Justfile Organization**:
   - Keep embedded scripts minimal
   - Use descriptive but concise comments
   - Group related functions by prefix

## Code Style
```rust
// Imports: std → external → local
use std::time::Duration;
use reqwest::Client;
use crate::config::Config;

// Naming: snake_case/PascalCase
async fn fetch_events(config: &Config) -> Result<Vec<Event>>

// Error handling with anyhow
use anyhow::{Context, Result};

// Logging with simplelog
log::info!("Scraping events for {}", city);

// Rate limiting
rate_limiter.wait().await;
```

## Project Structure
```
/src/
  main.rs         # Entry point
  lib.rs          # Integration test interface
  config.rs       # Configuration
  event.rs        # Data structures
  rate_limiter.rs # API throttling
  logger.rs       # Logging
  exporter.rs     # Export utilities
  scraper.rs      # Web scraping
  api/
    mod.rs        # API routing
    database.rs   # PostgreSQL database API
  db/
    mod.rs        # Database trait
    postgres.rs   # PostgreSQL implementation
/ihoje_models/    # Shared models crate
  src/
    lib.rs        # Re-exports
    event.rs      # Shared event model
    query.rs      # Query parameters
/frontend/
  src/
    api/          # Frontend API client
    components/   # UI components
    models/       # Data models
    pages/        # Page components
/tests/
  integration_test.rs # Basic tests
  workflow_test.rs    # End-to-end tests
```

## Shared Models
The codebase uses a shared models crate (`ihoje_models`) for common types between frontend and backend:

1. Common event structure in `Event` used by:
   - Backend database
   - API responses
   - Frontend components

2. Query parameters in `EventQuery` for consistent filtering:
   - API requests
   - Database queries
   - Frontend filters

## Database Integration
- PostgreSQL is the primary data store
- Direct database queries provide better performance
- Backend API endpoints expose database data to frontend
- No provider middleware for database queries

## SQLite Checkpoints
SQLite-based task tracking:
```
# Setup
just db-init      # Initialize database
just db-migrate   # Migrate existing data

# Commands work with both systems
just add-task "x" "y"
just mark-step-complete "x" "y" "z"
```

Benefits:
- Structured data for complex histories
- Atomic operations prevent corruption
- Compatible with markdown system

## MCP Tools

### Available Tools
- `brave-browser` - Web search (needs BRAVE_API_KEY)
- `sequential-thinking` - Step-by-step reasoning
- `filesystem` - File access
- `puppeteer` - Browser automation
- `fetch` - Web content
- `browser-tools` - DOM manipulation
- `mangekyou` - Implementation planning

### Setup
```bash
# Install all tools
just mcp-install-all

# Check status
just mcp-status

# Manage Mangekyou server
just mcp-start      # Start Mangekyou server
just mcp-stop       # Stop Mangekyou server
just mcp-restart    # Restart Mangekyou server
just mcp-logs       # View Mangekyou logs
just mcp-health     # Check server health

# List available tools
just mcp-list

# Other management commands
just mcp-uninstall-all    # Stop and clean up all tools
just mcp-reset-all        # Uninstall and reinstall all tools
```

## MCP Usage Guide
Claude automatically selects MCP tools based on context. No explicit tool requests needed.

### How To Use Each Tool

| Tool | Use Cases | Example Prompts |
|------|-----------|----------------|
| **brave-browser** | Current info, API docs, error solutions | "Find docs for Firecrawl API", "Best practice for Rust rate limiting" |
| **sequential-thinking** | Complex debugging, algorithms | "Debug this step-by-step", "Design an event processing algorithm" |
| **filesystem** | External files | "Import CSV from Desktop", "Check my Documents folder" |
| **puppeteer** | Web scraping, screenshots | "Test our scraper", "Capture screenshot of event page" |
| **fetch** | API requests, web content | "Get event data from URL", "Check this API endpoint" |
| **browser-tools** | DOM elements, advanced web | "Extract event cards", "Find pricing on this page" |
| **mangekyou** | Implementation planning | "Add CSV export functionality", "Create user authentication system" |

### The Mangekyou MCP Tool

Mangekyou is a specialized MCP tool that generates implementation plans for feature requests:

#### Using Mangekyou
1. Start the server:
   ```bash
   just mcp-start
   ```
2. Check server status:
   ```bash
   just mcp-status
   ```
3. Verify the server is running at: http://localhost:17891/mcp/v1/mangekyou

#### Troubleshooting Mangekyou
- If the server isn't responding, check the status and restart:
  ```bash
  just mcp-status
  just mcp-restart
  ```
- Verify the server is binding to localhost:17891
- Monitor log output with: `just mcp-logs`

### Troubleshooting MCP Tools

If you encounter connection issues with MCP tools:

1. **Browser-tools errors**: Connection failures during startup are normal and don't affect functionality
2. **Installation issues**: Use `just mcp-install-all` with improved error handling
3. **Missing tools**: Check with `just mcp-list` and reinstall specific tool if needed
4. **Brave API errors**: Ensure BRAVE_API_KEY is set in .env file

## Important Implementation Notes

1. **Keep Code Out of Justfiles**:
   - Never implement Python, Rust, or complex logic directly in justfiles
   - Extract all implementations to external .py, .rs, or .sh files
   - Justfiles should only contain short, debuggable commands

2. **Avoid Nested Claude Calls**:
   - Never call Claude inside Claude inside scripts
   - Keep script chains flat and debuggable
   - Prefer direct tools over complex layered execution chains