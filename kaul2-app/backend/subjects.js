import { Low } from 'lowdb'
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
