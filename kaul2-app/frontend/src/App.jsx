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
