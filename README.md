# Smart Greenhouse Monitoring System

A comprehensive IoT solution for monitoring greenhouse environments, featuring real-time telemetry, automated data persistence, and secure multi-user access with resource ownership.

## 🏗 Project Architecture

- **`backend/`**: FastAPI REST API, PostgreSQL Database, and Alembic migrations. Features JWT authentication and multi-tenant resource ownership.
- **`frontend/`**: Flutter mobile/web application with a modern neon-dark theme and secure state management.
- **`embedded/`**: ESP32 firmware (C++/PlatformIO) for sensor data collection and MQTT transmission.
- **`ml/`**: Machine Learning notebooks for predictive analytics and crop yield optimization.

---

## 🚀 Getting Started

Follow these steps to get the entire system running on your local machine.

### 1. Prerequisites
- [Docker](https://www.docker.com/get-started) and Docker Compose
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- Python 3.11+ (for local scripts if not using Docker)

---

### 2. Backend & Database Setup
The backend serves as the central hub for authentication and data storage.

1.  **Navigate to the backend directory:**
    ```bash
    cd backend
    ```

2.  **Start the services (PostgreSQL + FastAPI):**
    ```bash
    docker-compose up --build -d
    ```

3.  **Initialize the Database Schema:**
    Run this command to create the necessary tables (`users`, `greenhouses`, `devices`, `telemetry`):
    ```bash
    docker-compose run app python init_db.py
    ```

4.  **Verify Connectivity:**
    - **API Docs**: [http://localhost:8000/docs](http://localhost:8000/docs)
    - **Health Check**: [http://localhost:8000/api/v1/health](http://localhost:8000/api/v1/health)

---

### 3. Frontend (Flutter) Setup
The frontend provides the user interface for monitoring and management.

1.  **Navigate to the frontend directory:**
    ```bash
    cd frontend
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the application:**
    ```bash
    flutter run
    ```
    *Note: If running on an Android Emulator, the app is pre-configured to use `10.0.2.2` to communicate with your host machine's localhost.*

---

## 🧪 Testing Functionality

### 1. Authentication Flow
- **Register**: Open the app and create a new account.
- **Login**: Use your credentials to sign in.
- **Persistence**: Close the app and reopen it; you should remain logged in thanks to secure JWT storage.
- **Logout**: Navigate to **Settings** and click **Log Out** to clear your session.

### 2. Greenhouse Management (Authenticated)
- Go to the **Settings** page in the app or use the API docs.
- **Add Greenhouse**: Create a new greenhouse profile (automatically linked to your user account).
- **Ownership Isolation**: Verify that you only see greenhouses you created.
- **Management**: Rename or delete greenhouses; all associated devices and telemetry will be cleaned up automatically.
- **Error Handling**: Try performing these actions with the backend stopped to see the new user-friendly connection error messages.

### 3. Real-Time Telemetry (Requires MQTT Broker)
- Ensure an MQTT broker (like Mosquitto) is running on port `1883`.
- The ESP32 (or a simulator) should publish JSON data to: `<greenhouse_id>/<mac_address>/telemetry`.
- Dashboard gauges will update in real-time as data arrives.

---

## 🛡 Development Commands

| Action | Command |
| :--- | :--- |
| **Stop Backend** | `docker-compose down` |
| **Reset Database** | `docker-compose down -v` |
| **Generate Migration** | `docker-compose run app alembic revision --autogenerate -m "msg"` |
| **Apply Migration** | `docker-compose run app alembic upgrade head` |

---

## 🌳 Git Migration Workflow

To ensure a safe and incremental transition, we follow these Git practices:

### Branching Strategy
- **`main`**: Stable, production-ready code.
- **`develop`**: Integration branch for upcoming features.
- **`feature/*`**: Individual migration steps (e.g., `feature/mqtt-bridge`).

**Example Workflow:**
```bash
# Start a new feature
git checkout develop
git pull origin develop
git checkout -b feature/auth-fix

# After development and verification
git add .
git commit -m "feat(auth): fix login token expiration"
git checkout develop
git merge feature/auth-fix
```

### Commit Conventions
We use [Conventional Commits](https://www.conventionalcommits.org/):
- `feat(backend):` New API features.
- `fix(frontend):` Bug fixes in the UI.
- `chore:` Maintenance or configuration updates.

### Safety & Rollbacks
- **Code**: Use `git revert` for safe rollbacks of merged code.
  ```bash
  # Revert a specific merge commit
  git revert -m 1 <commit_hash>
  ```
- **Database**: Use `alembic downgrade -1` to revert the last schema change.
- **Full Reset**: Use `docker-compose down -v` to clear volumes and start from a clean state.

---

## 📂 Documentation Links
- [Backend Deep Dive](backend/README.md)
- [System Walkthrough](.artifacts/20260513-155838-b986e196-61a4-4e7a-ac03-a2bb67c42b1d/walkthrough.artifact.md)
