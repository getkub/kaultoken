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
done

# Serverless unit tests
for module in counter share rating auth; do
  mkdir -p "test/serverless/unit/$module"
done

# 1. test/frontend/unit/counter/CounterComponent.test.js
cat <<EOL > "test/frontend/unit/counter/CounterComponent.test.js"
import { render, screen, fireEvent } from '@testing-library/react';
import CounterComponent from '../../../frontend/src/modules/counter/CounterComponent';
import axios from 'axios';

jest.mock('axios');

describe('CounterComponent', () => {
  beforeEach(() => {
    axios.post.mockResolvedValue({ data: { count: 1 } });
  });

  it('increments count on button click', async () => {
    render(<CounterComponent />);
    const button = screen.getByText(/Increment/i);
    fireEvent.click(button);
    expect(await screen.findByText('Counter: 1')).toBeInTheDocument();
  });

  it('displays initial count of 0', () => {
    render(<CounterComponent />);
    expect(screen.getByText('Counter: 0')).toBeInTheDocument();
  });
});
EOL

# 2. test/frontend/unit/counter/CounterService.test.js
cat <<EOL > "test/frontend/unit/counter/CounterService.test.js"
import axios from 'axios';
import { incrementCounter } from '../../../frontend/src/modules/counter/CounterService';

jest.mock('axios');

describe('CounterService', () => {
  it('calls increment API and returns new count', async () => {
    axios.post.mockResolvedValue({ data: { count: 2 } });
    const result = await incrementCounter('demo');
    expect(axios.post).toHaveBeenCalledWith('http://localhost:3001/api/v1/counter/increment', { counterId: 'demo' });
    expect(result).toBe(2);
  });
});
EOL

# 3. test/frontend/integration/counterIntegration.test.js
cat <<EOL > "test/frontend/integration/counterIntegration.test.js"
import { render, screen, fireEvent } from '@testing-library/react';
import App from '../../../frontend/src/App';
import axios from 'axios';

jest.mock('axios');

describe('Counter Integration', () => {
  it('increments counter across app', async () => {
    axios.post.mockResolvedValue({ data: { count: 1 } });
    render(<App />);
    const button = screen.getByText(/Increment/i);
    fireEvent.click(button);
    expect(await screen.findByText('Counter: 1')).toBeInTheDocument();
  });
});
EOL

# 4. test/serverless/unit/counter/increment.test.js
cat <<EOL > "test/serverless/unit/counter/increment.test.js"
const { handler } = require('../../serverless/counter/increment');
const AWS = require('aws-sdk');

jest.mock('aws-sdk', () => {
  const mDocumentClient = {
    update: jest.fn().mockReturnValue({
      promise: jest.fn().mockResolvedValue({ Attributes: { count: 1 } }),
    }),
  };
  return { DynamoDB: { DocumentClient: jest.fn(() => mDocumentClient) } };
});

describe('counterIncrement', () => {
  it('increments counter and returns new count', async () => {
    const event = { body: JSON.stringify({ counterId: 'demo' }) };
    const result = await handler(event);

    expect(result.statusCode).toBe(200);
    expect(JSON.parse(result.body)).toEqual({ success: true, count: 1 });
  });

  it('handles errors gracefully', async () => {
    AWS.DynamoDB.DocumentClient().update.mockReturnValue({
      promise: jest.fn().mockRejectedValue(new Error('DynamoDB error')),
    });
    const event = { body: JSON.stringify({ counterId: 'demo' }) };
    const result = await handler(event);

    expect(result.statusCode).toBe(500);
    expect(JSON.parse(result.body).error).toBe('DynamoDB error');
  });
});
EOL

# 5. test/serverless/unit/auth/login.test.js
cat <<EOL > "test/serverless/unit/auth/login.test.js"
const { handler } = require('../../serverless/auth/login');

describe('authLogin', () => {
  it('returns a dummy token for POC', async () => {
    const event = { body: JSON.stringify({ username: 'test', password: 'pass' }) };
    const result = await handler(event); // Assuming a simple handler exists

    expect(result.statusCode).toBe(200);
    expect(JSON.parse(result.body)).toHaveProperty('token');
  });
});
EOL

# 6. test/serverless/integration/counterApi.test.js
cat <<EOL > "test/serverless/integration/counterApi.test.js"
const { handler } = require('../../serverless/counter/increment');

describe('Counter API Integration', () => {
  it('increments counter via simulated API call', async () => {
    const event = {
      body: JSON.stringify({ counterId: 'demo' }),
      httpMethod: 'POST',
      path: '/api/v1/counter/increment',
    };
    const result = await handler(event);

    expect(result.statusCode).toBe(200);
    const body = JSON.parse(result.body);
    expect(body.success).toBe(true);
    expect(body.count).toBeGreaterThan(0);
  });
});
EOL

# 7. test/__mocks__/axios.js
cat <<EOL > "test/__mocks__/axios.js"
module.exports = {
  post: jest.fn(),
};
EOL

# 8. test/__mocks__/aws-sdk.js
cat <<EOL > "test/__mocks__/aws-sdk.js"
const AWS = {
  DynamoDB: {
    DocumentClient: jest.fn(() => ({
      update: jest.fn().mockReturnValue({
        promise: jest.fn().mockResolvedValue({ Attributes: { count: 0 } }),
      }),
    })),
  },
};
module.exports = AWS;
EOL

echo "Test files created successfully in $PROJECT_PATH/test!"
