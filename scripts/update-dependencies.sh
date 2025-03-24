#\!/bin/bash
# Script to update all dependencies to the latest versions

set -e

echo "Updating Rust dependencies..."
cargo update

echo "Updating Python dependencies in mangekyou-mcp..."
cd scripts/mangekyou-mcp
pip install -r requirements.txt --upgrade
pip freeze > requirements.txt

echo "Updating Python dependencies in mangekyo-mcp..."
cd ../mangekyo-mcp
pip install -r requirements.txt --upgrade
pip freeze > requirements.txt

echo "All dependencies updated successfully\!"
