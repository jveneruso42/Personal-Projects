"""
Database helper functions for Learn by Doing v1
Provides user management and authentication utilities
"""

from typing import Optional
from sqlalchemy.orm import Session
from passlib.context import CryptContext
from app.models import User

# Password hashing context using Argon2
pwd_context = CryptContext(schemes=["argon2"], deprecated="auto")


def hash_password(password: str) -> str:
    """
    Hash a password using Argon2
    
    Args:
        password: Plain text password
        
    Returns:
        Hashed password string
    """
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    Verify a plain password against a hashed password
    
    Args:
        plain_password: Plain text password to verify
        hashed_password: Hashed password to compare against
        
    Returns:
        True if password matches, False otherwise
    """
    return pwd_context.verify(plain_password, hashed_password)


def get_user_by_email(db: Session, email: str) -> Optional[User]:
    """
    Get a user by email address
    
    Args:
        db: Database session
        email: User's email address
        
    Returns:
        User object if found, None otherwise
    """
    return db.query(User).filter(User.email == email).first()


def get_user_by_username(db: Session, username: str) -> Optional[User]:
    """
    Get a user by username
    
    Args:
        db: Database session
        username: User's username
        
    Returns:
        User object if found, None otherwise
    """
    return db.query(User).filter(User.username == username).first()


def user_exists(db: Session, email: Optional[str] = None, username: Optional[str] = None) -> bool:
    """
    Check if a user exists by email or username
    
    Args:
        db: Database session
        email: Optional email to check
        username: Optional username to check
        
    Returns:
        True if user exists, False otherwise
    """
    if email:
        return db.query(User).filter(User.email == email).first() is not None
    if username:
        return db.query(User).filter(User.username == username).first() is not None
    return False


def authenticate_user(db: Session, email: str, password: str) -> Optional[User]:
    """
    Authenticate a user with email and password
    
    Args:
        db: Database session
        email: User's email
        password: Plain text password
        
    Returns:
        User object if authentication successful, None otherwise
    """
    user = get_user_by_email(db, email)
    if not user:
        return None
    if not verify_password(password, str(user.hashed_password)):
        return None
    return user


def create_user(
    db: Session,
    email: str,
    username: str,
    password: str,
    first_name: Optional[str] = None,
    last_name: Optional[str] = None,
    role: str = "pending",
    is_approved: bool = False,
) -> User:
    """
    Create a new user in the database
    
    Args:
        db: Database session
        email: User's email
        username: User's username
        password: Plain text password (will be hashed)
        first_name: Optional first name
        last_name: Optional last name
        role: User role (default: "pending")
        is_approved: Whether user is pre-approved (default: False)
        
    Returns:
        Created User object
    """
    hashed_password = hash_password(password)
    user = User(
        email=email,
        username=username,
        hashed_password=hashed_password,
        first_name=first_name,
        last_name=last_name,
        role=role,
        is_approved=is_approved,
        is_active=True,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user
