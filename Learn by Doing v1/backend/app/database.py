"""
Database connection and session management.

Provides SQLAlchemy setup and database session dependency for FastAPI.

Uses enhanced database utilities for:
- Connection pooling (QueuePool for production, NullPool for development)
- Health checks and diagnostics
- Retry logic with exponential backoff
- Comprehensive logging
"""

import os
import logging
from typing import Generator
from dotenv import load_dotenv
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.exc import SQLAlchemyError

from app.models import Base
from app.database_utils import (
    create_database_engine,
    validate_database_connection,
    log_connection_info,
    DatabaseConnectionError,
)
from app.logging_config import get_logger

# Configure logging with comprehensive configuration
logger = get_logger(__name__)

# Load environment variables
load_dotenv()

# Database URL from environment
DATABASE_URL = os.getenv(
    "DATABASE_URL", "postgresql://user:password@localhost/andromeda"
)

# Determine environment
ENVIRONMENT = os.getenv("ENVIRONMENT", "development").lower()
DEBUG = os.getenv("DEBUG", "False").lower() == "true"

# Log connection info (safely)
log_connection_info(DATABASE_URL)

# Create SQLAlchemy engine with best practices
try:
    engine = create_database_engine(
        database_url=DATABASE_URL,
        environment=ENVIRONMENT,
        echo_sql=DEBUG,  # Only log SQL in debug mode
        pool_size=5 if ENVIRONMENT == "production" else 1,
        max_overflow=10 if ENVIRONMENT == "production" else 0,
        pool_recycle=3600,  # Recycle connections after 1 hour
        pool_pre_ping=True,  # Validate connections before use
        connect_timeout=10,
    )
    logger.info(f"Database engine created successfully (environment={ENVIRONMENT})")
except DatabaseConnectionError as e:
    logger.error(f"Fatal error: Could not create database engine: {e}")
    raise

# Create session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def get_db() -> Generator[Session, None, None]:
    """
    Dependency for FastAPI to get database session.

    Usage in endpoints:
        @app.get("/")
        async def endpoint(db: Session = Depends(get_db)):
            ...

    Yields:
        SQLAlchemy Session object

    Raises:
        SQLAlchemyError: If database operations fail
    """
    db = SessionLocal()
    try:
        yield db
    except SQLAlchemyError as e:
        logger.error(f"Database error: {e}")
        db.rollback()
        raise
    finally:
        db.close()


def init_db() -> None:
    """
    Initialize database by creating all tables.

    Should be called during application startup.

    Raises:
        DatabaseConnectionError: If connection validation fails
    """
    try:
        logger.info("Validating database connection...")
        validate_database_connection(engine)

        logger.info("Creating database tables...")
        Base.metadata.create_all(bind=engine)
        logger.info("Database tables created/verified successfully")
    except DatabaseConnectionError as e:
        logger.error(f"Database initialization failed: {e}")
        raise
    except SQLAlchemyError as e:
        logger.error(f"SQL error during database initialization: {e}")
        raise


def drop_all_tables() -> None:
    """
    Drop all tables from database.

    WARNING: This will delete all data. Only use in development!
    """
    try:
        logger.warning("Dropping all database tables...")
        Base.metadata.drop_all(bind=engine)
        logger.warning("All tables dropped successfully")
    except SQLAlchemyError as e:
        logger.error(f"Error dropping tables: {e}")
        raise


def close_db() -> None:
    """
    Close database connections.

    Should be called during application shutdown.
    """
    try:
        from app.database_utils import dispose_engine

        dispose_engine(engine)
    except Exception as e:
        logger.error(f"Error closing database: {e}")
