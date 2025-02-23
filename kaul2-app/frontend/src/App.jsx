import React, { useState, useEffect } from 'react';
import './App.css';

function App() {
  const [subjects, setSubjects] = useState([]);
  const [selectedUser, setSelectedUser] = useState('user1');
  const [userPoints, setUserPoints] = useState({});
  const [userProfiles, setUserProfiles] = useState([]);
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
      setUserProfiles(data.userProfiles || []);
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

  const calculatePointsStats = () => {
    const user = userPoints[selectedUser] || { 
      points: 100, 
      upVoteRewards: {}, 
      downVoteRewards: {} 
    };
    
    // Calculate rewards
    const totalUpVoteRewards = Object.values(user.upVoteRewards || {})
      .reduce((sum, reward) => sum + reward, 0);
    const totalDownVoteRewards = Object.values(user.downVoteRewards || {})
      .reduce((sum, reward) => sum + reward, 0);
    
    // Calculate donations (votes made by this user)
    const donatedPoints = subjects.reduce((total, subject) => {
      const userVotes = subject.voterHistory?.filter(vote => vote.userId === selectedUser) || [];
      return total + (userVotes.length * 10); // Each vote costs 10 points
    }, 0);

    // Calculate donations by type
    const upVoteDonations = subjects.reduce((total, subject) => {
      const userUpVotes = subject.voterHistory?.filter(
        vote => vote.userId === selectedUser && vote.voteType === 'up'
      ) || [];
      return total + (userUpVotes.length * 10);
    }, 0);

    const downVoteDonations = subjects.reduce((total, subject) => {
      const userDownVotes = subject.voterHistory?.filter(
        vote => vote.userId === selectedUser && vote.voteType === 'down'
      ) || [];
      return total + (userDownVotes.length * 10);
    }, 0);
    
    return {
      current: user.points || 100,
      upVoteRewards: totalUpVoteRewards,
      downVoteRewards: totalDownVoteRewards,
      totalRewards: totalUpVoteRewards + totalDownVoteRewards,
      donatedPoints,
      upVoteDonations,
      downVoteDonations
    };
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
          {userProfiles.map(user => (
            <option key={user.id} value={user.id}>
              {user.avatar} {user.name}
            </option>
          ))}
        </select>
        <div className="user-stats">
          <div className="points-summary">
            <div className="points-row">
              <span>Current Points:</span>
              <span className="points">{calculatePointsStats().current}</span>
            </div>
            
            <div className="section-divider">Rewards Earned</div>
            <div className="points-row">
              <span>From Upvotes:</span>
              <span className="points up-rewards">+{calculatePointsStats().upVoteRewards.toFixed(1)}</span>
            </div>
            <div className="points-row">
              <span>From Downvotes:</span>
              <span className="points down-rewards">+{calculatePointsStats().downVoteRewards.toFixed(1)}</span>
            </div>
            <div className="points-row total">
              <span>Total Rewards:</span>
              <span className="points">+{calculatePointsStats().totalRewards.toFixed(1)}</span>
            </div>

            <div className="section-divider">Points Donated</div>
            <div className="points-row">
              <span>Upvotes Given:</span>
              <span className="points donated-up">-{calculatePointsStats().upVoteDonations}</span>
            </div>
            <div className="points-row">
              <span>Downvotes Given:</span>
              <span className="points donated-down">-{calculatePointsStats().downVoteDonations}</span>
            </div>
            <div className="points-row total-donated">
              <span>Total Donated:</span>
              <span className="points">-{calculatePointsStats().donatedPoints}</span>
            </div>
          </div>
          
          <div className="rewards-breakdown">
            <h3>Rewards by Subject:</h3>
            {Object.entries(userPoints[selectedUser]?.upVoteRewards || {}).map(([subjectId, reward]) => {
              const subject = subjects.find(s => s.id === parseInt(subjectId));
              return reward > 0 && (
                <div key={`up-${subjectId}`} className="reward-item up">
                  <span>👍 {subject?.title || `Subject ${subjectId}`}:</span>
                  <span className="reward-points">+{reward.toFixed(1)}</span>
                </div>
              );
            })}
            {Object.entries(userPoints[selectedUser]?.downVoteRewards || {}).map(([subjectId, reward]) => {
              const subject = subjects.find(s => s.id === parseInt(subjectId));
              return reward > 0 && (
                <div key={`down-${subjectId}`} className="reward-item down">
                  <span>👎 {subject?.title || `Subject ${subjectId}`}:</span>
                  <span className="reward-points">+{reward.toFixed(1)}</span>
                </div>
              );
            })}
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
                    disabled={calculatePointsStats().current < 10}
                  >
                    Vote Up (10 points)
                  </button>
                  <button 
                    onClick={() => handleVote(subject.id, 'down')}
                    className="vote-button vote-down"
                    disabled={calculatePointsStats().current < 10}
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
