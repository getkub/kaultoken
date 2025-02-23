#!/bin/bash

BASE_PATH="$PWD"
PROJECT_PATH="$BASE_PATH/kaul2-app"

# Kill any existing processes
echo "Cleaning up existing processes..."
lsof -ti:3001 | xargs kill -9 2>/dev/null || true
lsof -ti:5173 | xargs kill -9 2>/dev/null || true

# Start servers
echo "Starting backend server..."
npm --prefix $PROJECT_PATH/backend run dev &
BACKEND_PID=$!

echo "Starting frontend server..."
npm --prefix $PROJECT_PATH/frontend run dev &
FRONTEND_PID=$!

# Handle termination
trap "kill $BACKEND_PID $FRONTEND_PID" SIGINT SIGTERM EXIT

echo "Servers started!"
echo "Backend: http://localhost:3001"
echo "Frontend: http://localhost:5173"
echo "Press Ctrl+C to stop"

wait
