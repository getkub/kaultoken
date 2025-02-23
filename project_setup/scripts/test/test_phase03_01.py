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

    def create_db_files(self):
        """Create separate db files for subjects and users"""
        
        # subjects.js
        subjects_db_code = """import { Low } from 'lowdb'
import { JSONFile } from 'lowdb/node'
import path from 'path'
import { fileURLToPath } from 'url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const dbPath = path.join(__dirname, 'subjects.json')

const defaultData = {
  subjects: [
    { 
      id: 1, 
      title: 'Kubernetes',
      emoji: '🚢',
      votes: { up: 0, down: 0 },
      voterHistory: [],
      lastUpdated: new Date().toISOString()
    },
    { 
      id: 2, 
      title: 'AWS Cloud',
      emoji: '☁️',
      votes: { up: 0, down: 0 },
      voterHistory: [],
      lastUpdated: new Date().toISOString()
    },
    { 
      id: 3, 
      title: 'Ubuntu Linux',
      emoji: '🐧',
      votes: { up: 0, down: 0 },
      voterHistory: [],
      lastUpdated: new Date().toISOString()
    },
    { 
      id: 4, 
      title: 'LangChain',
      emoji: '🔗',
      votes: { up: 0, down: 0 },
      voterHistory: [],
      lastUpdated: new Date().toISOString()
    }
  ]
}

const subjectsDb = new Low(new JSONFile(dbPath), defaultData)

// Initialize database
await subjectsDb.read()
if (!subjectsDb.data) {
  subjectsDb.data = defaultData
  await subjectsDb.write()
}

export default subjectsDb
"""

        # users.js
        users_db_code = """import { Low } from 'lowdb'
import { JSONFile } from 'lowdb/node'
import path from 'path'
import { fileURLToPath } from 'url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const dbPath = path.join(__dirname, 'users.json')

const defaultData = {
  profiles: [
    { id: 'user1', name: 'Alice', avatar: '👩‍💻' },
    { id: 'user2', name: 'Bob', avatar: '👨‍💻' },
    { id: 'user3', name: 'Charlie', avatar: '🧑‍💻' },
    { id: 'user4', name: 'Diana', avatar: '👩‍🔬' }
  ],
  points: {}  // Stores points and rewards for each user
}

const usersDb = new Low(new JSONFile(dbPath), defaultData)

// Initialize database
await usersDb.read()
if (!usersDb.data) {
  usersDb.data = defaultData
  await usersDb.write()
}

export default usersDb
"""

        # Write the files
        backend_path = self.backend_path
        backend_path.mkdir(parents=True, exist_ok=True)
        
        (backend_path / "subjects.js").write_text(subjects_db_code)
        (backend_path / "users.js").write_text(users_db_code)
        print("Created separate database files")

    def create_handler_file(self):
        """Create handler.js with separate db imports"""
        handler_code = """import subjectsDb from './subjects.js'
import usersDb from './users.js'

const VOTE_COST = 10
const INITIAL_POINTS = 100
const MIN_REWARD = 0.000001  // Minimum reward threshold

// Tier configuration for precise distribution
const REWARD_TIERS = {
  TIER1: { max: 10, share: 5, reward: 0.5 },        // First 10: 5 points (0.5 each)
  TIER2: { max: 100, share: 3, reward: 0.033 },     // Next 90: 3 points (0.033 each)
  TIER3: { max: 1000, share: 1.5, reward: 0.00167 }, // Next 900: 1.5 points (0.00167 each)
  TIER4: { max: 10000, share: 0.5, reward: 0.000056 } // Next 9000: 0.5 points (0.000056 each)
}

const initializeUser = (userId) => {
  if (!usersDb.data.points[userId]) {
    usersDb.data.points[userId] = {
      points: INITIAL_POINTS,
      upVoteRewards: {},
      downVoteRewards: {},
      rewardHistory: []
    }
  }
  return usersDb.data.points[userId]
}

const calculateRewardForPosition = (position) => {
  // Exact reward based on position tier
  if (position <= REWARD_TIERS.TIER1.max) {
    return REWARD_TIERS.TIER1.reward
  } else if (position <= REWARD_TIERS.TIER2.max) {
    return REWARD_TIERS.TIER2.reward
  } else if (position <= REWARD_TIERS.TIER3.max) {
    return REWARD_TIERS.TIER3.reward
  } else if (position <= REWARD_TIERS.TIER4.max) {
    return REWARD_TIERS.TIER4.reward
  }
  return 0
}

const distributeRewards = async (subjectId, voteType, currentVoterId) => {
  try {
    const subject = subjectsDb.data.subjects.find(s => s.id === subjectId)
    if (!subject || !subject.voterHistory) return

    // Get previous voters of the same type
    const previousVoters = subject.voterHistory
      .filter(vote => 
        vote.voteType === voteType && 
        vote.userId !== currentVoterId
      )

    console.log(`\nDistributing ${voteType} rewards for subject ${subjectId}`)
    console.log(`Current voter: ${currentVoterId}`)
    console.log(`Previous voters: ${previousVoters.length}`)

    let totalDistributed = 0
    
    // Calculate and distribute rewards
    for (let i = 0; i < previousVoters.length; i++) {
      const voter = previousVoters[i]
      const position = i + 1
      const rewardShare = calculateRewardForPosition(position)
      
      if (rewardShare < MIN_REWARD) {
        console.log(`Reward too small (${rewardShare}), stopping distribution`)
        break
      }

      const user = initializeUser(voter.userId)
      const rewardCategory = voteType === 'up' ? 'upVoteRewards' : 'downVoteRewards'
      
      if (!user[rewardCategory][String(subjectId)]) {
        user[rewardCategory][String(subjectId)] = 0
      }
      
      user[rewardCategory][String(subjectId)] += rewardShare
      user.points += rewardShare
      totalDistributed += rewardShare

      // Record reward in history
      user.rewardHistory.push({
        timestamp: new Date().toISOString(),
        subjectId: String(subjectId),
        amount: rewardShare,
        fromUser: currentVoterId,
        voteType: voteType,
        position: position,
        tier: position <= 10 ? 1 : position <= 100 ? 2 : position <= 1000 ? 3 : 4
      })

      console.log(`Rewarded ${voter.userId} (position ${position}, tier ${position <= 10 ? 1 : position <= 100 ? 2 : position <= 1000 ? 3 : 4}) with ${rewardShare.toFixed(6)} points`)
    }
    
    console.log(`Total points distributed: ${totalDistributed.toFixed(6)} of ${VOTE_COST}`)
    await usersDb.write()
  } catch (error) {
    console.error('Error in distributeRewards:', error)
  }
}

export const getSubjects = async (event) => {
  try {
    await Promise.all([subjectsDb.read(), usersDb.read()])
    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({
        subjects: subjectsDb.data.subjects,
        users: usersDb.data.points,
        userProfiles: usersDb.data.profiles
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
    await Promise.all([subjectsDb.read(), usersDb.read()])
    
    const user = initializeUser(userId)
    if (user.points < VOTE_COST) {
      throw new Error('Not enough points to vote')
    }

    const subject = subjectsDb.data.subjects.find(s => s.id === id)
    if (!subject) {
      throw new Error('Subject not found')
    }

    // Initialize if needed
    if (!subject.votes) subject.votes = { up: 0, down: 0 }
    if (!subject.voterHistory) subject.voterHistory = []

    // Check for duplicate votes
    const hasVoted = subject.voterHistory.some(vote => 
      vote.userId === userId && vote.voteType === voteType
    )
    if (hasVoted) {
      throw new Error('You have already voted this way on this subject')
    }

    // Deduct points first
    user.points -= VOTE_COST

    // Record vote
    subject.votes[voteType]++
    subject.lastUpdated = new Date().toISOString()
    
    // Add to voter history with position
    subject.voterHistory.push({
      userId,
      timestamp: new Date().toISOString(),
      points: VOTE_COST,
      voteType,
      position: subject.voterHistory.length + 1
    })

    // Save changes and distribute rewards
    await Promise.all([
      subjectsDb.write(),
      distributeRewards(id, voteType, userId)
    ])

    // Get updated user data
    await usersDb.read()
    const updatedUser = usersDb.data.points[userId]

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({ 
        success: true, 
        subjects: subjectsDb.data.subjects,
        user: updatedUser,
        message: `Vote recorded! Rewards distributed to previous voters.`
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
        (self.backend_path / "handler.js").write_text(handler_code)
        print("Created handler.js with separate db handling")

    def create_app_file(self):
        """Create App.jsx with user selection and points display"""
        app_code = """import React, { useState, useEffect } from 'react';
import './App.css';

const EMOJIS = {
  UP: '\\u{1F44D}',
  DOWN: '\\u{1F44E}',
  INFO: '\\u{2139}'
};

function SubjectDetail({ subject, onClose, selectedUser }) {
  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleString();
  };

  return (
    <div className="subject-detail-modal">
      <div className="modal-content">
        <div className="modal-header">
          <h2>{subject.title || `Subject ${subject.id}`}</h2>
          <button className="close-button" onClick={onClose}>×</button>
        </div>
        
        <div className="modal-body">
          <div className="vote-stats">
            <div className="stat-item up">
              <span className="emoji">{EMOJIS.UP}</span>
              <span className="stat-value">{subject.votes?.up || 0}</span>
            </div>
            <div className="stat-item down">
              <span className="emoji">{EMOJIS.DOWN}</span>
              <span className="stat-value">{subject.votes?.down || 0}</span>
            </div>
          </div>

          <div className="vote-history">
            <h3>Vote History</h3>
            <div className="vote-list">
              {subject.voterHistory?.slice().reverse().map((vote, index) => (
                <div 
                  key={index} 
                  className={`vote-item ${vote.userId === selectedUser ? 'highlight' : ''}`}
                >
                  <span className="emoji">
                    {vote.voteType === 'up' ? EMOJIS.UP : EMOJIS.DOWN}
                  </span>
                  <span className="voter-id">{vote.userId}</span>
                  <span className="vote-position">#{vote.position}</span>
                  <span className="vote-time">{formatDate(vote.timestamp)}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function App() {
  const [subjects, setSubjects] = useState([]);
  const [selectedUser, setSelectedUser] = useState('user1');
  const [userPoints, setUserPoints] = useState({});
  const [userProfiles, setUserProfiles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedSubject, setSelectedSubject] = useState(null);

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

      <div className="subjects-panel">
        <h2>Subjects</h2>
        <div className="subjects-grid">
          {subjects.map(subject => (
            <div key={subject.id} className="subject-card">
              <div className="subject-image">
                {subject.emoji || '🖼️'}
              </div>
              <h3>{subject.title || `Subject ${subject.id}`}</h3>
              <div className="vote-actions">
                <button 
                  className="vote-button up"
                  onClick={(e) => handleVote(subject.id, 'up')}
                >
                  <span className="emoji">{EMOJIS.UP}</span>
                  <span className="count">{subject.votes?.up || 0}</span>
                </button>
                <button 
                  className="vote-button down"
                  onClick={(e) => handleVote(subject.id, 'down')}
                >
                  <span className="emoji">{EMOJIS.DOWN}</span>
                  <span className="count">{subject.votes?.down || 0}</span>
                </button>
                <button 
                  className="details-button"
                  onClick={() => setSelectedSubject(subject)}
                >
                  <span className="emoji">{EMOJIS.INFO}</span> Details
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>

      {selectedSubject && (
        <SubjectDetail 
          subject={selectedSubject}
          onClose={() => setSelectedSubject(null)}
          selectedUser={selectedUser}
        />
      )}
    </div>
  );
}

export default App;
"""
        app_css = """
.app {
  display: flex;
  padding: 20px;
  gap: 20px;
  min-height: 100vh;
  background: #f0f2f5;
}

.loading {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 100vh;
  font-size: 1.5em;
}

.user-panel {
  width: 300px;
  padding: 20px;
  background: white;
  border-radius: 12px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  position: sticky;
  top: 20px;
  height: fit-content;
}

.user-select {
  width: 100%;
  padding: 10px;
  margin: 10px 0;
  border: 1px solid #ddd;
  border-radius: 6px;
  font-size: 1em;
}

.user-stats {
  margin-top: 20px;
  padding: 15px;
  background: #f8f9fa;
  border-radius: 8px;
}

.points-summary {
  background: white;
  padding: 20px;
  border-radius: 8px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
  margin-bottom: 20px;
}

.points-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 0;
  border-bottom: 1px solid #eee;
}

.points-row:last-child {
  border-bottom: none;
}

.points-row.total {
  margin-top: 8px;
  padding-top: 12px;
  border-top: 2px solid #eee;
  font-weight: bold;
  font-size: 1.1em;
  color: #2196f3;
}

.points {
  font-weight: 500;
}

.reward-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin: 8px 0;
  padding: 10px;
  background: white;
  border-radius: 6px;
  box-shadow: 0 1px 2px rgba(0,0,0,0.05);
}

.reward-points {
  color: #4caf50;
  font-weight: 500;
}

.user-stats h3 {
  margin-top: 0;
  margin-bottom: 15px;
  color: #333;
}

.subjects-panel {
  flex: 1;
  padding: 20px;
}

.subjects-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
  gap: 20px;
  padding: 20px;
}

.subject-card {
  background: white;
  border-radius: 12px;
  padding: 20px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.subject-image {
  font-size: 5em;  /* Increased size for subject emojis */
  text-align: center;
  height: 140px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f8f9fa;
  border-radius: 8px;
  margin-bottom: 10px;
  transition: transform 0.2s;
  cursor: pointer;
}

.subject-image:hover {
  transform: scale(1.05);
  background: #f0f0f0;
}

.vote-actions {
  display: flex;
  gap: 10px;
  margin-top: auto;
}

.emoji {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI Emoji", "Segoe UI Symbol", "Noto Color Emoji", "Android Emoji", EmojiSymbols, "EmojiOne Mozilla", "Twemoji Mozilla", "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
  line-height: 1;
  vertical-align: middle;
  display: inline-block;
}

.subject-image .emoji {
  font-size: 1em;  /* Full size for subject emojis */
}

.vote-button .emoji {
  font-size: 1.4em;  /* Smaller size for vote emojis */
}

.vote-button {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 16px;
  border: 1px solid #eee;
  border-radius: 20px;
  cursor: pointer;
  transition: all 0.2s;
  background: white;
}

.vote-button:hover {
  background: #e3f2fd;
  border-color: #bbdefb;
}

.vote-button .count {
  font-weight: 500;
}

.details-button {
  margin-left: auto;
  padding: 8px 16px;
  border: none;
  border-radius: 20px;
  background: #e3f2fd;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 5px;
}

.details-button:hover {
  background: #bbdefb;
}

.subject-detail-modal {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0,0,0,0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.modal-content {
  background: white;
  border-radius: 8px;
  width: 90%;
  max-width: 600px;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
}

.modal-header {
  padding: 20px;
  border-bottom: 1px solid #eee;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.close-button {
  background: none;
  border: none;
  font-size: 24px;
  cursor: pointer;
  color: #666;
}

.modal-body {
  padding: 20px;
}

.vote-stats {
  display: flex;
  gap: 20px;
  margin-bottom: 20px;
}

.stat-item {
  flex: 1;
  padding: 15px;
  background: #f8f9fa;
  border-radius: 8px;
  text-align: center;
}

.stat-value {
  display: block;
  font-size: 24px;
  font-weight: 500;
  margin-top: 5px;
}

.vote-list {
  max-height: 400px;
  overflow-y: auto;
}

.vote-item {
  display: flex;
  align-items: center;
  gap: 15px;
  padding: 10px;
  border-bottom: 1px solid #eee;
}

.vote-item.highlight {
  background: #fff3e0;
}

.vote-type {
  font-size: 1.2em;
}

.voter-id {
  font-weight: 500;
  flex: 1;
}

.vote-position {
  color: #666;
}

.vote-time {
  color: #666;
  font-size: 0.9em;
}

.rewards-breakdown {
  margin-top: 20px;
  padding: 15px;
  background: white;
  border-radius: 8px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
}

.rewards-breakdown h3 {
  margin-top: 0;
  margin-bottom: 15px;
  color: #333;
}

.section-divider {
  font-weight: 500;
  color: #666;
  padding: 15px 0 5px 0;
  border-bottom: 1px solid #eee;
  margin-bottom: 10px;
}

.points-row .donated-up {
  color: #2196f3;
}

.points-row .donated-down {
  color: #f44336;
}

.total-donated {
  margin-top: 8px;
  padding-top: 8px;
  border-top: 1px dashed #eee;
  font-weight: 500;
  color: #e91e63;
}
"""
        # Create frontend directory if it doesn't exist
        frontend_path = self.frontend_path / "src"
        frontend_path.mkdir(parents=True, exist_ok=True)

        # Write App.jsx
        app_file = frontend_path / "App.jsx"
        app_file.write_text(app_code)
        print(f"Created App.jsx at {app_file}")

        # Write App.css
        css_file = frontend_path / "App.css"
        css_file.write_text(app_css)
        print(f"Created App.css at {css_file}")

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
            self.create_db_files()
            self.create_handler_file()
            self.create_app_file()
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