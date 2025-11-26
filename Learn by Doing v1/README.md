# Learn by Doing v1

A simplified learning management application built with Flutter and FastAPI. This project is derived from the Andromeda Behavior Tracker, focusing on core authentication and dashboard functionality.

## Features

### Frontend (Flutter Web)
- **Authentication System**
  - Login screen with email/username support
  - Sign up with email verification
  - Password reset via email
  - Pending approval workflow
- **Home Dashboard**
  - Personalized greeting
  - Activity overview
  - Quick stats cards
- **Profile Management**
  - Profile image upload with cropping
  - User information editing
  - Timezone selection
- **Bottom Navigation**
  - Home tab
  - Menu/Profile access via hamburger icon

### Backend (FastAPI + PostgreSQL)
- **User Management**
  - JWT authentication
  - Role-based access control (user, admin, super_admin)
  - Email verification
  - Password reset with secure tokens
- **Database**
  - PostgreSQL with SQLAlchemy ORM
  - Alembic migrations
  - User profiles with images

## Tech Stack

### Frontend
- **Framework**: Flutter 3.7+
- **State Management**: Riverpod
- **Routing**: GoRouter
- **HTTP Client**: Dio
- **Fonts**: Google Fonts (Comic Neue)

### Backend
- **Framework**: FastAPI
- **Database**: PostgreSQL
- **ORM**: SQLAlchemy
- **Migrations**: Alembic
- **Authentication**: JWT (PyJWT)
- **Email**: SMTP

## Prerequisites

- **Flutter** 3.7 or higher
- **Python** 3.9 or higher
- **PostgreSQL** 14 or higher
- **Node.js** (optional, for additional tooling)

## Installation

### 1. Clone the Repository

```bash
cd "a:\Documents\Apps - VS Code with AI\Learn by Doing v1"
```

### 2. Backend Setup

```bash
cd backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows PowerShell:
.\venv\Scripts\Activate.ps1
# Linux/Mac:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Create .env file from template
cp .env.example .env

# Edit .env file with your settings:
# - DATABASE_URL
# - SECRET_KEY (generate with: openssl rand -hex 32)
# - SMTP settings for email

# Create database
createdb learn_by_doing_v1

# Run migrations
alembic upgrade head

# Start backend
python -m uvicorn main:app --reload --host 127.0.0.1 --port 8000
# OR use the startup script:
.\start-backend.ps1
```

### 3. Frontend Setup

```bash
cd frontend

# Get Flutter dependencies
flutter pub get

# Start frontend
flutter run -d web-server --web-port 9000
# OR use the startup script:
.\start-frontend.ps1
```

## Configuration

### Backend Configuration (.env)

```env
# Database
DATABASE_URL=postgresql://postgres:password@localhost:5432/learn_by_doing_v1

# JWT Secret
SECRET_KEY=your-secret-key-here

# Email (for password reset)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
FROM_EMAIL=your-email@gmail.com

# Application
DEBUG=True
ENVIRONMENT=development
FRONTEND_URL=http://localhost:9000
```

### Frontend Configuration

Edit `frontend/lib/config/api_config.dart`:

```dart
class ApiConfig {
  static const String baseUrl = 'http://127.0.0.1:8000';
  static const Duration timeout = Duration(seconds: 30);
}
```

## Running the Application

### Development Mode

1. **Start Backend** (Terminal 1):
   ```bash
   cd backend
   .\start-backend.ps1
   ```

2. **Start Frontend** (Terminal 2):
   ```bash
   cd frontend
   .\start-frontend.ps1
   ```

3. **Access Application**:
   - Frontend: http://localhost:9000
   - Backend API: http://127.0.0.1:8000
   - API Docs: http://127.0.0.1:8000/docs

### First Time Setup

1. **Create First User**:
   - Navigate to http://localhost:9000
   - Click "Sign Up"
   - Fill in user details
   - Check your email for verification (if SMTP configured)
   - First user becomes super_admin by default

2. **Login**:
   - Use your credentials to login
   - You'll see the Dashboard

## Project Structure

```
Learn by Doing v1/
├── frontend/
│   ├── lib/
│   │   ├── config/          # API and web configuration
│   │   ├── main.dart        # App entry point
│   │   ├── models/          # Data models
│   │   ├── providers/       # Riverpod providers
│   │   ├── screens/         # UI screens
│   │   │   ├── home_screen.dart
│   │   │   ├── login_screen.dart
│   │   │   ├── profile_screen.dart
│   │   │   ├── forgot_password_screen.dart
│   │   │   ├── reset_password_screen.dart
│   │   │   ├── pending_approval_screen.dart
│   │   │   └── unauthenticated_screen.dart
│   │   ├── services/        # API services
│   │   ├── utils/           # Utilities
│   │   └── widgets/         # Reusable widgets
│   ├── assets/
│   │   └── images/          # Images and assets
│   ├── pubspec.yaml         # Flutter dependencies
│   └── start-frontend.ps1   # Startup script
│
├── backend/
│   ├── app/
│   │   ├── routers/
│   │   │   ├── auth.py      # Authentication endpoints
│   │   │   └── users.py     # User management endpoints
│   │   ├── database.py      # Database configuration
│   │   ├── main.py          # FastAPI app configuration
│   │   └── models.py        # SQLAlchemy models
│   ├── migrations/          # Alembic migrations
│   │   └── versions/
│   ├── .env.example         # Environment template
│   ├── alembic.ini          # Alembic configuration
│   ├── main.py              # App entry point
│   ├── requirements.txt     # Python dependencies
│   └── start-backend.ps1    # Startup script
│
└── README.md               # This file
```

## API Endpoints

### Authentication
- `POST /auth/signup` - Create new user account
- `POST /auth/login` - Login with credentials
- `POST /auth/logout` - Logout user
- `POST /auth/forgot-password` - Request password reset
- `POST /auth/reset-password` - Reset password with token
- `POST /auth/verify-email` - Verify email address

### Users
- `GET /users/me` - Get current user profile
- `GET /users/{user_id}` - Get user by ID
- `PUT /users/{user_id}` - Update user profile
- `DELETE /users/{user_id}` - Delete user (admin only)

### System
- `GET /` - API status
- `GET /health` - Health check
- `GET /api/version` - Get application version

## Development

### Database Migrations

Create a new migration:
```bash
cd backend
alembic revision --autogenerate -m "description"
```

Apply migrations:
```bash
alembic upgrade head
```

Rollback migration:
```bash
alembic downgrade -1
```

### Code Style

**Frontend (Dart)**:
- Follow Flutter style guide
- Use `flutter analyze` to check for issues
- Format code with `flutter format lib/`

**Backend (Python)**:
- Follow PEP 8
- Use type hints
- Format with `black`
- Lint with `flake8`

## Troubleshooting

### Backend won't start
- Check DATABASE_URL in .env
- Ensure PostgreSQL is running
- Verify virtual environment is activated
- Check port 8000 is not in use

### Frontend won't start
- Run `flutter clean` then `flutter pub get`
- Check Flutter version: `flutter doctor`
- Verify port 9000 is not in use

### Database connection errors
- Verify PostgreSQL service is running
- Check database exists: `psql -l`
- Verify credentials in .env
- Check firewall settings

### CORS errors
- Verify frontend URL in backend CORS settings
- Check API_CONFIG baseUrl in frontend
- Clear browser cache

## License

This project is derived from the Andromeda Behavior Tracker and is intended for educational purposes.

## Credits

Based on the Andromeda Behavior Tracker project, simplified for learning and demonstration purposes.

## Support

For issues or questions, please create an issue in the repository.
