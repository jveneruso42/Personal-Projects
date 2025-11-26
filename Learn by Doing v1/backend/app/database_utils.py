"""
Database utilities for Learn by Doing v1
Provides database engine creation, connection validation, and logging utilities
"""

import logging
from typing import Optional
from urllib.parse import urlparse
from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.pool import QueuePool, NullPool

logger = logging.getLogger(__name__)


class DatabaseConnectionError(Exception):
    """Custom exception for database connection errors"""
    pass


def log_connection_info(database_url: str) -> None:
    """
    Safely log database connection information without exposing credentials
    
    Args:
        database_url: Database connection URL
    """
    try:
        parsed = urlparse(database_url)
        safe_url = f"{parsed.scheme}://{parsed.hostname}:{parsed.port or 'default'}{parsed.path}"
        logger.info(f"Database connection: {safe_url}")
    except Exception as e:
        logger.warning(f"Could not parse database URL for logging: {e}")


def create_database_engine(
    database_url: str,
    environment: str = "development",
    echo_sql: bool = False,
    pool_size: int = 5,
    max_overflow: int = 10,
    pool_recycle: int = 3600,
    pool_pre_ping: bool = True,
    connect_timeout: int = 10,
) -> Engine:
    """
    Create a SQLAlchemy database engine with best practices
    
    Args:
        database_url: Database connection URL
        environment: Environment name (production, development, etc.)
        echo_sql: Whether to log SQL statements
        pool_size: Number of connections to maintain in the pool
        max_overflow: Maximum number of connections that can be created beyond pool_size
        pool_recycle: Recycle connections after this many seconds
        pool_pre_ping: Test connections before using them
        connect_timeout: Connection timeout in seconds
        
    Returns:
        SQLAlchemy Engine instance
        
    Raises:
        DatabaseConnectionError: If engine creation fails
    """
    try:
        # Choose pooling strategy based on environment
        if environment == "production":
            # Use connection pooling for production
            connect_args = {"connect_timeout": connect_timeout} if "postgresql" in database_url else {}
            
            engine = create_engine(
                database_url,
                echo=echo_sql,
                poolclass=QueuePool,
                pool_size=pool_size,
                max_overflow=max_overflow,
                pool_recycle=pool_recycle,
                pool_pre_ping=pool_pre_ping,
                connect_args=connect_args,
            )
            logger.info(f"Database engine created (environment={environment}, poolclass=QueuePool)")
        else:
            # No pooling for development
            connect_args = {"connect_timeout": connect_timeout} if "postgresql" in database_url else {}
            
            engine = create_engine(
                database_url,
                echo=echo_sql,
                poolclass=NullPool,
                pool_pre_ping=pool_pre_ping,
                connect_args=connect_args,
            )
            logger.info(f"Database engine created (environment={environment}, poolclass=NullPool)")
        
        return engine
        
    except Exception as e:
        logger.error(f"Failed to create database engine: {e}")
        raise DatabaseConnectionError(f"Could not create database engine: {e}")


def validate_database_connection(engine: Engine) -> bool:
    """
    Validate that the database connection is working
    
    Args:
        engine: SQLAlchemy Engine to test
        
    Returns:
        True if connection is valid, False otherwise
    """
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        logger.info("Database connection validated successfully")
        return True
    except SQLAlchemyError as e:
        logger.error(f"Database connection validation failed: {e}")
        return False
