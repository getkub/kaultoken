#!/bin/bash

PROJECT_NAME="kaul2-app"
BASE_PATH="$PWD"
PROJECT_PATH="$BASE_PATH/$PROJECT_NAME"

# Create React component files
mkdir -p $PROJECT_PATH/frontend/src/components/{SubjectList,SubjectCard,VoteButton}

# Create React components
cat > $PROJECT_PATH/frontend/src/components/SubjectList/index.tsx << 'EOL'
import React, { useEffect, useState } from 'react';
import { Subject } from '../../../../shared/types';
import { SubjectService } from '../../services/SubjectService';
import SubjectCard from '../SubjectCard';
import './styles.css';

const SubjectList: React.FC = () => {
  const [subjects, setSubjects] = useState<Subject[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadSubjects();
  }, []);

  const loadSubjects = async () => {
    try {
      const data = await SubjectService.getSubjects();
      setSubjects(data);
    } catch (error) {
      console.error('Failed to load subjects:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) return <div>Loading subjects...</div>;

  return (
    <div className="subject-list">
      {subjects.map(subject => (
        <SubjectCard 
          key={subject.id} 
          subject={subject}
          onVoteUpdate={(newVotes) => {
            setSubjects(prev => 
              prev.map(s => 
                s.id === subject.id 
                  ? { ...s, votes: newVotes }
                  : s
              )
            );
          }}
        />
      ))}
    </div>
  );
};

export default SubjectList;
EOL

cat > $PROJECT_PATH/frontend/src/components/SubjectCard/index.tsx << 'EOL'
import React, { useState } from 'react';
import { Subject, VoteCount } from '../../../../shared/types';
import VoteButton from '../VoteButton';
import './styles.css';

interface Props {
  subject: Subject;
  onVoteUpdate: (newVotes: VoteCount) => void;
}

const SubjectCard: React.FC<Props> = ({ subject, onVoteUpdate }) => {
  const [isVoting, setIsVoting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleVote = async (isUpvote: boolean) => {
    setIsVoting(true);
    setError(null);

    try {
      // Mock wallet connection and vote
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // Optimistically update the UI
      const newVotes = {
        upvotes: subject.votes.upvotes + (isUpvote ? 1 : 0),
        downvotes: subject.votes.downvotes + (isUpvote ? 0 : 1)
      };
      
      onVoteUpdate(newVotes);
    } catch (err) {
      setError('Failed to process vote. Please try again.');
    } finally {
      setIsVoting(false);
    }
  };

  return (
    <div className="subject-card">
      <h3>{subject.title}</h3>
      <p>{subject.description}</p>
      <div className="vote-section">
        <VoteButton
          type="up"
          count={subject.votes.upvotes}
          onClick={() => handleVote(true)}
          disabled={isVoting}
        />
        <VoteButton
          type="down"
          count={subject.votes.downvotes}
          onClick={() => handleVote(false)}
          disabled={isVoting}
        />
      </div>
      {isVoting && <div className="loading">Processing vote...</div>}
      {error && <div className="error">{error}</div>}
    </div>
  );
};

export default SubjectCard;
EOL

cat > $PROJECT_PATH/frontend/src/components/VoteButton/index.tsx << 'EOL'
import React from 'react';
import './styles.css';

interface Props {
  type: 'up' | 'down';
  count: number;
  onClick: () => void;
  disabled?: boolean;
}

const VoteButton: React.FC<Props> = ({ type, count, onClick, disabled }) => {
  return (
    <button 
      className={`vote-button ${type} ${disabled ? 'disabled' : ''}`}
      onClick={onClick}
      disabled={disabled}
    >
      {type === 'up' ? '👍' : '👎'} {count}
    </button>
  );
};

export default VoteButton;
EOL

# Create styles
cat > $PROJECT_PATH/frontend/src/components/SubjectList/styles.css << 'EOL'
.subject-list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 20px;
  padding: 20px;
}
EOL

cat > $PROJECT_PATH/frontend/src/components/SubjectCard/styles.css << 'EOL'
.subject-card {
  border: 1px solid #ddd;
  border-radius: 8px;
  padding: 16px;
  background: white;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.vote-section {
  display: flex;
  gap: 16px;
  margin-top: 16px;
}

.loading {
  margin-top: 8px;
  color: #666;
  font-size: 14px;
}

.error {
  margin-top: 8px;
  color: #ff4444;
  font-size: 14px;
}
EOL

cat > $PROJECT_PATH/frontend/src/components/VoteButton/styles.css << 'EOL'
.vote-button {
  padding: 8px 16px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  gap: 8px;
}

.vote-button.up {
  background: #e8f5e9;
  color: #2e7d32;
}

.vote-button.down {
  background: #ffebee;
  color: #c62828;
}

.vote-button:hover:not(.disabled) {
  transform: translateY(-2px);
}

.vote-button.disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
EOL

# Create mock data service
cat > $PROJECT_PATH/frontend/src/services/mockData.ts << 'EOL'
import { Subject } from '../../../shared/types';

export const mockSubjects: Subject[] = [
  {
    id: '1',
    title: 'First Test Subject',
    description: 'This is a test subject for demonstration',
    walletAddress: '0x123...abc',
    votes: { upvotes: 10, downvotes: 2 },
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  },
  {
    id: '2',
    title: 'Second Test Subject',
    description: 'Another test subject with different votes',
    walletAddress: '0x456...def',
    votes: { upvotes: 5, downvotes: 1 },
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  },
];
EOL

echo "Mock screen components created successfully!" 