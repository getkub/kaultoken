#!/bin/bash

PROJECT_NAME="kaul2-app"

# Create absolute path rooted from current directory
BASE_PATH="$PWD"  # Or replace with a fixed path like "/home/user/projects" if preferred
PROJECT_PATH="$BASE_PATH/$PROJECT_NAME"

# First create the project directory
mkdir -p $PROJECT_PATH

# Create directory structure
mkdir -p $PROJECT_PATH/{backend,frontend}/{src,test}
mkdir -p $PROJECT_PATH/backend/src/{services/{subject,vote,wallet},functions/{getSubjects,recordVote,verifyTransaction}}
mkdir -p $PROJECT_PATH/frontend/src/{components,services,hooks}
mkdir -p $PROJECT_PATH/shared/types

# Create shared types
cat > $PROJECT_PATH/shared/types/index.ts << 'EOL'
export interface Subject {
  id: string;
  title: string;
  description: string;
  walletAddress: string;
  votes: VoteCount;
  createdAt: string;
  updatedAt: string;
}

export interface VoteCount {
  upvotes: number;
  downvotes: number;
}

export interface Vote {
  subjectId: string;
  isUpvote: boolean;
  txHash?: string;
  timestamp: string;
}

export interface ApiResponse<T> {
  data: T;
  success: boolean;
  error?: string;
}
EOL

# Create serverless.yml
cat > $PROJECT_PATH/backend/serverless.yml << 'EOL'
service: subject-voting-api

provider:
  name: aws
  runtime: nodejs18.x
  stage: ${opt:stage, 'dev'}
  region: ${opt:region, 'us-east-1'}
  environment:
    STAGE: ${self:provider.stage}

functions:
  getSubjects:
    handler: src/functions/getSubjects/index.handler
    events:
      - http:
          path: /api/v1/subjects
          method: get
          cors: true

  getSubject:
    handler: src/functions/getSubjects/getOne.handler
    events:
      - http:
          path: /api/v1/subjects/{subjectId}
          method: get
          cors: true

  recordVote:
    handler: src/functions/recordVote/index.handler
    events:
      - http:
          path: /api/v1/subjects/{subjectId}/votes
          method: post
          cors: true

  verifyTransaction:
    handler: src/functions/verifyTransaction/index.handler
    events:
      - http:
          path: /api/v1/transactions/verify
          method: post
          cors: true
EOL

# Create subject service
cat > $PROJECT_PATH/backend/src/services/subject/index.ts << 'EOL'
import { Subject, ApiResponse } from '../../../../shared/types';

// Mock database
const subjects: Subject[] = [
  {
    id: '1',
    title: 'First Subject',
    description: 'This is a test subject',
    walletAddress: '0x123...abc',
    votes: { upvotes: 0, downvotes: 0 },
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  }
];

export class SubjectService {
  static async getSubjects(): Promise<ApiResponse<Subject[]>> {
    return {
      success: true,
      data: subjects
    };
  }

  static async getSubject(id: string): Promise<ApiResponse<Subject>> {
    const subject = subjects.find(s => s.id === id);
    if (!subject) {
      return {
        success: false,
        data: null as any,
        error: 'Subject not found'
      };
    }
    return {
      success: true,
      data: subject
    };
  }
}
EOL

# Create getSubjects Lambda function
cat > $PROJECT_PATH/backend/src/functions/getSubjects/index.ts << 'EOL'
import { APIGatewayProxyHandler } from 'aws-lambda';
import { SubjectService } from '../../services/subject';

export const handler: APIGatewayProxyHandler = async (event) => {
  try {
    const result = await SubjectService.getSubjects();
    
    return {
      statusCode: result.success ? 200 : 400,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(result)
    };
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({
        success: false,
        error: 'Internal server error'
      })
    };
  }
};
EOL

# Create frontend service
cat > $PROJECT_PATH/frontend/src/services/SubjectService.ts << 'EOL'
import axios from 'axios';
import { Subject, Vote, ApiResponse } from '../../../shared/types';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:3000/api/v1';

export class SubjectService {
  static async getSubjects(): Promise<Subject[]> {
    const response = await axios.get<ApiResponse<Subject[]>>(`${API_BASE_URL}/subjects`);
    return response.data.data;
  }

  static async recordVote(subjectId: string, vote: Vote): Promise<void> {
    await axios.post(`${API_BASE_URL}/subjects/${subjectId}/votes`, vote);
  }
}
EOL

# Create package.json for backend
cat > $PROJECT_PATH/backend/package.json << 'EOL'
{
  "name": "subject-voting-api",
  "version": "1.0.0",
  "description": "Serverless subject voting API",
  "main": "index.js",
  "scripts": {
    "test": "jest",
    "dev": "serverless offline",
    "deploy": "serverless deploy"
  },
  "dependencies": {
    "@types/aws-lambda": "^8.10.92",
    "aws-lambda": "^1.0.7"
  },
  "devDependencies": {
    "@types/jest": "^27.4.0",
    "@types/node": "^17.0.10",
    "jest": "^27.4.7",
    "serverless": "^3.0.0",
    "serverless-offline": "^8.3.1",
    "ts-jest": "^27.1.3",
    "typescript": "^4.5.4"
  }
}
EOL

# Create tsconfig.json for backend
cat > $PROJECT_PATH/backend/tsconfig.json << 'EOL'
{
  "compilerOptions": {
    "target": "es2019",
    "module": "commonjs",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "outDir": ".build",
    "rootDir": "./",
    "sourceMap": true,
    "paths": {
      "@shared/*": ["../shared/*"]
    }
  },
  "include": ["src/**/*", "../shared/**/*"],
  "exclude": ["node_modules", "**/*.test.ts"]
}
EOL


echo "Project structure created successfully!" 