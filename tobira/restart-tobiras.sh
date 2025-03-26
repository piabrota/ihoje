#!/bin/bash
# Script to restart both tobira containers
set -e

echo "Restarting both tobira containers..."

# Stop and remove existing containers
echo "Cleaning up existing containers..."
docker rm -f ihoje-mock >/dev/null 2>&1 || true
docker rm -f ihoje-wasm >/dev/null 2>&1 || true

# Re-run the main script
echo "Starting tobiras again..."
"$(dirname "$0")/run-both-tobiras.sh"