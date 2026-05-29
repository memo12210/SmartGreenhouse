import pytest
import uuid
from datetime import datetime, timedelta, timezone, date
from unittest.mock import MagicMock, patch

from app.domain.greenhouse import Greenhouse
from app.domain.device import Device
from app.domain.telemetry import Telemetry
from app.repositories.greenhouse import GreenhouseRepository
from app.repositories.telemetry import TelemetryRepository
from app.repositories.ml import PredictionRepository
from app.services.ml import MLPredictionService
from app.ml.data.schemas import PredictionOutput

@pytest.mark.asyncio
async def test_get_aggregated_metrics(db_session):
    # Setup
    gh_repo = GreenhouseRepository(db_session)
    telemetry_repo = TelemetryRepository(db_session)

    gh = Greenhouse(
        name="Test GH",
        owner_id=uuid.uuid4(),
        extra_metadata={}
    )
    db_session.add(gh)
    await db_session.flush()

    dev = Device(
        name="Test Dev",
        serial_number="TESTMAC1",
        device_type="sensor",
        greenhouse_id=gh.id
    )
    db_session.add(dev)
    await db_session.flush()

    now = datetime.now(timezone.utc)
    t1 = Telemetry(
        device_id=dev.id,
        timestamp=now - timedelta(seconds=10),
        temperature=20.0,
        humidity=50.0,
        co2=400.0,
        light_intensity=1000.0
    )
    t2 = Telemetry(
        device_id=dev.id,
        timestamp=now - timedelta(seconds=5),
        temperature=30.0,
        humidity=60.0,
        co2=500.0,
        light_intensity=2000.0
    )
    db_session.add_all([t1, t2])
    await db_session.flush()

    # Test
    metrics = await telemetry_repo.get_aggregated_metrics(
        gh.id,
        now - timedelta(seconds=120),
        now
    )

    assert metrics["avg_temperature_C"] == 25.0
    assert metrics["min_temperature_C"] == 20.0
    assert metrics["max_temperature_C"] == 30.0
    assert metrics["humidity_percent"] == 55.0
    assert metrics["co2_ppm"] == 450.0
    assert metrics["light_intensity_lux"] == 1500.0

@pytest.mark.asyncio
async def test_ml_prediction_service_run(db_session):
    # Setup repos
    gh_repo = GreenhouseRepository(db_session)
    telemetry_repo = TelemetryRepository(db_session)
    prediction_repo = PredictionRepository(db_session)

    # Setup greenhouse with metadata
    gh = Greenhouse(
        name="Prediction GH",
        owner_id=uuid.uuid4(),
        extra_metadata={
            "crop_type": "Tomato",
            "variety": "Beefsteak",
            "planting_date": "2023-01-01",
            "harvest_date": "2023-04-01",
            "fertilizer_N_kg_ha": 100,
            "fertilizer_P_kg_ha": 50,
            "fertilizer_K_kg_ha": 150
        }
    )
    db_session.add(gh)
    await db_session.flush()

    # Mock InferenceService
    mock_inference = MagicMock()
    mock_inference.predict.return_value = PredictionOutput(
        yield_kg_per_m2=15.5,
        model_version="v1.0.0-test",
        prediction_timestamp=datetime.now().isoformat()
    )

    service = MLPredictionService(
        prediction_repo=prediction_repo,
        telemetry_repo=telemetry_repo,
        greenhouse_repo=gh_repo,
        inference_service=mock_inference
    )

    # Mock aggregated metrics return
    with patch.object(TelemetryRepository, 'get_aggregated_metrics', return_value={
        "avg_temperature_C": 25.0,
        "min_temperature_C": 20.0,
        "max_temperature_C": 30.0,
        "humidity_percent": 55.0,
        "co2_ppm": 450.0,
        "light_intensity_lux": 1500.0
    }):
        now = datetime.now(timezone.utc)
        prediction = await service.run_prediction_for_greenhouse(
            gh.id,
            now - timedelta(seconds=120),
            now
        )

        assert prediction is not None
        assert prediction.yield_kg_per_m2 == 15.5
        assert prediction.greenhouse_id == gh.id

        # Verify inference input (days_to_maturity calculation)
        mock_inference.predict.assert_called_once()
        input_data = mock_inference.predict.call_args[0][0]
        # 2023-04-01 - 2023-01-01 = 90 days
        assert input_data.days_to_maturity == 90.0
        assert input_data.fertilizer_N_kg_ha == 100.0
