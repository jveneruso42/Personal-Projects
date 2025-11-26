# Learn by Doing v1 - Project Structure

```
Learn by Doing v1/
│
├── 📁 frontend/                    Flutter Web Application
│   ├── 📁 lib/
│   │   ├── 📁 config/
│   │   │   ├── api_config.dart        # API endpoints configuration
│   │   │   └── web_config.dart        # Web platform configuration
│   │   │
│   │   ├── 📁 models/
│   │   │   └── auth_models.dart       # Authentication data models
│   │   │
│   │   ├── 📁 providers/
│   │   │   └── (Riverpod providers for state management)
│   │   │
│   │   ├── 📁 screens/
│   │   │   ├── home_screen.dart       # 🏠 Dashboard (simplified)
│   │   │   ├── login_screen.dart      # 🔐 Login/Signup
│   │   │   ├── profile_screen.dart    # 👤 User profile
│   │   │   ├── forgot_password_screen.dart
│   │   │   ├── reset_password_screen.dart
│   │   │   ├── pending_approval_screen.dart
│   │   │   └── unauthenticated_screen.dart
│   │   │
│   │   ├── 📁 services/
│   │   │   ├── auth_service.dart      # Authentication logic
│   │   │   ├── backend_health_service.dart
│   │   │   ├── dio_service.dart       # HTTP client
│   │   │   └── version_service.dart   # Version checking
│   │   │
│   │   ├── 📁 utils/
│   │   │   └── web_file_picker.dart   # File upload utilities
│   │   │
│   │   ├── 📁 widgets/
│   │   │   ├── branded_app_bar.dart
│   │   │   └── image_cropper_widget.dart
│   │   │
│   │   └── main.dart                  # 🚀 App entry point
│   │
│   ├── 📁 assets/
│   │   └── 📁 images/
│   │       └── BlueberryKids.jpg      # Banner image
│   │
│   ├── pubspec.yaml                   # Dependencies
│   ├── start-frontend.ps1             # Windows startup
│   └── start-frontend.sh              # Linux/Mac startup
│
│
├── 📁 backend/                     FastAPI Backend
│   ├── 📁 app/
│   │   ├── 📁 routers/
│   │   │   ├── __init__.py
│   │   │   ├── auth.py               # 🔐 Authentication endpoints
│   │   │   └── users.py              # 👥 User management
│   │   │
│   │   ├── __init__.py
│   │   ├── database.py               # 🗄️ Database configuration
│   │   ├── main.py                   # App configuration (from Andromeda)
│   │   └── models.py                 # 📊 SQLAlchemy models (User)
│   │
│   ├── 📁 migrations/                Alembic Database Migrations
│   │   ├── 📁 versions/
│   │   │   ├── 52d0af0d5e0c_initialize_schema.py
│   │   │   ├── 581f016f260d_add_profile_image_to_users_and_create_.py
│   │   │   └── add_timezone_to_users.py
│   │   ├── env.py
│   │   └── README
│   │
│   ├── .env.example                  # Environment template
│   ├── alembic.ini                   # Alembic configuration
│   ├── main.py                       # 🚀 App entry point (simplified)
│   ├── requirements.txt              # Python dependencies
│   └── start-backend.ps1             # Startup script
│
│
├── 📄 README.md                    # 📖 Complete documentation
├── 📄 QUICK_START.md               # ⚡ 5-minute setup guide
├── 📄 PROJECT_CREATION_SUMMARY.md  # 📋 What was created
└── 📄 PROJECT_FILES_COMPLETE.md    # 📚 Reference from Andromeda
```

## 🎯 Key Components

### Frontend Architecture

```
User Interface (Flutter)
    ↓
  Screens (UI Pages)
    ↓
  Services (Business Logic)
    ↓
  Dio HTTP Client
    ↓
  Backend API
```

### Backend Architecture

```
HTTP Request
    ↓
  FastAPI Router
    ↓
  Business Logic
    ↓
  SQLAlchemy ORM
    ↓
  PostgreSQL Database
```

## 📊 Data Flow

### Authentication Flow

```
Login Screen
    ↓
  POST /auth/login
    ↓
  Validate Credentials
    ↓
  Generate JWT Token
    ↓
  Return User Data
    ↓
  Store in UserData
    ↓
  Navigate to Home
```

### Profile Update Flow

```
Profile Screen
    ↓
  Edit User Info
    ↓
  PUT /users/{id}
    ↓
  Update Database
    ↓
  Return Updated User
    ↓
  Update UserData
    ↓
  Show Success
```

## 🔐 Security Layers

```
Frontend             Backend              Database
--------             -------              --------
JWT Token    →    Verify Token    →    Secure Data
Role Check   →    Role Guard      →    Access Control
HTTPS        →    CORS Policy     →    Encryption
```

## 🗂️ Database Schema

```sql
users
├── id (Primary Key)
├── email (Unique)
├── username (Unique)
├── first_name
├── last_name
├── desired_name
├── phone
├── hashed_password
├── profile_image (Binary)
├── timezone
├── role (user, admin, super_admin)
├── is_active
├── is_email_verified
├── registered_date
└── approved_date
```

## 🌐 API Endpoints

### Authentication
- `POST /auth/signup` - Create account
- `POST /auth/login` - Login
- `POST /auth/logout` - Logout
- `POST /auth/forgot-password` - Request reset
- `POST /auth/reset-password` - Reset password
- `POST /auth/verify-email` - Verify email

### Users
- `GET /users/me` - Get current user
- `GET /users/{id}` - Get user by ID
- `PUT /users/{id}` - Update user
- `DELETE /users/{id}` - Delete user

### System
- `GET /` - API status
- `GET /health` - Health check
- `GET /api/version` - Get version

## 📱 Screens

### Public (No Auth Required)
- **Login Screen** - Login/Signup tabs
- **Forgot Password** - Request password reset
- **Reset Password** - Set new password
- **Unauthenticated** - Access denied

### Protected (Auth Required)
- **Home Screen** - Dashboard with welcome
- **Profile Screen** - Edit user info
- **Pending Approval** - Waiting for admin approval

## 🎨 Navigation

```
Bottom Navigation Bar
├── Home (🏠)
└── Menu (☰) → Profile
```

## 🔧 Configuration Files

### Frontend
- `pubspec.yaml` - Flutter dependencies
- `lib/config/api_config.dart` - API settings
- `lib/config/web_config.dart` - Web platform

### Backend
- `requirements.txt` - Python packages
- `.env` - Environment variables
- `alembic.ini` - Database migrations
- `main.py` - FastAPI configuration

## 📦 Dependencies

### Frontend (Flutter)
- flutter_riverpod - State management
- go_router - Navigation
- dio - HTTP client
- google_fonts - Typography
- image - Image processing

### Backend (Python)
- fastapi - Web framework
- sqlalchemy - Database ORM
- alembic - Migrations
- pyjwt - JWT tokens
- passlib - Password hashing
- python-multipart - File uploads

## 🚀 Startup Sequence

### 1. Backend
```bash
Activate venv → Load .env → Connect to DB → Start FastAPI → Listen on :8000
```

### 2. Frontend
```bash
Load dependencies → Compile Dart → Start web server → Open :9000
```

### 3. First Access
```bash
Navigate to localhost:9000 → Check backend health → Show login screen
```

---

**Visual guide to help you navigate the Learn by Doing v1 project! 🎉**
