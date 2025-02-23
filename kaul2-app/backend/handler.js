import db from './db.js'

// GET /subjects
export const getSubjects = async (event) => {
  try {
    await db.read()
    console.log('GET /subjects - Current data:', JSON.stringify(db.data.subjects, null, 2))
    
    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify(db.data.subjects)
    }
  } catch (error) {
    console.error('Error reading subjects:', error)
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({ 
        success: false, 
        error: 'Failed to read database' 
      })
    }
  }
}

// POST /vote
export const recordVote = async (event) => {
  console.log('POST /vote called with body:', event.body)
  try {
    const { id, voteType } = JSON.parse(event.body)
    
    await db.read()
    db.data.subjects = db.data.subjects.map(subject => {
      if (subject.id === id) {
        return {
          ...subject,
          votes: {
            ...subject.votes,
            [voteType]: subject.votes[voteType] + 1
          },
          lastUpdated: new Date().toISOString()
        }
      }
      return subject
    })
    await db.write()

    console.log('Updated vote data:', JSON.stringify(db.data.subjects, null, 2))
    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({ 
        success: true, 
        subjects: db.data.subjects 
      })
    }
  } catch (error) {
    console.error('Error processing vote:', error)
    return {
      statusCode: 400,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({ 
        success: false, 
        error: 'Invalid request' 
      })
    }
  }
}

// Rest of handler.js remains the same...
