#!/bin/bash

# Define project path
PROJECT_NAME="kaul-app"
BASE_PATH="$PWD"
PROJECT_PATH="$BASE_PATH/$PROJECT_NAME"

# Navigate to project root
cd "$PROJECT_PATH" || { echo "Failed to cd to $PROJECT_PATH"; exit 1; }

# Install frontend testing dependencies
cd "$PROJECT_PATH/frontend" || { echo "Failed to cd to frontend"; exit 1; }
npm install --save-dev jest @testing-library/react@14.3.1 @testing-library/jest-dom@6.4.2
echo "Frontend testing dependencies installed!"

# Install serverless testing dependencies
cd "$PROJECT_PATH/serverless" || { echo "Failed to cd to serverless"; exit 1; }
npm install --save-dev jest
echo "Serverless testing dependencies installed!"

echo "All testing dependencies installed successfully in $PROJECT_PATH!"
