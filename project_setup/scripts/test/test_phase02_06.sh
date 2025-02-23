PROJECT_NAME="kaul2-app"
BASE_PATH="$PWD"
PROJECT_PATH="$BASE_PATH/$PROJECT_NAME"
BACKEND_PATH="$PROJECT_PATH/backend"
FRONTEND_PATH="$PROJECT_PATH/frontend"

# Create backend directory if it doesn't exist
mkdir -p $BACKEND_PATH

# Update backend package.json to add lowdb
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
    "@types/aws-lambda": "^8.10.92",
    "lowdb": "^7.0.1"
  },
  "devDependencies": {
    "serverless": "^4.6.4",
    "serverless-offline": "latest"
  }
}
EOL

# Install backend dependencies
echo "Installing backend dependencies..."
cd $BACKEND_PATH
npm install

# Create db.js with proper data loading
cat > $BACKEND_PATH/db.js << 'EOL'
import { Low } from 'lowdb'
import { JSONFile } from 'lowdb/node'
import path from 'path'
import { fileURLToPath } from 'url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const dbPath = path.join(__dirname, 'db.json')

// Default data structure
const defaultData = {
  subjects: [
    { 
      id: 1, 
      title: 'First Subject', 
      votes: { up: 0, down: 0 },
      lastUpdated: new Date().toISOString()
    },
    { 
      id: 2, 
      title: 'Second Subject', 
      votes: { up: 0, down: 0 },
      lastUpdated: new Date().toISOString()
    }
  ]
}

const adapter = new JSONFile(dbPath)
const db = new Low(adapter, defaultData)

// Initialize database
await db.read()

export default db
EOL

# Update handler.js with better error handling
cat > $BACKEND_PATH/handler.js << 'EOL'
import db from './db.js'

// GET /subjects
export const getSubjects = async (event) => {
  try {
    await db.read()
    console.log('GET /subjects - Current data:', JSON.stringify(db.data.subjects, null, 2))
    
    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify(db.data.subjects)
    }
  } catch (error) {
    console.error('Error reading subjects:', error)
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({ 
        success: false, 
        error: 'Failed to read database' 
      })
    }
  }
}

// POST /vote
export const recordVote = async (event) => {
  console.log('POST /vote called with body:', event.body)
  try {
    const { id, voteType } = JSON.parse(event.body)
    
    await db.read()
    db.data.subjects = db.data.subjects.map(subject => {
      if (subject.id === id) {
        return {
          ...subject,
          votes: {
            ...subject.votes,
            [voteType]: subject.votes[voteType] + 1
          },
          lastUpdated: new Date().toISOString()
        }
      }
      return subject
    })
    await db.write()

    console.log('Updated vote data:', JSON.stringify(db.data.subjects, null, 2))
    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({ 
        success: true, 
        subjects: db.data.subjects 
      })
    }
  } catch (error) {
    console.error('Error processing vote:', error)
    return {
      statusCode: 400,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({ 
        success: false, 
        error: 'Invalid request' 
      })
    }
  }
}

// Rest of handler.js remains the same...
EOL

# Update the test runner to be simpler
cat > $BASE_PATH/project_setup/scripts/test/run_test_phase02_06.sh << 'EOL'
#!/bin/bash

BASE_PATH="$PWD"
PROJECT_PATH="$BASE_PATH/kaul2-app"

# Kill any existing processes
echo "Cleaning up existing processes..."
lsof -ti:3001 | xargs kill -9 2>/dev/null || true
lsof -ti:5173 | xargs kill -9 2>/dev/null || true

# Start servers
echo "Starting backend server..."
npm --prefix $PROJECT_PATH/backend run dev &
BACKEND_PID=$!

echo "Starting frontend server..."
npm --prefix $PROJECT_PATH/frontend run dev &
FRONTEND_PID=$!

# Handle termination
trap "kill $BACKEND_PID $FRONTEND_PID" SIGINT SIGTERM EXIT

echo "Servers started!"
echo "Backend: http://localhost:3001"
echo "Frontend: http://localhost:5173"
echo "Press Ctrl+C to stop"

wait
EOL

chmod +x $BASE_PATH/project_setup/scripts/test/run_test_phase02_06.sh

# Update frontend App.jsx to fetch initial data
cat > $FRONTEND_PATH/src/App.jsx << 'EOL'
import React, { useState, useEffect } from 'react';
import './App.css';

function App() {
  const [subjects, setSubjects] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Fetch initial data
  useEffect(() => {
    fetchSubjects();
  }, []);

  const fetchSubjects = async () => {
    try {
      const response = await fetch('http://localhost:3001/subjects');
      const data = await response.json();
      console.log('Loaded subjects:', data);
      setSubjects(data);
      setError(null);
    } catch (err) {
      console.error('Failed to load subjects:', err);
      setError('Failed to load subjects');
    } finally {
      setLoading(false);
    }
  };

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
        const result = await response.json();
        console.log('Vote recorded:', result);
        setSubjects(result.subjects);
        setError(null);
      }
    } catch (err) {
      console.error('Voting failed:', err);
      setError('Failed to record vote');
    }
  };

  if (loading) return <div className="loading">Loading subjects...</div>;
  if (error) return <div className="error">{error}</div>;

  return (
    <div className="app">
      <h1>Kaul2 Voting Demo</h1>
      <div className="subjects">
        {subjects.map(subject => (
          <div key={subject.id} className="subject-card">
            <h2>{subject.title}</h2>
            <div className="vote-buttons">
              <button 
                onClick={() => handleVote(subject.id, 'up')} 
                className="vote-up"
              >
                👍 {subject.votes.up}
              </button>
              <button 
                onClick={() => handleVote(subject.id, 'down')} 
                className="vote-down"
              >
                👎 {subject.votes.down}
              </button>
            </div>
            <div className="last-updated">
              Last updated: {new Date(subject.lastUpdated).toLocaleString()}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

export default App;
EOL

# Update App.css with loading and error styles
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

.loading, .error {
  text-align: center;
  padding: 20px;
  margin: 20px;
  border-radius: 8px;
}

.loading {
  background: #e3f2fd;
  color: #1976d2;
}

.error {
  background: #ffebee;
  color: #c62828;
}

.last-updated {
  margin-top: 10px;
  font-size: 0.8em;
  color: #666;
}
EOL

# Rest of the script remains the same... 