# Claude Code CLI Help Guide

This document provides a comprehensive reference for using the Claude Code CLI tool.

## Basic Commands

| Command | Description |
|---------|-------------|
| `claude` | Start a new conversation with Claude |
| `claude -h`, `claude --help` | Show help information |
| `claude -f <file>`, `claude --file <file>` | Include file content in your prompt |
| `claude -c`, `claude --compact` | Compact the conversation to save context |
| `claude -e`, `claude --exec` | Execute a script file as input |
| `claude --context <name>` | Specify a named context to read from |
| `claude init`, `claude i` | Initialize the current directory for Claude |

## Slash Commands

These commands can be used during an active conversation:

| Command | Description |
|---------|-------------|
| `/help` | Show help information about Claude Code |
| `/compact` | Compact the conversation to save context space |

## File Operation Best Practices

When Claude edits files:

1. **Always use View first** to understand the file's contents
2. **Verify directory paths** before creating new files
3. **Include sufficient context** in your old_string for Edit operations
4. **Make one change at a time** when editing complex files

## Available Tools

Claude Code has access to the following tools:

### File Management

| Tool | Description |
|------|-------------|
| `View` | Read a file from the filesystem |
| `Edit` | Make changes to a file (modify, create, append) |
| `Replace` | Completely overwrite or create a file |
| `LS` | List files and directories in a given path |

### Search Tools

| Tool | Description |
|------|-------------|
| `GlobTool` | Find files matching a glob pattern (e.g., `**/*.js`) |
| `GrepTool` | Search file contents using regex patterns |
| `dispatch_agent` | Launch an agent to perform complex search tasks |

### Command Execution

| Tool | Description |
|------|-------------|
| `Bash` | Execute shell commands in a persistent shell session |

### Jupyter Notebook Support

| Tool | Description |
|------|-------------|
| `ReadNotebook` | Read a Jupyter notebook (.ipynb file) |
| `NotebookEditCell` | Edit a specific cell in a Jupyter notebook |

## Common Workflows

### Code Exploration

```
# Find all JavaScript files in the project
claude> Let's find all JavaScript files in this project

# Search for specific code patterns
claude> Find all files that import the 'express' module

# Understanding the codebase structure
claude> Help me understand how this application is organized
```

### Code Modification

```
# Fixing bugs
claude> This function in src/utils.js has a bug where it doesn't handle null inputs properly. Can you fix it?

# Adding features
claude> Add a new function to src/helpers.js that formats dates according to ISO 8601

# Refactoring
claude> Refactor this function to use async/await instead of promises
```

### Git Operations

```
# Creating commits
claude> Create a commit with these changes

# Creating branches
claude> Create a new branch called 'feature/user-auth'

# Creating PRs
claude> Create a pull request for the current branch
```

## Using dispatch_agent

The `dispatch_agent` tool is powerful for complex searches:

```
claude> Find all dependencies using deprecated methods

<function_calls>
<invoke name="dispatch_agent">
<parameter name="prompt">Search through all JavaScript files for any uses of deprecated methods or APIs. Look for:
1. Documentation comments with @deprecated tags
2. Dependencies with known deprecated methods
3. Code patterns that suggest the use of deprecated APIs

Return a list of files and the specific deprecated methods or APIs they're using.