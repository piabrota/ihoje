#!/usr/bin/env python3
"""
Test script for Mangekyou MCP
This script tests the Mangekyou MCP server by sending a direct request
"""
import os
import sys
import json
import time
import requests
import argparse

def test_mangekyou(query):
    """Test the Mangekyou MCP with a query."""
    print(f"Testing Mangekyou MCP with query: {query}")
    
    # MCP endpoint
    url = "http://localhost:3791/mcp/v1/mangekyou"
    
    # Prepare request payload
    payload = {
        "body": {
            "query": query
        }
    }
    
    try:
        # Send request to the MCP server
        response = requests.post(url, json=payload)
        
        # Check response
        if response.status_code == 200:
            data = response.json()
            print("\n" + "=" * 50)
            print("MANGEKYOU SHARINGAN VISION")
            print("=" * 50 + "\n")
            print(data.get("response", "No response received"))
            print("\n" + "=" * 50)
            return True
        else:
            print(f"Error: Received status code {response.status_code}")
            print(response.text)
            return False
    except Exception as e:
        print(f"Error communicating with Mangekyou MCP server: {e}")
        return False

if __name__ == "__main__":
    # Parse command-line arguments
    parser = argparse.ArgumentParser(description="Test the Mangekyou MCP")
    parser.add_argument("query", help="The implementation plan query to test")
    args = parser.parse_args()
    
    # Run test
    test_mangekyou(args.query)