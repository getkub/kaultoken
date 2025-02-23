#!/bin/bash

# Define project path
PROJECT_NAME="kaul-app"
BASE_PATH="$PWD"
PROJECT_PATH="$BASE_PATH/$PROJECT_NAME"

# Navigate to project root
cd "$PROJECT_PATH" || { echo "Failed to cd to $PROJECT_PATH"; exit 1; }

# Create test directory structure
mkdir -p test/{frontend,serverless}/{unit,integration} test/__mocks__

# Frontend unit tests
for module in counter share rating; do
  mkdir -p "test/frontend/unit/$module"
  touch "test/frontend/unit/$module/${module^}Component.test.js"
  touch "test/frontend/unit/$module/${module^}Service.test.js"
done

# Frontend integration tests
touch "test/frontend/integration/counterIntegration.test.js"

# Serverless unit tests
for module in counter share rating auth; do
  mkdir -p "test/serverless/unit/$module"
  if [ "$module" != "auth" ]; then
    touch "test/serverless/unit/$module/increment.test.js"
  else
    touch "test/serverless/unit/$module/login.test.js"
  fi
done

# Serverless integration tests
touch "test/serverless/integration/counterApi.test.js"

# Mock files
touch "test/__mocks__/axios.js"
touch "test/__mocks__/aws-sdk.js"

# Add testing dependencies to frontend package.json
cd "$PROJECT_PATH/frontend" || exit 1
npm install --save-dev jest @testing-library/react @testing-library/jest-dom

# Update frontend package.json with test script
cat <<EOL > package.json
{
  "name": "frontend",
  "version": "1.0.0",
  "scripts": {
    "start": "react-scripts start",
    "test": "jest"
  },
  "dependencies": {
    "react": "^18.2.0",
    "axios": "^1.6.0",
    "aws-amplify": "^6.0.0"
  },
  "devDependencies": {
    "jest": "^29.7.0",
    "@testing-library/react": "^14.0.0",
    "@testing-library/jest-dom": "^6.0.0"
  },
  "jest": {
    "testEnvironment": "jsdom"
  }
}
EOL

# Add testing dependencies to serverless package.json
cd "$PROJECT_PATH/serverless" || exit 1
npm install --save-dev jest

# Update serverless package.json with test script
cat <<EOL > package.json
{
  "name": "serverless-backend",
  "version": "1.0.0",
  "scripts": {
    "deploy": "sls deploy",
    "test": "jest"
  },
  "devDependencies": {
    "serverless": "^3.38.0",
    "serverless-offline": "^13.3.0",
    "serverless-dynamodb-local": "^0.2.40",
    "jest": "^29.7.0"
  },
  "dependencies": {
    "aws-sdk": "^2.1510.0"
  }
}
EOL

echo "Test directory structure created at $PROJECT_PATH/test!"