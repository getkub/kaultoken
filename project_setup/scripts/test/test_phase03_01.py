from pathlib import Path
import os
import json
from typing import Dict, Any
import shutil

class ProjectSetup:
    def __init__(self, project_name: str, phase: str, task: str):
        self.project_name = project_name
        self.phase = phase
        self.task = task
        self.script_name = f"test_phase{phase}_{task}"
        self.base_path = Path.cwd()
        self.project_path = self.base_path / project_name
        self.backend_path = self.project_path / "backend"
        self.frontend_path = self.project_path / "frontend"
        self.scripts_path = self.base_path / "project_setup" / "scripts" / "test"

    def create_directories(self):
        """Create necessary directories"""
        self.backend_path.mkdir(parents=True, exist_ok=True)
        self.scripts_path.mkdir(parents=True, exist_ok=True)
        print(f"Created directories at {self.backend_path}")

    def generate_db_code(self, template: Dict[str, Any]) -> str:
        """Generate the db.js code"""
        return f"""import {{ Low }} from 'lowdb'
import {{ JSONFile }} from 'lowdb/node'
import path from 'path'
import {{ fileURLToPath }} from 'url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const dbPath = path.join(__dirname, 'db.json')

const defaultData = {json.dumps(template, indent=2)}

const adapter = new JSONFile(dbPath)
const db = new Low(adapter, defaultData)

// Initialize database with default data
await db.read()
if (!db.data) {{
    db.data = defaultData
    await db.write()
}}

// Ensure users object exists
if (!db.data.users) {{
    db.data.users = {{}}
    await db.write()
}}

export default db
"""

    def create_db_file(self):
        """Create db.js with template"""
        db_template = {
            "subjects": [
                {
                    "id": 1,
                    "title": "Kubernetes",
                    "emoji": "🚢",
                    "votes": {"up": 0, "down": 0},
                    "voterHistory": [],
                    "lastUpdated": "2024-01-01T00:00:00.000Z"
                },
                {
                    "id": 2,
                    "title": "AWS Cloud",
                    "emoji": "☁️",
                    "votes": {"up": 0, "down": 0},
                    "voterHistory": [],
                    "lastUpdated": "2024-01-01T00:00:00.000Z"
                },
                {
                    "id": 3,
                    "title": "Ubuntu Linux",
                    "emoji": "🐧",
                    "votes": {"up": 0, "down": 0},
                    "voterHistory": [],
                    "lastUpdated": "2024-01-01T00:00:00.000Z"
                },
                {
                    "id": 4,
                    "title": "LangChain",
                    "emoji": "🔗",
                    "votes": {"up": 0, "down": 0},
                    "voterHistory": [],
                    "lastUpdated": "2024-01-01T00:00:00.000Z"
                }
            ],
            "users": {}
        }
        
        db_code = self.generate_db_code(db_template)
        db_file = self.backend_path / "db.js"
        db_file.write_text(db_code)
        print(f"Created db.js at {db_file}")

    def create_handler_file(self):
        """Create handler.js with business logic"""
        handler_code = """import db from './db.js'

const VOTE_COST = 10
const INITIAL_POINTS = 100

// Helper to initialize or get user
const initializeUser = (userId) => {
  if (!db.data.users[userId]) {
    db.data.users[userId] = {
      points: INITIAL_POINTS,
      rewards: {}
    }
  }
  return db.data.users[userId]
}

// Helper to distribute rewards
const distributeRewards = (subjectId, votePoints) => {
  const subject = db.data.subjects.find(s => s.id === subjectId)
  if (!subject || !subject.voterHistory.length) return

  subject.voterHistory.forEach((voter, index) => {
    const rewardShare = votePoints / Math.pow(2, index + 1)
    const user = initializeUser(voter.userId)
    if (!user.rewards[subjectId]) user.rewards[subjectId] = 0
    user.rewards[subjectId] += rewardShare
  })
}

export const getSubjects = async (event) => {
  try {
    await db.read()
    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({
        subjects: db.data.subjects,
        users: db.data.users
      })
    }
  } catch (error) {
    console.error('Error:', error)
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({ error: 'Failed to read data' })
    }
  }
}

export const recordVote = async (event) => {
  try {
    const { id, voteType, userId } = JSON.parse(event.body)
    await db.read()
    
    const user = initializeUser(userId)
    if (user.points < VOTE_COST) {
      throw new Error('Not enough points to vote')
    }

    // Find and validate subject
    const subject = db.data.subjects.find(s => s.id === id)
    if (!subject) {
      throw new Error(`Subject not found`)
    }

    // Initialize voterHistory if it doesn't exist
    if (!subject.voterHistory) {
      subject.voterHistory = []
    }

    // Initialize votes if they don't exist
    if (!subject.votes) {
      subject.votes = { up: 0, down: 0 }
    }

    // Deduct points from user
    user.points -= VOTE_COST

    // Record vote
    subject.votes[voteType] = (subject.votes[voteType] || 0) + 1
    subject.lastUpdated = new Date().toISOString()
    
    // Add to voter history
    subject.voterHistory.push({
      userId,
      timestamp: new Date().toISOString(),
      points: VOTE_COST
    })

    // Distribute rewards
    distributeRewards(id, VOTE_COST)
    
    // Save changes
    await db.write()

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({ 
        success: true, 
        subjects: db.data.subjects,
        user: user
      })
    }
  } catch (error) {
    console.error('Error:', error)
    return {
      statusCode: 400,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({ 
        success: false, 
        error: error.message 
      })
    }
  }
}

// OPTIONS handler for CORS
export const options = async (event) => {
  return {
    statusCode: 200,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type'
    },
    body: JSON.stringify({})
  }
}"""
        handler_file = self.backend_path / "handler.js"
        handler_file.write_text(handler_code)
        print(f"Created handler.js at {handler_file}")

    def create_app_file(self):
        """Create App.jsx with user selection and points display"""
        app_code = """import React, { useState, useEffect } from 'react';
import './App.css';

const USERS = ['user1', 'user2', 'user3', 'user4'];

function App() {
  const [subjects, setSubjects] = useState([]);
  const [selectedUser, setSelectedUser] = useState('user1');
  const [userPoints, setUserPoints] = useState({});
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchSubjects();
  }, [selectedUser]);

  const fetchSubjects = async () => {
    try {
      setLoading(true);
      const response = await fetch('http://localhost:3001/subjects');
      const data = await response.json();
      console.log('Fetched data:', data);  // Debug log
      setSubjects(data.subjects || []);
      setUserPoints(data.users || {});
    } catch (error) {
      console.error('Error fetching subjects:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleVote = async (subjectId, voteType) => {
    try {
      const response = await fetch('http://localhost:3001/vote', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          id: subjectId,
          voteType,
          userId: selectedUser
        })
      });
      const data = await response.json();
      console.log('Vote response:', data);  // Debug log
      
      if (data.success) {
        setSubjects(data.subjects);
        setUserPoints(prev => ({
          ...prev,
          [selectedUser]: data.user
        }));
      } else {
        alert(data.error || 'Failed to vote');
      }
    } catch (error) {
      console.error('Error voting:', error);
      alert('Error voting: ' + error.message);
    }
  };

  const getCurrentUserPoints = () => {
    const user = userPoints[selectedUser];
    return user ? user.points : 100;
  };

  const getCurrentUserRewards = () => {
    const user = userPoints[selectedUser];
    return user ? (user.rewards || {}) : {};
  };

  if (loading) {
    return <div className="loading">Loading...</div>;
  }

  return (
    <div className="app">
      <div className="user-panel">
        <h2>User Selection</h2>
        <select 
          value={selectedUser} 
          onChange={(e) => setSelectedUser(e.target.value)}
          className="user-select"
        >
          {USERS.map(user => (
            <option key={user} value={user}>{user}</option>
          ))}
        </select>
        <div className="user-stats">
          <h3>Current Points: {getCurrentUserPoints()}</h3>
          <div className="rewards">
            <h3>Rewards Earned:</h3>
            {Object.entries(getCurrentUserRewards()).map(([subjectId, reward]) => (
              <div key={subjectId} className="reward-item">
                Subject {subjectId}: {Number(reward).toFixed(1)} points
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="main-content">
        <h1>Subject Voting System</h1>
        {subjects.length === 0 ? (
          <div className="no-subjects">No subjects available</div>
        ) : (
          <div className="subjects-grid">
            {subjects.map(subject => (
              <div key={subject.id} className="subject-card">
                <h2>{subject.title}</h2>
                <div className="emoji">{subject.emoji}</div>
                <div className="votes-display">
                  <span>👍 {subject.votes?.up || 0}</span>
                  <span>👎 {subject.votes?.down || 0}</span>
                </div>
                <div className="vote-buttons">
                  <button 
                    onClick={() => handleVote(subject.id, 'up')}
                    className="vote-button vote-up"
                    disabled={getCurrentUserPoints() < 10}
                  >
                    Vote Up (10 points)
                  </button>
                  <button 
                    onClick={() => handleVote(subject.id, 'down')}
                    className="vote-button vote-down"
                    disabled={getCurrentUserPoints() < 10}
                  >
                    Vote Down (10 points)
                  </button>
                </div>
                <div className="voter-history">
                  <h4>Recent Votes:</h4>
                  {(subject.voterHistory || []).map((vote, index) => (
                    <div key={index} className="vote-record">
                      {vote.userId} voted ({vote.points} points)
                    </div>
                  ))}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

export default App;
"""
        app_css = """
.app {
  display: flex;
  padding: 20px;
  gap: 20px;
  min-height: 100vh;
  background: #f0f2f5;
}

.loading {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 100vh;
  font-size: 1.5em;
}

.user-panel {
  width: 300px;
  padding: 20px;
  background: white;
  border-radius: 12px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  position: sticky;
  top: 20px;
  height: fit-content;
}

.user-select {
  width: 100%;
  padding: 10px;
  margin: 10px 0;
  border: 1px solid #ddd;
  border-radius: 6px;
  font-size: 1em;
}

.user-stats {
  margin-top: 20px;
  padding: 15px;
  background: #f8f9fa;
  border-radius: 8px;
}

.reward-item {
  margin: 8px 0;
  padding: 10px;
  background: white;
  border-radius: 6px;
  box-shadow: 0 1px 2px rgba(0,0,0,0.05);
}

.main-content {
  flex: 1;
  padding: 20px;
}

.subjects-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 20px;
  margin-top: 20px;
}

.subject-card {
  background: white;
  padding: 20px;
  border-radius: 12px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.emoji {
  font-size: 48px;
  text-align: center;
  margin: 15px 0;
}

.votes-display {
  display: flex;
  justify-content: center;
  gap: 20px;
  margin: 10px 0;
  font-size: 1.2em;
}

.vote-buttons {
  display: flex;
  gap: 10px;
  margin: 15px 0;
}

.vote-button {
  flex: 1;
  padding: 10px;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-weight: 500;
  transition: all 0.2s;
}

.vote-button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.vote-up {
  background: #e3f2fd;
  color: #1976d2;
}

.vote-down {
  background: #fce4ec;
  color: #c2185b;
}

.vote-up:hover:not(:disabled) {
  background: #bbdefb;
}

.vote-down:hover:not(:disabled) {
  background: #f8bbd0;
}

.voter-history {
  margin-top: 20px;
  padding-top: 15px;
  border-top: 1px solid #eee;
}

.vote-record {
  padding: 8px;
  margin: 5px 0;
  background: #f8f9fa;
  border-radius: 4px;
  font-size: 0.9em;
}

.no-subjects {
  text-align: center;
  padding: 40px;
  font-size: 1.2em;
  color: #666;
}
"""
        # Create frontend directory if it doesn't exist
        frontend_path = self.frontend_path / "src"
        frontend_path.mkdir(parents=True, exist_ok=True)

        # Write App.jsx
        app_file = frontend_path / "App.jsx"
        app_file.write_text(app_code)
        print(f"Created App.jsx at {app_file}")

        # Write App.css
        css_file = frontend_path / "App.css"
        css_file.write_text(app_css)
        print(f"Created App.css at {css_file}")

    def create_run_script(self):
        """Create the bash runner script"""
        run_script_content = f"""#!/bin/bash
# Auto-generated runner for {self.script_name}

# First run the Python setup script
python3 {self.scripts_path}/{self.script_name}.py

if [ $? -ne 0 ]; then
    echo "Python setup failed!"
    exit 1
fi

BASE_PATH="$PWD"
PROJECT_PATH="$BASE_PATH/{self.project_name}"
BACKEND_PATH="$PROJECT_PATH/backend"
FRONTEND_PATH="$PROJECT_PATH/frontend"

echo "Starting servers for {self.project_name}..."

# Kill any existing processes
echo "Cleaning up existing processes..."
lsof -ti:3001 | xargs kill -9 2>/dev/null || true
lsof -ti:5173 | xargs kill -9 2>/dev/null || true

# Install dependencies if needed
if [ ! -d "$BACKEND_PATH/node_modules" ]; then
    echo "Installing backend dependencies..."
    cd $BACKEND_PATH && npm install
fi

if [ ! -d "$FRONTEND_PATH/node_modules" ]; then
    echo "Installing frontend dependencies..."
    cd $FRONTEND_PATH && npm install
fi

# Start servers
echo "Starting backend server..."
cd $BACKEND_PATH && npm run dev &
BACKEND_PID=$!

echo "Starting frontend server..."
cd $FRONTEND_PATH && npm run dev &
FRONTEND_PID=$!

# Handle termination
trap "kill $BACKEND_PID $FRONTEND_PID" SIGINT SIGTERM EXIT

echo "🚀 Servers started!"
echo "📱 Frontend: http://localhost:5173"
echo "⚙️  Backend: http://localhost:3001"
echo ""
echo "Points System:"
echo "- Each user starts with 100 points"
echo "- Each vote costs 10 points"
echo "- Rewards are distributed in pyramid scheme:"
echo "  * First voter: 50% of future vote points"
echo "  * Second voter: 25% of future vote points"
echo "  * Third voter: 12.5% of future vote points"
echo ""
echo "Press Ctrl+C to stop all servers"

wait
"""
        run_script_path = self.scripts_path / f"run_{self.script_name}.sh"
        run_script_path.write_text(run_script_content)
        run_script_path.chmod(0o755)  # Make executable
        print(f"Created runner script at {run_script_path}")

    def setup(self):
        """Main setup method"""
        try:
            print(f"Setting up {self.project_name}...")
            self.create_directories()
            self.create_db_file()
            self.create_handler_file()
            self.create_app_file()
            self.create_run_script()
            print("\nSetup completed successfully!")
            print("\nYou can now run:")
            print(f"bash ./project_setup/scripts/test/run_{self.script_name}.sh")
        except Exception as e:
            print(f"Error during setup: {e}")
            raise

if __name__ == "__main__":
    setup = ProjectSetup(
        project_name="kaul2-app",
        phase="03",
        task="01"
    )
    setup.setup() 