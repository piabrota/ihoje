#!/bin/bash
# Script to restart the mock tobira container with latest changes
set -e

CONTAINER_NAME="ihoje-mock"
IMAGE_NAME="shinri-no-tobira:simple"
PORT="8080"  # Mock version uses port 8080

echo "🔍 Checking for existing containers..."
if docker ps -a | grep -q $CONTAINER_NAME; then
  echo "🛑 Stopping and removing existing container: $CONTAINER_NAME"
  docker stop $CONTAINER_NAME
  docker rm $CONTAINER_NAME
else
  echo "✅ No existing container found"
fi

echo "🧹 Cleaning up any dangling images..."
docker image prune -f

echo "🏗️ Building new Docker image: $IMAGE_NAME"
docker build -t $IMAGE_NAME -f Dockerfile.simple .

echo "🚀 Starting new container..."
docker run -d -p $PORT:8080 --name $CONTAINER_NAME $IMAGE_NAME

echo "✨ Container successfully restarted!"
echo "📱 Mock tobira is available at: http://localhost:$PORT"
echo ""
echo "📊 Container status:"
docker ps | grep $CONTAINER_NAME

echo ""
echo "📝 To view logs: docker logs $CONTAINER_NAME"
echo "🛑 To stop container: docker stop $CONTAINER_NAME"