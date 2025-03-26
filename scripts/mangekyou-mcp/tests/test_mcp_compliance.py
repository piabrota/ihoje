#!/usr/bin/env python3
"""
MCP Compliance Tests for Mangekyou Server

This script tests the compliance of the Mangekyou MCP server with Model Context Protocol specifications.
It verifies that the server implements required endpoints, handles requests correctly,
and returns responses in the expected format.
"""

import json
import unittest
import requests
import jsonschema
from urllib.parse import urljoin

# Server configuration
MCP_SERVER_URL = "http://localhost:17891"
MCP_TOOL_NAME = "mangekyou"


class MCPComplianceTest(unittest.TestCase):
    """Test cases for MCP compliance verification."""

    def setUp(self):
        """Set up test environment."""
        self.base_url = MCP_SERVER_URL
        self.info_url = urljoin(self.base_url, "/mcp/v1/info")
        self.tool_url = urljoin(self.base_url, f"/mcp/v1/{MCP_TOOL_NAME}")
        self.health_url = urljoin(self.base_url, "/health")

    def test_health_endpoint(self):
        """Test that the health endpoint is available and returns expected response."""
        response = requests.get(self.health_url)
        
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("status", data)
        self.assertEqual(data["status"], "ok")

    def test_info_endpoint(self):
        """Test that the info endpoint returns valid tool information."""
        response = requests.get(self.info_url)
        
        self.assertEqual(response.status_code, 200)
        data = response.json()
        
        # Verify required fields
        self.assertIn("tools", data)
        
        # Verify tool details
        tools = data["tools"]
        self.assertIsInstance(tools, list)
        self.assertTrue(len(tools) > 0)
        
        # Verify tool schema
        tool = next((t for t in tools if t.get("name") == MCP_TOOL_NAME), None)
        self.assertIsNotNone(tool)
        self.assertIn("description", tool)
        self.assertIn("name", tool)
        self.assertIn("parameters", tool)

        # Validate schema format
        parameters = tool["parameters"]
        self.assertIn("type", parameters)
        self.assertIn("properties", parameters)

    def test_tool_endpoint_parameter_validation(self):
        """Test that the tool endpoint validates required parameters."""
        # Test with missing required parameters
        response = requests.post(
            self.tool_url,
            json={"body": {}}
        )
        
        self.assertIn(response.status_code, [400, 422])  # Either is acceptable for validation errors
        
    def test_tool_endpoint_valid_request(self):
        """Test tool endpoint with a valid request."""
        # Get the schema first to understand required parameters
        info_response = requests.get(self.info_url)
        info_data = info_response.json()
        tool = next((t for t in info_data["tools"] if t.get("name") == MCP_TOOL_NAME), None)
        parameters = tool["parameters"]
        
        # Extract required parameters from schema
        required_params = parameters.get("required", [])
        properties = parameters.get("properties", {})
        
        # Create a test request with minimal valid parameters
        test_request = {"body": {}}
        
        # Add required string parameters with placeholder values
        for param in required_params:
            if param in properties:
                param_type = properties[param].get("type")
                if param_type == "string":
                    test_request["body"][param] = f"test_{param}"
                elif param_type == "object":
                    test_request["body"][param] = {}
                elif param_type == "array":
                    test_request["body"][param] = []
                elif param_type == "boolean":
                    test_request["body"][param] = True
                elif param_type == "number" or param_type == "integer":
                    test_request["body"][param] = 1
        
        # Add project context for mangekyou
        test_request["body"]["project"] = "test_project"
        test_request["body"]["language"] = "python"
        test_request["body"]["feature"] = "test feature"
        
        # Send valid request
        response = requests.post(
            self.tool_url,
            json=test_request
        )
        
        # Check response (should be 200 for success)
        self.assertEqual(response.status_code, 200)
        data = response.json()
        
        # Validate response format
        self.assertIn("response", data)
        
    def test_error_handling(self):
        """Test error handling for invalid requests."""
        # Test with malformed JSON
        headers = {"Content-Type": "application/json"}
        response = requests.post(
            self.tool_url,
            data="malformed json",
            headers=headers
        )
        
        self.assertIn(response.status_code, [400, 422])
        
    def test_response_headers(self):
        """Test that the server returns the correct content type."""
        response = requests.get(self.info_url)
        
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.headers["Content-Type"], "application/json")


if __name__ == "__main__":
    unittest.main()