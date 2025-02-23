#!/bin/bash

PROJECT_NAME="kaul2-app"
BASE_PATH="$PWD"
PROJECT_PATH="$BASE_PATH/$PROJECT_NAME"
BACKEND_PATH="$PROJECT_PATH/backend"
FRONTEND_PATH="$PROJECT_PATH/frontend"

# Update backend package.json with correct scripts
cat > $BACKEND_PATH/package.json << 'EOL'
{
  "name": "subject-voting-api",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "serverless offline start",
    "start": "serverless offline start"
  },
  "dependencies": {
    "@types/aws-lambda": "^8.10.92"
  },
  "devDependencies": {
    "serverless": "^4.6.4",
    "serverless-offline": "latest"
  }
}
EOL

# Update backend handler to store votes in memory
cat > $BACKEND_PATH/handler.js << 'EOL'
// In-memory storage for votes
let subjects = [
  { id: 1, title: 'First Subject', votes: { up: 0, down: 0 } },
  { id: 2, title: 'Second Subject', votes: { up: 0, down: 0 } }
];

export const getSubjects = async () => {
  return {
    statusCode: 200,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    },
    body: JSON.stringify(subjects)
  };
};

export const recordVote = async (event) => {
  const { id, voteType } = JSON.parse(event.body);
  
  subjects = subjects.map(subject => {
    if (subject.id === id) {
      return {
        ...subject,
        votes: {
          ...subject.votes,
          [voteType]: subject.votes[voteType] + 1
        }
      };
    }
    return subject;
  });

  return {
    statusCode: 200,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    },
    body: JSON.stringify({ success: true })
  };
};
EOL

# Update serverless.yml to add vote endpoint
cat > $BACKEND_PATH/serverless.yml << 'EOL'
service: subject-voting-api
frameworkVersion: '4'

provider:
  name: aws
  runtime: nodejs20.x

plugins:
  - serverless-offline

functions:
  getSubjects:
    handler: handler.getSubjects
    events:
      - httpApi:
          path: /subjects
          method: get
  recordVote:
    handler: handler.recordVote
    events:
      - httpApi:
          path: /vote
          method: post

custom:
  serverless-offline:
    httpPort: 3001
    noPrependStageInUrl: true
EOL

# Update frontend package.json with correct scripts
cat > $FRONTEND_PATH/package.json << 'EOL'
{
  "name": "kaul2-frontend",
  "private": true,
  "version": "0.0.1",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "start": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "axios": "^1.6.2"
  },
  "devDependencies": {
    "@vitejs/plugin-react": "^4.2.0",
    "vite": "^5.0.0"
  }
}
EOL

# Create necessary frontend directories
mkdir -p $FRONTEND_PATH/src

# Create index.html
cat > $FRONTEND_PATH/index.html << 'EOL'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Kaul2 Voting App</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
EOL

# Create main.jsx
cat > $FRONTEND_PATH/src/main.jsx << 'EOL'
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
EOL

# Create App.jsx with voting functionality
cat > $FRONTEND_PATH/src/App.jsx << 'EOL'
import React, { useState, useEffect } from 'react';
import './App.css';

function App() {
  const [subjects, setSubjects] = useState([
    { id: 1, title: 'First Subject', votes: { up: 0, down: 0 } },
    { id: 2, title: 'Second Subject', votes: { up: 0, down: 0 } }
  ]);

  const handleVote = async (id, type) => {
    try {
      const response = await fetch('http://localhost:3001/vote', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ id, voteType: type })
      });
      
      if (response.ok) {
        // Update local state
        setSubjects(subjects.map(subject => {
          if (subject.id === id) {
            return {
              ...subject,
              votes: {
                ...subject.votes,
                [type]: subject.votes[type] + 1
              }
            };
          }
          return subject;
        }));
      }
    } catch (error) {
      console.error('Voting failed:', error);
    }
  };

  return (
    <div className="app">
      <h1>Kaul2 Voting Demo</h1>
      <div className="subjects">
        {subjects.map(subject => (
          <div key={subject.id} className="subject-card">
            <h2>{subject.title}</h2>
            <div className="vote-buttons">
              <button onClick={() => handleVote(subject.id, 'up')} className="vote-up">
                👍 {subject.votes.up}
              </button>
              <button onClick={() => handleVote(subject.id, 'down')} className="vote-down">
                👎 {subject.votes.down}
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

export default App;
EOL

# Create App.css
cat > $FRONTEND_PATH/src/App.css << 'EOL'
.app {
  max-width: 800px;
  margin: 0 auto;
  padding: 20px;
}

h1 {
  text-align: center;
  color: #333;
}

.subjects {
  display: grid;
  gap: 20px;
  padding: 20px;
}

.subject-card {
  border: 1px solid #ddd;
  border-radius: 8px;
  padding: 20px;
  background: white;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.vote-buttons {
  display: flex;
  gap: 10px;
  margin-top: 10px;
}

button {
  padding: 8px 16px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  transition: background 0.2s;
  display: flex;
  align-items: center;
  gap: 5px;
}

.vote-up {
  background: #e8f5e9;
}

.vote-down {
  background: #ffebee;
}

button:hover {
  opacity: 0.9;
}
EOL

# Create index.css
cat > $FRONTEND_PATH/src/index.css << 'EOL'
:root {
  font-family: Inter, system-ui, Avenir, Helvetica, Arial, sans-serif;
  line-height: 1.5;
  font-weight: 400;
}

body {
  margin: 0;
  min-width: 320px;
  min-height: 100vh;
  background: #f5f5f5;
}
EOL

# Create a test runner with BASE_PATH prefix
cat > $BASE_PATH/project_setup/scripts/test/run_test_phase02_05.sh << 'EOL'
#!/bin/bash

BASE_PATH="$PWD"
PROJECT_PATH="$BASE_PATH/kaul2-app"

# Kill any existing processes on the ports
echo "Cleaning up existing processes..."
lsof -ti:3001 | xargs kill -9 2>/dev/null || true
lsof -ti:5173 | xargs kill -9 2>/dev/null || true

# Start backend with dev script
echo "Starting backend server..."
npm --prefix $PROJECT_PATH/backend run dev &
BACKEND_PID=$!

# Start frontend with dev script
echo "Starting frontend server..."
npm --prefix $PROJECT_PATH/frontend run dev &
FRONTEND_PID=$!

# Handle script termination
trap "kill $BACKEND_PID $FRONTEND_PID" SIGINT SIGTERM EXIT

echo "Both servers started!"
echo "Backend running on: http://localhost:3001"
echo "Frontend running on: http://localhost:5173"
echo "Press Ctrl+C to stop both servers"

# Keep script running
wait
EOL

chmod +x $BASE_PATH/project_setup/scripts/test/run_test_phase02_05.sh

echo "Setup complete! To run both servers from any directory:"
echo "1. From $BASE_PATH:"
echo "   ./project_setup/scripts/test/run_test_phase02_05.sh" 