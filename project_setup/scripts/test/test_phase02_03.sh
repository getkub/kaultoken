#!/bin/bash

PROJECT_NAME="kaul2-app"
BASE_PATH="$PWD"
PROJECT_PATH="$BASE_PATH/$PROJECT_NAME"
BACKEND_PATH="$PROJECT_PATH/backend"
TEST_SCRIPTS_PATH="$BASE_PATH/project_setup/scripts/test"

# Clean and recreate backend
rm -rf $BACKEND_PATH
mkdir -p $BACKEND_PATH

# Create package.json with ESM support
cat > $BACKEND_PATH/package.json << 'EOL'
{
  "name": "subject-voting-api",
  "version": "1.0.0",
  "type": "module",
  "private": true,
  "dependencies": {
    "@types/aws-lambda": "^8.10.92"
  },
  "devDependencies": {
    "serverless": "^4.6.4",
    "serverless-offline": "latest"
  }
}
EOL

# Create serverless.yml for v4
cat > $BACKEND_PATH/serverless.yml << 'EOL'
service: subject-voting-api
frameworkVersion: '4'

provider:
  name: aws
  runtime: nodejs20.x

plugins:
  - serverless-offline

functions:
  hello:
    handler: handler.hello
    events:
      - httpApi:
          path: /
          method: get
EOL

# Create handler.js using ESM
cat > $BACKEND_PATH/handler.js << 'EOL'
export const hello = async (event) => {
  return {
    statusCode: 200,
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(
      {
        message: 'Hello from Lambda!',
        input: event,
      }
    ),
  };
};
EOL

# Install dependencies
cd $BACKEND_PATH
npm install

# Create test runner
mkdir -p $TEST_SCRIPTS_PATH
cat > $TEST_SCRIPTS_PATH/run_test_phase02_01.sh << 'EOL'
#!/bin/bash

BASE_PATH="$PWD"
PROJECT_PATH="$BASE_PATH/kaul2-app"
BACKEND_PATH="$PROJECT_PATH/backend"

cd $BACKEND_PATH
echo "Starting serverless offline..."
npx serverless offline
EOL

chmod +x $TEST_SCRIPTS_PATH/run_test_phase02_01.sh

echo "Setup complete! To run the test:"
echo "1. cd $BASE_PATH"
echo "2. ./project_setup/scripts/test/run_test_phase02_01.sh" 