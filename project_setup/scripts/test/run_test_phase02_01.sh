#!/bin/bash

BASE_PATH="$PWD"
PROJECT_PATH="$BASE_PATH/kaul2-app"
BACKEND_PATH="$PROJECT_PATH/backend"

cd $BACKEND_PATH
echo "Starting serverless offline..."
npx serverless offline
