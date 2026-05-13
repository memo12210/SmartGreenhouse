from app.database import engine, Base
from app.models import User, Greenhouse, Device, Telemetry

def init_db():
    print("Initializing the database tables...")
    Base.metadata.create_all(bind=engine)
    print("Tables created successfully.")

if __name__ == "__main__":
    init_db()
