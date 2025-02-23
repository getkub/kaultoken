import { Low } from 'lowdb'
import { JSONFile } from 'lowdb/node'
import path from 'path'
import { fileURLToPath } from 'url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const dbPath = path.join(__dirname, 'db.json')

// Default data structure
const defaultData = {
  subjects: [
    { 
      id: 1, 
      title: 'First Subject', 
      votes: { up: 0, down: 0 },
      lastUpdated: new Date().toISOString()
    },
    { 
      id: 2, 
      title: 'Second Subject', 
      votes: { up: 0, down: 0 },
      lastUpdated: new Date().toISOString()
    }
  ]
}

const adapter = new JSONFile(dbPath)
const db = new Low(adapter, defaultData)

// Initialize database
await db.read()

export default db
