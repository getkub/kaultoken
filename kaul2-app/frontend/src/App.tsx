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
