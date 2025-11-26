# Backend Standards & Best Practices

## Core Principles

- Follow the SOLID principles
- Follow the ACID principles
- Ensure cognitive complexity is no higher than 15
- Maintain high code quality and readability
- Prioritize security, performance, and maintainability

---

## Python Best Practices

### Code Style & Quality

#### PEP 8 Compliance
```python
# ✅ GOOD: PEP 8 compliant
def process_user_data(user_id: int, include_history: bool = False) -> dict:
    """Process user data with optional history inclusion."""
    user = get_user(user_id)
    if user is None:
        raise ValueError(f"User {user_id} not found")
    
    return format_user_response(user, include_history)


# ❌ BAD: Non-compliant formatting
def processUserData(userId,includeHistory=False)->dict:
    user=get_user(userId)
    if user==None:
        raise ValueError("User not found")
    return formatUserResponse(user,includeHistory)
```

#### Type Hints (Required)
```python
# ✅ GOOD: Complete type annotations
from typing import Optional, List, Dict, Union

def fetch_users(
    limit: int,
    offset: int = 0,
    role: Optional[str] = None
) -> List[Dict[str, Union[int, str]]]:
    """Fetch users with optional role filter."""
    pass


# ❌ BAD: No type hints
def fetch_users(limit, offset=0, role=None):
    pass
```

#### Docstrings (Google Style)
```python
# ✅ GOOD: Comprehensive docstring
def validate_email(email: str) -> bool:
    """Validate email format using RFC 5322 standards.
    
    Args:
        email: The email address to validate.
        
    Returns:
        True if email is valid, False otherwise.
        
    Raises:
        ValueError: If email is None or empty string.
        
    Example:
        >>> validate_email("user@example.com")
        True
    """
    pass


# ❌ BAD: Missing documentation
def validate_email(email):
    pass
```

### Error Handling & Validation

```python
# ✅ GOOD: Explicit error handling
class UserNotFoundError(Exception):
    """Raised when a user cannot be found."""
    pass


def get_user(user_id: int) -> "User":
    """Get user by ID."""
    user = db.session.query(User).filter(User.id == user_id).first()
    
    if not user:
        raise UserNotFoundError(f"User with id {user_id} not found")
    
    return user


# ❌ BAD: Silent failures or generic exceptions
def get_user(user_id):
    user = db.session.query(User).filter(User.id == user_id).first()
    return user  # Returns None silently


# ❌ BAD: Catching all exceptions
def get_user(user_id):
    try:
        return db.session.query(User).filter(User.id == user_id).first()
    except Exception:  # Too broad
        return None
```

### Code Organization

```python
# ✅ GOOD: Organized module structure
# app/services/user_service.py

from typing import Optional, List
from app.models import User
from app.schemas import UserCreate, UserUpdate, UserResponse
from app.database import db


class UserService:
    """Service for user business logic."""
    
    @staticmethod
    def create_user(user_data: UserCreate) -> User:
        """Create new user."""
        user = User(**user_data.dict())
        db.session.add(user)
        db.session.commit()
        return user
    
    @staticmethod
    def get_user(user_id: int) -> Optional[User]:
        """Fetch user by ID."""
        return db.session.query(User).filter(User.id == user_id).first()
    
    @staticmethod
    def list_users(limit: int = 10, offset: int = 0) -> List[User]:
        """List users with pagination."""
        return db.session.query(User).limit(limit).offset(offset).all()


# ❌ BAD: All logic in one file
# app.py
def create_user():
    pass

def get_user():
    pass

def list_users():
    pass
```

---

## SQLAlchemy Best Practices

### Model Definition

```python
# ✅ GOOD: Well-structured SQLAlchemy model
from datetime import datetime
from sqlalchemy import Column, Integer, String, Boolean, DateTime, Index
from sqlalchemy.orm import declarative_base

Base = declarative_base()


class User(Base):
    """User model with proper indexing and constraints."""
    
    __tablename__ = "users"
    
    # Primary Key
    id = Column(Integer, primary_key=True, index=True)
    
    # Core Fields
    email = Column(String(255), unique=True, nullable=False, index=True)
    username = Column(String(100), unique=True, nullable=False, index=True)
    first_name = Column(String(100), nullable=False)
    last_name = Column(String(100), nullable=False)
    
    # Status Fields
    is_active = Column(Boolean, default=True, nullable=False)
    is_verified = Column(Boolean, default=False, nullable=False)
    
    # Timestamps
    created_at = Column(
        DateTime,
        default=datetime.utcnow,
        nullable=False,
        index=True
    )
    updated_at = Column(
        DateTime,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
        nullable=False
    )
    
    # Composite Index
    __table_args__ = (
        Index("ix_user_email_status", "email", "is_active"),
    )
    
    def __repr__(self) -> str:
        return f"<User(id={self.id}, email={self.email})>"


# ❌ BAD: Poorly structured model
class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True)
    email = Column(String)  # No constraints, no index
    is_active = Column(Boolean)  # No default
    created_at = Column(DateTime)  # No default, no index
```

### Query Patterns

```python
# ✅ GOOD: Efficient queries with joins and eager loading
from sqlalchemy.orm import joinedload, Session

def get_user_with_posts(db: Session, user_id: int) -> Optional[User]:
    """Get user with posts eagerly loaded."""
    return db.query(User).options(
        joinedload(User.posts)
    ).filter(User.id == user_id).first()


def search_active_users(db: Session, email_pattern: str) -> List[User]:
    """Search active users by email pattern."""
    return db.query(User).filter(
        User.is_active == True,
        User.email.ilike(f"%{email_pattern}%")
    ).all()


# ❌ BAD: N+1 query problem
def get_users_with_posts(db: Session) -> List[User]:
    users = db.query(User).all()  # Query 1
    for user in users:
        posts = db.query(Post).filter(Post.user_id == user.id).all()  # N queries
        user.posts = posts
    return users


# ❌ BAD: Inefficient wildcard search
def search_users(db: Session, email: str):
    return db.query(User).filter(
        User.email.like(f"%{email}%")  # Slow on large datasets
    ).all()
```

### Session Management

```python
# ✅ GOOD: Context manager for session handling
from sqlalchemy.orm import Session
from contextlib import contextmanager

@contextmanager
def get_db_session():
    """Context manager for database sessions."""
    session = SessionLocal()
    try:
        yield session
        session.commit()
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()


# Usage
with get_db_session() as db:
    user = User(email="user@example.com")
    db.add(user)


# ❌ BAD: Manual session management
session = SessionLocal()
user = User(email="user@example.com")
session.add(user)
session.commit()
session.close()  # Might not execute if exception occurs
```

### Type Safety with Static Type Checkers

**Problem**: SQLAlchemy uses Python descriptors for model attributes. When you define a column like `id = Column(Integer)`, the static type checker (Pylance/Pyright) sees this as `Column[int]`, but at runtime it behaves as a regular `int`. This causes type errors when accessing or assigning attributes.

**Solution**: Use `getattr()` to read attributes and `setattr()` to write attributes. These built-in functions bypass static type checking while maintaining full runtime correctness.

#### Reading Model Attributes with getattr()

```python
# ✅ GOOD: Use getattr() to read SQLAlchemy model attributes
def _build_user_response(db_user: User) -> UserResponse:
    """Build user response using getattr() to avoid type errors."""
    user_id: int = getattr(db_user, "id")
    email: str = getattr(db_user, "email")
    first_name: str = getattr(db_user, "first_name")
    last_name: str = getattr(db_user, "last_name")
    is_active: bool = getattr(db_user, "is_active")
    created_at: datetime = getattr(db_user, "created_at")
    
    return UserResponse(
        id=user_id,
        email=email,
        first_name=first_name,
        last_name=last_name,
        is_active=is_active,
        created_at=created_at
    )


# ❌ BAD: Direct attribute access causes type errors
def _build_user_response(db_user: User) -> UserResponse:
    # Error: Cannot assign Column[int] to int
    user_id: int = db_user.id
    # Error: Cannot assign Column[str] to str
    email: str = db_user.email
    
    return UserResponse(id=user_id, email=email)
```

#### Writing Model Attributes with setattr()

```python
# ✅ GOOD: Use setattr() to write SQLAlchemy model attributes
@router.put("/users/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: int,
    user: UserUpdate,
    db: Session = Depends(get_db)
):
    """Update user using setattr() to avoid type errors."""
    db_user = db.query(User).filter(User.id == user_id).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Use setattr() for all attribute updates
    if user.email is not None:
        setattr(db_user, "email", user.email)
    if user.first_name is not None:
        setattr(db_user, "first_name", user.first_name)
    if user.last_name is not None:
        setattr(db_user, "last_name", user.last_name)
    if user.is_active is not None:
        setattr(db_user, "is_active", user.is_active)
    
    setattr(db_user, "updated_at", datetime.utcnow())
    
    db.commit()
    db.refresh(db_user)
    
    return _build_user_response(db_user)


# ❌ BAD: Direct assignment causes type errors
@router.put("/users/{user_id}", response_model=UserResponse)
async def update_user(user_id: int, user: UserUpdate, db: Session = Depends(get_db)):
    db_user = db.query(User).filter(User.id == user_id).first()
    
    # Error: Cannot assign str to Column[str]
    db_user.email = user.email
    # Error: Cannot assign bool to Column[bool]
    db_user.is_active = user.is_active
```

#### Type Assertions After Queries

```python
# ✅ GOOD: Assert non-None after .first() queries
@router.post("/change-password")
async def change_password(request: ChangePasswordRequest, db: Session = Depends(get_db)):
    """Change password with type assertion."""
    user = db.query(User).filter(User.id == request.user_id).first()
    
    # Assert satisfies the type checker that user is not None
    assert user is not None
    
    # Now we can safely access user attributes
    current_hash = str(getattr(user, "hashed_password"))
    if not verify_password(request.old_password, current_hash):
        raise HTTPException(status_code=400, detail="Invalid password")
    
    new_hash = hash_password(request.new_password)
    setattr(user, "hashed_password", new_hash)
    db.commit()


# ❌ BAD: No type assertion causes potential None errors
@router.post("/change-password")
async def change_password(request: ChangePasswordRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == request.user_id).first()
    
    # Error: user may be None, type checker complains
    current_hash = user.hashed_password
```

#### Explicit Type Conversions

```python
# ✅ GOOD: Explicit str() conversion for function parameters
def verify_user_password(db_user: User, password: str) -> bool:
    """Verify password with explicit type conversion."""
    # Convert Column[str] to str for the function parameter
    hashed_password = str(getattr(db_user, "hashed_password"))
    return verify_password(password, hashed_password)


# ❌ BAD: Passing Column[str] to function expecting str
def verify_user_password(db_user: User, password: str) -> bool:
    # Error: verify_password expects str, receives Column[str]
    return verify_password(password, db_user.hashed_password)
```

#### Complete Example: Type-Safe CRUD Operations

```python
from datetime import datetime
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

router = APIRouter()


def _build_user_response(db_user: User) -> UserResponse:
    """Build user response with type safety."""
    return UserResponse(
        id=getattr(db_user, "id"),
        email=getattr(db_user, "email"),
        first_name=getattr(db_user, "first_name"),
        last_name=getattr(db_user, "last_name"),
        is_active=getattr(db_user, "is_active"),
        created_at=getattr(db_user, "created_at"),
        updated_at=getattr(db_user, "updated_at")
    )


@router.post("/users", response_model=UserResponse)
async def create_user(user: UserCreate, db: Session = Depends(get_db)):
    """Create user with type-safe attribute access."""
    db_user = User(
        email=user.email,
        first_name=user.first_name,
        last_name=user.last_name,
        hashed_password=hash_password(user.password),
        is_active=True,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow()
    )
    
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    return _build_user_response(db_user)


@router.get("/users/{user_id}", response_model=UserResponse)
async def get_user(user_id: int, db: Session = Depends(get_db)):
    """Get user with type-safe attribute access."""
    db_user = db.query(User).filter(User.id == user_id).first()
    
    if db_user is None:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Type assertion satisfies the type checker
    assert db_user is not None
    
    return _build_user_response(db_user)


@router.put("/users/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: int,
    user: UserUpdate,
    db: Session = Depends(get_db)
):
    """Update user with type-safe setattr()."""
    db_user = db.query(User).filter(User.id == user_id).first()
    
    if db_user is None:
        raise HTTPException(status_code=404, detail="User not found")
    
    assert db_user is not None
    
    # Use setattr() for all updates
    if user.email is not None:
        setattr(db_user, "email", user.email)
    if user.first_name is not None:
        setattr(db_user, "first_name", user.first_name)
    if user.last_name is not None:
        setattr(db_user, "last_name", user.last_name)
    
    setattr(db_user, "updated_at", datetime.utcnow())
    
    db.commit()
    db.refresh(db_user)
    
    return _build_user_response(db_user)


@router.delete("/users/{user_id}")
async def delete_user(user_id: int, db: Session = Depends(get_db)):
    """Delete user with type assertion."""
    db_user = db.query(User).filter(User.id == user_id).first()
    
    if db_user is None:
        raise HTTPException(status_code=404, detail="User not found")
    
    assert db_user is not None
    
    db.delete(db_user)
    db.commit()
    
    return {"message": "User deleted successfully"}
```

**Key Takeaways**:
- Use `getattr(model, "attribute")` to read SQLAlchemy model attributes
- Use `setattr(model, "attribute", value)` to write SQLAlchemy model attributes
- Always add `assert result is not None` after `.first()` queries
- Use explicit type conversions like `str()` when passing to functions expecting specific types
- This pattern maintains runtime correctness while satisfying static type checkers

---

## FastAPI Best Practices

### API Structure

```python
# ✅ GOOD: Well-organized FastAPI application
# app/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.v1 import users, admin, students
from app.core.config import settings

app = FastAPI(
    title="Andromeda API",
    description="Educational behavior tracking system",
    version="1.0.0"
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# API Routers
app.include_router(users.router, prefix="/api/v1/users", tags=["users"])
app.include_router(admin.router, prefix="/api/v1/admin", tags=["admin"])
app.include_router(students.router, prefix="/api/v1/students", tags=["students"])


# ❌ BAD: All endpoints in one file
@app.get("/users")
def get_users():
    pass

@app.post("/users")
def create_user():
    pass

@app.get("/admin/users")
def admin_get_users():
    pass
```

### Request/Response Schemas

```python
# ✅ GOOD: Comprehensive Pydantic schemas
from pydantic import BaseModel, EmailStr, Field, validator
from typing import Optional
from datetime import datetime


class UserBase(BaseModel):
    """Base user schema with common fields."""
    email: EmailStr
    first_name: str = Field(..., min_length=1, max_length=100)
    last_name: str = Field(..., min_length=1, max_length=100)
    phone: Optional[str] = Field(None, regex=r"^\+?1?\d{9,15}$")


class UserCreate(UserBase):
    """Schema for creating users."""
    password: str = Field(..., min_length=8, max_length=255)
    
    @validator('password')
    def validate_password(cls, v):
        if not any(c.isupper() for c in v):
            raise ValueError('Password must contain uppercase letter')
        if not any(c.isdigit() for c in v):
            raise ValueError('Password must contain digit')
        return v


class UserResponse(UserBase):
    """Schema for user responses (excludes sensitive data)."""
    id: int
    is_active: bool
    created_at: datetime
    
    class Config:
        from_attributes = True  # Support ORM models


class UserUpdate(BaseModel):
    """Schema for updating users."""
    first_name: Optional[str] = Field(None, min_length=1)
    last_name: Optional[str] = Field(None, min_length=1)
    phone: Optional[str] = None


# ❌ BAD: Loose validation
class User(BaseModel):
    email: str  # No EmailStr validation
    first_name: str  # No length constraints
    password: str  # No password strength requirements
```

### Route Handlers

```python
# ✅ GOOD: Clean, documented route handlers
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas import UserCreate, UserResponse
from app.services.user_service import UserService

router = APIRouter()


@router.post(
    "/",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create new user",
    responses={
        201: {"description": "User created successfully"},
        400: {"description": "Invalid input"},
        409: {"description": "User already exists"},
    }
)
def create_user(
    user_data: UserCreate,
    db: Session = Depends(get_db)
) -> UserResponse:
    """Create a new user in the system.
    
    - **email**: Must be unique and valid
    - **password**: Must be at least 8 characters with uppercase and digit
    """
    existing_user = db.query(User).filter(User.email == user_data.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="User with this email already exists"
        )
    
    user = UserService.create_user(user_data)
    return user


@router.get("/{user_id}", response_model=UserResponse)
def get_user(
    user_id: int = Path(..., gt=0),
    db: Session = Depends(get_db)
) -> UserResponse:
    """Get user by ID."""
    user = UserService.get_user(user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"User {user_id} not found"
        )
    return user


# ❌ BAD: Unclear error handling
@router.post("/")
def create_user(user_data: dict, db: Session):
    user = User(**user_data)
    db.add(user)
    db.commit()
    return user  # No error handling


# ❌ BAD: No documentation
@router.get("/{id}")
def get_user(id: int, db: Session = Depends(get_db)):
    return db.query(User).filter(User.id == id).first()
```

### Dependency Injection

```python
# ✅ GOOD: Reusable dependencies with DI
from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.core.security import verify_token

def get_db() -> Session:
    """Database session dependency."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_current_user(
    token: str = Header(...),
    db: Session = Depends(get_db)
) -> User:
    """Get current authenticated user."""
    payload = verify_token(token)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials"
        )
    
    user = db.query(User).filter(User.id == payload['user_id']).first()
    if not user or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found or inactive"
        )
    return user


def get_admin_user(
    current_user: User = Depends(get_current_user)
) -> User:
    """Ensure user has admin role."""
    if current_user.role != 'admin':
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    return current_user


# Usage
@router.get("/admin/users")
def admin_list_users(
    admin: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    return db.query(User).all()


# ❌ BAD: Repeated dependency logic
@router.get("/users")
def get_users(db: Session = Depends(get_db)):
    token = request.headers.get("authorization")
    if not token:
        raise HTTPException(status_code=401)
    payload = verify_token(token)
    user = db.query(User).filter(User.id == payload['user_id']).first()
    if not user:
        raise HTTPException(status_code=401)
    return db.query(User).all()
```

### JWT Token Handling (Critical)

**Problem**: JWT tokens use RFC 7519 standard field names. The most common issue is accessing `current_user["id"]` when JWT uses `"sub"` for user ID.

**JWT Token Structure**:
```python
{
    "sub": "15",              # Subject (user_id) - STRING, not int!
    "email": "user@example.com",
    "role": "admin",
    "permissions": [...],
    "first_name": "John",
    "last_name": "Doe",
    "desired_name": "Johnny",
    "exp": 1234567890,        # Expiration timestamp
    "iat": 1234567890,        # Issued at timestamp
    "type": "access"          # Token type
}
```

#### Correct JWT Field Access

```python
# ✅ GOOD: Correct JWT field access with type annotation
from typing import Dict, Any

@router.put("/resources/{resource_id}", response_model=ResourceResponse)
def update_resource(
    resource_id: int,
    resource_data: ResourceUpdate,
    current_user: Dict[str, Any] = Depends(get_current_user),  # Dict, not User!
    db: Session = Depends(get_db)
) -> ResourceResponse:
    """Update resource with JWT user info."""
    db_resource = db.query(Resource).filter(Resource.id == resource_id).first()
    
    if not db_resource:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Resource not found"
        )
    
    # ✅ CORRECT: Access JWT 'sub' field and convert to int
    setattr(db_resource, "updated_by_id", int(current_user["sub"]))
    
    # ✅ CORRECT: Use .get() with fallback for optional fields
    setattr(db_resource, "updated_by_name", 
            current_user.get("desired_name") or 
            f"{current_user.get('first_name', '')} {current_user.get('last_name', '')}")
    
    # Update other fields
    if resource_data.name is not None:
        setattr(db_resource, "name", resource_data.name)
    
    setattr(db_resource, "updated_at", datetime.utcnow())
    
    db.commit()
    db.refresh(db_resource)
    
    return _build_resource_response(db_resource)


# ❌ BAD: Using current_user: User type annotation
@router.put("/resources/{resource_id}")
def update_resource(
    resource_id: int,
    resource_data: ResourceUpdate,
    current_user: User = Depends(get_current_user),  # Wrong! get_current_user returns dict
    db: Session = Depends(get_db)
):
    # This will cause type errors and runtime failures
    db_resource.updated_by_id = current_user.id  # AttributeError: dict has no attribute 'id'


# ❌ BAD: Accessing 'id' instead of 'sub'
@router.put("/resources/{resource_id}")
def update_resource(
    resource_id: int,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # KeyError: 'id' - JWT tokens use 'sub' not 'id'!
    db_resource.updated_by_id = current_user["id"]


# ❌ BAD: Not converting 'sub' string to int
@router.put("/resources/{resource_id}")
def update_resource(
    resource_id: int,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # TypeError: 'sub' is a string, database expects int
    db_resource.updated_by_id = current_user["sub"]
```

#### JWT Field Access Checklist

**Always follow these rules when accessing JWT token fields:**

1. **Type Annotation**: Use `current_user: Dict[str, Any]` NOT `current_user: User`
2. **User ID**: Access `int(current_user["sub"])` NOT `current_user["id"]`
3. **String Conversion**: JWT 'sub' is always a string, convert to int for database IDs
4. **Safe Access**: Use `.get(key, default)` for optional fields to avoid KeyError
5. **Name Fields**: Prefer `desired_name` over concatenating `first_name` + `last_name`

```python
# ✅ GOOD: Complete example with all best practices
from typing import Dict, Any
from datetime import datetime

@router.post("/resources", response_model=ResourceResponse)
def create_resource(
    resource_data: ResourceCreate,
    current_user: Dict[str, Any] = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> ResourceResponse:
    """Create resource with proper JWT field access."""
    
    # Extract user info with proper type conversion and fallbacks
    user_id = int(current_user["sub"])  # Convert string to int
    user_name = (
        current_user.get("desired_name") or 
        f"{current_user.get('first_name', '')} {current_user.get('last_name', '')}".strip() or
        current_user.get("email", "Unknown")
    )
    
    db_resource = Resource(
        name=resource_data.name,
        description=resource_data.description,
        created_by_id=user_id,
        created_by_name=user_name,
        updated_by_id=user_id,
        updated_by_name=user_name,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow()
    )
    
    db.add(db_resource)
    db.commit()
    db.refresh(db_resource)
    
    return _build_resource_response(db_resource)


@router.put("/resources/{resource_id}", response_model=ResourceResponse)
def update_resource(
    resource_id: int,
    resource_data: ResourceUpdate,
    current_user: Dict[str, Any] = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> ResourceResponse:
    """Update resource with proper JWT field access."""
    db_resource = db.query(Resource).filter(Resource.id == resource_id).first()
    
    if not db_resource:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Resource not found"
        )
    
    # Update tracking fields
    setattr(db_resource, "updated_by_id", int(current_user["sub"]))
    setattr(db_resource, "updated_by_name", 
            current_user.get("desired_name") or 
            f"{current_user.get('first_name', '')} {current_user.get('last_name', '')}")
    setattr(db_resource, "updated_at", datetime.utcnow())
    
    # Update resource fields
    if resource_data.name is not None:
        setattr(db_resource, "name", resource_data.name)
    if resource_data.description is not None:
        setattr(db_resource, "description", resource_data.description)
    
    db.commit()
    db.refresh(db_resource)
    
    return _build_resource_response(db_resource)


@router.delete("/resources/{resource_id}")
def delete_resource(
    resource_id: int,
    current_user: Dict[str, Any] = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete resource with proper JWT field access."""
    db_resource = db.query(Resource).filter(Resource.id == resource_id).first()
    
    if not db_resource:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Resource not found"
        )
    
    # Log deletion with user info
    user_id = int(current_user["sub"])
    user_name = current_user.get("desired_name") or current_user.get("email")
    logger.info(f"Resource {resource_id} deleted by user {user_id} ({user_name})")
    
    db.delete(db_resource)
    db.commit()
    
    return {"message": "Resource deleted successfully"}
```

#### Common JWT Fields Reference

| JWT Field | Type | Description | Example Access |
|-----------|------|-------------|----------------|
| `sub` | string | User ID (Subject) | `int(current_user["sub"])` |
| `email` | string | User email | `current_user["email"]` |
| `role` | string | User role | `current_user.get("role", "user")` |
| `permissions` | list | User permissions | `current_user.get("permissions", [])` |
| `first_name` | string | First name | `current_user.get("first_name", "")` |
| `last_name` | string | Last name | `current_user.get("last_name", "")` |
| `desired_name` | string | Preferred name | `current_user.get("desired_name")` |
| `exp` | int | Expiration timestamp | `current_user["exp"]` |
| `iat` | int | Issued at timestamp | `current_user["iat"]` |
| `type` | string | Token type | `current_user.get("type", "access")` |

**Remember**: Never access `current_user["id"]` - it doesn't exist! Always use `int(current_user["sub"])`.

---

## PostgreSQL Best Practices

### Connection Management

```python
# ✅ GOOD: Connection pooling with environment-based configuration
from sqlalchemy import create_engine, event
from sqlalchemy.pool import QueuePool
from app.core.config import settings

# Connection string from environment
DATABASE_URL = (
    f"postgresql://{settings.DB_USER}:{settings.DB_PASSWORD}"
    f"@{settings.DB_HOST}:{settings.DB_PORT}/{settings.DB_NAME}"
)

engine = create_engine(
    DATABASE_URL,
    poolclass=QueuePool,
    pool_size=10,
    max_overflow=20,
    pool_pre_ping=True,  # Verify connections before using
    pool_recycle=3600,   # Recycle connections after 1 hour
    echo=settings.DEBUG,
)


# Handle connection errors gracefully
@event.listens_for(engine, "connect")
def receive_connect(dbapi_conn, connection_record):
    """Set connection timeout and idle session timeout."""
    dbapi_conn.isolation_level = None
    cursor = dbapi_conn.cursor()
    cursor.execute("SET idle_in_transaction_session_timeout = '5min'")
    cursor.close()


# ❌ BAD: No connection pooling
engine = create_engine(f"postgresql://user:pass@localhost/db")

# ❌ BAD: Hardcoded credentials
DATABASE_URL = "postgresql://admin:password123@localhost:5432/mydb"
```

### Schema Design

```python
# ✅ GOOD: Well-designed schema with constraints and indexes
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    username VARCHAR(100) NOT NULL UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    is_verified BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT email_format CHECK (email LIKE '%@%.%'),
    CONSTRAINT username_length CHECK (LENGTH(username) >= 3)
);

CREATE INDEX ix_users_email ON users(email);
CREATE INDEX ix_users_username ON users(username);
CREATE INDEX ix_users_created_at ON users(created_at);
CREATE INDEX ix_users_email_active ON users(email, is_active);

-- Audit trail
CREATE TABLE user_audit (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    action VARCHAR(50) NOT NULL,
    changed_fields JSONB,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX ix_user_audit_user_id ON user_audit(user_id);
CREATE INDEX ix_user_audit_changed_at ON user_audit(changed_at);


# ❌ BAD: Poor schema design
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    email TEXT,  -- No uniqueness, no format validation
    username TEXT,  -- No constraints
    name TEXT,  -- Single field for multiple parts
    status BOOLEAN,  -- Ambiguous field name
    created_at TIMESTAMP
);
```

### Query Optimization

```python
-- ✅ GOOD: Efficient queries with proper indexes
EXPLAIN ANALYZE
SELECT u.id, u.email, COUNT(p.id) as post_count
FROM users u
LEFT JOIN posts p ON u.id = p.user_id
WHERE u.is_active = TRUE
  AND u.created_at > CURRENT_TIMESTAMP - INTERVAL '30 days'
GROUP BY u.id, u.email
ORDER BY post_count DESC
LIMIT 10;

-- Create supporting indexes
CREATE INDEX ix_posts_user_id ON posts(user_id);
CREATE INDEX ix_users_created_at_active ON users(created_at, is_active);


-- ❌ BAD: Inefficient query
SELECT * FROM users
WHERE email LIKE '%example.com'  -- No leading wildcard for indexes
  AND (status = 'active' OR status = 'pending');  -- OR clause prevents indexes
```

---

## Microservices Best Practices

### Service Architecture

```python
# ✅ GOOD: Well-defined microservice structure
# services/user_service/main.py
from fastapi import FastAPI
from app.api.routes import auth, profile
from app.core.config import settings

app = FastAPI(
    title="User Service",
    docs_url="/docs",
    openapi_url="/openapi.json"
)

# Health check endpoint (required for orchestration)
@app.get("/health", tags=["health"])
def health_check():
    """Service health check endpoint."""
    return {
        "status": "healthy",
        "service": "user-service",
        "version": "1.0.0"
    }

# Service routes
app.include_router(auth.router, prefix="/auth", tags=["auth"])
app.include_router(profile.router, prefix="/profile", tags=["profile"])


# ❌ BAD: Monolithic service structure
# All logic in one file
@app.get("/users")
def get_users():
    pass

@app.post("/users")
def create_user():
    pass

@app.get("/admin/reports")
def get_reports():
    pass
```

### Inter-Service Communication

```python
# ✅ GOOD: Async HTTP communication with retry logic
import aiohttp
from tenacity import retry, stop_after_attempt, wait_exponential
from app.core.config import settings

class UserServiceClient:
    """Client for communicating with User Service."""
    
    def __init__(self, base_url: str = settings.USER_SERVICE_URL):
        self.base_url = base_url
    
    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10)
    )
    async def get_user(self, user_id: int) -> dict:
        """Get user with retry logic."""
        async with aiohttp.ClientSession() as session:
            async with session.get(
                f"{self.base_url}/users/{user_id}",
                timeout=aiohttp.ClientTimeout(total=5)
            ) as response:
                if response.status == 200:
                    return await response.json()
                else:
                    raise Exception(f"Failed to get user: {response.status}")
    
    async def verify_user_exists(self, user_id: int) -> bool:
        """Verify user exists without raising."""
        try:
            await self.get_user(user_id)
            return True
        except Exception:
            return False


# ❌ BAD: Synchronous blocking calls
import requests

def get_user(user_id: int):
    response = requests.get(f"http://user-service/users/{user_id}")
    return response.json()  # Blocks entire request


# ❌ BAD: No timeout or retry
def get_user(user_id: int):
    response = requests.get(f"http://user-service/users/{user_id}")
    return response.json()
```

### Event-Driven Architecture

```python
# ✅ GOOD: Event-based communication with message queue
from fastapi import FastAPI
from app.events import publisher, events
from sqlalchemy.orm import Session

app = FastAPI()


@app.post("/users")
async def create_user(user_data: UserCreate, db: Session = Depends(get_db)):
    """Create user and publish event."""
    user = UserService.create_user(user_data)
    
    # Publish event for other services
    await publisher.publish(
        event=events.UserCreatedEvent(
            user_id=user.id,
            email=user.email,
            timestamp=datetime.utcnow()
        ),
        topic="user.created"
    )
    
    return user


@app.post("/users/{user_id}/activate")
async def activate_user(user_id: int, db: Session = Depends(get_db)):
    """Activate user and publish event."""
    user = UserService.get_user(user_id)
    user.is_active = True
    db.commit()
    
    # Publish event
    await publisher.publish(
        event=events.UserActivatedEvent(
            user_id=user.id,
            timestamp=datetime.utcnow()
        ),
        topic="user.activated"
    )
    
    return user


# services/notification_service/consumers.py
async def on_user_created(event: events.UserCreatedEvent):
    """Listen to user created events."""
    await send_welcome_email(event.email)
    logger.info(f"Welcome email sent to {event.email}")


async def on_user_activated(event: events.UserActivatedEvent):
    """Listen to user activated events."""
    await send_activation_email(event.user_id)
    logger.info(f"Activation email sent to user {event.user_id}")


# ❌ BAD: Tight coupling between services
@app.post("/users")
def create_user(user_data: UserCreate, db: Session):
    user = UserService.create_user(user_data)
    
    # Direct call to notification service (blocking)
    notification_service.send_welcome_email(user.email)
    
    return user
```

### Service Configuration & Secrets

```python
# ✅ GOOD: Configuration management with environment variables
from pydantic import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    """Application settings from environment variables."""
    
    # API Configuration
    API_TITLE: str = "Andromeda API"
    API_VERSION: str = "1.0.0"
    DEBUG: bool = False
    
    # Database
    DB_USER: str
    DB_PASSWORD: str
    DB_HOST: str
    DB_PORT: int = 5432
    DB_NAME: str
    
    # Security
    SECRET_KEY: str  # Required
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # Service URLs
    USER_SERVICE_URL: str
    NOTIFICATION_SERVICE_URL: str
    ANALYTICS_SERVICE_URL: str
    
    # CORS
    ALLOWED_ORIGINS: List[str] = ["http://localhost:3000"]
    
    class Config:
        env_file = ".env"
        case_sensitive = True


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()


# Usage
settings = get_settings()
DATABASE_URL = (
    f"postgresql://{settings.DB_USER}:{settings.DB_PASSWORD}"
    f"@{settings.DB_HOST}:{settings.DB_PORT}/{settings.DB_NAME}"
)


# ❌ BAD: Hardcoded secrets
DATABASE_URL = "postgresql://admin:admin123@localhost:5432/mydb"
SECRET_KEY = "super-secret-key-123"

# ❌ BAD: No separation of concerns
DEBUG = True
TESTING = False
```

### Logging & Monitoring

```python
# ✅ GOOD: Structured logging and monitoring
import logging
import json
from datetime import datetime
from pythonjsonlogger import jsonlogger

# Structured JSON logging
logHandler = logging.StreamHandler()
formatter = jsonlogger.JsonFormatter()
logHandler.setFormatter(formatter)

logger = logging.getLogger()
logger.addHandler(logHandler)
logger.setLevel(logging.INFO)


# Middleware for request logging
from fastapi import Request
from time import time

@app.middleware("http")
async def log_requests(request: Request, call_next):
    """Log all requests with response time."""
    start_time = time()
    
    try:
        response = await call_next(request)
        duration = time() - start_time
        
        logger.info(
            "HTTP Request",
            extra={
                "method": request.method,
                "path": request.url.path,
                "status_code": response.status_code,
                "duration_ms": duration * 1000,
                "client_host": request.client.host,
            }
        )
        
        return response
    except Exception as exc:
        duration = time() - start_time
        logger.error(
            "HTTP Error",
            extra={
                "method": request.method,
                "path": request.url.path,
                "duration_ms": duration * 1000,
                "error": str(exc),
            }
        )
        raise


# ❌ BAD: Print statements for logging
print("User created:", user_id)
print("Error:", error_message)

# ❌ BAD: No structured logging
logger.info(f"Request from {request.client.host} to {request.url.path}")
```

### Text Encoding & Unicode Handling

#### UTF-8 Encoding (Required)
```python
# ✅ GOOD: Explicit UTF-8 encoding for file operations
import os
from pathlib import Path

def read_config_file(file_path: str) -> str:
    """Read configuration file with proper UTF-8 encoding."""
    path = Path(file_path)
    
    # Always specify UTF-8 encoding
    with open(path, 'r', encoding='utf-8') as f:
        return f.read()


def write_log_file(content: str, file_path: str) -> None:
    """Write content to file with UTF-8 encoding."""
    path = Path(file_path)
    
    # Ensure parent directory exists
    path.parent.mkdir(parents=True, exist_ok=True)
    
    # Always use UTF-8 encoding
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)


# ✅ GOOD: Environment variable handling with encoding
def get_env_var(name: str, default: str = "") -> str:
    """Get environment variable with proper encoding handling."""
    value = os.getenv(name, default)
    
    # Ensure proper string handling (Python 3 strings are Unicode by default)
    if isinstance(value, bytes):
        return value.decode('utf-8')
    
    return value


# ❌ BAD: No encoding specified (system default may fail)
with open('config.txt', 'r') as f:  # May fail on Windows with Unicode
    content = f.read()

# ❌ BAD: Assuming ASCII encoding
with open('log.txt', 'w') as f:  # May fail with Unicode characters
    f.write("🚀 Application started")  # Emojis may cause encoding errors
```

#### Console Output & Logging
```python
# ✅ GOOD: Safe console output handling
import sys
import logging

def safe_print(message: str) -> None:
    """Print message safely, handling encoding issues."""
    try:
        print(message)
    except UnicodeEncodeError:
        # Fallback for Windows console encoding issues
        print(message.encode('utf-8', errors='replace').decode('utf-8'))


def setup_logging():
    """Configure logging with proper encoding handling."""
    # Use UTF-8 encoding for log files
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s [%(levelname)s] %(message)s',
        handlers=[
            logging.FileHandler('app.log', encoding='utf-8'),
            logging.StreamHandler(sys.stdout)
        ]
    )
    
    # Ensure stdout can handle Unicode
    if hasattr(sys.stdout, 'reconfigure'):
        sys.stdout.reconfigure(encoding='utf-8')


# ✅ GOOD: Unicode-safe logging messages
logger = logging.getLogger(__name__)

def log_user_action(user_id: int, action: str, details: str):
    """Log user actions with Unicode support."""
    # Use Unicode characters safely in log messages
    logger.info(f"User {user_id}: {action} - {details}")
    
    # Avoid direct emoji usage in critical paths
    # Use descriptive text instead of emojis for better compatibility
    logger.info(f"User {user_id}: Action completed successfully")


# ❌ BAD: Direct emoji usage causing encoding failures
logger.info("🚀 Starting application...")  # May fail on Windows console
print("✅ User created successfully")    # May cause UnicodeEncodeError
```

#### String Operations
```python
# ✅ GOOD: Unicode-safe string operations
def normalize_text(text: str) -> str:
    """Normalize text for consistent processing."""
    import unicodedata
    
    # Normalize Unicode characters
    normalized = unicodedata.normalize('NFC', text)
    
    # Handle encoding issues gracefully
    try:
        # Ensure string can be encoded/decoded safely
        encoded = normalized.encode('utf-8')
        return encoded.decode('utf-8')
    except (UnicodeEncodeError, UnicodeDecodeError):
        # Fallback: remove problematic characters
        return ''.join(c for c in normalized if ord(c) < 128)


def safe_string_formatting(name: str, value: str) -> str:
    """Format strings safely with Unicode characters."""
    try:
        return f"User {name}: {value}"
    except UnicodeEncodeError:
        # Fallback formatting
        safe_name = name.encode('utf-8', errors='replace').decode('utf-8')
        safe_value = value.encode('utf-8', errors='replace').decode('utf-8')
        return f"User {safe_name}: {safe_value}"


# ❌ BAD: String operations without encoding safety
message = f"User {user_name} logged in"  # May fail if user_name contains Unicode
log_file.write(message)                  # May cause encoding errors
```

#### File System Operations
```python
# ✅ GOOD: Unicode-safe file system operations
import os
from pathlib import Path

def create_directory_safe(dir_path: str) -> bool:
    """Create directory with Unicode path support."""
    try:
        path = Path(dir_path)
        path.mkdir(parents=True, exist_ok=True)
        return True
    except (OSError, UnicodeEncodeError) as e:
        logger.error(f"Failed to create directory {dir_path}: {e}")
        return False


def list_files_safe(dir_path: str) -> list[str]:
    """List files in directory with Unicode support."""
    try:
        path = Path(dir_path)
        return [str(f) for f in path.iterdir() if f.is_file()]
    except (OSError, UnicodeEncodeError) as e:
        logger.error(f"Failed to list files in {dir_path}: {e}")
        return []


# ❌ BAD: File operations without Unicode handling
os.mkdir("dossier_avec_émojis 🚀")  # May fail on Windows
with open("fichier_avec_🚀.txt", 'w') as f:  # May cause encoding errors
    f.write("content")
```

### API Versioning

```python
# ✅ GOOD: Clear API versioning strategy
# app/api/v1/users.py
from fastapi import APIRouter

router = APIRouter()

@router.get("/", summary="List users (v1)")
def list_users():
    """List users - Version 1 (deprecated, use /v2/)."""
    pass


# app/api/v2/users.py
router = APIRouter()

@router.get("/", summary="List users (v2)")
def list_users_v2(
    skip: int = 0,
    limit: int = 10,
    filter_active: bool = True
):
    """List users with enhanced filtering - Version 2."""
    pass


# app/main.py
from app.api.v1 import users as users_v1
from app.api.v2 import users as users_v2

app = FastAPI()
app.include_router(users_v1.router, prefix="/api/v1/users")
app.include_router(users_v2.router, prefix="/api/v2/users")


# ❌ BAD: No versioning
@app.get("/users")
def get_users():
    # Hard to maintain backward compatibility
    pass
```

---

## Security Best Practices

### Authentication & Authorization

```python
# ✅ GOOD: Secure password handling and JWT tokens
from passlib.context import CryptContext
from datetime import datetime, timedelta
from jose import JWTError, jwt
from fastapi import HTTPException, status

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(password: str) -> str:
    """Hash password using bcrypt."""
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify password against hash."""
    return pwd_context.verify(plain_password, hashed_password)


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    """Create JWT access token."""
    to_encode = data.copy()
    
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(
        to_encode,
        settings.SECRET_KEY,
        algorithm=settings.ALGORITHM
    )
    return encoded_jwt


def verify_token(token: str) -> dict:
    """Verify and decode JWT token."""
    try:
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=[settings.ALGORITHM]
        )
        return payload
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )


# ❌ BAD: Plaintext passwords
user.password = user_data.password

# ❌ BAD: Custom encryption
user.password = custom_encrypt(user_data.password)

# ❌ BAD: No token expiration
def create_token(user_id: int):
    return jwt.encode({"user_id": user_id}, "secret")
```

### SQL Injection Prevention

```python
# ✅ GOOD: Parameterized queries
def search_users(db: Session, email: str) -> List[User]:
    """Search users - SQL injection safe."""
    return db.query(User).filter(
        User.email.ilike(f"%{email}%")  # SQLAlchemy parameterizes this
    ).all()


# Using raw SQL safely
from sqlalchemy import text

results = db.execute(
    text("SELECT * FROM users WHERE email = :email"),
    {"email": user_email}
).fetchall()


# ❌ BAD: String concatenation
query = f"SELECT * FROM users WHERE email = '{email}'"
results = db.execute(query)

# ❌ BAD: Unescaped user input
query = f"SELECT * FROM users WHERE email LIKE '%{search_term}%'"
```

---

## Authentication & Authorization Best Practices

### OpenID Connect (OIDC) for Authentication

**What is OpenID Connect?**
- OpenID Connect is an identity layer built on top of OAuth2
- Used for **authentication** (verifying who the user is)
- Provides standardized user identity information via ID tokens
- Industry standard for SSO (Single Sign-On)

**Best Practices:**

```python
# ✅ GOOD: OIDC authentication flow
from authlib.integrations.starlette_client import OAuth
from starlette.config import Config
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import jwt
from jwt import PyJWKClient
from typing import Optional

app = FastAPI()
config = Config('.env')
oauth = OAuth(config)

# Configure OIDC provider (e.g., Auth0, Keycloak, Azure AD)
oauth.register(
    name='oidc_provider',
    client_id=config('OIDC_CLIENT_ID'),
    client_secret=config('OIDC_CLIENT_SECRET'),
    server_metadata_url=config('OIDC_DISCOVERY_URL'),
    client_kwargs={
        'scope': 'openid profile email',
        'token_endpoint_auth_method': 'client_secret_post'
    }
)

security = HTTPBearer()


async def verify_id_token(token: str) -> dict:
    """
    Verify OIDC ID token signature and claims.
    
    Args:
        token: JWT ID token from OIDC provider
        
    Returns:
        dict: Decoded token claims
        
    Raises:
        HTTPException: If token is invalid or expired
    """
    try:
        # Get JWKS from OIDC provider
        jwks_client = PyJWKClient(config('OIDC_JWKS_URI'))
        signing_key = jwks_client.get_signing_key_from_jwt(token)
        
        # Verify token signature and claims
        claims = jwt.decode(
            token,
            signing_key.key,
            algorithms=['RS256'],
            audience=config('OIDC_CLIENT_ID'),
            issuer=config('OIDC_ISSUER')
        )
        
        # Validate required claims
        required_claims = ['sub', 'iss', 'aud', 'exp', 'iat']
        if not all(claim in claims for claim in required_claims):
            raise ValueError("Missing required claims")
            
        return claims
        
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired"
        )
    except jwt.InvalidTokenError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid token: {str(e)}"
        )


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security)
) -> dict:
    """
    Get current authenticated user from ID token.
    
    Args:
        credentials: HTTP Bearer token from Authorization header
        
    Returns:
        dict: User claims from verified token
        
    Raises:
        HTTPException: If authentication fails
    """
    token = credentials.credentials
    claims = await verify_id_token(token)
    return claims


@app.get("/login")
async def login(request: Request):
    """Initiate OIDC login flow."""
    redirect_uri = request.url_for('auth_callback')
    return await oauth.oidc_provider.authorize_redirect(request, redirect_uri)


@app.get("/auth/callback")
async def auth_callback(request: Request):
    """Handle OIDC callback with authorization code."""
    try:
        token = await oauth.oidc_provider.authorize_access_token(request)
        
        # Verify ID token
        user_claims = await verify_id_token(token['id_token'])
        
        # Store user session or return tokens
        return {
            "access_token": token['access_token'],
            "id_token": token['id_token'],
            "user": user_claims
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Authentication failed: {str(e)}"
        )


@app.get("/protected")
async def protected_route(user: dict = Depends(get_current_user)):
    """Protected route requiring authentication."""
    return {"message": f"Hello {user.get('name', user['sub'])}!"}


# ❌ BAD: No token verification
@app.get("/protected")
async def bad_protected(token: str):
    # Just decoding without verification - UNSAFE!
    claims = jwt.decode(token, verify=False)
    return {"user": claims}


# ❌ BAD: Hardcoded secrets
oauth.register(
    name='provider',
    client_id='hardcoded_client_id',  # Never hardcode credentials
    client_secret='hardcoded_secret'
)
```

### OAuth2 for Authorization

**What is OAuth2?**
- OAuth2 is an **authorization** framework (what the user can do)
- Defines scopes/permissions for API access
- Uses access tokens (not ID tokens) for API authorization
- Separates authentication from authorization

**Best Practices:**

```python
# ✅ GOOD: OAuth2 authorization with scopes
from fastapi import Security
from fastapi.security import OAuth2PasswordBearer, SecurityScopes
from pydantic import BaseModel, ValidationError
from typing import List, Set

oauth2_scheme = OAuth2PasswordBearer(
    tokenUrl="token",
    scopes={
        "users:read": "Read user information",
        "users:write": "Create and update users",
        "users:delete": "Delete users",
        "admin:all": "Full administrative access",
        "students:read": "Read student information",
        "students:write": "Create and update students"
    }
)


class TokenData(BaseModel):
    """Token payload data."""
    sub: str  # Subject (user ID)
    scopes: List[str] = []
    exp: int  # Expiration timestamp


async def verify_access_token(
    token: str,
    required_scopes: SecurityScopes
) -> TokenData:
    """
    Verify OAuth2 access token and check scopes.
    
    Args:
        token: JWT access token
        required_scopes: Required OAuth2 scopes
        
    Returns:
        TokenData: Validated token data
        
    Raises:
        HTTPException: If token invalid or insufficient scopes
    """
    # Build authentication challenge header
    if required_scopes.scopes:
        authenticate_value = f'Bearer scope="{required_scopes.scope_str}"'
    else:
        authenticate_value = "Bearer"
        
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": authenticate_value},
    )
    
    try:
        # Decode and verify access token
        payload = jwt.decode(
            token,
            config('JWT_SECRET_KEY'),
            algorithms=[config('JWT_ALGORITHM')]
        )
        
        user_id: str = payload.get("sub")
        if user_id is None:
            raise credentials_exception
            
        token_scopes = payload.get("scopes", [])
        token_data = TokenData(sub=user_id, scopes=token_scopes, exp=payload['exp'])
        
    except (jwt.InvalidTokenError, ValidationError):
        raise credentials_exception
        
    # Check if token has required scopes
    token_scopes_set = set(token_data.scopes)
    for scope in required_scopes.scopes:
        if scope not in token_scopes_set:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Insufficient permissions",
                headers={"WWW-Authenticate": authenticate_value},
            )
            
    return token_data


async def get_current_user_with_scopes(
    security_scopes: SecurityScopes,
    token: str = Depends(oauth2_scheme)
) -> TokenData:
    """
    Get current user and verify required scopes.
    
    Args:
        security_scopes: Required OAuth2 scopes
        token: Access token from Authorization header
        
    Returns:
        TokenData: Validated user and scopes
    """
    return await verify_access_token(token, security_scopes)


# Example: Route requiring specific scopes
@app.get("/users/{user_id}")
async def read_user(
    user_id: int,
    current_user: TokenData = Security(
        get_current_user_with_scopes,
        scopes=["users:read"]
    )
):
    """Read user - requires 'users:read' scope."""
    return {"user_id": user_id, "authenticated_as": current_user.sub}


@app.post("/users/")
async def create_user(
    user_data: dict,
    current_user: TokenData = Security(
        get_current_user_with_scopes,
        scopes=["users:write"]
    )
):
    """Create user - requires 'users:write' scope."""
    return {"created_by": current_user.sub}


@app.delete("/users/{user_id}")
async def delete_user(
    user_id: int,
    current_user: TokenData = Security(
        get_current_user_with_scopes,
        scopes=["users:delete", "admin:all"]  # Either scope works
    )
):
    """Delete user - requires 'users:delete' OR 'admin:all' scope."""
    return {"deleted_by": current_user.sub}


# ❌ BAD: No scope checking
@app.get("/admin/users")
async def admin_users(token: str = Depends(oauth2_scheme)):
    # Any valid token can access - no authorization!
    return {"users": []}


# ❌ BAD: Role-based instead of scope-based
@app.get("/users")
async def get_users(user: User = Depends(get_current_user)):
    if user.role != "admin":  # Tight coupling to roles
        raise HTTPException(403)
    return {"users": []}
```

### Microservices Authorization Pattern

**Best Practices for Distributed Authorization:**

```python
# ✅ GOOD: Service-to-service authentication with JWT
from datetime import datetime, timedelta
import httpx
from fastapi import Request

class ServiceAuthClient:
    """Client for service-to-service authentication."""
    
    def __init__(self, service_name: str):
        self.service_name = service_name
        self.client_id = config(f'{service_name.upper()}_CLIENT_ID')
        self.client_secret = config(f'{service_name.upper()}_CLIENT_SECRET')
        self._access_token: Optional[str] = None
        self._token_expires_at: Optional[datetime] = None
        
    async def get_access_token(self) -> str:
        """
        Get service access token with automatic refresh.
        
        Returns:
            str: Valid access token
        """
        # Check if cached token is still valid
        if self._access_token and self._token_expires_at:
            if datetime.utcnow() < self._token_expires_at - timedelta(minutes=5):
                return self._access_token
                
        # Request new token using client credentials grant
        async with httpx.AsyncClient() as client:
            response = await client.post(
                config('OAUTH2_TOKEN_URL'),
                data={
                    'grant_type': 'client_credentials',
                    'client_id': self.client_id,
                    'client_secret': self.client_secret,
                    'scope': 'service:internal'
                }
            )
            response.raise_for_status()
            
            token_data = response.json()
            self._access_token = token_data['access_token']
            expires_in = token_data.get('expires_in', 3600)
            self._token_expires_at = datetime.utcnow() + timedelta(seconds=expires_in)
            
            return self._access_token
            
    async def call_service(
        self,
        method: str,
        url: str,
        **kwargs
    ) -> httpx.Response:
        """
        Make authenticated request to another service.
        
        Args:
            method: HTTP method (GET, POST, etc.)
            url: Target service URL
            **kwargs: Additional request parameters
            
        Returns:
            Response from target service
        """
        token = await self.get_access_token()
        
        headers = kwargs.pop('headers', {})
        headers['Authorization'] = f'Bearer {token}'
        
        async with httpx.AsyncClient() as client:
            response = await client.request(
                method=method,
                url=url,
                headers=headers,
                **kwargs
            )
            return response


# Example: User service calling Student service
user_service_client = ServiceAuthClient('user_service')

@app.get("/users/{user_id}/students")
async def get_user_students(
    user_id: int,
    current_user: dict = Depends(get_current_user)
):
    """Get students for a user - calls Student service."""
    
    # Authenticate with Student service
    response = await user_service_client.call_service(
        'GET',
        f'{config("STUDENT_SERVICE_URL")}/api/v1/students',
        params={'user_id': user_id}
    )
    
    return response.json()


# ❌ BAD: No authentication between services
async def call_other_service(url: str):
    async with httpx.AsyncClient() as client:
        # Unprotected internal API call
        response = await client.get(url)
    return response.json()
```

### Token Validation Middleware

```python
# ✅ GOOD: Centralized token validation middleware
from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
import logging

logger = logging.getLogger(__name__)


class JWTAuthMiddleware(BaseHTTPMiddleware):
    """Middleware to validate JWT tokens on all requests."""
    
    # Routes that don't require authentication
    PUBLIC_ROUTES = [
        '/docs',
        '/openapi.json',
        '/health',
        '/login',
        '/auth/callback'
    ]
    
    async def dispatch(self, request: Request, call_next):
        """
        Validate JWT token before processing request.
        
        Args:
            request: Incoming HTTP request
            call_next: Next middleware/route handler
            
        Returns:
            Response from handler or 401 if auth fails
        """
        # Skip authentication for public routes
        if any(request.url.path.startswith(route) for route in self.PUBLIC_ROUTES):
            return await call_next(request)
            
        # Extract token from Authorization header
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return Response(
                content='{"detail": "Missing or invalid Authorization header"}',
                status_code=401,
                media_type='application/json'
            )
            
        token = auth_header.split(' ')[1]
        
        try:
            # Verify token and attach claims to request state
            claims = await verify_access_token(token, SecurityScopes())
            request.state.user = claims
            
            logger.info(
                f"Authenticated request: user={claims.sub} "
                f"path={request.url.path} method={request.method}"
            )
            
        except HTTPException as e:
            logger.warning(
                f"Authentication failed: {e.detail} "
                f"path={request.url.path} method={request.method}"
            )
            return Response(
                content=f'{{"detail": "{e.detail}"}}',
                status_code=e.status_code,
                media_type='application/json'
            )
            
        response = await call_next(request)
        return response


# Add middleware to app
app.add_middleware(JWTAuthMiddleware)


# Access authenticated user in routes
@app.get("/profile")
async def get_profile(request: Request):
    """Get current user profile from request state."""
    user = request.state.user
    return {"user_id": user.sub, "scopes": user.scopes}
```

### Security Checklist

**✅ Authentication (OIDC) Requirements:**
- [ ] Use industry-standard OIDC provider (Auth0, Keycloak, Azure AD, etc.)
- [ ] Verify ID token signature using JWKS endpoint
- [ ] Validate all required token claims (sub, iss, aud, exp, iat)
- [ ] Use HTTPS for all OIDC endpoints
- [ ] Implement token refresh flow
- [ ] Store client secrets in environment variables or secret manager
- [ ] Use PKCE (Proof Key for Code Exchange) for public clients
- [ ] Implement session timeout and logout

**✅ Authorization (OAuth2) Requirements:**
- [ ] Define granular scopes (users:read, users:write, etc.)
- [ ] Verify access token signature and expiration
- [ ] Check required scopes for each protected endpoint
- [ ] Use principle of least privilege (minimum required scopes)
- [ ] Implement scope-based access control, not role-based
- [ ] Return 401 for authentication errors, 403 for authorization errors
- [ ] Include WWW-Authenticate header in 401 responses
- [ ] Log all authentication and authorization failures

**✅ Microservices Security Requirements:**
- [ ] Use mutual TLS (mTLS) for service-to-service communication
- [ ] Implement client credentials grant for service tokens
- [ ] Cache service tokens with automatic refresh
- [ ] Validate tokens on every internal API call
- [ ] Use API gateway for external requests
- [ ] Implement rate limiting per service
- [ ] Monitor and alert on authentication failures
- [ ] Rotate client secrets regularly (90 days maximum)

**❌ Common Security Mistakes to Avoid:**
- Never disable token signature verification
- Never hardcode client secrets or API keys
- Never use `verify=False` in JWT decode
- Never trust tokens without validating issuer and audience
- Never expose internal service endpoints publicly
- Never use bearer tokens in URL query parameters
- Never store tokens in localStorage (use httpOnly cookies)
- Never implement custom crypto - use proven libraries

---

## Performance Best Practices

### Caching

```python
# ✅ GOOD: Strategic caching with Redis
from functools import lru_cache
import redis
import json

redis_client = redis.Redis(host='localhost', port=6379, decode_responses=True)


@lru_cache(maxsize=128)
def get_config(key: str) -> str:
    """Cache configuration values."""
    return settings.get(key)


def get_user_cached(user_id: int, db: Session) -> Optional[User]:
    """Get user with Redis caching."""
    cache_key = f"user:{user_id}"
    
    # Try cache first
    cached = redis_client.get(cache_key)
    if cached:
        return json.loads(cached)
    
    # Fetch from database
    user = db.query(User).filter(User.id == user_id).first()
    if user:
        redis_client.setex(
            cache_key,
            3600,  # 1 hour TTL
            json.dumps(user.to_dict())
        )
    
    return user


# ❌ BAD: No caching for expensive operations
def get_user_stats(user_id: int):
    # Re-calculates on every request
    return calculate_stats(user_id)
```

### Database Query Optimization

```python
# ✅ GOOD: Batch operations and efficient queries
def bulk_create_users(users_data: List[UserCreate], db: Session):
    """Bulk insert users efficiently."""
    users = [User(**data.dict()) for data in users_data]
    db.bulk_save_objects(users)
    db.commit()


def get_user_analytics(db: Session) -> dict:
    """Aggregated analytics - single query."""
    result = db.query(
        func.count(User.id).label('total_users'),
        func.sum(User.posts.count()).label('total_posts'),
        func.avg(User.posts.count()).label('avg_posts_per_user')
    ).first()
    
    return {
        "total_users": result.total_users,
        "total_posts": result.total_posts,
        "avg_posts": result.avg_posts_per_user
    }


# ❌ BAD: N+1 queries
users = db.query(User).all()
for user in users:
    user.post_count = db.query(Post).filter(Post.user_id == user.id).count()

# ❌ BAD: Fetching everything then filtering
all_users = db.query(User).all()
active_users = [u for u in all_users if u.is_active]
```

---

## Testing Best Practices

```python
# ✅ GOOD: Comprehensive test structure
import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.database import get_db

client = TestClient(app)


@pytest.fixture
def test_db():
    """Create test database."""
    # Setup
    Base.metadata.create_all(bind=test_engine)
    yield test_session
    # Teardown
    Base.metadata.drop_all(bind=test_engine)


@pytest.fixture
def test_user(test_db):
    """Create test user."""
    user = User(email="test@example.com", is_active=True)
    test_db.add(user)
    test_db.commit()
    return user


def test_create_user_success(test_db):
    """Test successful user creation."""
    response = client.post("/api/v1/users", json={
        "email": "new@example.com",
        "first_name": "John",
        "last_name": "Doe",
        "password": "SecurePass123"
    })
    
    assert response.status_code == 201
    assert response.json()["email"] == "new@example.com"


def test_create_user_duplicate_email(test_db, test_user):
    """Test creating user with duplicate email."""
    response = client.post("/api/v1/users", json={
        "email": test_user.email,
        "first_name": "Jane",
        "last_name": "Doe",
        "password": "SecurePass123"
    })
    
    assert response.status_code == 409


def test_get_user_not_found(test_db):
    """Test getting non-existent user."""
    response = client.get("/api/v1/users/9999")
    assert response.status_code == 404


# ❌ BAD: Testing against production database
def test_create_user():
    response = client.post("/api/v1/users", ...)
    # Uses actual production data
    
# ❌ BAD: No test fixtures or setup
def test_user_creation():
    db.query(User).delete()  # Dangerous!
    # Tests lack isolation
```

---

## Unit Test Coverage Best Practices

### Coverage Targets

```python
# ✅ GOOD: Define coverage targets in setup.cfg or pytest.ini
[coverage:run]
branch = True
source = app/

[coverage:report]
precision = 2
show_missing = True
skip_covered = False
exclude_lines =
    pragma: no cover
    def __repr__
    raise AssertionError
    raise NotImplementedError
    if __name__ == .__main__.:
    if TYPE_CHECKING:

fail_under = 80  # Fail if coverage drops below 80%
```

### Unit Test Structure

```python
# ✅ GOOD: Well-organized unit tests
import pytest
from unittest.mock import Mock, patch, MagicMock
from app.services.user_service import UserService
from app.models import User
from app.schemas import UserCreate


class TestUserService:
    """Test suite for UserService business logic."""
    
    @pytest.fixture
    def user_service(self):
        """Provide UserService instance."""
        return UserService()
    
    @pytest.fixture
    def mock_db(self):
        """Provide mock database."""
        return Mock()
    
    def test_create_user_success(self, user_service, mock_db):
        """Test successful user creation."""
        # Arrange
        user_data = UserCreate(
            email="user@example.com",
            password="SecurePass123",
            first_name="John",
            last_name="Doe"
        )
        
        # Act
        result = user_service.create_user(user_data)
        
        # Assert
        assert result.email == "user@example.com"
        assert result.first_name == "John"
        mock_db.add.assert_called_once()
    
    def test_create_user_duplicate_email(self, user_service, mock_db):
        """Test creating user with duplicate email."""
        # Arrange
        user_data = UserCreate(
            email="existing@example.com",
            password="SecurePass123",
            first_name="Jane",
            last_name="Doe"
        )
        mock_db.query.return_value.filter.return_value.first.return_value = User(
            email="existing@example.com"
        )
        
        # Act & Assert
        with pytest.raises(ValueError, match="Email already exists"):
            user_service.create_user(user_data)
    
    def test_get_user_success(self, user_service, mock_db):
        """Test successful user retrieval."""
        # Arrange
        expected_user = User(id=1, email="user@example.com")
        mock_db.query.return_value.filter.return_value.first.return_value = expected_user
        
        # Act
        result = user_service.get_user(1)
        
        # Assert
        assert result.id == 1
        assert result.email == "user@example.com"
    
    def test_get_user_not_found(self, user_service, mock_db):
        """Test getting non-existent user."""
        # Arrange
        mock_db.query.return_value.filter.return_value.first.return_value = None
        
        # Act & Assert
        with pytest.raises(ValueError, match="User not found"):
            user_service.get_user(9999)
    
    @patch('app.services.user_service.hash_password')
    def test_password_hashing(self, mock_hash, user_service):
        """Test that passwords are hashed."""
        # Arrange
        mock_hash.return_value = "hashed_password_123"
        
        # Act & Assert
        mock_hash.assert_called()
```

### Test Organization

```python
# ✅ GOOD: Organize tests by component
# tests/
#   unit/
#     test_services/
#       test_user_service.py
#       test_auth_service.py
#     test_models/
#       test_user_model.py
#     test_schemas/
#       test_user_schema.py
#   integration/
#     test_user_api.py
#     test_auth_api.py
#   e2e/
#     test_user_flow.py


# ✅ GOOD: Use parametrized tests for multiple cases
@pytest.mark.parametrize("email,expected_valid", [
    ("user@example.com", True),
    ("invalid.email@", False),
    ("@example.com", False),
    ("user@.com", False),
])
def test_email_validation(email, expected_valid):
    """Test email validation with multiple inputs."""
    result = is_valid_email(email)
    assert result == expected_valid


# ✅ GOOD: Use fixtures for common setup
@pytest.fixture
def admin_user(test_db):
    """Create admin user for tests."""
    user = User(
        email="admin@example.com",
        role="admin",
        is_active=True
    )
    test_db.add(user)
    test_db.commit()
    return user


@pytest.fixture
def authenticated_client(admin_user):
    """Provide authenticated test client."""
    token = create_test_token(admin_user.id)
    client = TestClient(app)
    client.headers.update({"Authorization": f"Bearer {token}"})
    return client
```

### Mocking Best Practices

```python
# ✅ GOOD: Mock external dependencies
from unittest.mock import patch, MagicMock

def test_send_email_notification():
    """Test email sending logic."""
    with patch('app.services.email_service.send_email') as mock_send:
        # Act
        notify_user("user@example.com", "Welcome!")
        
        # Assert
        mock_send.assert_called_once_with(
            to="user@example.com",
            subject="Welcome!",
            template="welcome"
        )
        # Verify call arguments
        args, kwargs = mock_send.call_args
        assert kwargs['to'] == "user@example.com"


# ✅ GOOD: Use monkeypatch for environment variables
def test_with_env_variable(monkeypatch):
    """Test with modified environment."""
    monkeypatch.setenv("DEBUG", "True")
    
    result = get_debug_mode()
    assert result is True


# ❌ BAD: Over-mocking (mocks implementation details)
def test_user_creation():
    with patch('app.db.session.add'):
        with patch('app.db.session.commit'):
            # Tests implementation instead of behavior
            pass


# ❌ BAD: No assertions
def test_something():
    user = create_user("user@example.com")
    # Missing assert statement!
```

### Coverage Analysis

```python
# ✅ GOOD: Run coverage with detailed report
# Terminal: pytest --cov=app --cov-report=html --cov-report=term-missing

# Coverage report analysis:
# - Lines covered: 85%
# - Branches covered: 78%
# - Missing coverage: 
#   - app/services/email_service.py (95%): Line 42 (Exception handling)
#   - app/utils/cache.py (72%): Lines 15-18 (Cache eviction)


# ✅ GOOD: Track coverage over time
# Use tools like:
# - codecov.io
# - coveralls.io
# - sonarqube


# ✅ GOOD: Set coverage requirements per module
[coverage:report]
exclude_lines =
    pragma: no cover
    def __repr__
    raise NotImplementedError

# Require 90% coverage for critical modules
# - app/services/auth_service.py: 95%
# - app/models/user.py: 92%
# - app/routes/users.py: 88%
```

---

## Integration Test Best Practices

### Integration Test Structure

```python
# ✅ GOOD: Comprehensive integration tests
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Use in-memory SQLite for integration tests
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"

@pytest.fixture(scope="session")
def test_engine():
    """Create test database engine."""
    engine = create_engine(
        SQLALCHEMY_DATABASE_URL,
        connect_args={"check_same_thread": False}
    )
    Base.metadata.create_all(bind=engine)
    yield engine
    Base.metadata.drop_all(bind=engine)


@pytest.fixture(scope="function")
def test_db(test_engine):
    """Provide isolated test database session."""
    connection = test_engine.connect()
    transaction = connection.begin()
    session = sessionmaker(autocommit=False, autoflush=False, bind=connection)()
    
    yield session
    
    session.close()
    transaction.rollback()
    connection.close()


@pytest.fixture
def client(test_db):
    """Provide test client with test database."""
    def override_get_db():
        try:
            yield test_db
        finally:
            test_db.close()
    
    app.dependency_overrides[get_db] = override_get_db
    yield TestClient(app)
    app.dependency_overrides.clear()


class TestUserIntegration:
    """Integration tests for user endpoints."""
    
    def test_create_and_retrieve_user(self, client):
        """Test creating and retrieving user."""
        # Create user
        response = client.post("/api/v1/users", json={
            "email": "user@example.com",
            "password": "SecurePass123",
            "first_name": "John",
            "last_name": "Doe"
        })
        
        assert response.status_code == 201
        user_id = response.json()["id"]
        
        # Retrieve user
        response = client.get(f"/api/v1/users/{user_id}")
        
        assert response.status_code == 200
        data = response.json()
        assert data["email"] == "user@example.com"
        assert data["first_name"] == "John"
    
    def test_user_email_uniqueness_constraint(self, client):
        """Test email uniqueness across users."""
        email = "unique@example.com"
        
        # Create first user
        response1 = client.post("/api/v1/users", json={
            "email": email,
            "password": "Pass123!",
            "first_name": "User",
            "last_name": "One"
        })
        assert response1.status_code == 201
        
        # Try to create second user with same email
        response2 = client.post("/api/v1/users", json={
            "email": email,
            "password": "Pass123!",
            "first_name": "User",
            "last_name": "Two"
        })
        
        assert response2.status_code == 409
        assert "already exists" in response2.json()["error"]["message"]
    
    def test_authentication_flow(self, client):
        """Test complete authentication flow."""
        # Signup
        signup_response = client.post("/api/v1/auth/signup", json={
            "email": "newuser@example.com",
            "password": "SecurePass123",
            "first_name": "New",
            "last_name": "User"
        })
        assert signup_response.status_code == 201
        
        # Login
        login_response = client.post("/api/v1/auth/login", json={
            "username": "newuser@example.com",
            "password": "SecurePass123"
        })
        assert login_response.status_code == 200
        token = login_response.json()["access_token"]
        
        # Access protected endpoint
        headers = {"Authorization": f"Bearer {token}"}
        protected_response = client.get("/api/v1/users/me", headers=headers)
        
        assert protected_response.status_code == 200
        assert protected_response.json()["email"] == "newuser@example.com"
```

### Database Transaction Testing

```python
# ✅ GOOD: Test transaction behavior
def test_database_rollback_on_error(test_db):
    """Test that changes are rolled back on error."""
    initial_count = test_db.query(User).count()
    
    try:
        user = User(email="user@example.com")
        test_db.add(user)
        test_db.flush()
        
        # Simulate error
        raise Exception("Simulated error")
    except Exception:
        test_db.rollback()
    
    final_count = test_db.query(User).count()
    assert final_count == initial_count  # User not persisted


# ✅ GOOD: Test concurrent operations
@pytest.mark.asyncio
async def test_concurrent_user_creation():
    """Test creating users concurrently."""
    import asyncio
    
    async def create_user(email):
        return await user_service.create_user_async({
            "email": email,
            "password": "Pass123!"
        })
    
    tasks = [
        create_user(f"user{i}@example.com")
        for i in range(10)
    ]
    
    results = await asyncio.gather(*tasks)
    assert len(results) == 10
```

### API Endpoint Integration Testing

```python
# ✅ GOOD: Test full API workflows
class TestUserWorkflow:
    """Test complete user workflows through API."""
    
    def test_user_registration_to_profile_update(self, client):
        """Test user journey from signup to profile update."""
        # Step 1: Register
        register_response = client.post("/api/v1/auth/signup", json={
            "email": "journey@example.com",
            "password": "SecurePass123",
            "first_name": "Journey",
            "last_name": "Test"
        })
        assert register_response.status_code == 201
        
        # Step 2: Login
        login_response = client.post("/api/v1/auth/login", json={
            "username": "journey@example.com",
            "password": "SecurePass123"
        })
        assert login_response.status_code == 200
        token = login_response.json()["access_token"]
        
        # Step 3: Update profile
        headers = {"Authorization": f"Bearer {token}"}
        update_response = client.put(
            "/api/v1/users/me",
            json={
                "first_name": "Updated",
                "phone": "+1-555-0123"
            },
            headers=headers
        )
        assert update_response.status_code == 200
        
        # Step 4: Verify changes
        profile_response = client.get("/api/v1/users/me", headers=headers)
        assert profile_response.json()["first_name"] == "Updated"
        assert profile_response.json()["phone"] == "+1-555-0123"
    
    def test_authorization_workflow(self, client):
        """Test authorization at different user roles."""
        # Create admin
        admin_response = client.post("/api/v1/auth/signup", json={
            "email": "admin@example.com",
            "password": "Pass123!",
            "first_name": "Admin",
            "last_name": "User",
            "role": "admin"
        })
        admin_token = admin_response.json()["access_token"]
        admin_headers = {"Authorization": f"Bearer {admin_token}"}
        
        # Create regular user
        user_response = client.post("/api/v1/auth/signup", json={
            "email": "user@example.com",
            "password": "Pass123!",
            "first_name": "Regular",
            "last_name": "User"
        })
        user_token = user_response.json()["access_token"]
        user_headers = {"Authorization": f"Bearer {user_token}"}
        
        # Admin can access admin endpoint
        admin_list = client.get("/api/v1/admin/users", headers=admin_headers)
        assert admin_list.status_code == 200
        
        # User cannot access admin endpoint
        user_denied = client.get("/api/v1/admin/users", headers=user_headers)
        assert user_denied.status_code == 403
```

### Error Scenario Testing

```python
# ✅ GOOD: Test error handling in integration tests
class TestErrorHandling:
    """Test error scenarios across multiple components."""
    
    def test_validation_error_propagation(self, client):
        """Test validation errors through API."""
        response = client.post("/api/v1/users", json={
            "email": "invalid-email",  # Invalid format
            "password": "weak",  # Too short
            "first_name": "",  # Empty
            "last_name": "Doe"
        })
        
        assert response.status_code == 422
        error_data = response.json()
        assert "error" in error_data
        assert len(error_data["error"]["details"]) >= 3
    
    def test_database_connection_error(self, monkeypatch):
        """Test handling of database connection errors."""
        def mock_get_db():
            raise Exception("Database connection failed")
        
        monkeypatch.setattr("app.database.SessionLocal", mock_get_db)
        
        response = client.get("/api/v1/users")
        
        assert response.status_code == 500
        assert "error" in response.json()
    
    def test_rate_limiting(self, client):
        """Test rate limiting on endpoints."""
        # Make requests in rapid succession
        responses = []
        for i in range(105):  # Limit is typically 100/minute
            response = client.get("/api/v1/users")
            responses.append(response.status_code)
        
        # Should be successful until rate limit
        assert 200 in responses
        assert 429 in responses  # Too Many Requests
```

### Performance Testing in Integration Tests

```python
# ✅ GOOD: Include performance checks in integration tests
import time

def test_user_list_performance(client):
    """Test that user list endpoint performs well."""
    # Create test data
    for i in range(100):
        client.post("/api/v1/users", json={
            "email": f"user{i}@example.com",
            "password": "Pass123!",
            "first_name": "Test",
            "last_name": f"User{i}"
        })
    
    # Measure response time
    start = time.time()
    response = client.get("/api/v1/users?limit=50")
    duration = time.time() - start
    
    # Should complete quickly (< 500ms)
    assert duration < 0.5
    assert response.status_code == 200
    assert len(response.json()["users"]) == 50
```

---

## Summary

### Key Takeaways

1. **Code Quality**: Use type hints, follow PEP 8, write comprehensive docstrings
2. **Error Handling**: Create custom exceptions, handle specific cases
3. **Database**: Use proper indexing, connection pooling, eager loading
4. **API Design**: Comprehensive schemas, proper status codes, clear documentation
5. **Microservices**: Async communication, event-driven, proper health checks
6. **Security**: Hash passwords, use JWT, parameterized queries
7. **Performance**: Implement caching, optimize queries, batch operations
8. **Unit Testing**: Aim for 80%+ coverage, use fixtures, mock external dependencies
9. **Integration Testing**: Test full workflows, use isolated test databases, verify API contracts
10. **Test Organization**: Separate unit, integration, and E2E tests; use clear naming conventions

### Tools & Libraries

- **Code Quality**: `pylint`, `black`, `isort`, `mypy`
- **Testing**: `pytest`, `pytest-cov`, `httpx`
- **Database**: `sqlalchemy`, `alembic`
- **API**: `fastapi`, `pydantic`
- **Security**: `passlib`, `python-jose`, `bcrypt`
- **Caching**: `redis`
- **Logging**: `python-json-logger`


