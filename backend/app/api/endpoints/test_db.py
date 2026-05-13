from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db

router = APIRouter()

@router.get("/test-db")
def test_db_connection(db: Session = Depends(get_db)):
    try:
        # Try to execute a simple query to check the connection
        db.execute(text("SELECT 1"))
        return {"status": "success", "message": "Database connection is working!"}
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Database connection failed: {str(e)}"
        )
