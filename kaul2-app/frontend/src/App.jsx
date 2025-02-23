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
