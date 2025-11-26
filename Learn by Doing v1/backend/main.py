"""
Learn by Doing v1 - FastAPI Backend Application
Simplified version with user authentication
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from app.routers import auth, users
from app.database import engine, Base

# Application version
VERSION = "1.0.0"


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager"""
    # Startup
    print("🚀 Starting Learn by Doing v1 backend...")
    print(f"📦 Version: {VERSION}")

    # Create all database tables
    Base.metadata.create_all(bind=engine)
    print("✅ Database tables initialized")

    yield

    # Shutdown
    print("👋 Shutting down...")


# Create FastAPI application
app = FastAPI(
    title="Learn by Doing v1 API",
    description="Backend API for Learn by Doing v1",
    version=VERSION,
    lifespan=lifespan,
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:9000",
        "http://localhost:3000",
        "http://127.0.0.1:9000",
        "http://127.0.0.1:3000",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router, prefix="/auth", tags=["Authentication"])
app.include_router(users.router, prefix="/users", tags=["Users"])


@app.get("/")
async def root():
    """Root endpoint"""
    return {"message": "Learn by Doing v1 API", "version": VERSION}


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "version": VERSION}


@app.get("/api/version")
async def get_version():
    """Get application version"""
    return {"version": VERSION, "app_name": "Learn by Doing v1"}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)
