import subjectsDb from './subjects.js'
import usersDb from './users.js'

const VOTE_COST = 10
const INITIAL_POINTS = 100
const MIN_REWARD = 0.000001
const REWARD_TIERS = {
  TIER1: { max: 10, share: 5, reward: 0.5 },
  TIER2: { max: 100, share: 3, reward: 0.033 },
  TIER3: { max: 1000, share: 1.5, reward: 0.00167 },
  TIER4: { max: 10000, share: 0.5, reward: 0.000056 }
}

const logger = {
  info: (message, data = {}) => {
    console.log(JSON.stringify({
      timestamp: new Date().toISOString(),
      level: 'INFO',
      message,
      ...data
    }))
  },
  error: (message, error = {}, data = {}) => {
    console.error(JSON.stringify({
      timestamp: new Date().toISOString(),
      level: 'ERROR',
      message,
      error: {
        name: error.name,
        message: error.message,
        stack: error.stack
      },
      ...data
    }))
  },
  debug: (message, data = {}) => {
    console.debug(JSON.stringify({
      timestamp: new Date().toISOString(),
      level: 'DEBUG',
      message,
      ...data
    }))
  },
  metric: (message, metrics = {}) => {
    console.log(JSON.stringify({
      timestamp: new Date().toISOString(),
      level: 'METRIC',
      message,
      ...metrics
    }))
  }
}

const initializeUser = (userId) => {
  if (!usersDb.data.points[userId]) {
    logger.info('Initializing new user', { userId, initialPoints: INITIAL_POINTS })
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
  let tier = 'NONE'
  let reward = 0

  if (position <= REWARD_TIERS.TIER1.max) {
    tier = 'TIER1'
    reward = REWARD_TIERS.TIER1.reward
  } else if (position <= REWARD_TIERS.TIER2.max) {
    tier = 'TIER2'
    reward = REWARD_TIERS.TIER2.reward
  } else if (position <= REWARD_TIERS.TIER3.max) {
    tier = 'TIER3'
    reward = REWARD_TIERS.TIER3.reward
  } else if (position <= REWARD_TIERS.TIER4.max) {
    tier = 'TIER4'
    reward = REWARD_TIERS.TIER4.reward
  }

  logger.debug('Calculated reward', { position, tier, reward })
  return reward
}

const distributeRewards = async (subjectId, voteType, currentVoterId) => {
  try {
    logger.info('Starting reward distribution', {
      subjectId,
      voteType,
      currentVoterId
    })

    const subject = subjectsDb.data.subjects.find(s => s.id === subjectId)
    if (!subject || !subject.voterHistory) {
      logger.error('Invalid subject or voter history', {}, { subjectId })
      return
    }

    const previousVoters = subject.voterHistory
      .filter(vote => vote.voteType === voteType && vote.userId !== currentVoterId)

    logger.info('Found previous voters', {
      subjectId,
      voterCount: previousVoters.length
    })

    let totalDistributed = 0
    const distributions = []
    
    for (let i = 0; i < previousVoters.length; i++) {
      const voter = previousVoters[i]
      const position = i + 1
      const rewardShare = calculateRewardForPosition(position)
      
      if (rewardShare < MIN_REWARD) {
        logger.debug('Reward too small, stopping distribution', {
          position,
          rewardShare
        })
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

      distributions.push({
        userId: voter.userId,
        position,
        reward: rewardShare,
        newTotal: user.points
      })

      logger.debug('Distributed reward', {
        userId: voter.userId,
        position,
        reward: rewardShare,
        newTotal: user.points
      })
    }
    
    logger.info('Completed reward distribution', {
      subjectId,
      totalDistributed,
      distributionCount: distributions.length,
      distributions
    })

    await usersDb.write()
  } catch (error) {
    logger.error('Error in distributeRewards', error, {
      subjectId,
      voteType,
      currentVoterId
    })
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

const _recordVote = async (event) => {
  const startTime = Date.now()
  const requestId = event.requestContext?.requestId || 'unknown'

  try {
    const { id, voteType, userId } = JSON.parse(event.body)
    logger.info('Vote request received', { 
      requestId,
      subjectId: id,
      voteType,
      userId 
    })

    await Promise.all([subjectsDb.read(), usersDb.read()])
    
    const user = initializeUser(userId)
    if (user.points < VOTE_COST) {
      logger.error('Insufficient points', {}, { userId, points: user.points })
      throw new Error('Not enough points to vote')
    }

    const subject = subjectsDb.data.subjects.find(s => s.id === id)
    if (!subject) {
      logger.error('Subject not found', {}, { id })
      throw new Error('Subject not found')
    }

    if (!subject.votes) subject.votes = { up: 0, down: 0 }
    if (!subject.voterHistory) subject.voterHistory = []

    const hasVoted = subject.voterHistory.some(vote => 
      vote.userId === userId && vote.voteType === voteType
    )
    
    if (hasVoted) {
      logger.error('Duplicate vote attempt', {}, { userId, subjectId: id, voteType })
      throw new Error('You have already voted this way on this subject')
    }

    user.points -= VOTE_COST
    logger.info('Points deducted for vote', {
      userId,
      cost: VOTE_COST,
      newTotal: user.points
    })

    subject.votes[voteType]++
    subject.lastUpdated = new Date().toISOString()
    
    subject.voterHistory.push({
      userId,
      timestamp: new Date().toISOString(),
      points: VOTE_COST,
      voteType,
      position: subject.voterHistory.length + 1
    })

    logger.info('Vote recorded', {
      subjectId: id,
      voteType,
      userId,
      position: subject.voterHistory.length
    })

    await Promise.all([
      subjectsDb.write(),
      distributeRewards(id, voteType, userId)
    ])

    await usersDb.read()
    const updatedUser = usersDb.data.points[userId]

    // Log final points as DEBUG
    logger.debug('Points updated', {
      requestId,
      userId,
      finalPoints: updatedUser.points
    })

    const response = {
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

    const duration = Date.now() - startTime
    const billedDuration = Math.ceil(duration)

    logger.info('Vote processing completed', {
      requestId,
      userId
    })

    logger.metric('Lambda execution metrics', {
      requestId,
      functionName: 'recordVote',
      duration: `${duration} ms`,
      billedDuration: `${billedDuration} ms`,
      memoryUsed: process.memoryUsage().heapUsed,
      timestamp: new Date().toISOString()
    })

    return response
  } catch (error) {
    logger.error('Vote processing failed', error, {
      requestId,
      body: event.body
    })

    const duration = Date.now() - startTime
    logger.metric('Lambda execution metrics', {
      requestId,
      functionName: 'recordVote',
      duration: `${duration} ms`,
      billedDuration: `${Math.ceil(duration)} ms`,
      memoryUsed: process.memoryUsage().heapUsed,
      status: 'error',
      timestamp: new Date().toISOString()
    })

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

// Wrapper to prevent AWS default logging
export const recordVote = async (event, context) => {
  // Disable AWS Lambda's default logging
  context.callbackWaitsForEmptyEventLoop = false
  
  // Store original console
  const originalConsole = {
    log: console.log,
    error: console.error,
    debug: console.debug
  }

  // Replace console temporarily
  console.log = (...args) => {
    if (typeof args[0] === 'string' && !args[0].includes('(λ: recordVote)')) {
      originalConsole.log.apply(console, args)
    }
  }
  console.error = (...args) => {
    if (typeof args[0] === 'string' && !args[0].includes('(λ: recordVote)')) {
      originalConsole.error.apply(console, args)
    }
  }
  console.debug = (...args) => {
    if (typeof args[0] === 'string' && !args[0].includes('(λ: recordVote)')) {
      originalConsole.debug.apply(console, args)
    }
  }

  try {
    return await _recordVote(event)
  } finally {
    // Restore original console
    console.log = originalConsole.log
    console.error = originalConsole.error
    console.debug = originalConsole.debug
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