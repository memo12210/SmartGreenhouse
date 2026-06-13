import asyncio
import logging
import os
from typing import Optional
from app.ml.training.trainer import ModelTrainer

logger = logging.getLogger(__name__)

class MLTrainingWorker:
    def __init__(self, data_path: str = "data/raw/greenhouse_crop_yields.csv", model_path: str = None):
        self.data_path = data_path
        # Must match what InferenceService loads, so training writes where
        # inference reads.
        self.model_path = model_path or os.getenv(
            "ML_MODEL_PATH", "app/ml/models/best_model.joblib"
        )
        self._task = None
        self.is_training = False

    def _backend_dir(self) -> str:
        # backend/app/workers/ml_training_worker.py -> backend root
        return os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

    def _resolve(self, path: str) -> str:
        return path if os.path.isabs(path) else os.path.join(self._backend_dir(), path)

    def model_exists(self) -> bool:
        return os.path.isfile(self._resolve(self.model_path))

    def _find_data(self) -> Optional[str]:
        """Locate the training CSV. Returns its absolute path, or None if the
        file does not exist (no synthetic data is generated)."""
        for candidate in (self._resolve(self.data_path), os.path.abspath(self.data_path)):
            if os.path.isfile(candidate):
                return os.path.abspath(candidate)
        return None

    async def run_training(self, force: bool = False):
        if self.is_training:
            logger.info("ML Training Worker: Training already in progress.")
            return

        # Auto-training only runs when there is no model yet. A manual retrain
        # (POST /ml/train) passes force=True.
        if not force and self.model_exists():
            logger.info(
                "ML Training Worker: Model already present at %s; skipping training.",
                self._resolve(self.model_path),
            )
            return

        # The training data is required; if the CSV is absent we do NOT train.
        abs_data_path = self._find_data()
        if abs_data_path is None:
            logger.warning(
                "ML Training Worker: Training data '%s' not found; skipping training. "
                "Add the CSV and restart (or POST /api/v1/ml/train) to train a model.",
                self.data_path,
            )
            return

        self.is_training = True
        logger.info("ML Training Worker: Starting background training from %s ...", abs_data_path)
        try:
            model_save_path = self._resolve(self.model_path)
            trainer = ModelTrainer()
            # Run synchronous training in a thread to avoid blocking the event loop.
            await asyncio.to_thread(trainer.train, abs_data_path, model_save_path)
            logger.info(
                "ML Training Worker: Background training completed; model saved to %s.",
                model_save_path,
            )
        except Exception as e:
            logger.error(f"ML Training Worker: Training failed: {e}")
        finally:
            self.is_training = False

    def start(self, force: bool = False):
        if self._task is None or self._task.done():
            self._task = asyncio.create_task(self.run_training(force=force))
            logger.info("ML Training Worker: Task scheduled (force=%s).", force)

    async def stop(self):
        if self._task is not None and not self._task.done():
            self._task.cancel()
            try:
                await self._task
            except asyncio.CancelledError:
                pass
        self._task = None
        logger.info("ML Training Worker: stopped.")

ml_training_worker = MLTrainingWorker()
