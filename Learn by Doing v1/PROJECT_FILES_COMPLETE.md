# Learn by Doing v1 - Complete Project Files

This document contains all the files needed from the Andromeda Behavior Tracker project to create the simplified "Learn by Doing v1" project.

---

## Table of Contents

### Frontend Files
1. [lib/screens/login_screen.dart](#1-login_screendart)
2. [lib/screens/forgot_password_screen.dart](#2-forgot_password_screendart)
3. [lib/screens/reset_password_screen.dart](#3-reset_password_screendart)
4. [lib/screens/profile_screen.dart](#4-profile_screendart)
5. [lib/screens/unauthenticated_screen.dart](#5-unauthenticated_screendart)
6. [lib/screens/pending_approval_screen.dart](#6-pending_approval_screendart)
7. [lib/services/backend_health_service.dart](#7-backend_health_servicedart)
8. [lib/services/version_service.dart](#8-version_servicedart)
9. [lib/config/api_config.dart](#9-api_configdart)
10. [lib/config/web_config.dart](#10-web_configdart)
11. [NOTES: dio_provider, image_cropper_widget, image_picker_web](#11-missing-frontend-files)

### Backend Files
1. [backend/app/models.py (User model)](#12-modelspy-user-model)
2. [backend/app/routers/auth.py](#13-routersauthpy)
3. [backend/app/routers/users.py](#14-routersuserspy)
4. [backend/app/database.py](#15-databasepy)
5. [backend/app/main.py](#16-mainpy)
6. [backend/requirements.txt](#17-requirementstxt)
7. [NOTES: config.py](#18-missing-backend-files)

---

## Frontend Files

### 1. login_screen.dart

**Path:** `frontend/lib/screens/login_screen.dart`

**Purpose:** Main authentication screen with login and signup tabs. Handles user authentication, registration, password reset flows, and auto-update detection.

**Key Features:**
- Login with email or username
- Sign up with email verification and approval workflow
- Password strength indicator (WCAG 2.2 AA compliant)
- Social login placeholders (Google, Apple, Okta)
- Version checking and auto-refresh on frontend updates
- Autofill support for password managers
- Forgot password link
- Account already exists dialog with options

**Dependencies:**
- flutter/material.dart
- flutter_riverpod
- go_router
- dio
- ../main.dart (UserData)
- ../config/api_config.dart
- ../services/authentication_validators.dart
- ../services/version_service.dart
- ../services/auth_service.dart
- ../services/dio_service.dart
- ../models/auth_models.dart
- ../utils/form_validators.dart

**Full Content:** See attached file or the read_file output above (1602 lines)

---

### 2. forgot_password_screen.dart

**Path:** `frontend/lib/screens/forgot_password_screen.dart`

**Purpose:** Password reset request screen that sends a secure token to the user's email.

**Key Features:**
- Email validation
- Generic success message (security best practice - doesn't reveal if email exists)
- Branded app bar
- Simple focused interface
- Clear user guidance

**Dependencies:**
- flutter/material.dart
- ../services/api_service.dart
- ../widgets/branded_app_bar.dart

**Full Content:** See attached file (approximately 300 lines)

---

### 3. reset_password_screen.dart

**Path:** `frontend/lib/screens/reset_password_screen.dart`

**Purpose:** Password reset screen that allows users to set a new password using a token from email.

**Key Features:**
- Token extraction from URL parameters (web-compatible)
- Real-time password strength meter
- Password confirmation field with visual feedback
- WCAG 2.2 AA compliant strength indicator
- Token validation and expiration handling
- Clear security requirements display

**Dependencies:**
- flutter/material.dart
- ../services/api_service.dart
- ../models/password_reset_models.dart
- ../widgets/branded_app_bar.dart

**Full Content:** See attached file (approximately 650 lines)

---

### 4. profile_screen.dart

**Path:** `frontend/lib/screens/profile_screen.dart`

**Purpose:** User profile management screen for viewing and editing profile information.

**Key Features:**
- Profile image upload with circular cropping
- Editable user fields (first name, last name, preferred name, email, phone)
- Timezone selection
- Password change button (links to separate screen)
- Real-time change detection
- Update button only shows when changes are made
- Base64 image encoding/decoding
- Backend API integration with dio

**Dependencies:**
- flutter/material.dart
- flutter/foundation.dart
- flutter_riverpod
- dio
- go_router
- ../main.dart (UserData)
- ../config/api_config.dart
- ../widgets/compact_bottom_nav.dart
- ../widgets/image_cropper_widget.dart
- ../services/web_file_picker.dart
- ../services/dio_service.dart
- ../services/auth_service.dart

**Full Content:** See attached file (approximately 800 lines)

---

### 5. unauthenticated_screen.dart

**Path:** `frontend/lib/screens/unauthenticated_screen.dart`

**Purpose:** Screen displayed when an unauthenticated user tries to access a protected page.

**Key Features:**
- Friendly error message with image
- Tap-to-login functionality
- Responsive design for mobile and desktop
- Simple, clear user guidance

**Dependencies:**
- flutter/material.dart
- go_router

**Full Content:** See attached file (approximately 100 lines)

---

### 6. pending_approval_screen.dart

**Path:** `frontend/lib/screens/pending_approval_screen.dart`

**Purpose:** Waiting screen for newly signed-up users awaiting admin approval.

**Key Features:**
- Dr. Seuss "Waiting Place" inspired design
- Seasonal background images (4 seasons)
- Comic Neue font for whimsical feel
- Auto-logout after 5 minutes of inactivity
- Countdown timer display
- Hamburger menu with logout option
- Activity tracking to reset timer

**Dependencies:**
- flutter/material.dart
- flutter_riverpod
- google_fonts
- dart:async
- ../services/background_provider.dart
- ../services/logout_service.dart
- ../widgets/branded_app_bar.dart

**Full Content:** See attached file (approximately 250 lines)

---

### 7. backend_health_service.dart

**Path:** `frontend/lib/services/backend_health_service.dart`

**Purpose:** Service to check backend API health status and display error dialogs.

**Key Features:**
- Backend connectivity check
- Health endpoint polling
- Error dialog with retry option
- Navigation to login on failure
- 5-second timeout

**Dependencies:**
- flutter/material.dart
- go_router
- http package

**Full Content:** See attached file (approximately 80 lines)

---

### 8. version_service.dart

**Path:** `frontend/lib/services/version_service.dart`

**Purpose:** Frontend version management and update checking service.

**Key Features:**
- Version reading from AppVersion config
- LocalStorage for version tracking
- Update detection via version comparison
- Cache clearing and page refresh on updates
- Cooldown to prevent excessive checks (5 minutes)
- Web-compatible localStorage access

**Dependencies:**
- dart:async
- flutter/foundation.dart
- ../config/app_version.dart
- version_service_stub.dart (conditional import)
- version_service_web.dart (conditional import)

**Full Content:** See attached file (approximately 130 lines)

---

### 9. api_config.dart

**Path:** `frontend/lib/config/api_config.dart`

**Purpose:** Centralized API configuration for all endpoints and security settings.

**Key Features:**
- Environment-based URL selection (dev vs production)
- HTTPS enforcement for production
- Development uses 127.0.0.1:8002
- Production uses https://ruckusrulers.com
- Predefined endpoint constants
- Security headers configuration
- Timeout and retry settings

**Configuration:**
- Development: `http://127.0.0.1:8002/api/v1`
- Production: `https://ruckusrulers.com/api/v1`
- Request timeout: 30 seconds
- Max retries: 3
- Retry delay: 1000ms

**Full Content:** See attached file (approximately 120 lines)

---

### 10. web_config.dart

**Path:** `frontend/lib/config/web_config.dart`

**Purpose:** Platform-agnostic web configuration with conditional imports.

**Key Features:**
- Exports web_config_stub.dart for non-web platforms
- Exports web_config_web.dart for web platforms
- Uses dart.library.js_interop condition

**Full Content:**
```dart
/// Conditional import for web configuration
/// This file provides a platform-agnostic interface:
/// - web_config_web.dart for web platforms
/// - web_config_stub.dart for non-web platforms (tests, VM)
library;

export 'web_config_stub.dart'
    if (dart.library.js_interop) 'web_config_web.dart';
```

---

### 11. Missing Frontend Files

**NOTE:** The following files were not found in the project:

1. **lib/providers/dio_provider.dart** - Not found
   - Likely renamed to `dio_service.dart` in the services folder
   - Purpose: Dio HTTP client provider for Riverpod

2. **lib/widgets/image_cropper_widget.dart** - Not found
   - Used by profile_screen.dart for circular image cropping
   - Purpose: Interactive image cropping widget

3. **lib/utils/image_picker_web.dart** - Not found
   - Likely replaced by `services/web_file_picker.dart`
   - Purpose: Web-compatible file picker

**Recommendation:** Search for:
- `dio_service.dart` or similar
- `image_cropper` widget implementation
- `web_file_picker.dart` in services folder

---

## Backend Files

### 12. models.py (User Model)

**Path:** `backend/app/models.py`

**Purpose:** SQLAlchemy database models for the application.

**User Model Features:**
- Authentication fields (email, username, hashed_password)
- Profile fields (first_name, last_name, desired_name, phone)
- Role-based access control (pending, teacher, paraeducator, admin, super_admin)
- Approval workflow (is_approved, approved_at, approved_by_id)
- Rejection workflow (is_rejected, rejected_at, rejected_by_id)
- Password reset fields (token, expiry, requested_at)
- Profile image storage (LargeBinary)
- Timezone preference
- Timestamps (created_at, updated_at, registered_date)
- Activity flags (is_active, is_superuser)

**Other Models in File:**
- Student
- Behavior
- AssignedStudentBehavior
- Strategy
- AssignedStudentStrategy
- Support
- AssignedStudentSupport
- Accommodation
- AssignedStudentAccommodation
- StudentTrackingCounter
- StudentTrackingLog

**Full Content:** See attached file (approximately 320 lines for User model)

---

### 13. routers/auth.py

**Path:** `backend/app/routers/auth.py`

**Purpose:** Authentication router handling login, registration, password reset, and token management.

**Key Features:**
- OAuth2-compliant JWT tokens with role claims
- Modern password security (NIST SP 800-63B)
- AWS SES for password reset emails
- Role-based access control (RBAC)
- Admin user approval/rejection endpoints
- Refresh token support
- Login with email or username
- Password strength validation

**Endpoints:**
- POST /api/v1/auth/login
- POST /api/v1/auth/register
- POST /api/v1/auth/forgot-password
- POST /api/v1/auth/reset-password
- POST /api/v1/auth/refresh
- POST /api/v1/auth/logout
- GET /api/v1/auth/me
- POST /api/v1/auth/check-email
- POST /api/v1/auth/admin/approve-user (Admin only)
- POST /api/v1/auth/admin/reject-user (Admin only)
- GET /api/v1/auth/admin/pending-users (Admin only)

**Dependencies:**
- FastAPI
- SQLAlchemy
- Passlib (Argon2)
- python-jose (JWT)
- Pydantic
- python-dotenv
- Custom modules: password_validator, db, database, aws_email_service, models, security

**Full Content:** See attached file (1451 lines)

---

### 14. routers/users.py

**Path:** `backend/app/routers/users.py`

**Purpose:** User management router for profile updates, password changes, and user CRUD operations.

**Key Features:**
- User profile updates with image support
- Base64 image encoding/decoding
- Password change with current password verification
- Password strength validation
- Role management
- User activation/deactivation
- Timezone support

**Endpoints:**
- POST /api/v1/users/ (Create user)
- GET /api/v1/users/ (List users with filtering)
- GET /api/v1/users/{user_id} (Get user)
- PUT /api/v1/users/{user_id} (Update user)
- DELETE /api/v1/users/{user_id} (Delete user)
- POST /api/v1/users/{user_id}/change-password (Change password)
- POST /api/v1/users/{user_id}/activate (Activate user)
- POST /api/v1/users/{user_id}/deactivate (Deactivate user)

**Dependencies:**
- FastAPI
- SQLAlchemy
- Pydantic
- python-dotenv
- Custom modules: database, models, db, password_validator, security

**Full Content:** See attached file (approximately 550 lines)

---

### 15. database.py

**Path:** `backend/app/database.py`

**Purpose:** Database connection and session management for FastAPI.

**Key Features:**
- SQLAlchemy engine setup with connection pooling
- Database health checks and diagnostics
- Retry logic with exponential backoff
- Comprehensive logging
- Environment-based configuration (dev vs production)
- Connection pool management
  - Production: QueuePool with 5 connections, 10 overflow
  - Development: Minimal pooling
- Pre-ping validation
- 1-hour connection recycling

**Functions:**
- `get_db()` - FastAPI dependency for database sessions
- `init_db()` - Initialize database tables
- `drop_all_tables()` - Development only table deletion
- `close_db()` - Cleanup database connections

**Configuration:**
- DATABASE_URL from environment
- Pool size: 5 (prod) / 1 (dev)
- Max overflow: 10 (prod) / 0 (dev)
- Pool recycle: 3600 seconds
- Connect timeout: 10 seconds

**Dependencies:**
- SQLAlchemy
- python-dotenv
- Custom modules: models, database_utils, logging_config

**Full Content:** See attached file (approximately 150 lines)

---

### 16. main.py

**Path:** `backend/app/main.py`

**Purpose:** FastAPI main application with initialization, middleware, and routes.

**Key Features:**
- Modern lifespan management (replaces deprecated on_event)
- Database health checks on startup
- Super Admin initialization
- CORS middleware (allow all origins for development)
- Version injection for frontend
- Comprehensive logging
- Health monitoring endpoints
- Diagnostics endpoints
- Exception handlers

**Endpoints:**
- GET / (Serves frontend with version injection)
- GET /health (Basic health check)
- GET /health/db (Detailed health with database)
- GET /test (Connection test)
- GET /api/v1/test (Connection test with base URL)
- GET /api/v1/version (API version info)
- GET /api/version (Simplified version info)
- GET /api/v1 (API info)
- GET /admin/diagnostics (Get diagnostics)
- GET /admin/diagnostics/save (Save diagnostics to file)
- GET /admin/diagnostics/cleanup (Cleanup old diagnostics)
- GET /admin/diagnostics/database-health (Check DB health)

**Included Routers:**
- auth (Authentication)
- students (Student management)
- behaviors (Behavior tracking)
- users (User management)
- analytics (Analytics)
- strategies (Intervention strategies)
- supports (Support resources)
- accommodations (Student accommodations)

**Configuration:**
- DEBUG mode from environment
- ALLOWED_ORIGINS from environment
- SECRET_KEY from environment
- DATABASE_URL from environment
- Docs enabled only in DEBUG mode

**Dependencies:**
- FastAPI
- python-dotenv
- Custom modules: logging_config, diagnostics, database, database_utils, version, routers

**Full Content:** See attached file (approximately 600 lines)

---

### 17. requirements.txt

**Path:** `backend/requirements.txt`

**Purpose:** Python package dependencies for the backend.

**Key Packages:**
- **FastAPI** (>=0.115.0) - Modern web framework
- **Uvicorn[standard]** (>=0.32.0) - ASGI server
- **SQLAlchemy** (>=2.0.36) - ORM
- **psycopg2-binary** (>=2.9.10) - PostgreSQL driver
- **Alembic** (>=1.14.0) - Database migrations
- **python-dotenv** (>=1.0.1) - Environment variables
- **Pydantic** (>=2.10.0) - Data validation
- **pydantic-settings** (>=2.6.0) - Settings management
- **passlib[argon2]** (>=1.7.4) - Password hashing
- **python-jose[cryptography]** (>=3.3.0) - JWT handling
- **PyJWT** (>=2.8.0) - JWT library
- **httpx** (>=0.28.0) - HTTP client
- **pytest** (>=8.3.0) - Testing framework
- **pytest-cov** (>=6.0.0) - Coverage
- **black** (>=24.10.0) - Code formatter
- **flake8** (>=7.1.0) - Linter
- **mypy** (>=1.13.0) - Type checker
- **sendgrid** (>=6.11.0) - Email service
- **boto3** (>=1.28.0) - AWS SDK
- **cryptography** (>=42.0.0) - Cryptographic recipes

**Full Content:**
```
# Andromeda SPED App Backend Requirements
fastapi>=0.115.0
uvicorn[standard]>=0.32.0
sqlalchemy>=2.0.36
psycopg2-binary>=2.9.10
alembic>=1.14.0
python-dotenv>=1.0.1
pydantic>=2.10.0
pydantic-settings>=2.6.0
passlib[argon2]>=1.7.4
python-jose[cryptography]>=3.3.0
PyJWT>=2.8.0
httpx>=0.28.0
pytest>=8.3.0
pytest-cov>=6.0.0
black>=24.10.0
flake8>=7.1.0
mypy>=1.13.0
sendgrid>=6.11.0
boto3>=1.28.0
cryptography>=42.0.0
```

---

### 18. Missing Backend Files

**NOTE:** The following backend files were not found:

1. **backend/app/config.py** - Not found
   - Purpose: Configuration management
   - Likely integrated into other modules or uses pydantic-settings

2. **backend/main.py** at root level - Not found
   - Found instead: `backend/app/main.py` (provided above)
   - Alternative entry points exist:
     - `backend/start.py`
     - `backend/serve.py`

**Recommendation:**
- Use `backend/app/main.py` as the main application file
- Check `start.py` or `serve.py` for the application runner
- Configuration likely uses environment variables via python-dotenv
- Pydantic Settings may handle configuration in individual modules

---

## Summary

### Frontend Architecture
- **Framework:** Flutter (web-compatible)
- **State Management:** Riverpod
- **Routing:** GoRouter
- **HTTP Client:** Dio
- **UI:** Material Design with custom gradients
- **Security:** JWT tokens, HTTPS enforcement, WCAG 2.2 AA compliance

### Backend Architecture
- **Framework:** FastAPI
- **Database:** PostgreSQL with SQLAlchemy ORM
- **Authentication:** JWT with Argon2 password hashing
- **Email:** AWS SES for password resets
- **Security:** NIST SP 800-63B password standards, CORS, role-based access control

### Key Features
1. **Authentication**
   - Login with email or username
   - Registration with admin approval workflow
   - Password reset via email token
   - JWT token management with refresh tokens

2. **User Management**
   - Profile editing with image upload
   - Timezone selection
   - Password change with strength validation
   - Role-based permissions

3. **Security**
   - Modern password requirements (12+ chars, complexity)
   - Token expiration and refresh
   - HTTPS enforcement in production
   - SQL injection protection via ORM
   - XSS protection via React/Flutter frameworks

4. **User Experience**
   - Responsive design (mobile and desktop)
   - Auto-update detection with cache refresh
   - Accessibility (WCAG 2.2 AA compliant)
   - Clear error messages
   - Loading states and feedback

### Deployment Notes
- Frontend: Flutter web build to `frontend/web/`
- Backend: FastAPI with Uvicorn ASGI server
- Database: PostgreSQL with connection pooling
- Environment: Separate dev and production configs
- Version tracking: Build time injection for update detection

---

## Next Steps for "Learn by Doing v1"

1. **Create simplified project structure**
   - Strip out student/behavior tracking features
   - Keep only authentication and profile management
   - Simplify navigation (no admin dashboard needed initially)

2. **Essential features to keep**
   - Login/Signup screens
   - Profile editing
   - Password reset flow
   - Unauthenticated/Pending approval screens

3. **Features to remove/simplify**
   - Student tracking
   - Behavior logging
   - Analytics
   - Admin approval workflow (optional: can auto-approve)

4. **Database schema**
   - Keep only User model
   - Remove all tracking tables
   - Simplify to single-table design

5. **API endpoints**
   - /auth/* (keep all)
   - /users/* (keep profile management only)
   - Remove student/behavior/analytics routes

6. **Frontend components**
   - Keep authentication screens
   - Keep profile screen
   - Remove dashboard, tracking, admin pages

---

*Document generated on November 25, 2025*
*Source: Andromeda Behavior Tracker project*
*Destination: Learn by Doing v1 project*
