// In-memory storage for votes
let subjects = [
  { id: 1, title: 'First Subject', votes: { up: 0, down: 0 } },
  { id: 2, title: 'Second Subject', votes: { up: 0, down: 0 } }
];

export const getSubjects = async () => {
  return {
    statusCode: 200,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    },
    body: JSON.stringify(subjects)
  };
};

export const recordVote = async (event) => {
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

  return {
    statusCode: 200,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    },
    body: JSON.stringify({ success: true })
  };
};
