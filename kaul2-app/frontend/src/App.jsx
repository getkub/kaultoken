import React, { useState, useEffect } from 'react';
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
