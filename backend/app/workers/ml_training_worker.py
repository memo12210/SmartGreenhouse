import asyncio
import logging
import os
from app.ml.training.trainer import ModelTrainer

logger = logging.getLogger(__name__)

class MLTrainingWorker:
    def __init__(self, data_path: str = "data/raw/greenhouse_crop_yields.csv"):
        self.data_path = data_path
        self._task = None
        self.is_training = False

    async def run_training(self):
        if self.is_training:
            logger.info("ML Training Worker: Training already in progress.")
            return

        self.is_training = True
        logger.info("ML Training Worker: Starting background training...")
        try:
            # Determine the backend directory dynamically
            current_file_path = os.path.abspath(__file__)
            # backend/app/workers/ml_training_worker.py -> backend root
            backend_dir = os.path.dirname(os.path.dirname(os.path.dirname(current_file_path)))

            potential_paths = [
                os.path.join(backend_dir, self.data_path),
                os.path.abspath(self.data_path),
            ]

            abs_data_path = None
            for path in potential_paths:
                if os.path.exists(path) and os.path.isfile(path):
                    abs_data_path = os.path.abspath(path)
                    break

            if abs_data_path:
                trainer = ModelTrainer()
                # Run synchronous training in a thread to avoid blocking the event loop
                await asyncio.to_thread(trainer.train, abs_data_path)
                logger.info("ML Training Worker: Background training completed successfully.")
            else:
                logger.error(f"ML Training Worker: Training data not found. Tried paths: {potential_paths}")
        except Exception as e:
            logger.error(f"ML Training Worker: Training failed: {e}")
        finally:
            self.is_training = False

    def start(self):
        if self._task is None or self._task.done():
            self._task = asyncio.create_task(self.run_training())
            logger.info("ML Training Worker: Task scheduled.")

ml_training_worker = MLTrainingWorker()
