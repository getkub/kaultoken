from pathlib import Path
import json
import sys

def reset_db():
    try:
        project_name = "kaul2-app"
        base_path = Path.cwd()
        backend_path = base_path / project_name / "backend"
        
        # Default data for subjects
        subjects_data = {
            "subjects": [
                {
                    "id": 1,
                    "title": "Kubernetes",
                    "emoji": "🚢",
                    "votes": {"up": 0, "down": 0},
                    "voterHistory": [],
                    "lastUpdated": "2024-01-01T00:00:00.000Z"
                },
                {
                    "id": 2,
                    "title": "AWS Cloud",
                    "emoji": "☁️",
                    "votes": {"up": 0, "down": 0},
                    "voterHistory": [],
                    "lastUpdated": "2024-01-01T00:00:00.000Z"
                },
                {
                    "id": 3,
                    "title": "Ubuntu Linux",
                    "emoji": "🐧",
                    "votes": {"up": 0, "down": 0},
                    "voterHistory": [],
                    "lastUpdated": "2024-01-01T00:00:00.000Z"
                },
                {
                    "id": 4,
                    "title": "LangChain",
                    "emoji": "🔗",
                    "votes": {"up": 0, "down": 0},
                    "voterHistory": [],
                    "lastUpdated": "2024-01-01T00:00:00.000Z"
                }
            ]
        }

        # Default data for users
        users_data = {
            "profiles": [
                {"id": "user1", "name": "Alice", "avatar": "👩‍💻"},
                {"id": "user2", "name": "Bob", "avatar": "👨‍💻"},
                {"id": "user3", "name": "Charlie", "avatar": "🧑‍💻"},
                {"id": "user4", "name": "Diana", "avatar": "👩‍🔬"}
            ],
            "points": {}
        }

        # Create directory if it doesn't exist
        backend_path.mkdir(parents=True, exist_ok=True)

        # Write the separate database files
        with open(backend_path / "subjects.json", 'w') as f:
            json.dump(subjects_data, f, indent=2)

        with open(backend_path / "users.json", 'w') as f:
            json.dump(users_data, f, indent=2)

        print("✅ Successfully reset databases:")
        print("- subjects.json: All votes reset")
        print("- users.json: All points reset")
        return True

    except Exception as e:
        print(f"❌ Error resetting databases: {e}")
        return False

if __name__ == "__main__":
    success = reset_db()
    sys.exit(0 if success else 1) 