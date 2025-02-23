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