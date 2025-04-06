from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv

load_dotenv()

# Database URL from environment variable or use default
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://moneymind_user:LiAPP7sBct8LZjLacQDJEMhNHc7wY2zc@dpg-cvnormre5dus73d1sqqg-a/moneymind")

# Render PostgreSQL URL format
if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

# SQLAlchemy engine with connection pooling for web service
engine = create_engine(
    DATABASE_URL,
    pool_size=5,
    max_overflow=10,
    pool_recycle=1800
)

# Session factory bound to the engine
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base class for declarative class definitions
Base = declarative_base()

# Get DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()