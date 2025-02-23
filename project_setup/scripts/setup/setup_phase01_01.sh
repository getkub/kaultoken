#!/bin/bash

# Project root directory
PROJECT_NAME="kaul-app"
mkdir -p $PROJECT_NAME
cd $PROJECT_NAME

# Frontend directory structure (React)
mkdir -p frontend/src/{modules,services,store}
cd frontend/src

# Frontend modules
for module in counter share rating; do
  mkdir -p "modules/$module"
  touch "modules/$module/${module^}Component.jsx"  # Capitalize module name
  touch "modules/$module/${module^}Service.js"
done

# Frontend services and store
touch services/api.js services/counter.js services/share.js services/rating.js
touch store/counterSlice.js store/shareSlice.js store/ratingSlice.js
cd ../..

# Serverless directory structure
mkdir -p serverless/{counter,share,rating,auth,config,utils}
cd serverless

# Serverless modules
for module in counter share rating auth; do
  mkdir -p "$module"
  if [ "$module" != "auth" ]; then
    touch "$module/increment.js"  # Placeholder for main function
  else
    touch "$module/login.js"      # Auth-specific function
  fi
done

# Serverless config and utils
touch config/dynamodb.js config/appsync.js
touch utils/events.js

# Serverless framework config
cat <<EOL > serverless.yml
service: my-app
provider:
  name: aws
  runtime: nodejs20.x
  stage: \${opt:stage, 'dev'}
  region: us-east-1

functions:
  counterIncrement:
    handler: counter/increment.handler
    events:
      - http:
          path: api/v1/counter/increment
          method: post
          cors: true
  shareTransfer:
    handler: share/transfer.handler
    events:
      - http:
          path: api/v1/share/transfer
          method: post
          cors: true
  ratingSubmit:
    handler: rating/increment.handler
    events:
      - http:
          path: api/v1/rating/submit
          method: put
          cors: true
  authLogin:
    handler: auth/login.handler
    events:
      - http:
          path: api/v1/auth/login
          method: post
          cors: true

resources:
  Resources:
    CountersTable:
      Type: AWS::DynamoDB::Table
      Properties:
        TableName: counters
        AttributeDefinitions:
          - AttributeName: counterId
            AttributeType: S
        KeySchema:
          - AttributeName: counterId
            KeyType: HASH
        BillingMode: PAY_PER_REQUEST
EOL

# Events directory
mkdir -p ../events
touch ../events/readme.md  # Placeholder for event system docs

# Infrastructure directory (IaC)
mkdir -p ../infrastructure
touch ../infrastructure/readme.md  # Placeholder for Terraform or additional IaC

# Add basic package.json for frontend
cd ../frontend
cat <<EOL > "$PROJECT_PATH/frontend/package.json"
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
    "aws-amplify": "^6.0.0",
    "react-scripts": "^5.0.1"
  },
  "devDependencies": {
    "jest": "^29.7.0",
    "@testing-library/react": "^14.3.1",
    "@testing-library/jest-dom": "^6.4.2"
  },
  "jest": {
    "testEnvironment": "jsdom"
  }
}
EOL

# Add basic package.json for serverless
cd ../serverless
cat <<EOL > package.json
{
  "name": "serverless-backend",
  "version": "1.0.0",
  "scripts": {
    "deploy": "sls deploy"
  },
  "devDependencies": {
    "serverless": "^3.38.0"
  },
  "dependencies": {
    "aws-sdk": "^2.1510.0"
  }
}
EOL

# Return to project root and set permissions
cd ..
chmod +x *.sh 2>/dev/null  # Make script executable if saved as a file

echo "Directory structure created successfully in $PROJECT_NAME!"
tree . || echo "Run 'sudo apt install tree' to view the structure visually."