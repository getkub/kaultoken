#!/bin/bash

PROJECT_NAME="kaul2-app"
BASE_PATH="$PWD"
PROJECT_PATH="$BASE_PATH/$PROJECT_NAME"
FRONTEND_PATH="$PROJECT_PATH/frontend"

# Remove existing frontend directory content
rm -rf $FRONTEND_PATH/*

# Initialize frontend with Vite + React + TypeScript
cd $FRONTEND_PATH
npm create vite@latest . -- --template react-ts --force

# Install dependencies with legacy peer deps to avoid conflicts
cd $FRONTEND_PATH
npm install --legacy-peer-deps \
  axios@^1.4.0 \
  @types/node@^20.2.5 \
  @types/react@^18.2.7 \
  @types/react-dom@^18.2.4 \
  classnames@^2.3.2 \
  react@^18.2.0 \
  react-dom@^18.2.0 \
  react-query@^3.39.3

# Return to original directory
cd $BASE_PATH

# Create main App component
cat > $FRONTEND_PATH/src/App.tsx << 'EOL'
import React from 'react';
import SubjectList from './components/SubjectList';
import './App.css';

function App() {
  return (
    <div className="app">
      <header className="app-header">
        <h1>Subject Voting Demo</h1>
      </header>
      <main>
        <SubjectList />
      </main>
    </div>
  );
}

export default App;
EOL

# Update App.css
cat > $PROJECT_PATH/frontend/src/App.css << 'EOL'
.app {
  min-height: 100vh;
  background-color: #f5f5f5;
}

.app-header {
  background-color: #ffffff;
  padding: 1rem 2rem;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.app-header h1 {
  margin: 0;
  font-size: 1.5rem;
  color: #333;
}

main {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;
}
EOL

# Update index.css
cat > $PROJECT_PATH/frontend/src/index.css << 'EOL'
:root {
  font-family: Inter, system-ui, Avenir, Helvetica, Arial, sans-serif;
  line-height: 1.5;
  font-weight: 400;
}

* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

body {
  margin: 0;
  min-width: 320px;
  min-height: 100vh;
}
EOL

# Create environment files
cat > $PROJECT_PATH/frontend/.env.development << 'EOL'
VITE_API_URL=http://localhost:3000/api/v1
EOL

cat > $PROJECT_PATH/frontend/.env.production << 'EOL'
VITE_API_URL=/api/v1
EOL

# Update package.json scripts
cat > $PROJECT_PATH/frontend/package.json << 'EOL'
{
  "name": "subject-voting-frontend",
  "private": true,
  "version": "0.0.1",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "lint": "eslint src --ext ts,tsx --report-unused-disable-directives --max-warnings 0",
    "preview": "vite preview",
    "test": "vitest"
  },
  "dependencies": {
    "axios": "^1.4.0",
    "classnames": "^2.3.2",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-query": "^3.39.3"
  },
  "devDependencies": {
    "@types/node": "^20.2.5",
    "@types/react": "^18.2.7",
    "@types/react-dom": "^18.2.4",
    "@typescript-eslint/eslint-plugin": "^5.59.7",
    "@typescript-eslint/parser": "^5.59.7",
    "@vitejs/plugin-react": "^4.0.0",
    "eslint": "^8.41.0",
    "eslint-plugin-react-hooks": "^4.6.0",
    "eslint-plugin-react-refresh": "^0.4.1",
    "typescript": "^5.0.4",
    "vite": "^4.3.9",
    "vitest": "^0.31.1"
  }
}
EOL

# Create Vite config
cat > $PROJECT_PATH/frontend/vite.config.ts << 'EOL'
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
      '@shared': path.resolve(__dirname, '../shared'),
    },
  },
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:3001',
        changeOrigin: true,
      },
    },
  },
});
EOL

# Create TypeScript config
cat > $PROJECT_PATH/frontend/tsconfig.json << 'EOL'
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"],
      "@shared/*": ["../shared/*"]
    }
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
EOL

# Create TypeScript Node config
cat > $PROJECT_PATH/frontend/tsconfig.node.json << 'EOL'
{
  "compilerOptions": {
    "composite": true,
    "skipLibCheck": true,
    "module": "ESNext",
    "moduleResolution": "bundler",
    "allowSyntheticDefaultImports": true
  },
  "include": ["vite.config.ts"]
}
EOL

echo "React project setup completed!"
echo "To start the development server:"
echo "1. cd $PROJECT_PATH/frontend"
echo "2. npm install"
echo "3. npm run dev" 