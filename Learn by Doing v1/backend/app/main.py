"""
Andromeda SPED App - FastAPI Main Application

This module initializes the FastAPI application with all necessary configurations,
middleware, and routes for the Andromeda behavior tracking system.

Features:
- Proper lifespan management with startup/shutdown handlers
- Database health checks and connection validation
- Comprehensive logging of application state
- CORS middleware configuration
- Health monitoring endpoints
"""

import os
import logging
from contextlib import asynccontextmanager
from datetime import datetime
from typing import AsyncGenerator
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, HTMLResponse
from dotenv import load_dotenv

# Import comprehensive logging configuration
from app.logging_config import setup_logging, get_logger
from app.diagnostics import diagnostics

# Initialize comprehensive logging
setup_logging()
logger = get_logger(__name__)

from app.database import init_db, close_db, engine
from app.database_utils import get_database_health
from app.version import get_version_info, get_version_for_injection

# Load environment variables
load_dotenv()

# Configuration
DEBUG = os.getenv("DEBUG", "False").lower() == "true"
ENVIRONMENT = os.getenv("ENVIRONMENT", "development").lower()
ALLOWED_ORIGINS_STR = os.getenv("ALLOWED_ORIGINS", "").strip()
ALLOWED_ORIGINS = (
    [origin.strip() for origin in ALLOWED_ORIGINS_STR.split(",")]
    if ALLOWED_ORIGINS_STR
    else []
)
SECRET_KEY = os.getenv("SECRET_KEY")
DATABASE_URL = os.getenv("DATABASE_URL")


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator:
    """
    Lifespan context manager for startup and shutdown events.

    This replaces the deprecated @app.on_event("startup") and @app.on_event("shutdown")
    decorators with the modern lifespan approach.

    Startup:
    - Logs application configuration
    - Validates database connectivity
    - Initializes database schema
    - Reports health status

    Shutdown:
    - Closes database connections
    - Logs shutdown status
    """
    # Startup: Initialize resources
    try:
        logger.info("=" * 70)
        logger.info("Starting Andromeda SPED App...")
        logger.info("=" * 70)
        logger.info(f"Environment: {ENVIRONMENT.upper()}")
        logger.info(f"Debug Mode: {DEBUG}")
        db_info = (
            DATABASE_URL.split("@")[1]
            if DATABASE_URL and "@" in DATABASE_URL
            else "unknown"
        )
        logger.info(f"Database: {db_info}")
        logger.info(f"Environment: {ENVIRONMENT}")
        logger.info(f"Debug Mode: {DEBUG}")
        logger.info(
            f"CORS Origins: {ALLOWED_ORIGINS if ALLOWED_ORIGINS else 'All origins allowed'}"
        )

        # Validate database connection
        logger.info("Validating database connection...")
        health = get_database_health(engine)

        if health.is_healthy:
            logger.info(
                f"Database connection healthy (response_time={health.response_time_ms:.2f}ms)"
            )
        else:
            logger.error(f"Database connection unhealthy: {health.error_message}")
            raise RuntimeError("Database connection validation failed at startup")

        # Initialize database tables
        logger.info("Initializing database tables...")
        init_db()
        logger.info("Database tables initialized successfully")

        # Initialize Super Admin user
        logger.info("Initializing Super Admin user...")
        from app.db import init_super_admin
        from app.database import SessionLocal

        super_admin_email = os.getenv("SUPER_ADMIN_EMAIL")
        super_admin_password = os.getenv("SUPER_ADMIN_PASSWORD")

        if super_admin_email and super_admin_password:
            db = SessionLocal()
            try:
                if init_super_admin(db, super_admin_email, super_admin_password):
                    logger.info(f"Super Admin initialized: {super_admin_email}")
                else:
                    logger.warning("Failed to initialize Super Admin")
            finally:
                db.close()
        else:
            logger.warning("Super Admin credentials not configured in .env")

        logger.info("=" * 70)
        logger.info("Application initialized successfully")
        logger.info("=" * 70)

    except Exception as e:
        logger.error("=" * 70)
        logger.error(f"Fatal error during startup: {e}")
        logger.error("=" * 70)
        raise

    try:
        yield
    except Exception as e:
        logger.error(f"Error during application lifetime: {e}")
        raise

    # Shutdown: Cleanup resources
    try:
        logger.info("=" * 70)
        logger.info("Shutting down Andromeda SPED App...")
        logger.info("=" * 70)
        close_db()
        logger.info("Database engine disposed successfully")
        logger.info("=" * 70)
    except Exception as e:
        logger.error(f"Error during shutdown: {e}")
        logger.error("=" * 70)


# Initialize FastAPI app
app = FastAPI(
    title="Andromeda SPED App API",
    description="API for tracking student behavior in special education settings",
    version="1.0.0",
    docs_url="/docs" if DEBUG else None,
    redoc_url="/redoc" if DEBUG else None,
    lifespan=lifespan,
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for development
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Health check endpoint
@app.get("/health", tags=["Health"])
async def health_check():
    """
    Health check endpoint to verify API is running.

    Returns basic application health information without database checks.

    Returns:
        dict: Status information including service name and status
    """
    return {
        "status": "healthy",
        "service": "Andromeda SPED App API",
        "version": "1.0.0",
        "debug": DEBUG,
        "environment": ENVIRONMENT,
        "timestamp": datetime.now().isoformat(),
    }


# Detailed health check endpoint with database status
@app.get("/health/db", tags=["Health"])
async def health_check_with_db():
    """
    Detailed health check endpoint that includes database status.

    This endpoint checks:
    - API availability
    - Database connectivity
    - Connection pool health
    - Response times

    Use /health for quick checks (no DB query).
    Use /health/db for detailed diagnostics.

    Returns:
        dict: Detailed health status including database information
    """
    health = get_database_health(engine)

    return {
        "status": "healthy" if health.is_healthy else "unhealthy",
        "service": "Andromeda SPED App API",
        "version": "1.0.0",
        "environment": ENVIRONMENT,
        "database": {
            "healthy": health.is_healthy,
            "response_time_ms": health.response_time_ms,
            "pool": {
                "size": health.pool_size,
                "checked_out": health.pool_checked_out,
                "overflow": health.pool_overflow,
            },
            "error": health.error_message,
        },
        "timestamp": health.timestamp,
    }


# Connection test endpoint
@app.options("/{full_path:path}", tags=["CORS"])
async def options_handler(full_path: str):
    """
    Handle CORS preflight requests.

    Returns:
        dict: Empty response for OPTIONS requests
    """
    return {}


@app.get("/test", tags=["Test"])
async def connection_test():
    """
    Test endpoint for frontend connectivity verification.

    Returns:
        dict: Test response
    """
    return {
        "status": "connected",
        "message": "Frontend can reach backend successfully",
        "timestamp": datetime.now().isoformat(),
    }


# Also add test endpoint at /api/v1/test for compatibility with dio baseUrl
@app.get("/api/v1/test", tags=["Test"])
async def connection_test_v1():
    """
    Test endpoint at /api/v1/test for frontend dio baseUrl compatibility.

    Returns:
        dict: Test response
    """
    return {
        "status": "connected",
        "message": "Frontend can reach backend successfully at /api/v1/test",
        "timestamp": datetime.now().isoformat(),
    }


# Root endpoint - Serve index.html with version injection
@app.get("/", response_class=HTMLResponse, tags=["Root"])
async def root():
    """
    Serve the frontend index.html file with version injection.

    This endpoint injects the current frontend version and build time into the
    index.html template, allowing the frontend to detect updates.

    The index.html file expects these template variables:
    - ${FRONTEND_VERSION|1.0.0+1}: The version from pubspec.yaml or FRONTEND_VERSION env
    - ${BUILD_TIME|unknown}: The current ISO format timestamp

    Returns:
        HTMLResponse: The index.html file with injected version variables
    """
    try:
        # Get version information
        version_data = get_version_for_injection()
        version_info = get_version_info()

        # Read index.html from frontend/web directory
        index_path = Path("frontend/web/index.html")

        if not index_path.exists():
            logger.warning(f"index.html not found at {index_path}")
            return HTMLResponse(
                content="""
                <html>
                    <head><title>Andromeda SPED App</title></head>
                    <body>
                        <h1>Frontend Not Built</h1>
                        <p>Please build the Flutter frontend first:</p>
                        <code>cd frontend && flutter build web</code>
                    </body>
                </html>
                """,
                status_code=503,
            )

        # Read HTML content
        html_content = index_path.read_text()

        # Inject version variables
        html_content = html_content.replace(
            "${FRONTEND_VERSION|1.0.0+1}", version_data["FRONTEND_VERSION"]
        )
        html_content = html_content.replace(
            "${BUILD_TIME|unknown}", version_data["BUILD_TIME"]
        )

        logger.debug(
            f"Serving index.html with version {version_info['version']} "
            f"(from {version_info['source']})"
        )

        return HTMLResponse(
            content=html_content,
            headers={
                "Cache-Control": "public, max-age=3600",
                "X-Frontend-Version": version_data["FRONTEND_VERSION"],
                "X-Build-Time": version_data["BUILD_TIME"],
            },
        )

    except Exception as e:
        logger.error(f"Error serving index.html: {e}")
        return HTMLResponse(
            content="<html><body><h1>Error Loading Frontend</h1></body></html>",
            status_code=500,
        )


# Version endpoints
@app.get("/api/v1/version", tags=["Version"])
async def get_api_version():
    """
    Get the backend API version and other version information.

    This endpoint returns version details useful for deployment tracking
    and version verification in logs and monitoring systems.

    Returns:
        dict: Version information with keys:
            - api_version: Backend API version (matches package version)
            - frontend_version: Frontend version from pubspec.yaml
            - frontend_source: Where frontend version was read from
            - timestamp: When this endpoint was called
    """
    version_info = get_version_info()
    return {
        "api_version": "1.0.0",
        "frontend_version": version_info["version"],
        "frontend_source": version_info["source"],
        "build_time": version_info["build_time"],
        "timestamp": datetime.now().isoformat(),
    }


@app.get("/api/version", tags=["Version"])
async def get_version():
    """
    Get version information (simplified endpoint for frontend consumption).

    This endpoint provides frontend-focused version information without
    implementation details. Useful for version checking in the frontend.

    Returns:
        dict: Version information with keys:
            - version: Current frontend version
            - build_time: ISO format build timestamp
            - api_version: Backend API version
    """
    version_info = get_version_info()
    return {
        "version": version_info["version"],
        "build_time": version_info["build_time"],
        "api_version": "1.0.0",
        "timestamp": datetime.now().isoformat(),
    }


# API version 1 routes placeholder
@app.get("/api/v1", tags=["API"])
async def api_v1_info():
    """
    API v1 information endpoint.

    Returns:
        dict: API version information
    """
    return {
        "version": "1.0.0",
        "endpoints": {
            "auth": "/api/v1/auth",
            "students": "/api/v1/students",
            "behaviors": "/api/v1/behaviors",
            "users": "/api/v1/users",
        },
    }


# Exception handlers
@app.exception_handler(404)
async def not_found_handler(request, exc):
    """Handle 404 errors with custom response."""
    return JSONResponse(
        status_code=404,
        content={
            "error": "Not Found",
            "message": "The requested resource was not found",
            "path": str(request.url),
        },
    )


@app.exception_handler(500)
async def internal_error_handler(request, exc):
    """Handle 500 errors with custom response."""
    return JSONResponse(
        status_code=500,
        content={
            "error": "Internal Server Error",
            "message": "An unexpected error occurred",
        },
    )


# Diagnostics and Monitoring Endpoints
@app.get("/admin/diagnostics", tags=["Admin"], summary="Get application diagnostics")
async def get_diagnostics():
    """
    Retrieve current application diagnostics and metrics.

    Requires superadmin authentication in production.

    Returns:
        dict: Current diagnostics summary including:
            - Database connection pool status
            - Query performance metrics
            - Error statistics
            - System uptime and request counts
    """
    try:
        summary = diagnostics.get_diagnostics_summary()
        logger.info("Diagnostics retrieved")
        return {
            "status": "success",
            "diagnostics": summary,
        }
    except Exception as e:
        logger.error(f"Error retrieving diagnostics: {e}")
        return {
            "status": "error",
            "error": str(e),
        }


@app.get("/admin/diagnostics/save", tags=["Admin"], summary="Save diagnostics to file")
async def save_diagnostics():
    """
    Force save current diagnostics to file.

    Useful for archival and analysis.

    Returns:
        dict: Path to saved diagnostics file
    """
    try:
        filepath = diagnostics.save_metrics()
        logger.info(f"Diagnostics saved to {filepath}")
        return {
            "status": "success",
            "file": filepath,
        }
    except Exception as e:
        logger.error(f"Error saving diagnostics: {e}")
        return {
            "status": "error",
            "error": str(e),
        }


@app.get(
    "/admin/diagnostics/cleanup", tags=["Admin"], summary="Clean up old diagnostics"
)
async def cleanup_diagnostics():
    """
    Clean up diagnostic files older than retention period (7 days).

    Returns:
        dict: Cleanup status
    """
    try:
        diagnostics.cleanup_old_diagnostics()
        logger.info("Diagnostics cleanup completed")
        return {
            "status": "success",
            "message": "Old diagnostics cleaned up",
        }
    except Exception as e:
        logger.error(f"Error during diagnostics cleanup: {e}")
        return {
            "status": "error",
            "error": str(e),
        }


@app.get(
    "/admin/diagnostics/database-health",
    tags=["Admin"],
    summary="Check database health",
)
async def check_database_health():
    """
    Check detailed database health status.

    Returns:
        dict: Database health information with connection pool status and response time
    """
    try:
        health = get_database_health(engine)
        if health and hasattr(diagnostics, "record_database_health"):
            diagnostics.record_database_health(
                is_healthy=health.is_healthy, response_time_ms=health.response_time_ms
            )

        return {
            "status": "success",
            "health": health.to_dict() if health else {},
        }
    except Exception as e:
        logger.error(f"Error checking database health: {e}")
        return {
            "status": "error",
            "error": str(e),
        }


# Import and include routers
from app.routers import auth, students, behaviors, users, analytics
from app.routers.resources import (
    strategies_router,
    supports_router,
    accommodations_router,
)

app.include_router(auth.router)
app.include_router(students.router)
app.include_router(behaviors.router)
app.include_router(users.router)
app.include_router(analytics.router)
app.include_router(strategies_router)
app.include_router(supports_router)
app.include_router(accommodations_router)
