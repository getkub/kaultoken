import { Low } from 'lowdb'
import { JSONFile } from 'lowdb/node'
import path from 'path'
import { fileURLToPath } from 'url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const dbPath = path.join(__dirname, 'db.json')

const defaultData = {
  "subjects": [
    {
      "id": 1,
      "title": "Kubernetes",
      "emoji": "\ud83d\udea2",
      "votes": {
        "up": 0,
        "down": 0
      },
      "voterHistory": [],
      "lastUpdated": "2024-01-01T00:00:00.000Z"
    },
    {
      "id": 2,
      "title": "AWS Cloud",
      "emoji": "\u2601\ufe0f",
      "votes": {
        "up": 0,
        "down": 0
      },
      "voterHistory": [],
      "lastUpdated": "2024-01-01T00:00:00.000Z"
    },
    {
      "id": 3,
      "title": "Ubuntu Linux",
      "emoji": "\ud83d\udc27",
      "votes": {
        "up": 0,
        "down": 0
      },
      "voterHistory": [],
      "lastUpdated": "2024-01-01T00:00:00.000Z"
    },
    {
      "id": 4,
      "title": "LangChain",
      "emoji": "\ud83d\udd17",
      "votes": {
        "up": 0,
        "down": 0
      },
      "voterHistory": [],
      "lastUpdated": "2024-01-01T00:00:00.000Z"
    }
  ],
  "users": {}
}

const adapter = new JSONFile(dbPath)
const db = new Low(adapter, defaultData)

// Initialize database with default data
await db.read()
if (!db.data) {
    db.data = defaultData
    await db.write()
}

// Ensure users object exists
if (!db.data.users) {
    db.data.users = {}
    await db.write()
}

export default db
