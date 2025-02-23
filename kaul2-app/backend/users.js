import { Low } from 'lowdb'
import { JSONFile } from 'lowdb/node'
import path from 'path'
import { fileURLToPath } from 'url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const dbPath = path.join(__dirname, 'users.json')

const defaultData = {
  profiles: [
    { id: 'user1', name: 'Alice', avatar: '👩‍💻' },
    { id: 'user2', name: 'Bob', avatar: '👨‍💻' },
    { id: 'user3', name: 'Charlie', avatar: '🧑‍💻' },
    { id: 'user4', name: 'Diana', avatar: '👩‍🔬' }
  ],
  points: {}  // Stores points and rewards for each user
}

const usersDb = new Low(new JSONFile(dbPath), defaultData)

// Initialize database
await usersDb.read()
if (!usersDb.data) {
  usersDb.data = defaultData
  await usersDb.write()
}

export default usersDb
