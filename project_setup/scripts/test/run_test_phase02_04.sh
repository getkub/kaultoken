#!/bin/bash

BASE_PATH="$PWD"
PROJECT_PATH="$BASE_PATH/kaul2-app"

echo "Starting frontend development server..."
npm --prefix $PROJECT_PATH/frontend run dev
