#!/bin/bash
# Script to test the admin login redirect functionality

echo "Starting Tobira in dev mode..."
trunk serve --open &
TRUNK_PID=$!

# Give it time to start
sleep 5

echo "Opening admin URL in browser..."
if command -v xdg-open > /dev/null; then
  xdg-open http://localhost:8080/admin
elif command -v open > /dev/null; then
  open http://localhost:8080/admin
else
  echo "Please open http://localhost:8080/admin in your browser"
fi

echo "Test instructions:"
echo "1. You should see the login page when visiting /admin"
echo "2. Click 'Login with Google'"
echo "3. After authentication, you should be redirected back to /admin"
echo "4. Check the console for debugging messages"
echo ""
echo "Press Ctrl+C to stop the server when done testing"

# Wait for user to stop the script
wait $TRUNK_PID