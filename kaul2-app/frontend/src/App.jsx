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
