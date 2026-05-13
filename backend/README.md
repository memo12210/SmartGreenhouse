# Smart Greenhouse Backend

Modular FastAPI backend with PostgreSQL, SQLAlchemy ORM, and JWT Authentication.

## 🚀 Quick Start (Docker)

### 1. Build and Start Services
This command builds the FastAPI image and starts the application along with the PostgreSQL database.
```bash
docker-compose up --build -d
```

### 2. Initialize Database Tables
Run the initialization script to create the necessary tables (`users`, `greenhouses`, `devices`, `telemetry`) in PostgreSQL.
```bash
docker-compose run app python init_db.py
```

### 3. Verify Health
Check these endpoints in your browser:
- **API Health**: [http://localhost:8000/api/v1/health](http://localhost:8000/api/v1/health)
- **Database Connection**: [http://localhost:8000/api/v1/test-db](http://localhost:8000/api/v1/test-db)

---

## 🧪 Testing the Auth Flow (End-to-End)

Open the **Interactive API Docs**: [http://localhost:8000/docs](http://localhost:8000/docs)

### Step 1: Register
1. Find `POST /api/v1/auth/register`.
2. Click **Try it out**, enter an email and password.
3. **Execute**. You should get a `200 OK` with user details.

### Step 2: Login
1. Find `POST /api/v1/auth/login/access-token`.
2. Enter the same credentials in the form.
3. **Execute**. Copy the `access_token` from the response.

### Step 3: Authorize
1. Click the green **Authorize** button at the top of the page.
2. Paste the `access_token` and click **Authorize**.

### Step 4: Access Protected Profile
1. Find `GET /api/v1/auth/me`.
2. Click **Try it out** -> **Execute**.
3. You should see your user profile data.

---

## 🛠 Development Commands

### Database Migrations (Alembic)
Whenever you modify models in `app/models/`:

**Generate a new migration:**
```bash
docker-compose run app alembic revision --autogenerate -m "description of changes"
```

**Apply migrations:**
```bash
docker-compose run app alembic upgrade head
```

### Reset Environment
To wipe the database and start fresh:
```bash
docker-compose down -v
```

## 📂 Project Structure
- `app/api`: API endpoints and dependencies.
- `app/core`: Configuration and security settings.
- `app/crud`: Business logic and DB operations.
- `app/models`: SQLAlchemy database models.
- `app/schemas`: Pydantic data validation models.
- `alembic/`: Database migration history.
