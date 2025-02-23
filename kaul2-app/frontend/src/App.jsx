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
