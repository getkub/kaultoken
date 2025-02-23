#!/bin/bash

PROJECT_NAME="kaul2-app"
BASE_PATH="$PWD"
PROJECT_PATH="$BASE_PATH/$PROJECT_NAME"
FRONTEND_PATH="$PROJECT_PATH/frontend"

# Setup frontend with Vite + React
# Using --prefix to run npm commands from BASE_PATH
npm --prefix $FRONTEND_PATH install

# Create package.json
cat > $FRONTEND_PATH/package.json << 'EOL'
{
  "name": "kaul2-frontend",
  "private": true,
  "version": "0.0.1",
  "type": "module",
  "scripts": {
    "dev": "vite",
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

# Create main App component
cat > $FRONTEND_PATH/src/App.jsx << 'EOL'
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';

function App() {
  const [subjects, setSubjects] = useState([
    { id: 1, title: 'First Subject', votes: { up: 0, down: 0 } },
    { id: 2, title: 'Second Subject', votes: { up: 0, down: 0 } }
  ]);

  const handleVote = (id, type) => {
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
  };

  return (
    <div className="app">
      <h1>Kaul2 Voting Demo</h1>
      <div className="subjects">
        {subjects.map(subject => (
          <div key={subject.id} className="subject-card">
            <h2>{subject.title}</h2>
            <div className="vote-buttons">
              <button onClick={() => handleVote(subject.id, 'up')}>
                👍 {subject.votes.up}
              </button>
              <button onClick={() => handleVote(subject.id, 'down')}>
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

# Create CSS styles
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
  background: #f0f0f0;
  cursor: pointer;
  transition: background 0.2s;
}

button:hover {
  background: #e0e0e0;
}
EOL

# Create index.html
cat > $FRONTEND_PATH/index.html << 'EOL'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Kaul2 Voting Demo</title>
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

echo "Frontend setup complete! To start the app from any directory:"
echo "1. From $BASE_PATH:"
echo "   npm --prefix $PROJECT_NAME/frontend run dev"
echo ""
echo "2. Or create a test runner script:"

# Create a test runner that uses --prefix
mkdir -p $BASE_PATH/project_setup/scripts/test
cat > $BASE_PATH/project_setup/scripts/test/run_test_phase02_02.sh << 'EOL'
#!/bin/bash

BASE_PATH="$PWD"
PROJECT_PATH="$BASE_PATH/kaul2-app"

echo "Starting frontend development server..."
npm --prefix $PROJECT_PATH/frontend run dev
EOL

chmod +x $BASE_PATH/project_setup/scripts/test/run_test_phase02_02.sh

echo "3. Then run:"
echo "   ./project_setup/scripts/test/run_test_phase02_02.sh" 