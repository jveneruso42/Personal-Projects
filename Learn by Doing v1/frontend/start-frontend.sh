#!/bin/bash
# Learn by Doing v1 - Frontend Startup Script

echo "🚀 Starting Learn by Doing v1 Frontend..."

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "❌ node_modules not found!"
    echo "Please run: flutter pub get"
    exit 1
fi

# Start Flutter web server
echo "Starting Flutter web server on http://localhost:9000..."
flutter run -d web-server --web-port 9000
