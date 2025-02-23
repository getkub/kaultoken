#!/bin/bash

# Define project name
PROJECT_NAME="kaul-app"

# Create absolute path rooted from current directory
BASE_PATH="$PWD"  # Or replace with a fixed path like "/home/user/projects" if preferred
PROJECT_PATH="$BASE_PATH/$PROJECT_NAME"

# Create the project directory if it doesn’t exist
mkdir -p "$PROJECT_PATH"

# Navigate to the absolute project path
cd "$PROJECT_PATH" || { echo "Failed to cd to $PROJECT_PATH"; exit 1; }

# Navigate to frontend and install dependencies
cd "$PROJECT_PATH/frontend" || { echo "Failed to cd to frontend"; exit 1; }
npm install

# Navigate to serverless and install dependencies
cd "$PROJECT_PATH/serverless" || { echo "Failed to cd to serverless"; exit 1; }
npm install

echo "Setup completed in $PROJECT_PATH!"