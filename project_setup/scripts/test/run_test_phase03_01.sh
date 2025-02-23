#!/bin/bash
# Auto-generated runner for test_phase03_01

# First run the Python setup script
python3 /Users/kk/Documents/shared/softwares/git_repo/kaultoken/project_setup/scripts/test/test_phase03_01.py

if [ $? -ne 0 ]; then
    echo "Python setup failed!"
    exit 1
fi

BASE_PATH="$PWD"
PROJECT_PATH="$BASE_PATH/kaul2-app"
BACKEND_PATH="$PROJECT_PATH/backend"
FRONTEND_PATH="$PROJECT_PATH/frontend"

echo "Starting servers for kaul2-app..."

# Kill any existing processes
echo "Cleaning up existing processes..."
lsof -ti:3001 | xargs kill -9 2>/dev/null || true
lsof -ti:5173 | xargs kill -9 2>/dev/null || true

# Install dependencies if needed
if [ ! -d "$BACKEND_PATH/node_modules" ]; then
    echo "Installing backend dependencies..."
    cd $BACKEND_PATH && npm install
fi

if [ ! -d "$FRONTEND_PATH/node_modules" ]; then
    echo "Installing frontend dependencies..."
    cd $FRONTEND_PATH && npm install
fi

# Start servers
echo "Starting backend server..."
cd $BACKEND_PATH && npm run dev &
BACKEND_PID=$!

echo "Starting frontend server..."
cd $FRONTEND_PATH && npm run dev &
FRONTEND_PID=$!

# Handle termination
trap "kill $BACKEND_PID $FRONTEND_PID" SIGINT SIGTERM EXIT

echo "🚀 Servers started!"
echo "📱 Frontend: http://localhost:5173"
echo "⚙️  Backend: http://localhost:3001"
echo ""
echo "Points System:"
echo "- Each user starts with 100 points"
echo "- Each vote costs 10 points"
echo "- Rewards are distributed in pyramid scheme:"
echo "  * First voter: 50% of future vote points"
echo "  * Second voter: 25% of future vote points"
echo "  * Third voter: 12.5% of future vote points"
echo ""
echo "Press Ctrl+C to stop all servers"

wait
