// In-memory storage
let subjects = [
  { id: 1, title: 'First Subject', votes: { up: 0, down: 0 } },
  { id: 2, title: 'Second Subject', votes: { up: 0, down: 0 } }
];

// GET /subjects
export const getSubjects = async (event) => {
  console.log('GET /subjects called');
  return {
    statusCode: 200,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    },
    body: JSON.stringify(subjects)
  };
};

// POST /vote
export const recordVote = async (event) => {
  console.log('POST /vote called with body:', event.body);
  try {
    const { id, voteType } = JSON.parse(event.body);
    
    subjects = subjects.map(subject => {
      if (subject.id === id) {
        return {
          ...subject,
          votes: {
            ...subject.votes,
            [voteType]: subject.votes[voteType] + 1
          }
        };
      }
      return subject;
    });

    console.log('Updated subjects:', subjects);
    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({ success: true, subjects })
    };
  } catch (error) {
    console.error('Error processing vote:', error);
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
    };
  }
};

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
  };
};
