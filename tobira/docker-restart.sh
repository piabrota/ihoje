#!/bin/bash
# Script to restart tobira containers with latest changes
set -e

# Default variables
CONTAINER_TYPE=${1:-"mock"}  # Can be "mock" or "wasm"

# Set container and image names based on type
if [ "$CONTAINER_TYPE" == "mock" ]; then
  CONTAINER_NAME="ihoje-mock"
  IMAGE_NAME="shinri-no-tobira:simple"
  DOCKERFILE="Dockerfile.simple"
  PORT="8080"
  echo "🔄 Restarting MOCK tobira container on port $PORT..."
elif [ "$CONTAINER_TYPE" == "wasm" ]; then
  CONTAINER_NAME="ihoje-wasm"
  IMAGE_NAME="shinri-no-tobira:latest"
  DOCKERFILE="Dockerfile"
  PORT="8081"
  echo "🔄 Restarting WebAssembly tobira container on port $PORT..."
else
  echo "❌ Invalid container type. Use 'mock' or 'wasm'"
  exit 1
fi

echo "🔍 Checking for existing containers..."
# Check for containers with our name
if docker ps -a | grep -q $CONTAINER_NAME; then
  echo "🛑 Stopping and removing existing container: $CONTAINER_NAME"
  docker stop $CONTAINER_NAME || true
  docker rm $CONTAINER_NAME || true
fi

# Also check for any containers using our port
PORT_CONTAINER=$(docker ps -q --filter "publish=$PORT")
if [ -n "$PORT_CONTAINER" ]; then
  echo "🛑 Found container using port $PORT. Stopping: $(docker ps --no-trunc --format "{{.Names}}" --filter "id=$PORT_CONTAINER")"
  docker stop $PORT_CONTAINER || true
fi

echo "🧹 Cleaning up any dangling images..."
docker image prune -f

echo "🏗️ Building new Docker image: $IMAGE_NAME"
cd "$(dirname "$0")"

# For WebAssembly build, we need to be in the project root directory
if [ "$CONTAINER_TYPE" == "wasm" ]; then
  echo "Building WebAssembly from project root..."
  
  # Ensure MIME type is set correctly for WebAssembly files
  echo "Ensuring WebAssembly MIME type is correctly set in server and HTML..."
  
  # Edit the index.html to fix WebAssembly MIME type issues
  cp fixed_index.html index.html
  cp fixed_bootstrap.js bootstrap.js
  
  cd ..
  docker build -t $IMAGE_NAME -f tobira/$DOCKERFILE .
else
  # For mock build, we can stay in the tobira directory
  
  # Update the server to properly handle WASM MIME types
  echo "Updating spa_server.py with proper MIME type handling..."
  
  # Update the .htaccess file in the mock directory
  mkdir -p mock_data
  echo "AddType application/wasm .wasm" > mock_data/.htaccess
  
  docker build -t $IMAGE_NAME -f $DOCKERFILE .
fi

echo "🚀 Starting new container..."
# Always use 8080 internal port and map to external PORT
docker run -d -p $PORT:8080 --name $CONTAINER_NAME $IMAGE_NAME

# Wait a moment for the container to start
sleep 3

# Check container health
if docker ps -f "name=$CONTAINER_NAME" --format "{{.Status}}" | grep -q "Up"; then
  echo "✅ Container is running correctly"
  
  # Run debug script to ensure we can see the server is working
  echo "📊 Running diagnostic checks..."
  docker exec $CONTAINER_NAME /app/debug.sh || true
else
  echo "⚠️ Container might have issues - checking logs:"
  docker logs $CONTAINER_NAME
fi

echo "✨ Container successfully restarted!"
echo "📱 Tobira is available at: http://localhost:$PORT"
echo ""
echo "📊 Container status:"
docker ps | grep $CONTAINER_NAME

echo ""
echo "📝 To view logs: docker logs $CONTAINER_NAME"
echo "🛑 To stop container: docker stop $CONTAINER_NAME"