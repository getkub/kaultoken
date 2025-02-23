#!/bin/bash

# Phase 2.7: Enhanced UI Layout
#
# This script updates the frontend with:
# 1. Responsive grid layout for subject cards
# 2. Improved visual design and animations
# 3. Better voting button placement
# 4. Hover effects and transitions
# 5. Mobile-friendly design
#
# The backend remains the same as Phase 2.6

PROJECT_NAME="kaul2-app"
BASE_PATH="$PWD"
PROJECT_PATH="$BASE_PATH/$PROJECT_NAME"
BACKEND_PATH="$PROJECT_PATH/backend"
FRONTEND_PATH="$PROJECT_PATH/frontend"

# Backend setup remains the same as phase 2.6
# ... (previous backend code) ...

# Update db.js with proper initialization
cat > $BACKEND_PATH/db.js << 'EOL'
import { Low } from 'lowdb'
import { JSONFile } from 'lowdb/node'
import path from 'path'
import { fileURLToPath } from 'url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const dbPath = path.join(__dirname, 'db.json')

// Default data with all 4 subjects
const defaultData = {
  subjects: [
    { 
      id: 1, 
      title: 'Kubernetes',
      emoji: '🚢',
      votes: { up: 0, down: 0 },
      lastUpdated: new Date().toISOString()
    },
    { 
      id: 2, 
      title: 'AWS Cloud',
      emoji: '☁️',
      votes: { up: 0, down: 0 },
      lastUpdated: new Date().toISOString()
    },
    { 
      id: 3, 
      title: 'Ubuntu Linux',
      emoji: '🐧',
      votes: { up: 0, down: 0 },
      lastUpdated: new Date().toISOString()
    },
    { 
      id: 4, 
      title: 'LangChain',
      emoji: '🔗',
      votes: { up: 0, down: 0 },
      lastUpdated: new Date().toISOString()
    }
  ]
}

const adapter = new JSONFile(dbPath)
const db = new Low(adapter, defaultData)

// Initialize or reset the database with all subjects
await db.read()
if (!db.data || !db.data.subjects || db.data.subjects.length !== 4) {
  console.log('Initializing database with default data');
  db.data = defaultData;
  await db.write();
}

export default db
EOL

# Update App.jsx with stable state management
cat > $FRONTEND_PATH/src/App.jsx << 'EOL'
import React, { useState, useEffect } from 'react';
import './App.css';

// Define constant initial data
const INITIAL_SUBJECTS = [
  { 
    id: 1, 
    title: 'Kubernetes',
    emoji: '🚢',
    votes: { up: 0, down: 0 }
  },
  { 
    id: 2, 
    title: 'AWS Cloud',
    emoji: '☁️',
    votes: { up: 0, down: 0 }
  },
  { 
    id: 3, 
    title: 'Ubuntu Linux',
    emoji: '🐧',
    votes: { up: 0, down: 0 }
  },
  { 
    id: 4, 
    title: 'LangChain',
    emoji: '🔗',
    votes: { up: 0, down: 0 }
  }
];

function App() {
  const [subjects, setSubjects] = useState(INITIAL_SUBJECTS);
  const [loading, setLoading] = useState(false);  // Start as false since we have initial data
  const [error, setError] = useState(null);

  useEffect(() => {
    // Only update from backend if vote counts change
    const fetchSubjects = async () => {
      try {
        const response = await fetch('http://localhost:3001/subjects');
        const data = await response.json();
        if (data && Array.isArray(data)) {
          // Merge backend data with initial data, keeping emojis
          const updatedSubjects = subjects.map(subject => {
            const backendSubject = data.find(s => s.id === subject.id);
            return backendSubject ? {
              ...subject,
              votes: backendSubject.votes,
              lastUpdated: backendSubject.lastUpdated
            } : subject;
          });
          setSubjects(updatedSubjects);
        }
      } catch (err) {
        console.error('Fetch error:', err);
        // Don't set error - keep showing initial data
      }
    };

    fetchSubjects();
    // Poll for updates every 5 seconds
    const interval = setInterval(fetchSubjects, 5000);
    return () => clearInterval(interval);
  }, []);

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
        if (result.subjects) {
          // Merge vote results with existing subjects
          const updatedSubjects = subjects.map(subject => {
            const updatedSubject = result.subjects.find(s => s.id === subject.id);
            return updatedSubject ? {
              ...subject,
              votes: updatedSubject.votes,
              lastUpdated: updatedSubject.lastUpdated
            } : subject;
          });
          setSubjects(updatedSubjects);
        }
      }
    } catch (err) {
      console.error('Vote error:', err);
      // Show error but keep current state
      setError('Failed to record vote');
      setTimeout(() => setError(null), 3000); // Clear error after 3 seconds
    }
  };

  if (loading) return <div className="loading">Loading subjects...</div>;

  return (
    <div className="app">
      <h1>KAUL2 Topic Voting</h1>
      {error && <div className="error">{error}</div>}
      <div className="subjects">
        {subjects.map(subject => (
          <div key={subject.id} className="subject-card">
            <div className="subject-emoji">
              {subject.emoji}
            </div>
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
              {subject.lastUpdated ? 
                `Last vote: ${new Date(subject.lastUpdated).toLocaleTimeString()}` : 
                'No votes yet'}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

export default App;
EOL

# Update App.css to improve emoji display
cat > $FRONTEND_PATH/src/App.css << 'EOL'
.app {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

h1 {
  text-align: center;
  color: #333;
  margin-bottom: 30px;
  font-size: 2.5em;
}

.subjects {
  display: grid;
  grid-template-columns: repeat(2, 1fr);  /* Force 2 columns */
  gap: 25px;
  padding: 20px;
  max-width: 900px;
  margin: 0 auto;
}

.subject-card {
  border: 1px solid #ddd;
  border-radius: 12px;
  padding: 20px;
  background: white;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  transition: all 0.3s ease;
  display: flex;
  flex-direction: column;
  height: 250px;
  justify-content: space-between;
  align-items: center;
}

.subject-emoji {
  font-size: 4em;
  margin: 10px 0;
  text-align: center;
  transition: transform 0.3s ease;
  display: flex;
  justify-content: center;
  align-items: center;
  height: 80px;
  width: 100%;
}

.subject-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
  border-color: #2196f3;
}

.subject-card:hover .subject-emoji {
  transform: scale(1.1);
}

.subject-card h2 {
  margin: 0 0 15px 0;
  color: #2c3e50;
  font-size: 1.4em;
  text-align: center;
}

.vote-buttons {
  display: flex;
  justify-content: center;
  gap: 20px;
  margin-top: auto;
  padding: 10px 0;
}

button {
  padding: 12px 24px;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 1.2em;
  font-weight: 500;
}

.vote-up {
  background: #e8f5e9;
  color: #2e7d32;
}

.vote-down {
  background: #ffebee;
  color: #c62828;
}

button:hover {
  transform: scale(1.05);
  filter: brightness(1.1);
}

button:active {
  transform: scale(0.95);
}

.last-updated {
  margin-top: 15px;
  font-size: 0.8em;
  color: #666;
  text-align: center;
}

.loading, .error {
  text-align: center;
  padding: 20px;
  margin: 20px;
  border-radius: 12px;
  font-size: 1.2em;
  animation: fadeIn 0.3s ease;
}

.loading {
  background: #e3f2fd;
  color: #1976d2;
}

.error {
  background: #ffebee;
  color: #c62828;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(-10px); }
  to { opacity: 1; transform: translateY(0); }
}

@media (max-width: 768px) {
  .subjects {
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 15px;
    padding: 10px;
  }
  
  .subject-card {
    height: 230px;
  }

  .subject-emoji {
    font-size: 3em;
  }

  h1 {
    font-size: 2em;
  }

  button {
    padding: 10px 20px;
    font-size: 1.1em;
  }
}
EOL

# Create test runner for phase 2.7
cat > $BASE_PATH/project_setup/scripts/test/run_test_phase02_07.sh << 'EOL'
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

chmod +x $BASE_PATH/project_setup/scripts/test/run_test_phase02_07.sh

echo "Setup complete! To run the enhanced UI version:"
echo "1. From $BASE_PATH:"
echo "   ./project_setup/scripts/test/run_test_phase02_07.sh" 