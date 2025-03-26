#!/usr/bin/env python3
"""
Pytest configuration for Mangekyou MCP server tests.
Contains fixtures and shared utilities for testing.
"""

import os
import sys
import pytest
import asyncio
import subprocess
from pathlib import Path
from fastapi.testclient import TestClient

# Add parent directory to path to import mangekyou_mcp
sys.path.insert(0, str(Path(__file__).parent.parent))

from mangekyou_mcp.server import app


@pytest.fixture
def client():
    """FastAPI test client fixture."""
    return TestClient(app)


@pytest.fixture(scope="session")
def event_loop():
    """Create an instance of the default event loop for each test case."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest.fixture(scope="function")
def mock_repo(tmp_path):
    """Create a mock repository structure for testing context extraction."""
    repo_dir = tmp_path / "mock_repo"
    repo_dir.mkdir()
    
    # Create rust files
    rust_dir = repo_dir / "src"
    rust_dir.mkdir()
    
    with open(rust_dir / "main.rs", "w") as f:
        f.write("""
fn main() {
    println!("Hello, world!");
}
""")
    
    with open(repo_dir / "Cargo.toml", "w") as f:
        f.write("""
[package]
name = "test_project"
version = "0.1.0"
edition = "2021"
""")
    
    # Create python files
    python_dir = repo_dir / "python"
    python_dir.mkdir()
    
    with open(python_dir / "app.py", "w") as f:
        f.write("""
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def read_root():
    return {"Hello": "World"}
""")
    
    with open(repo_dir / "requirements.txt", "w") as f:
        f.write("""
fastapi>=0.111.0
uvicorn>=0.27.1
""")
    
    return repo_dir