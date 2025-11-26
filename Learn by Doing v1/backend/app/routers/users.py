"""
Users router for Andromeda SPED App.

Handles user management, roles, and permissions.
"""

import base64
import logging
from datetime import datetime
from typing import Dict, List, Optional

from fastapi import APIRouter, HTTPException, status, Depends
from pydantic import BaseModel, EmailStr, Field
from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError, IntegrityError

from ..database import get_db
from ..models import User
from ..db import verify_password, hash_password
from ..password_validator import PasswordValidator
from ..security.dependencies import get_current_user

# Initialize logger
logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/users", tags=["Users"])


# Helper functions for image encoding/decoding


def _encode_profile_image(image_bytes: Optional[bytes]) -> Optional[str]:
    """
    Encode profile image bytes to base64 string.

    Args:
        image_bytes: Raw image bytes or None

    Returns:
        Base64-encoded string or None if input is None

    Raises:
        ValueError: If encoding fails
    """
    if image_bytes is None:
        return None

    try:
        return base64.b64encode(image_bytes).decode("utf-8")
    except Exception as e:
        logger.error(f"Failed to encode profile image: {e}")
        raise ValueError(f"Image encoding failed: {str(e)}")


def _decode_profile_image(image_b64: str) -> bytes:
    """
    Decode base64 string to profile image bytes.

    Args:
        image_b64: Base64-encoded image string

    Returns:
        Decoded image bytes

    Raises:
        ValueError: If decoding fails or data is invalid
    """
    if not image_b64:
        raise ValueError("Image data cannot be empty")

    try:
        return base64.b64decode(image_b64)
    except Exception as e:
        logger.error(f"Failed to decode profile image: {e}")
        raise ValueError(f"Invalid base64 image data: {str(e)}")


def _build_user_response(db_user: User) -> UserResponse:
    """
    Build UserResponse from database User model.

    Args:
        db_user: SQLAlchemy User model instance

    Returns:
        UserResponse with all fields populated

    Raises:
        ValueError: If response building fails
    """
    try:
        # Handle profile image encoding
        image_bytes: Optional[bytes] = getattr(db_user, "profile_image", None)
        profile_image_b64 = _encode_profile_image(image_bytes)

        # Extract user attributes using getattr to avoid Column type issues
        user_id: int = getattr(db_user, "id")
        email: str = getattr(db_user, "email")
        first_name: str = getattr(db_user, "first_name")
        last_name: str = getattr(db_user, "last_name")
        role: str = getattr(db_user, "role")
        is_active: bool = getattr(db_user, "is_active")
        created_at_value = getattr(db_user, "created_at")
        updated_at_value = getattr(db_user, "updated_at")
        timezone_value: Optional[str] = getattr(db_user, "timezone", None)

        return UserResponse(
            id=user_id,
            email=email,
            first_name=first_name,
            last_name=last_name,
            role=role,
            is_active=is_active,
            created_at=(
                created_at_value.isoformat()
                if isinstance(created_at_value, datetime)
                else created_at_value
            ),
            updated_at=(
                updated_at_value.isoformat()
                if isinstance(updated_at_value, datetime)
                else updated_at_value
            ),
            profile_image=profile_image_b64,
            timezone=timezone_value,
        )
    except ValueError:
        raise
    except Exception as e:
        logger.error(f"Failed to build user response: {e}")
        raise ValueError(f"Response building failed: {str(e)}")


class UserBase(BaseModel):
    """Base user model."""

    email: EmailStr
    first_name: str = Field(..., min_length=1, max_length=100)
    last_name: str = Field(..., min_length=1, max_length=100)
    role: str = Field(..., pattern="^(admin|teacher|counselor|parent)$")


class UserCreate(UserBase):
    """User creation model."""

    password: str = Field(..., min_length=8)


class UserUpdate(BaseModel):
    """User update model."""

    email: Optional[EmailStr] = None
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    role: Optional[str] = None  # Can be any role value
    desired_name: Optional[str] = None
    phone: Optional[str] = None
    profile_image: Optional[str] = None  # Base64-encoded image data
    timezone: Optional[str] = None  # User's preferred timezone


class UserResponse(BaseModel):
    """User response model."""

    id: int
    email: EmailStr
    first_name: str
    last_name: str
    role: str  # Can include any role value from database (admin, teacher, counselor, parent, super_admin, etc.)
    is_active: bool
    created_at: str
    updated_at: str
    profile_image: Optional[str] = None  # Base64-encoded profile image
    timezone: Optional[str] = None  # User's preferred timezone


class ChangePasswordRequest(BaseModel):
    """Password change request model."""

    current_password: str = Field(..., min_length=1, description="Current password")
    new_password: str = Field(..., min_length=8, description="New password")

    class Config:
        """Pydantic config."""

        schema_extra = {
            "example": {
                "current_password": "CurrentPassword123!",
                "new_password": "NewPassword456!@#",
            }
        }


class ChangePasswordResponse(BaseModel):
    """Password change response model."""

    message: str
    success: bool


@router.post(
    "/",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create User",
)
async def create_user(user: UserCreate) -> UserResponse:
    """
    Create a new user account.

    Args:
        user: User information including email, name, role, and password

    Returns:
        UserResponse: Created user with ID and timestamps

    Raises:
        HTTPException: 400 if validation fails or 409 if user exists
    """
    # TODO: Implement actual database insert with password hashing
    # Password hashing should use passlib with argon2
    return UserResponse(
        id=1,
        email=user.email,
        first_name=user.first_name,
        last_name=user.last_name,
        role=user.role,
        is_active=True,
        created_at=datetime.utcnow().isoformat(),
        updated_at=datetime.utcnow().isoformat(),
    )


@router.get("/", response_model=List[UserResponse], summary="List Users")
async def list_users(
    skip: int = 0, limit: int = 100, role: Optional[str] = None
) -> List[UserResponse]:
    """
    List all users with optional filtering by role.

    Args:
        skip: Number of records to skip
        limit: Maximum number of records to return
        role: Optional role filter (admin, teacher, counselor, parent)

    Returns:
        List[UserResponse]: List of users
    """
    # TODO: Implement actual database query with role filtering
    return [
        UserResponse(
            id=1,
            email="admin@example.com",
            first_name="Admin",
            last_name="User",
            role="admin",
            is_active=True,
            created_at=datetime.utcnow().isoformat(),
            updated_at=datetime.utcnow().isoformat(),
        )
    ]


@router.get("/{user_id}", response_model=UserResponse, summary="Get User")
async def get_user(user_id: int) -> UserResponse:
    """
    Get a specific user by ID.

    Args:
        user_id: User ID

    Returns:
        UserResponse: User details

    Raises:
        HTTPException: 404 if user not found
    """
    # TODO: Implement actual database query
    return UserResponse(
        id=user_id,
        email="user@example.com",
        first_name="John",
        last_name="Doe",
        role="teacher",
        is_active=True,
        created_at=datetime.utcnow().isoformat(),
        updated_at=datetime.utcnow().isoformat(),
    )


@router.put("/{user_id}", response_model=UserResponse, summary="Update User")
async def update_user(
    user_id: int, *, user: UserUpdate, db: Session = Depends(get_db)
) -> UserResponse:
    """
    Update user information.

    Args:
        user_id: User ID
        user: Updated user information
        db: Database session

    Returns:
        UserResponse: Updated user details

    Raises:
        HTTPException: 404 if user not found, 400 if invalid image data, 500 on database error
    """
    try:
        # Fetch user from database
        db_user = db.query(User).filter(User.id == user_id).first()
        if not db_user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
            )

        # Update scalar fields
        if user.email:
            setattr(db_user, "email", user.email)
        if user.first_name:
            setattr(db_user, "first_name", user.first_name)
        if user.last_name:
            setattr(db_user, "last_name", user.last_name)
        if user.role:
            setattr(db_user, "role", user.role)
        if user.desired_name is not None:
            setattr(db_user, "desired_name", user.desired_name)
        if user.phone is not None:
            setattr(db_user, "phone", user.phone)
        if user.timezone is not None:
            setattr(db_user, "timezone", user.timezone)

        # Handle profile image - decode base64 to bytes
        if user.profile_image is not None:
            try:
                if user.profile_image == "":
                    # Empty string means remove image
                    setattr(db_user, "profile_image", None)
                else:
                    # Decode base64 string to bytes
                    image_bytes = _decode_profile_image(user.profile_image)
                    setattr(db_user, "profile_image", image_bytes)
            except ValueError as e:
                logger.warning(f"Invalid image data for user {user_id}: {e}")
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=str(e),
                )

        # Update database
        db.commit()
        db.refresh(db_user)

        logger.info(f"Updated user with ID {user_id}")

        # Build and return response
        return _build_user_response(db_user)

    except HTTPException:
        raise
    except IntegrityError as e:
        db.rollback()
        logger.error(f"Integrity error updating user {user_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="User with this email already exists",
        )
    except SQLAlchemyError as e:
        db.rollback()
        logger.error(f"Database error updating user {user_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Database error occurred",
        )
    except ValueError as e:
        db.rollback()
        logger.error(f"Validation error updating user {user_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )


@router.delete("/{user_id}", summary="Delete User")
async def delete_user(user_id: int) -> Dict:
    """
    Delete a user account.

    Args:
        user_id: User ID

    Returns:
        Dict: Deletion confirmation

    Raises:
        HTTPException: 404 if user not found
    """
    # TODO: Implement actual database delete with soft-delete consideration
    return {"message": f"User {user_id} deleted successfully"}


@router.post(
    "/{user_id}/change-password",
    response_model=ChangePasswordResponse,
    summary="Change User Password",
)
async def change_password(
    user_id: int,
    request: ChangePasswordRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> ChangePasswordResponse:
    """
    Change a user's password.

    **Security Requirements:**
    - User must be authenticated (Bearer token)
    - User can only change their own password (same user_id in token)
    - Current password must be verified
    - New password must meet security requirements:
      - Minimum 12 characters (enforced by PasswordValidator)
      - At least one uppercase letter
      - At least one lowercase letter
      - At least one digit
      - At least one special character
      - Cannot contain 3+ consecutive identical characters
      - Cannot be a common password

    Args:
        user_id: User ID from URL path
        request: Password change request containing current and new passwords
        current_user: Authenticated user from token (dependency)
        db: Database session (dependency)

    Returns:
        ChangePasswordResponse: Success message

    Raises:
        HTTPException 401: If user is not authenticated
        HTTPException 403: If user tries to change another user's password
        HTTPException 404: If user not found
        HTTPException 400: If current password is incorrect, new password is weak, or same as current

    Example:
        POST /api/v1/users/123/change-password
        Authorization: Bearer {token}

        {
            "current_password": "CurrentPassword123!",
            "new_password": "NewSecurePassword456!@#"
        }
    """
    # Verify user is authenticated
    if not current_user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
        )

    # Extract authenticated user ID from token
    try:
        auth_user_id_str = current_user.get("sub")
        if auth_user_id_str is None:
            raise ValueError("No user ID in token")
        auth_user_id = int(auth_user_id_str)
    except (TypeError, ValueError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token",
        )

    # Verify user can only change their own password
    if auth_user_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only change your own password",
        )

    # Get user from database
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"User {user_id} not found",
        )

    # Verify current password
    if not verify_password(request.current_password, str(user.hashed_password)):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Current password is incorrect",
        )

    # Validate new password strength
    is_valid, errors = PasswordValidator.validate(request.new_password)
    if not is_valid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"New password does not meet requirements: {'; '.join(errors)}",
        )

    # Prevent reusing the current password
    if verify_password(request.new_password, str(user.hashed_password)):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="New password cannot be the same as current password",
        )

    # Hash and update password
    try:
        user.hashed_password = hash_password(request.new_password)  # type: ignore
        user.updated_at = datetime.utcnow()  # type: ignore
        db.commit()
        db.refresh(user)
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update password in database",
        )

    return ChangePasswordResponse(
        message="Password changed successfully",
        success=True,
    )


@router.post(
    "/{user_id}/activate", response_model=UserResponse, summary="Activate User"
)
async def activate_user(user_id: int) -> UserResponse:
    """
    Activate a user account.

    Args:
        user_id: User ID

    Returns:
        UserResponse: Updated user details

    Raises:
        HTTPException: 404 if user not found
    """
    # TODO: Implement actual user activation
    return UserResponse(
        id=user_id,
        email="user@example.com",
        first_name="John",
        last_name="Doe",
        role="teacher",
        is_active=True,
        created_at=datetime.utcnow().isoformat(),
        updated_at=datetime.utcnow().isoformat(),
    )


@router.post(
    "/{user_id}/deactivate", response_model=UserResponse, summary="Deactivate User"
)
async def deactivate_user(user_id: int) -> UserResponse:
    """
    Deactivate a user account.

    Args:
        user_id: User ID

    Returns:
        UserResponse: Updated user details

    Raises:
        HTTPException: 404 if user not found
    """
    # TODO: Implement actual user deactivation
    return UserResponse(
        id=user_id,
        email="user@example.com",
        first_name="John",
        last_name="Doe",
        role="teacher",
        is_active=False,
        created_at=datetime.utcnow().isoformat(),
        updated_at=datetime.utcnow().isoformat(),
    )
