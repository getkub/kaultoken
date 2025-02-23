#!/bin/bash

BASE_PATH="$PWD"
PROJECT_PATH="$BASE_PATH/kaul2-app"

# Kill any existing processes on the ports
echo "Cleaning up existing processes..."
lsof -ti:3001 | xargs kill -9 2>/dev/null || true
lsof -ti:5173 | xargs kill -9 2>/dev/null || true

# Start backend with dev script
echo "Starting backend server..."
npm --prefix $PROJECT_PATH/backend run dev &
BACKEND_PID=$!

# Start frontend with dev script
echo "Starting frontend server..."
npm --prefix $PROJECT_PATH/frontend run dev &
FRONTEND_PID=$!

# Handle script termination
trap "kill $BACKEND_PID $FRONTEND_PID" SIGINT SIGTERM EXIT

echo "Both servers started!"
echo "Backend running on: http://localhost:3001"
echo "Frontend running on: http://localhost:5173"
echo "Press Ctrl+C to stop both servers"

# Keep script running
wait
