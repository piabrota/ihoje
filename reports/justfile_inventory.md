# Justfile Inventory

## Overview

This document provides a complete inventory of all justfiles and their recipes, organized by logical function, with identified patterns and inconsistencies.

## Justfile Summary

| File | Lines | Purpose | # of Recipes |
|------|-------|---------|--------------|
| claude.justfile | 102 | Claude Interaction Recipes | 7 |
| db.justfile | 173 | Database Management Recipes | 8 |
| hooks.justfile | 26 | Security Hooks Recipes | 3 |
| mcp.justfile | 131 | MCP Tools Management Recipes | 11 |
| podman.justfile | 108 | Podman Container Management Recipes | 12 |
| provider.justfile | 56 | Provider Security Recipes | 5 |
| run.justfile | 139 | Run Commands Recipes | 15 |
| security.justfile | 46 | Security Recipes | 8 |
| task.justfile | 175 | Task Management Recipes | 8 |
| test.justfile | 85 | Test Recipes | 8 |
| util.justfile | 129 | Utility Recipes | 8 |
| justfile.master | 155 | Master Justfile | 29 |

Total: 12 justfiles, ~120 recipes

## Common Patterns

1. **Universal Patterns:**
   - Each justfile begins with a descriptive comment
   - All justfiles have `default` recipe showing available commands
   - All justfiles have `help` recipe that explains available commands
   - All justfiles set `dotenv-load` for environment variable support

2. **Recipe Structure Patterns:**
   - Simple recipes use `command {{args}}` format
   - Complex recipes use bash script blocks with `#!/usr/bin/env bash`
   - Help recipes use multiple `@echo` statements for formatting
   - Many recipes have optional arguments with defaults

3. **Naming Conventions:**
   - Subcommand format: `category-subcommand` (e.g., `db-start`)
   - Forward patterns in master file: `category +ARGS`
   - Most recipe names use verb-noun format
   - Help command pattern: `category-help`

## Inconsistencies

1. **Documentation:**
   - Inconsistent header comment styles
   - Variable levels of inline documentation
   - Some files have recipe descriptions, others don't

2. **Parameter Handling:**
   - Variable approach to parameter validation
   - Inconsistent use of default values
   - Mixed use of positional and named parameters

3. **Error Handling:**
   - Some recipes check for preconditions, others don't
   - Variable approach to error reporting
   - Inconsistent exit code handling

4. **Code Style:**
   - Variable bash script formatting
   - Inconsistent use of `@` for command suppression
   - Different approaches to output formatting

## Cross-File Dependencies

1. **Direct Dependencies:**
   - `justfile` → all specialized justfiles
   - `justfile.master` → all specialized justfiles
   - `security.justfile` → `hooks.justfile` and `provider.justfile`

2. **Functionality Overlaps:**
   - `claude.justfile` and `util.justfile` both have context handling
   - `provider.justfile` and `run.justfile` have provider running
   - `task.justfile` functionality used by multiple other files

3. **Circular References:**
   - `security` → `hooks` → `provider` → `security`

## Recipe Inventory by Category

### Run Commands (run.justfile)
- default - Show recipes
- help - Show help
- app - Run with arguments
- city - Run with city
- city-args - Run with city and args
- date - Run with date range
- date-print - Run with date range and print URL
- date-city - Run with date range and city
- date-city-print - Print URL for city with date range
- custom-date - Run with custom date range
- postgres - Run with PostgreSQL export
- both - Run with both export formats
- postgres-date - Run with PostgreSQL and date
- provider - Run with specific provider
- provider-help - Show provider security help

### Database Commands (db.justfile)
- default - Show recipes
- help - Show help
- ensure-podman - Check podman is running
- start - Start PostgreSQL container
- stop - Stop PostgreSQL container
- info - Show connection info
- migrate - Apply migrations
- psql - Run PostgreSQL client
- status - Check database status
- reset - Reset database
- run-postgres - Run with PostgreSQL export

### Claude Commands (claude.justfile)
- default - Show recipes
- help - Show help
- claude - Run Claude with standard context
- claude-minimal - Run Claude with minimal context
- claude-micro - Run Claude with micro context
- dump-context - Show context files
- write - Write context to file
- reset - Reset Claude files
- improve-just - Improve justfile structure

### MCP Commands (mcp.justfile)
- default - Show recipes
- help - Show help
- brave-browser - Install Brave Browser MCP
- sequential-thinking - Install Sequential Thinking MCP
- filesystem - Install Filesystem MCP
- puppeteer - Install Puppeteer MCP
- fetch - Install Fetch MCP
- browser-tools - Install Browser Tools MCP
- list - List MCP tools
- debug - Debug MCP server
- update - Update MCP tools
- install-all - Install all MCP tools

### Task Commands (task.justfile)
- default - Show recipes
- help - Show help
- init - Initialize cache
- add - Add task to tracker
- complete - Mark step complete
- fail - Mark step failed
- show - Show task progress
- clean - Clean cache
- history - Show command history
- heavy - Show heavy operations

### Test Commands (test.justfile)
- default - Show recipes
- help - Show help
- real - Run tests with real API
- postgres - Run PostgreSQL tests
- create-test-data - Create mock test data
- create-mock-csv - Create mock CSV
- events - Run event data test
- all - Run all tests
- check-all - Run all quality checks

### Podman Commands (podman.justfile)
- default - Show recipes
- help - Show help
- build-image - Build container image
- build-lambda - Build lambda image
- push - Push image to registry
- push-lambda - Push lambda image
- run - Run container locally
- list-images - List container images
- compose - Run podman-compose
- login - Login to registry
- info - Show system info
- prune - Clean system
- volumes - List volumes
- inspect - Inspect volume
- clean-volumes - Clean volumes

### Security Commands (security.justfile)
- default - Show recipes
- help - Show help
- setup-precommit - Install pre-commit hooks
- hooks - Run hooks commands
- hooks-help - Show hooks help
- setup-hooks - Setup provider security hooks
- provider - Run provider commands
- provider-help - Show provider help

### Provider Commands (provider.justfile)
- default - Show recipes
- help - Show help
- scrub - Remove provider references
- anonymize-logs - Anonymize provider names
- run - Run with specific provider
- info - Show provider security help

### Hooks Commands (hooks.justfile)
- default - Show recipes
- help - Show help
- setup-precommit - Install pre-commit hooks
- setup-provider - Setup provider hooks

### Utility Commands (util.justfile)
- default - Show recipes
- help - Show help
- dump-context - Print context files
- context-file - Save context to file
- clean - Clean artifacts and logs
- clean-all - Clean everything
- clean-logs - Clean log files
- fmt - Format code
- lint - Run linter
- init-env - Create template .env file

## Observations and Recommendations

1. **Documentation Standardization:**
   - Implement consistent header format for all recipes
   - Standardize inline documentation style
   - Add parameter documentation uniformly

2. **Parameter Handling:**
   - Create standard validation pattern
   - Implement consistent default parameter approach
   - Standardize error messaging

3. **Recipe Organization:**
   - Eliminate duplicate functionality
   - Consolidate related commands
   - Create shared utility functions

4. **Dependency Management:**
   - Resolve circular dependencies
   - Create clear chain of command
   - Establish consistent dependency patterns

5. **Error Handling:**
   - Standardize approach to error states
   - Implement uniform validation checks
   - Create consistent error reporting