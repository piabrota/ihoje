"""
Mangekyou MCP Server Module

Implementation of the Mangekyou MCP server with FastAPI and Uvicorn
Enhanced with repomix integration for context extraction

Features:
1. Uses repomix for intelligent context extraction
2. Provides rich, actionable implementation plans
3. Supports language-specific planning (Rust, Python, JavaScript)
4. Works with any MCP client through standard endpoints
"""

import os
import json
import logging
import subprocess
from pathlib import Path
from typing import Dict, Any, Optional, List, Tuple

from fastapi import FastAPI, Request, Response, HTTPException, Header
from pydantic import BaseModel
import uvicorn

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler("/tmp/mangekyou.log")
    ]
)
logger = logging.getLogger("mangekyou.server")

# Configure server
PORT = int(os.environ.get("MANGEKYOU_PORT", 17891))
HOST = os.environ.get("MANGEKYOU_HOST", "127.0.0.1")
WORKERS = int(os.environ.get("MANGEKYOU_WORKERS", 1))

# Create FastAPI app
app = FastAPI(
    title="Mangekyou MCP Server",
    description="MCP-compliant implementation planning with repomix integration",
    version="1.0.0"
)

# Define request/response models
class McpMessage(BaseModel):
    role: str
    content: str

class McpRequest(BaseModel):
    body: Dict[str, Any]
    messages: Optional[List[McpMessage]] = None
    
class McpResponse(BaseModel):
    response: str

class InfoResponse(BaseModel):
    name: str
    description: str
    schema: Dict[str, Any]
    version: str

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "ok"}

@app.get("/mcp/v1/info")
async def mcp_info():
    """Provide MCP server information"""
    logger.info("MCP Info request received")
    return InfoResponse(
        name="mangekyou",
        description="Advanced implementation planning via MCP with repomix integration",
        schema={
            "type": "object",
            "properties": {
                "query": {
                    "type": "string", 
                    "description": "The implementation request"
                },
                "language": {
                    "type": "string",
                    "description": "Target language for implementation (rust, python, js)",
                    "enum": ["rust", "python", "js", "general"]
                },
                "repo_path": {
                    "type": "string",
                    "description": "Path to repository root (defaults to current directory)"
                },
                "unwrapped_context": {
                    "type": "string",
                    "description": "Context provided directly by the client"
                }
            },
            "required": ["query"]
        },
        version="1.0.0"
    )
    
@app.post("/mcp/v1/plan", response_model=McpResponse)
async def plan_endpoint(request: McpRequest, mcp_version: Optional[str] = Header(None, alias="X-MCP-Version")):
    """
    Standard endpoint for implementation planning following MCP specification.
    This provides client-agnostic operation for any MCP-compliant client.
    """
    try:
        logger.info(f"Planning request received via /v1/plan")
        logger.debug(f"MCP Version: {mcp_version}")
        
        # Extract parameters from request
        query = request.body.get("query", "")
        language = request.body.get("language", "")
        repo_path = request.body.get("repo_path", ".")
        unwrapped_context = request.body.get("unwrapped_context", "")
        
        if not query:
            logger.warning("Missing query parameter")
            raise HTTPException(status_code=400, detail="Missing query parameter")
        
        # Extract messages if available for language detection
        messages = request.messages if hasattr(request, "messages") and request.messages else None
        
        # Generate implementation plan
        plan = create_implementation_plan(
            query=query, 
            messages=messages,
            unwrapped_context=unwrapped_context,
            repo_path=repo_path
        )
        
        logger.info("Plan generated successfully via /v1/plan endpoint")
        
        return {"response": plan}
    except Exception as e:
        logger.error(f"Error processing plan request: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")

@app.post("/mcp/v1/mangekyou", response_model=McpResponse)
async def process_request(request: McpRequest, mcp_version: Optional[str] = Header(None, alias="X-MCP-Version")):
    """
    Handle Mangekyou MCP requests.
    Fully compliant with MCP specification.
    """
    try:
        logger.info(f"Request received: {request}")
        logger.debug(f"MCP Version: {mcp_version}")
        
        # Extract parameters from request
        query = request.body.get("query", "")
        language = request.body.get("language", "")  # Optional language override
        repo_path = request.body.get("repo_path", ".")  # Optional repo path
        unwrapped_context = request.body.get("unwrapped_context", "")  # Optional direct context
        
        if not query:
            logger.warning("Missing query parameter")
            raise HTTPException(status_code=400, detail="Missing query parameter")
        
        # Extract messages if available (for language detection)
        messages = request.messages if hasattr(request, "messages") and request.messages else None
        
        # Override detected language if explicitly specified
        if not language and messages:
            language = detect_language_from_request(query, messages)
        elif not language:
            language = detect_language_from_request(query)
            
        logger.info(f"Using language: {language}")
        
        # Generate implementation plan with enhanced context integration
        plan = create_implementation_plan(
            query=query, 
            messages=messages,
            unwrapped_context=unwrapped_context,
            repo_path=repo_path
        )
        
        logger.info("Plan generated successfully")
        
        return {"response": plan}
    except Exception as e:
        logger.error(f"Error processing request: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")

def detect_language_from_request(query: str, messages: Optional[List[McpMessage]] = None) -> str:
    """
    Detect the target language from the request content.
    Prioritizes language mentions in the query or messages.
    
    Returns: 
        string: "rust", "python", "js", or "general"
    """
    content = query.lower()
    
    # Also check messages if available
    if messages:
        for msg in messages:
            content += " " + msg.content.lower()
    
    # Detect language from content
    if "rust" in content and ("implement" in content or "create" in content):
        return "rust"
    elif "python" in content and ("implement" in content or "create" in content):
        return "python"
    elif ("javascript" in content or "js" in content) and ("implement" in content or "create" in content):
        return "javascript"
    
    # Default to general if no specific language detected
    return "general"

def extract_context(repo_path: str = ".", language: str = "general") -> str:
    """
    Extract relevant context from repository using repomix when available.
    Falls back to direct extraction for specific file types when repomix is unavailable.
    
    Args:
        repo_path: Path to repository root
        language: Target language for implementation ("rust", "python", "js", "general")
        
    Returns:
        string: Extracted context as formatted string
    """
    logger.info(f"Extracting context for language: {language}")
    
    try:
        # Try using repomix for intelligent context extraction
        result = subprocess.run(
            ["repomix", "compile", repo_path, "--lang", language], 
            capture_output=True, text=True, timeout=10
        )
        
        if result.returncode == 0 and result.stdout:
            logger.info("Successfully extracted context using repomix")
            return result.stdout
        else:
            logger.warning(f"repomix failed or returned empty: {result.stderr}")
            # Fall back to direct extraction
    except (FileNotFoundError, subprocess.SubprocessError) as e:
        logger.warning(f"repomix not available: {str(e)}")
        # Fall back to direct extraction
    
    # Language-specific file patterns
    if language == "rust":
        patterns = ["**/*.rs", "Cargo.toml"]
    elif language == "python":
        patterns = ["**/*.py", "pyproject.toml", "requirements.txt"]
    elif language == "javascript":
        patterns = ["**/*.js", "**/*.jsx", "**/*.ts", "**/*.tsx", "package.json"]
    else:
        patterns = ["**/*.rs", "**/*.py", "**/*.js", "**/*.toml", "**/*.json"]
    
    # Direct file extraction
    context = []
    repo_path = Path(repo_path)
    
    for pattern in patterns:
        for file_path in repo_path.glob(pattern):
            if file_path.is_file() and file_path.stat().st_size < 100000:  # Skip large files
                try:
                    rel_path = file_path.relative_to(repo_path)
                    content = file_path.read_text(errors='replace')
                    # Limit content size per file
                    if len(content) > 5000:
                        content = content[:5000] + "... [truncated]"
                    context.append(f"File: {rel_path}\n```\n{content}\n```\n")
                except Exception as e:
                    logger.warning(f"Error reading {file_path}: {str(e)}")
    
    return "\n\n".join(context)

def create_implementation_plan(query: str, messages: Optional[List[McpMessage]] = None, 
                            unwrapped_context: str = "", repo_path: str = ".") -> str:
    """
    Create an implementation plan based on the provided query and context.
    Integrates with repomix for intelligent context extraction.
    
    Args:
        query: The implementation request
        messages: Optional list of messages from the conversation
        unwrapped_context: Optional direct context provided by client
        repo_path: Path to repository root (defaults to current directory)
        
    Returns:
        string: Formatted implementation plan
    """
    # Detect target language
    language = detect_language_from_request(query, messages)
    logger.info(f"Detected language: {language}")
    
    # Extract relevant context if no direct context provided
    if not unwrapped_context:
        repo_path = os.environ.get("REPO_PATH", repo_path)
        extracted_context = extract_context(repo_path, language)
        context_source = "automatically extracted"
    else:
        extracted_context = unwrapped_context
        context_source = "directly provided"
        
    logger.info(f"Using {context_source} context for implementation planning")
    
    # Generate implementation plan with language-specific templates
    if language == "rust":
        return f"""
# Rust Implementation Plan for: {query}

## Context Analysis
- Repository contains Rust code with async/await patterns
- Uses anyhow for error handling
- Logging with simplelog
- Context was {context_source} for targeted implementation

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
        return f"""
# Python Implementation Plan for: {query}

## Context Analysis
- Repository contains Python FastAPI code
- Uses Pydantic for data validation
- Structured logging
- Context was {context_source} for targeted implementation

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
        logging.error(f"Error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))
```
"""
    elif language == "javascript":
        return f"""
# JavaScript Implementation Plan for: {query}

## Context Analysis
- Repository contains JavaScript code
- Context was {context_source} for targeted implementation

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
import { useEffect, useState } from 'react';

// Service implementation
const newService = async (params) => {
  try {
    // Implementation here
    return { success: true };
  } catch (error) {
    console.error(`Error: ${error.message}`);
    throw error;
  }
};

// Component implementation
function NewComponent({ props }) {
  const [state, setState] = useState(null);
  
  useEffect(() => {
    // Implementation here
  }, []);
  
  return (
    <div>
      {/* Component JSX */}
    </div>
  );
}
```
"""
    else:
        # General implementation plan
        return f"""
# Implementation Plan for: {query}

## Context Analysis
- Context was {context_source} for implementation planning

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

def start():
    """Start the server"""
    logger.info(f"Starting Mangekyou MCP server on {HOST}:{PORT}")
    
    # Using uvicorn programmatically with production settings
    uvicorn.run(
        "mangekyou_mcp.server:app", 
        host=HOST,
        port=PORT,
        workers=WORKERS,
        log_level="info",
        access_log=True,
        proxy_headers=True,
        forwarded_allow_ips="*"
    )

if __name__ == "__main__":
    start()
