#!/usr/bin/env python3
"""
Unit Tests for Mangekyou MCP Server

This module contains unit tests for the Mangekyou MCP server functionality.
"""

import unittest
from unittest import mock
import json
import sys
import os
from pathlib import Path

# Add parent directory to path to import mangekyou_mcp
sys.path.insert(0, str(Path(__file__).parent.parent))

from fastapi.testclient import TestClient
from mangekyou_mcp.server import app, detect_language_from_request, create_implementation_plan


class TestMangekyouServer(unittest.TestCase):
    """Test cases for the Mangekyou MCP server."""

    def setUp(self):
        """Set up test environment."""
        self.client = TestClient(app)

    def test_health_endpoint(self):
        """Test the health check endpoint."""
        response = self.client.get("/health")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), {"status": "ok"})

    def test_mcp_info_endpoint(self):
        """Test the MCP info endpoint."""
        response = self.client.get("/mcp/v1/info")
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["name"], "mangekyou")
        self.assertIn("description", data)
        self.assertIn("schema", data)
        self.assertIn("version", data)

    def test_mangekyou_endpoint_missing_query(self):
        """Test the Mangekyou endpoint with missing query parameter."""
        response = self.client.post("/mcp/v1/mangekyou", json={"body": {}})
        self.assertEqual(response.status_code, 400)

    @mock.patch("mangekyou_mcp.server.create_implementation_plan")
    def test_mangekyou_endpoint_valid_request(self, mock_create_plan):
        """Test the Mangekyou endpoint with a valid request."""
        # Mock implementation plan
        mock_create_plan.return_value = "Test implementation plan"
        
        # Test request
        response = self.client.post(
            "/mcp/v1/mangekyou",
            json={"body": {"query": "Implement a new feature"}}
        )
        
        # Check response
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["response"], "Test implementation plan")
        
        # Verify mock was called correctly
        mock_create_plan.assert_called_once()
        args, kwargs = mock_create_plan.call_args
        self.assertEqual(kwargs["query"], "Implement a new feature")

    def test_detect_language_from_request(self):
        """Test language detection from request content."""
        # Test Rust detection
        self.assertEqual(
            detect_language_from_request("Implement a new feature in Rust"),
            "rust"
        )
        
        # Test Python detection
        self.assertEqual(
            detect_language_from_request("Create a new Python module"),
            "python"
        )
        
        # Test JavaScript detection
        self.assertEqual(
            detect_language_from_request("Implement a JS component"),
            "javascript"
        )
        
        # Test default general detection
        self.assertEqual(
            detect_language_from_request("Add a new feature"),
            "general"
        )

    def test_create_implementation_plan(self):
        """Test implementation plan creation."""
        # Test Rust plan
        rust_plan = create_implementation_plan("Implement a new feature in Rust")
        self.assertIn("Rust Implementation Plan", rust_plan)
        
        # Test Python plan
        python_plan = create_implementation_plan("Create a new Python module")
        self.assertIn("Python Implementation Plan", python_plan)
        
        # Test JavaScript plan
        js_plan = create_implementation_plan("Implement a JS component")
        self.assertIn("JavaScript Implementation Plan", js_plan)
        
        # Test general plan
        general_plan = create_implementation_plan("Add a new feature")
        self.assertIn("Implementation Plan for:", general_plan)


if __name__ == "__main__":
    unittest.main()