import subjectsDb from './subjects.js'
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

    console.log(`
Distributing ${voteType} rewards for subject ${subjectId}`)
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
}