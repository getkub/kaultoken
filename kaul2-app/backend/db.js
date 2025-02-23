import { Low } from 'lowdb'
import { JSONFile } from 'lowdb/node'
import path from 'path'
import { fileURLToPath } from 'url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const dbPath = path.join(__dirname, 'db.json')

// Default data with all 4 subjects
const defaultData = {
  subjects: [
    { 
      id: 1, 
      title: 'Kubernetes',
      emoji: '🚢',
      votes: { up: 0, down: 0 },
      lastUpdated: new Date().toISOString()
    },
    { 
      id: 2, 
      title: 'AWS Cloud',
      emoji: '☁️',
      votes: { up: 0, down: 0 },
      lastUpdated: new Date().toISOString()
    },
    { 
      id: 3, 
      title: 'Ubuntu Linux',
      emoji: '🐧',
      votes: { up: 0, down: 0 },
      lastUpdated: new Date().toISOString()
    },
    { 
      id: 4, 
      title: 'LangChain',
      emoji: '🔗',
      votes: { up: 0, down: 0 },
      lastUpdated: new Date().toISOString()
    }
  ]
}

const adapter = new JSONFile(dbPath)
const db = new Low(adapter, defaultData)

// Initialize or reset the database with all subjects
await db.read()
if (!db.data || !db.data.subjects || db.data.subjects.length !== 4) {
  console.log('Initializing database with default data');
  db.data = defaultData;
  await db.write();
}

export default db
