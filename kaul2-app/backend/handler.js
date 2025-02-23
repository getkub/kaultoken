import db from './db.js'

const VOTE_COST = 10
const INITIAL_POINTS = 100

// Helper to initialize or get user
const initializeUser = (userId) => {
  if (!db.data.users[userId]) {
    db.data.users[userId] = {
      points: INITIAL_POINTS,
      rewards: {}
    }
  }
  return db.data.users[userId]
}

// Helper to distribute rewards
const distributeRewards = (subjectId, votePoints) => {
  const subject = db.data.subjects.find(s => s.id === subjectId)
  if (!subject || !subject.voterHistory.length) return

  subject.voterHistory.forEach((voter, index) => {
    const rewardShare = votePoints / Math.pow(2, index + 1)
    const user = initializeUser(voter.userId)
    if (!user.rewards[subjectId]) user.rewards[subjectId] = 0
    user.rewards[subjectId] += rewardShare
  })
}

export const getSubjects = async (event) => {
  try {
    await db.read()
    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({
        subjects: db.data.subjects,
        users: db.data.users
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
    await db.read()
    
    const user = initializeUser(userId)
    if (user.points < VOTE_COST) {
      throw new Error('Not enough points to vote')
    }

    // Find and validate subject
    const subject = db.data.subjects.find(s => s.id === id)
    if (!subject) {
      throw new Error(`Subject not found`)
    }

    // Initialize voterHistory if it doesn't exist
    if (!subject.voterHistory) {
      subject.voterHistory = []
    }

    // Initialize votes if they don't exist
    if (!subject.votes) {
      subject.votes = { up: 0, down: 0 }
    }

    // Deduct points from user
    user.points -= VOTE_COST

    // Record vote
    subject.votes[voteType] = (subject.votes[voteType] || 0) + 1
    subject.lastUpdated = new Date().toISOString()
    
    // Add to voter history
    subject.voterHistory.push({
      userId,
      timestamp: new Date().toISOString(),
      points: VOTE_COST
    })

    // Distribute rewards
    distributeRewards(id, VOTE_COST)
    
    // Save changes
    await db.write()

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({ 
        success: true, 
        subjects: db.data.subjects,
        user: user
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
}