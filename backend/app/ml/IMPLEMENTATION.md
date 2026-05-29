# Periodic ML Predictions Implementation Plan

This plan outlines the steps to implement periodic ML predictions (every 2 minutes) on collected telemetry data within that time period.

## Data Source Strategy

Based on the system requirements and dataset analysis, the following data mapping will be used for predictions:

| Field | Source | Note |
|-------|--------|------|
| `crop_type`, `variety`, `planting_date`, `harvest_date` | `Greenhouse.extra_metadata` | Extracted from JSON |
| `fertilizer_N/P/K_kg_ha` | `Greenhouse.extra_metadata` | Extracted from JSON |
| `days_to_maturity` | Calculated | `harvest_date` - `planting_date` |
| `avg/min/max_temperature_C` | `Telemetry` | Aggregated over 2-minute window |
| `humidity_percent`, `co2_ppm`, `light_intensity_lux` | `Telemetry` | Averages over 2-minute window |
| `photoperiod_hours` | Constant (12.46) | Dataset average |
| `irrigation_mm` | Constant (7.00) | Dataset average |
| `pest_severity` | Constant (1.81) | Dataset average |
| `soil_pH` | Constant (6.32) | Dataset average |

## Proposed Changes

### Database & Domain

#### [NEW] [ml.py](file:///home/memo/Documents/Projects/SmartGreenhouse/backend/app/domain/ml.py)
- Define `Prediction` model.
- Fields: `id`, `greenhouse_id` (UUID), `yield_kg_per_m2` (Float), `model_version` (String), `timestamp` (DateTime).

#### [telemetry.py](file:///home/memo/Documents/Projects/SmartGreenhouse/backend/app/repositories/telemetry.py)
- Add `get_aggregated_metrics(greenhouse_id, start_time, end_time)`:
    - Calculates MIN, MAX, AVG for temperature.
    - Calculates AVG for humidity, CO2, and light intensity.

#### [NEW] [ml.py](file:///home/memo/Documents/Projects/SmartGreenhouse/backend/app/repositories/ml.py)
- `PredictionRepository` for saving `Prediction` entities.

---

### Workers & Scheduling

#### [NEW] [ml_prediction_worker.py](file:///home/memo/Documents/Projects/SmartGreenhouse/backend/app/workers/ml_prediction_worker.py)
- `MLPredictionWorker` logic:
    1. Fetch all greenhouses.
    2. For each:
        a. Extract metadata and calculate `days_to_maturity`.
        b. Fetch aggregated telemetry metrics for the last 120 seconds.
        c. Use dataset constants for photoperiod, irrigation, pest, and pH.
        d. Run inference and save result.
- Interval: 120 seconds.

#### [main.py](file:///home/memo/Documents/Projects/SmartGreenhouse/backend/app/main.py)
- Register and start `MLPredictionWorker` in `lifespan`.

---

### Services

#### [NEW] [ml.py](file:///home/memo/Documents/Projects/SmartGreenhouse/backend/app/services/ml.py)
- `MLPredictionService` to encapsulate the business logic of gathering data and running the prediction.

## Verification Plan

### Automated Tests
- **Repository Tests**: Verify `get_aggregated_metrics` returns correct values for a set of test telemetry.
- **Service Tests**: Mock `InferenceService` and verify data mapping from `Greenhouse` metadata and `Telemetry` aggregations.
- **Command**: `pytest backend/app/tests/ml/test_periodic_predictions.py`

### Manual Verification
- Ingest telemetry for a test greenhouse via MQTT.
- Ensure `extra_metadata` is populated for the test greenhouse.
- Wait for the worker to trigger (check logs).
- Verify the `predictions` table contains a new entry with expected values.
