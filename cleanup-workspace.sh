#!/usr/bin/env bash
# Cleanup script for workspace migration

set -e  # Exit on error

# Create a backup directory
BACKUP_DIR="src_backup_$(date +%Y%m%d_%H%M%S)"
echo "Creating backup directory: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Back up original source files
echo "Backing up original src directory..."
cp -r src/* "$BACKUP_DIR/"
cp -r benches/* "$BACKUP_DIR/benches/"

# Remove original source files
echo "Removing original src directory..."
rm -rf src
echo "Removing original benches directory..."
rm -rf benches

echo "Conversion complete. Original files are backed up in: $BACKUP_DIR"
echo "The codebase is now fully organized as a Rust workspace:"
echo "- ihoje_core: Main application code"
echo "- ihoje_models: Shared data models"
echo "- tobira: WebAssembly frontend"
echo
echo "To build all packages: cargo build --workspace"
echo "To run the application: cargo run -p ihoje_core"
echo "To run the frontend: cargo run -p ihoje_tobira"