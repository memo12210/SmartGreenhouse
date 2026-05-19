# Getting Started & Testing Guide

This guide provides a step-by-step walkthrough to start the Smart Greenhouse Backend and test its core functionalities.

## Prerequisites

- **Docker & Docker Compose** installed.
- **Python 3.12+** (optional, for local script testing).
- An MQTT client like **MQTT Explorer** or `mosquitto_pub` (optional, for manual MQTT testing).

---

## 1. Start the Infrastructure

First, navigate to the `backend/` directory and prepare the environment:

```bash
cd backend
# Create your .env file from the example
cp .env.example .env
```

Start all services using Docker Compose:

```bash
docker-compose up -d
```

Verify that all containers are running and healthy:

```bash
docker-compose ps
```
You should see `api`, `db`, `redis`, `mqtt`, `otel-collector`, and `prometheus` running.

---

## 2. Initialize the Database

The system uses Alembic for database migrations. The application container is pre-configured with the correct `PYTHONPATH` to ensure migrations run smoothly.

```bash
# Apply migrations to create the initial schema
docker-compose exec api alembic upgrade head
```

---

## 3. Test REST API Functionalities

Access the interactive API documentation at: **`http://localhost:8000/docs`**

### Step A: Register and Login
1.  **Register**: Call `POST /api/v1/auth/register` with:
    ```json
    {
      "email": "admin@example.com",
      "password": "strongpassword123",
      "full_name": "Admin User",
      "role": "admin"
    }
    ```
2.  **Login**: Call `POST /api/v1/auth/login` (OAuth2 format) to get your `access_token`.
3.  **Authorize**: Click the "Authorize" button in Swagger and paste the `access_token`.

### Step B: Create a Greenhouse
1.  Call `POST /api/v1/greenhouses/`:
    ```json
    {
      "name": "Main Greenhouse",
      "location": "North Sector",
      "extra_metadata": {"type": "hydroponic"}
    }
    ```
    *Take note of the returned `id` (greenhouse_id).*

### Step C: Register a Device
1.  Call `POST /api/v1/devices/`:
    ```json
    {
      "name": "Sensor Node 1",
      "serial_number": "SN-001",
      "device_type": "esp32-sensor-hub",
      "greenhouse_id": "PASTE_GREENHOUSE_ID_HERE"
    }
    ```
    *Take note of the returned `id` (device_id).*

---

## 4. Test Telemetry Ingestion (MQTT)

You can simulate a device publishing telemetry data via MQTT. Note that all telemetry timestamps are stored as timezone-aware UTC.

### Using `mosquitto_pub`:
Replace `{greenhouse_id}` and `{device_id}` with the UUIDs obtained above.

```bash
mosquitto_pub -h localhost -p 1883 \
  -t "greenhouse/{greenhouse_id}/device/{device_id}/telemetry" \
  -m '{"temperature": 24.5, "humidity": 60, "soil_moisture": 45.2, "co2": 400}'
```

### Verify Ingestion:
1.  Go back to Swagger.
2.  Call `GET /api/v1/telemetry/{device_id}`.
3.  **Ownership Check**: The system strictly verifies that the device belongs to a greenhouse you own. If you try to access a device you don't own, you will receive a `404 Not Found`.

---

## 5. Test Device Commands

1.  In Swagger, call `POST /api/v1/devices/{device_id}/commands`:
    ```json
    {
      "command": "toggle_water_pump",
      "payload": {"state": "on"}
    }
    ```
2.  The backend will verify ownership and publish this command to the MQTT topic:
    `greenhouse/{greenhouse_id}/device/{device_id}/commands`
3.  You can verify this by subscribing to the topic using an MQTT client.

---

## 6. Alerts & Notifications

The system includes a fully functional Alerts module.

1.  **List Alerts**: Call `GET /api/v1/alerts/greenhouse/{greenhouse_id}` to see all alerts for your greenhouse.
2.  **Acknowledge**: Call `POST /api/v1/alerts/{alert_id}/acknowledge` to mark an alert as resolved.

---

## 7. Security & Stability Features

- **Ownership Enforcement**: All protected endpoints strictly verify resource ownership.
- **Data Integrity**: Unified `extra_metadata` naming and timezone-aware timestamps (`TIMESTAMPTZ`) are used throughout the system.
- **Robustness**: The API is configured to handle modern dependency versions (e.g., `bcrypt` 4.0.1+).

---

## 8. Stop the System

To shut down everything:

```bash
docker-compose down
```
