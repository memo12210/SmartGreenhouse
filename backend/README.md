# Smart Greenhouse Monitoring Platform Backend

Production-grade IoT backend for monitoring and managing smart greenhouses.

## Tech Stack

- **Framework**: FastAPI
- **Database**: PostgreSQL + TimescaleDB (for telemetry)
- **ORM**: Async SQLAlchemy 2.0
- **Cache/Buffer**: Redis
- **Messaging**: MQTT (Gmqtt)
- **Observability**: OpenTelemetry, Prometheus, Grafana
- **Security**: JWT (Access + Refresh tokens), RBAC
- **Containerization**: Docker & Docker Compose

## Features

- **User Management**: Registration, Login, JWT Authentication, RBAC (admin, operator, viewer).
- **Greenhouse Management**: Multi-greenhouse support, metadata tracking.
- **Device Management**: Provisioning, status tracking (heartbeat), command queue.
- **Telemetry**: High-volume ingestion, time-series data storage using TimescaleDB.
- **MQTT Pipeline**: Fully decoupled ingestion and command publishing.
- **Alerting**: Rule-based alert generation and acknowledgment (base implementation).

## Project Structure

```
backend/
├── app/
│   ├── api/            # REST API routers and dependencies
│   ├── core/           # Configuration, security, observability
│   ├── domain/         # SQLAlchemy models (Entities)
│   ├── infrastructure/ # Database, MQTT, Redis clients
│   ├── repositories/   # Async Repository pattern
│   ├── services/       # Business logic layer
│   ├── schemas/        # Pydantic models (DTOs)
│   ├── workers/        # Background tasks (MQTT subscriber)
│   ├── tests/          # Pytest suite
│   └── main.py         # Entry point
```

## Getting Started

### Prerequisites

- Docker and Docker Compose
- Python 3.12+ (for local development)

### Running with Docker

1. Create a `.env` file from `.env.example`:
   ```bash
   cp .env.example .env
   ```
2. Start the stack:
   ```bash
   docker-compose up -d
   ```
3. The API will be available at `http://localhost:8000` and Swagger docs at `http://localhost:8000/docs`.

### Database Migrations

```bash
# Apply migrations
alembic upgrade head

# Generate a new migration
alembic revision --autogenerate -m "description"
```

## Security

- Passwords are hashed using Argon2/Bcrypt.
- JWT tokens are used for authentication.
- Refresh token rotation is implemented to prevent token theft.
- Role-Based Access Control (RBAC) ensures users only access what they are allowed to.

## Observability

- **Metrics**: Available at `http://localhost:8000/metrics` (Prometheus format).
- **Tracing**: OpenTelemetry traces are exported to the OTLP collector.
- **Logs**: Structured JSON logging (via structlog).
