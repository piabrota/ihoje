# Mangekyou MCP Implementation

A powerful implementation planning tool using the Model Context Protocol (MCP) standard.

## Overview

Mangekyou MCP is a specialized tool that leverages AI to generate detailed implementation plans for software projects. It connects to any MCP-compatible client through the Model Context Protocol, making it easy to get AI-assisted planning directly within your development workflow.

## Key Features

- **MCP Compliant**: Works with any MCP client, not just Claude Code
- **Repomix Integration**: Intelligent context extraction for better plans
- **Language-Specific Planning**: Optimized plans for Rust, Python, and JavaScript
- **Client-Agnostic Design**: Standard MCP endpoints and message handling

## About the Mangekyou Sharingan

The Mangekyou Sharingan (万華鏡写輪眼, "Kaleidoscope Copy Wheel Eye") is the evolved form of the Sharingan, awakened by Uchiha clan members who have experienced intense emotional trauma. The Mangekyou grants its wielder powerful abilities:

- **Amaterasu**: Black flames that cannot be extinguished and burn anything they touch
- **Tsukuyomi**: Powerful genjutsu that traps opponents in an illusionary world
- **Susanoo**: A gigantic, spectral warrior that surrounds and protects the user

In the context of this MCP tool, the Mangekyou Sharingan symbolizes the ability to see through complex problems and visualize implementation paths with perfect clarity.

## Features

- Generate detailed implementation plans for software features
- Works with ANY MCP-compliant client (not just Claude Code)
- Repomix-powered intelligent context extraction
- Language-specific planning for Rust, Python, and JavaScript
- Direct context passing for specialized implementations
- Support for multiple AI providers (DeepSeek, OpenAI, Gemini)
- Context-aware planning using your project's codebase information

## Installation

### Using Justfile (Recommended)

```bash
# Install Mangekyou MCP dependencies and set up the environment
just mcp mangekyou

# Register with Claude
just register-mangekyou
```

### Manual Installation

1. Create a virtual environment:
   ```bash
   cd scripts/mangekyou-mcp
   python -m venv venv
   source venv/bin/activate
   ```

2. Install dependencies:
   ```bash
   pip install -e .
   ```

3. Register with Claude:
   ```bash
   claude mcp add mangekyou -s user "python -m mangekyou_mcp.server"
   ```

## Usage

Once installed and registered, you can use Mangekyou directly through Claude:

```
Can you use the Mangekyou Sharingan to create an implementation plan for adding rate limiting to our Rust API?
```

### Advanced Usage

#### Provider Selection

You can specify which AI provider to use:

```
Can you create an implementation plan for adding rate limiting to our Rust API? provider:openai
```

Available providers:
- `deepseek` (default)
- `openai`
- `gemini`

## Configuration

The tool looks for the following environment variables:
- `DEEPSEEK_API_KEY`: API key for DeepSeek AI
- `OPENAI_API_KEY`: API key for OpenAI
- `GEMINI_API_KEY`: API key for Google Gemini

You can add these to your `.env` file.

## API Endpoints

The MCP server exposes these endpoints:

- `GET /mcp/v1/info`: Returns metadata about the Mangekyou MCP tool
- `POST /mcp/v1/plan`: Standard MCP endpoint for implementation planning
- `POST /mcp/v1/mangekyou`: Legacy endpoint (maintained for compatibility)
- `GET /health`: Health check endpoint

## Request Format

```json
{
  "body": {
    "query": "Implement CSV export functionality",
    "language": "rust",
    "repo_path": "/path/to/repo",
    "unwrapped_context": "optional direct context"
  },
  "messages": [
    {
      "role": "user",
      "content": "I want to add CSV export capabilities"
    }
  ]
}
```

## Development

### Project Structure

```
mangekyou-mcp/
├── mangekyou_mcp/        # Python module
│   ├── __init__.py       
│   └── server.py         # FastAPI application
├── images/               # Mangekyou Sharingan images
├── pyproject.toml        # Project configuration
├── README.md             # Documentation
└── requirements.txt      # Dependencies
```

### Local Development

To start the server locally for development:

```bash
cd scripts/mangekyou-mcp
python -m mangekyou_mcp.server
```

## Troubleshooting

### Common Issues

- **Connection Issues**: If Claude can't connect to Mangekyou, try re-registering with `just register-mangekyou`.
- **Missing Dependencies**: Run `just mcp mangekyou` to ensure all dependencies are installed.
- **Missing API Keys**: Add required API keys to your `.env` file if you want to use specific AI providers.
- **Chakra Depletion**: Using the Mangekyou Sharingan too frequently may cause eye strain and fatigue. Use your vision wisely.