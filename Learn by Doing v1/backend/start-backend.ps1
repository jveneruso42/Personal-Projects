# Learn by Doing v1 - Backend Startup Script

Write-Host "🚀 Starting Learn by Doing v1 Backend..." -ForegroundColor Green

# Check if virtual environment exists
if (-not (Test-Path "venv")) {
    Write-Host "❌ Virtual environment not found!" -ForegroundColor Red
    Write-Host "Please run: python -m venv venv" -ForegroundColor Yellow
    exit 1
}

# Activate virtual environment
Write-Host "Activating virtual environment..." -ForegroundColor Cyan
& ".\venv\Scripts\Activate.ps1"

# Check if .env file exists
if (-not (Test-Path ".env")) {
    Write-Host "⚠️  No .env file found. Copying from .env.example..." -ForegroundColor Yellow
    Copy-Item ".env.example" ".env"
    Write-Host "Please edit .env file with your settings" -ForegroundColor Yellow
}

# Start the backend
Write-Host "Starting FastAPI server on http://127.0.0.1:8000..." -ForegroundColor Green
python -m uvicorn main:app --reload --host 127.0.0.1 --port 8000
