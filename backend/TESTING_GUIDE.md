# Smart Greenhouse Backend — Endpoint Testing Guide

A step-by-step, copy-paste guide for manually exercising every REST endpoint plus
the MQTT telemetry pipeline. Commands use `curl` and `jq`; MQTT uses
`mosquitto_pub`.

> Tested flow: register → log in → create a greenhouse → create a device →
> add an alert rule → push telemetry (REST **and** MQTT) → read alerts → ack/dismiss
> → notifications → ML → security/negative checks.

---

## 0. Prerequisites

### 0.1 Start the stack and run migrations

```bash
cd backend
cp .env.example .env          # first time only — then edit SECRET_KEY etc.
docker-compose up -d          # api, db (TimescaleDB), redis, mqtt (EMQX), otel, prometheus
docker-compose exec api alembic upgrade head
```

### 0.2 Install CLI tools (host)

```bash
# Debian/Ubuntu
sudo apt-get install -y jq mosquitto-clients
# Arch
sudo pacman -S jq mosquitto
# macOS
brew install jq mosquitto
```

### 0.3 Environment variables used throughout

```bash
export BASE="http://localhost:8000"      # compose maps host 8000 -> uvicorn :80
export MQTT_HOST="localhost"             # EMQX, host 1883
export EMAIL="tester@example.com"
export PASSWORD="supersecret123"         # NOTE: registration requires >= 12 chars
```

> Tip: if a JSON body contains `!` (e.g. in a message), interactive bash may fail
> with `event not found` (history expansion). Run `set +H` once to disable it, or
> avoid `!` in values you type.

Port reference (from `docker-compose.yml`):

| Service | Host port | Notes |
|---|---|---|
| API (uvicorn) | `8000` | REST + `/docs` |
| Prometheus metrics (app) | `8008` | `start_metrics_server()` |
| MQTT (EMQX) | `1883` | telemetry/commands |
| EMQX dashboard | `18083` | default admin/public |
| Prometheus server | `9090` | |

---

## 1. Health checks (no auth)

```bash
curl -s "$BASE/health" | jq
# Expect: {"status":"ok"}

curl -s "$BASE/api/v1/ml/health" | jq
# Expect: {"status":"ok","model_loaded":true|false,"model_path":"..."}
```

Interactive docs: open **http://localhost:8000/docs** in a browser — you can drive
every endpoint from there too.

---

## 2. Auth

### 2.1 Register (`POST /api/v1/auth/register`)

Public registration always creates a least-privilege **viewer**; `role`/`is_active`
in the body are ignored (security fix). Password must be **12–72 chars**.

```bash
curl -s -X POST "$BASE/api/v1/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"full_name\":\"Test User\",\"password\":\"$PASSWORD\"}" | jq
# Expect 200: {"email":...,"full_name":...,"role":"viewer","is_active":true,"id":"..."}
```

Negative checks:

```bash
# Too-short password -> 422
curl -s -o /dev/null -w "%{http_code}\n" -X POST "$BASE/api/v1/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"email":"x@y.com","password":"short"}'        # 422

# Attempt privilege escalation -> role is ignored, comes back "viewer"
curl -s -X POST "$BASE/api/v1/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"email":"evil@y.com","password":"longenough123","role":"admin"}' | jq .role
# Expect: "viewer"
```

### 2.2 Login (`POST /api/v1/auth/login`)

OAuth2 password flow — **form-encoded**, and the username field is the email.

```bash
export TOKENS=$(curl -s -X POST "$BASE/api/v1/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=$EMAIL&password=$PASSWORD")
echo "$TOKENS" | jq

export ACCESS=$(echo "$TOKENS"  | jq -r .access_token)
export REFRESH=$(echo "$TOKENS" | jq -r .refresh_token)
export AUTH="Authorization: Bearer $ACCESS"
```

Negative: wrong password → 401.

```bash
curl -s -o /dev/null -w "%{http_code}\n" -X POST "$BASE/api/v1/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=$EMAIL&password=wrong"                 # 401
```

### 2.3 Refresh (`POST /api/v1/auth/refresh`)

The refresh token is a **query parameter**, not a JSON body. Refresh **rotates**
(old refresh tokens are revoked).

```bash
export TOKENS=$(curl -s -X POST "$BASE/api/v1/auth/refresh?refresh_token=$REFRESH")
echo "$TOKENS" | jq
export ACCESS=$(echo "$TOKENS"  | jq -r .access_token)
export REFRESH=$(echo "$TOKENS" | jq -r .refresh_token)
export AUTH="Authorization: Bearer $ACCESS"
```

---

## 3. Users

```bash
# Current user
curl -s "$BASE/api/v1/users/me" -H "$AUTH" | jq

# Update own profile (only full_name/email/password are accepted)
curl -s -X PATCH "$BASE/api/v1/users/me" -H "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{"full_name":"Renamed Tester"}' | jq
```

Negative (security fix — role/is_active are NOT updatable here):

```bash
curl -s -X PATCH "$BASE/api/v1/users/me" -H "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{"role":"admin"}' | jq .role
# Expect: "viewer" (the role field is ignored)
```

---

## 4. Greenhouses

```bash
# Create
export GH=$(curl -s -X POST "$BASE/api/v1/greenhouses/" -H "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{
        "name":"Greenhouse A",
        "location":"Rooftop",
        "extra_metadata":{
          "crop_type":"tomato","variety":"cherry",
          "planting_date":"2026-03-01","harvest_date":"2026-06-01",
          "fertilizer_N_kg_ha":120,"fertilizer_P_kg_ha":60,"fertilizer_K_kg_ha":90
        }
      }')
echo "$GH" | jq
export GH_ID=$(echo "$GH" | jq -r .id)

# List (only the caller's greenhouses)
curl -s "$BASE/api/v1/greenhouses/" -H "$AUTH" | jq

# Get one
curl -s "$BASE/api/v1/greenhouses/$GH_ID" -H "$AUTH" | jq

# Update
curl -s -X PATCH "$BASE/api/v1/greenhouses/$GH_ID" -H "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{"location":"Rooftop North"}' | jq

# Delete (204) — do this LAST; cascades to devices/telemetry/alerts.
# curl -s -o /dev/null -w "%{http_code}\n" -X DELETE "$BASE/api/v1/greenhouses/$GH_ID" -H "$AUTH"
```

> The `extra_metadata` above is also what the ML prediction worker reads
> (`crop_type`, `variety`, `planting_date`, `harvest_date`, fertilizer values).

---

## 5. Devices

```bash
# Register a device (status value is lowercase: online/offline/maintenance/inactive)
export DEV=$(curl -s -X POST "$BASE/api/v1/devices/" -H "$AUTH" \
  -H "Content-Type: application/json" \
  -d "{
        \"name\":\"Node-1\",
        \"serial_number\":\"AA:BB:CC:DD:EE:01\",
        \"device_type\":\"sensor\",
        \"status\":\"online\",
        \"firmware_version\":\"1.0.0\",
        \"greenhouse_id\":\"$GH_ID\"
      }")
echo "$DEV" | jq
export DEV_ID=$(echo "$DEV" | jq -r .id)

# Get one
curl -s "$BASE/api/v1/devices/$DEV_ID" -H "$AUTH" | jq

# List devices in a greenhouse
curl -s "$BASE/api/v1/devices/greenhouse/$GH_ID" -H "$AUTH" | jq

# Update
curl -s -X PATCH "$BASE/api/v1/devices/$DEV_ID" -H "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{"firmware_version":"1.0.1"}' | jq
```

### 5.1 Send a command (`POST /api/v1/devices/{id}/commands`)

Publishes to `greenhouse/<gh>/device/<dev>/commands`.

```bash
curl -s -X POST "$BASE/api/v1/devices/$DEV_ID/commands" -H "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{"command":"open_vent","payload":{"angle":45}}' | jq
# Success -> status "sent".
# If the MQTT broker is DOWN -> HTTP 503 and the command row is saved as "failed"
# (security/correctness fix: no more false "sent").
```

Watch it arrive (in a second terminal, before sending):

```bash
mosquitto_sub -h "$MQTT_HOST" -t "greenhouse/+/device/+/commands" -v
```

---

## 6. Alert rules

Create a rule that will fire on the telemetry we send next (humidity > 80).

```bash
export RULE=$(curl -s -X POST "$BASE/api/v1/alerts/rules" -H "$AUTH" \
  -H "Content-Type: application/json" \
  -d "{
        \"device_id\":\"$DEV_ID\",
        \"field\":\"humidity\",
        \"operator\":\">\",
        \"threshold\":80.0,
        \"severity\":\"critical\",
        \"is_enabled\":true,
        \"message_template\":\"High humidity\"
      }")
echo "$RULE" | jq
export RULE_ID=$(echo "$RULE" | jq -r .id)

# List rules for the device
curl -s "$BASE/api/v1/alerts/rules/device/$DEV_ID" -H "$AUTH" | jq

# Update a rule
curl -s -X PATCH "$BASE/api/v1/alerts/rules/$RULE_ID" -H "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{"threshold":75.0}' | jq
```

Valid `field` values: `temperature, humidity, soil_moisture, light_intensity, co2,
battery_level`. Valid `operator`: `> < >= <= == !=` (`==`/`!=` use a float
tolerance). `severity`: `info | warning | critical`.

---

## 7. Telemetry — REST (`POST /api/v1/telemetry/`)

Requires auth **and** ownership of the target device (security fix). Sending
humidity 85 should trip the rule from step 6.

```bash
curl -s -X POST "$BASE/api/v1/telemetry/" -H "$AUTH" \
  -H "Content-Type: application/json" \
  -d "{
        \"device_id\":\"$DEV_ID\",
        \"temperature\":24.5,
        \"humidity\":85.0,
        \"soil_moisture\":40.0,
        \"light_intensity\":12000,
        \"co2\":600,
        \"battery_level\":95
      }" | jq

# Read it back (newest first)
curl -s "$BASE/api/v1/telemetry/$DEV_ID?limit=10" -H "$AUTH" | jq
# Optional time filter: ?start_time=2026-06-01T00:00:00Z&end_time=2026-06-30T00:00:00Z&limit=100
```

Negative / validation checks:

```bash
# No auth -> 401 (previously unauthenticated)
curl -s -o /dev/null -w "%{http_code}\n" -X POST "$BASE/api/v1/telemetry/" \
  -H "Content-Type: application/json" \
  -d "{\"device_id\":\"$DEV_ID\",\"humidity\":50}"            # 401

# Out-of-range sensor value -> 422 (temperature bounds -50..100)
curl -s -o /dev/null -w "%{http_code}\n" -X POST "$BASE/api/v1/telemetry/" -H "$AUTH" \
  -H "Content-Type: application/json" \
  -d "{\"device_id\":\"$DEV_ID\",\"temperature\":-9999}"      # 422
```

---

## 8. Telemetry — MQTT (`mosquitto_pub`)

This is the primary ingestion path. The backend worker subscribes to
`greenhouse/+/device/+/telemetry`. **The greenhouse and device must already exist**
(steps 4 & 5) because telemetry has a foreign key to the device.

> Topic format (matches the ESP32 firmware):
> `greenhouse/<greenhouse_id>/device/<device_id>/telemetry`
> Payload keys the firmware sends: `temperature, humidity, light_intensity, co2`
> (the schema also accepts `soil_moisture`, `battery_level`).

```bash
export TOPIC="greenhouse/$GH_ID/device/$DEV_ID/telemetry"

# Optional: watch the worker ingest it
docker-compose logs -f api &        # look for "Ingested telemetry..."

# Publish one reading (QoS 1). humidity 88 trips the humidity>75 rule.
mosquitto_pub -h "$MQTT_HOST" -q 1 -t "$TOPIC" \
  -m '{"temperature":26.1,"humidity":88.0,"light_intensity":13500,"co2":640}'

# If your broker requires auth (set MQTT_USER/MQTT_PASSWORD in .env), add:
#   -u "$MQTT_USER" -P "$MQTT_PASSWORD"
```

Verify it landed via the REST read-back:

```bash
curl -s "$BASE/api/v1/telemetry/$DEV_ID?limit=5" -H "$AUTH" | jq
```

Send a few more / simulate a stream:

```bash
for h in 50 60 90 91 40; do
  mosquitto_pub -h "$MQTT_HOST" -q 1 -t "$TOPIC" \
    -m "{\"temperature\":25,\"humidity\":$h,\"light_intensity\":12000,\"co2\":600}"
  sleep 1
done
```

Notes:
- A **duplicate** `(timestamp, device_id)` is silently de-duplicated (idempotent
  insert) — no 500, no double alert.
- A malformed/out-of-range payload is dropped and logged, not ingested.
- Publishing to a device/greenhouse UUID that doesn't exist fails the FK insert;
  the worker logs an error and moves on.

---

## 9. Alerts

After the high-humidity telemetry above, an alert should exist.

```bash
# List alerts for the greenhouse (paginated: ?skip=0&limit=100, cap 500)
curl -s "$BASE/api/v1/alerts/greenhouse/$GH_ID?limit=50" -H "$AUTH" | jq
export ALERT_ID=$(curl -s "$BASE/api/v1/alerts/greenhouse/$GH_ID" -H "$AUTH" | jq -r '.[0].id')

# Acknowledge
curl -s -X POST "$BASE/api/v1/alerts/$ALERT_ID/acknowledge" -H "$AUTH" | jq

# Dismiss (delete)
curl -s -X DELETE "$BASE/api/v1/alerts/$ALERT_ID/dismiss" -H "$AUTH" | jq
# Expect: {"status":"success"}
```

Behaviour to observe: while an alert of a given `alert_type` is **unacknowledged**,
repeated breaching telemetry does **not** create duplicates. After you acknowledge
it, the next breach creates a new alert.

---

## 10. Notifications (FCM)

```bash
# Register an FCM token (any string works for the DB row; sending needs a real token)
curl -s -X POST "$BASE/api/v1/notifications/fcm-token" -H "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{"token":"fake-fcm-token-123","platform":"android","device_name":"Pixel"}' | jq

# Send a test push to all of the current user's tokens
curl -s -X POST "$BASE/api/v1/notifications/test" -H "$AUTH" | jq
```

> Requires Firebase credentials at `FIREBASE_SERVICE_ACCOUNT_PATH`
> (`app/secrets/firebase-service-account.json` by default). Without it, the service
> raises at init and the `/test` call reports failures (errors are logged, not
> echoed back). With a fake token, expect `failure_count >= 1`.

---

## 11. Machine Learning

`/predict` and `/predict/batch` require auth. `/train` requires the **ADMIN** role.

```bash
# Single prediction
curl -s -X POST "$BASE/api/v1/ml/predict" -H "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{
        "greenhouse_id":12345.0,
        "crop_type":"tomato","variety":"cherry",
        "planting_date":"2026-03-01","harvest_date":"2026-06-01",
        "days_to_maturity":92,
        "avg_temperature_C":24,"min_temperature_C":18,"max_temperature_C":30,
        "humidity_percent":65,"co2_ppm":600,"light_intensity_lux":12000,
        "photoperiod_hours":12.5,"irrigation_mm":7,
        "fertilizer_N_kg_ha":120,"fertilizer_P_kg_ha":60,"fertilizer_K_kg_ha":90,
        "pest_severity":1.8,"soil_pH":6.3
      }' | jq
# 200 -> {"yield_kg_per_m2":...,"model_version":...}
# 404 -> "Prediction model is not available" (run training first)

# Batch (max 100 items -> otherwise 413)
curl -s -X POST "$BASE/api/v1/ml/predict/batch" -H "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{"data":[ { ... same shape as above ... } ]}' | jq
```

### 11.1 Training (ADMIN only)

`register` only creates viewers, so promote your user in the DB first:

```bash
docker-compose exec db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
  -c "UPDATE users SET role='ADMIN' WHERE email='$EMAIL';"
# NOTE: the DB enum stores the NAME in upper-case ('ADMIN'), not the JSON value 'admin'.
```

Re-login to get a token reflecting the new role, then:

```bash
# (after re-login: refresh $ACCESS / $AUTH as in step 2.2)
curl -s -X POST "$BASE/api/v1/ml/train" -H "$AUTH" | jq
# Expect: {"message":"Training started in background"}  (needs data/raw/greenhouse_crop_yields.csv)

# As a viewer, the same call -> 403
```

### 11.2 Automatic predictions (background worker)

Every **120 seconds** the prediction worker runs once for every greenhouse. For
each one it:

- aggregates that greenhouse's telemetry from the **last 120s window** —
  **temperature (avg, min, max)**, humidity (avg), CO₂ (avg), light (avg);
- combines it with the greenhouse `extra_metadata` (crop_type, variety,
  planting_date, harvest_date, fertilizer N/P/K);
- runs the model and stores a row in the `predictions` table.

A prediction is produced for a greenhouse only when **all** of these hold:

- a trained model exists (`/api/v1/ml/health` → `model_loaded: true`, see §11.1);
- the greenhouse `extra_metadata` contains `crop_type`, `variety`,
  `planting_date`, `harvest_date` (the “Greenhouse A” example in §4 includes them);
- at least one telemetry row landed in the last 120s window (push some via §7/§8).

So to watch predictions accrue: train a model, make sure the greenhouse metadata
is set, stream telemetry, and wait ~2 minutes. Watch the worker:

```bash
docker-compose logs -f api | grep "prediction for greenhouse"
```

### 11.3 View prediction history (`GET /api/v1/ml/predictions/greenhouse/{id}`)

Authenticated; returns the caller's greenhouse predictions, newest first
(paginated, `skip`-free, `limit` cap 500). Ownership enforced (404 otherwise).

```bash
curl -s "$BASE/api/v1/ml/predictions/greenhouse/$GH_ID?limit=50" -H "$AUTH" | jq
# [{"id":...,"greenhouse_id":...,"yield_kg_per_m2":...,"model_version":...,"timestamp":...}, ...]

# IDOR: another user's greenhouse -> 404
curl -s -o /dev/null -w "%{http_code}\n" \
  "$BASE/api/v1/ml/predictions/greenhouse/00000000-0000-0000-0000-000000000000" -H "$AUTH"  # 404
```

---

## 12. Security / negative regression checks

Quick pass confirming the audit fixes hold:

```bash
# 12.1 Invalid bearer token -> 401
curl -s -o /dev/null -w "%{http_code}\n" "$BASE/api/v1/users/me" \
  -H "Authorization: Bearer not-a-real-token"                       # 401

# 12.2 Refresh token cannot be used as an access token -> 401
curl -s -o /dev/null -w "%{http_code}\n" "$BASE/api/v1/users/me" \
  -H "Authorization: Bearer $REFRESH"                               # 401

# 12.3 Unauthenticated ML predict -> 401
curl -s -o /dev/null -w "%{http_code}\n" -X POST "$BASE/api/v1/ml/predict" \
  -H "Content-Type: application/json" -d '{}'                       # 401

# 12.4 IDOR: another user cannot see your greenhouse.
#   Register+login as a 2nd user, then GET /greenhouses/$GH_ID -> 404
```

---

## 13. Observability

```bash
# App Prometheus metrics (host 8008). Look for the now-wired custom counters.
curl -s http://localhost:8008/metrics | grep -E "http_requests_total|telemetry_ingested_total|http_request_duration_seconds" | head

# EMQX dashboard: http://localhost:18083  (default admin / public)
# Prometheus UI:  http://localhost:9090
```

---

## Appendix — full endpoint inventory

| Method | Path | Auth | Body / params |
|---|---|---|---|
| GET | `/health` | none | — |
| POST | `/api/v1/auth/register` | none | `UserRegister` (email, full_name, password≥12) |
| POST | `/api/v1/auth/login` | none | form: `username`(=email), `password` |
| POST | `/api/v1/auth/refresh` | none | query `refresh_token` |
| GET | `/api/v1/users/me` | user | — |
| PATCH | `/api/v1/users/me` | user | `UserSelfUpdate` (email/full_name/password) |
| POST | `/api/v1/greenhouses/` | user | `GreenhouseCreate` |
| GET | `/api/v1/greenhouses/` | user | — |
| GET | `/api/v1/greenhouses/{id}` | owner | — |
| PATCH | `/api/v1/greenhouses/{id}` | owner | `GreenhouseUpdate` |
| DELETE | `/api/v1/greenhouses/{id}` | owner | → 204 |
| POST | `/api/v1/devices/` | owner of GH | `DeviceCreate` |
| GET | `/api/v1/devices/{id}` | owner | — |
| GET | `/api/v1/devices/greenhouse/{gh_id}` | owner | — |
| PATCH | `/api/v1/devices/{id}` | owner | `DeviceUpdate` |
| DELETE | `/api/v1/devices/{id}` | owner | → 204 |
| POST | `/api/v1/devices/{id}/commands` | owner | `DeviceCommandCreate` (503 if MQTT down) |
| GET | `/api/v1/telemetry/{device_id}` | owner | query `start_time,end_time,limit≤1000` |
| POST | `/api/v1/telemetry/` | owner | `TelemetryCreate` |
| GET | `/api/v1/alerts/greenhouse/{gh_id}` | owner | query `skip,limit≤500` |
| POST | `/api/v1/alerts/{alert_id}/acknowledge` | owner | — |
| DELETE | `/api/v1/alerts/{alert_id}/dismiss` | owner | — |
| GET | `/api/v1/alerts/rules/device/{device_id}` | owner | — |
| POST | `/api/v1/alerts/rules` | owner | `AlertRuleCreate` |
| PATCH | `/api/v1/alerts/rules/{rule_id}` | owner | `AlertRuleUpdate` |
| DELETE | `/api/v1/alerts/rules/{rule_id}` | owner | — |
| POST | `/api/v1/notifications/fcm-token` | user | `FcmTokenCreate` |
| POST | `/api/v1/notifications/test` | user | — |
| POST | `/api/v1/ml/predict` | user | `PredictionInput` |
| POST | `/api/v1/ml/predict/batch` | user | `BatchPredictionInput` (≤100) |
| POST | `/api/v1/ml/train` | **admin** | — |
| GET | `/api/v1/ml/predictions/greenhouse/{gh_id}` | owner | query `limit≤500` — historical predictions |
| GET | `/api/v1/ml/health` | none | — |
| MQTT | `greenhouse/<gh>/device/<dev>/telemetry` | broker | JSON sensor payload |
| _worker_ | (every 120s, all greenhouses) | — | aggregates telemetry → stores `predictions` |
