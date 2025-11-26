"""
Authentication router for Andromeda SPED App

Handles user login, registration, password reset, and token management.
Implements:
- OAuth2-compliant JWT tokens with role claims
- Modern password security best practices (NIST SP 800-63B)
- AWS SES for secure password reset emails
- Role-based access control (RBAC)
"""

from datetime import datetime, timedelta
from typing import Dict, Optional
import secrets
import os
import logging
import base64

from fastapi import APIRouter, HTTPException, status, Depends
from pydantic import BaseModel, EmailStr
from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError
from passlib.context import CryptContext
from dotenv import load_dotenv
import jwt

from ..password_validator import validate_password
from ..db import (
    create_user,
    authenticate_user,
    user_exists,
    get_user_by_email,
    get_user_by_username,
)
from ..database import get_db
from ..aws_email_service import get_email_service
from ..models import User
from ..security import JWTManager, TokenPayload, Role, get_current_user, require_role

# Load environment variables
load_dotenv()

# Password hashing context
pwd_context = CryptContext(schemes=["argon2"], deprecated="auto")

# Logging
logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/auth", tags=["Authentication"])


# ============================================================================
# Helper Functions
# ============================================================================


def _encode_profile_image(image_data: Optional[bytes]) -> Optional[str]:
    """
    Encode binary image data to base64 string.

    Args:
        image_data: Binary image data

    Returns:
        Base64-encoded string or None if no image

    Raises:
        ValueError: If encoding fails
    """
    if not image_data:
        return None

    try:
        return base64.b64encode(image_data).decode("utf-8")
    except (TypeError, ValueError, UnicodeDecodeError, AttributeError) as e:
        logger.warning("Failed to encode profile image: %s", str(e))
        raise ValueError(f"Failed to encode profile image: {str(e)}")


def _build_user_info(user: User) -> UserInfo:
    """
    Build UserInfo response from User model.

    Args:
        user: User database model

    Returns:
        UserInfo: User information for API response

    Raises:
        ValueError: If required user fields are missing
    """
    try:
        profile_image_b64 = (
            _encode_profile_image(user.profile_image)  # type: ignore[arg-type]
            if user.profile_image is not None
            else None
        )
    except ValueError:
        # Log warning but don't fail the request
        profile_image_b64 = None

    return UserInfo(
        id=int(user.id),  # type: ignore[arg-type]
        email=str(user.email),
        username=str(user.username),
        first_name=str(user.first_name) if user.first_name is not None else None,
        last_name=str(user.last_name) if user.last_name is not None else None,
        desired_name=str(user.desired_name) if user.desired_name is not None else None,
        role=str(user.role),
        is_approved=bool(user.is_approved),
        profile_image=profile_image_b64,
    )


# ============================================================================
# Request/Response Models
# ============================================================================


class LoginRequest(BaseModel):
    """Login request model."""

    email: Optional[str] = None  # Can be email or username
    username: Optional[str] = None
    password: str

    class Config:
        """Pydantic config."""

        # At least one of email or username must be provided
        pass


class UserInfo(BaseModel):
    """User information in responses."""

    id: int
    email: str
    username: str
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    desired_name: Optional[str] = None
    role: str
    is_approved: bool
    profile_image: Optional[str] = None  # Base64-encoded profile image


class LoginResponse(BaseModel):
    """Login response model with OAuth2 compliance."""

    access_token: str
    token_type: str = "bearer"
    user: UserInfo


class RegisterRequest(BaseModel):
    """Registration request model."""

    email: EmailStr
    username: str
    password: str
    first_name: str
    last_name: str
    desired_name: str
    phone: Optional[str] = None  # Optional phone number


class RegisterResponse(BaseModel):
    """Registration response model."""

    id: int
    email: str
    first_name: str
    last_name: str
    desired_name: str
    role: str
    is_approved: bool
    created_at: str
    message: str


class ForgotPasswordRequest(BaseModel):
    """Forgot password request model."""

    email: EmailStr


class ForgotPasswordResponse(BaseModel):
    """Forgot password response model."""

    message: str
    email: str


class ResetPasswordRequest(BaseModel):
    """Reset password request model."""

    token: str
    new_password: str


class ResetPasswordResponse(BaseModel):
    """Reset password response model."""

    message: str
    email: str


class RefreshTokenRequest(BaseModel):
    """Refresh token request model."""

    refresh_token: str


class RefreshTokenResponse(BaseModel):
    """Refresh token response model."""

    access_token: str
    token_type: str = "bearer"


@router.post("/login", response_model=LoginResponse, summary="User Login (OAuth2)")
async def login(
    credentials: LoginRequest, db: Session = Depends(get_db)
) -> LoginResponse:
    """
    Authenticate user and return OAuth2-compliant JWT token.

    The returned JWT token contains:
    - User ID (sub claim)
    - Email
    - Role (pending, teacher, paraeducator, admin)
    - Permissions derived from role
    - Expiration time (24 hours by default)

    Args:
        credentials: Email/username and password for authentication
        db: Database session

    Returns:
        LoginResponse: OAuth2 bearer token and user information

    Raises:
        HTTPException: 401 if credentials are invalid
    """
    # Determine which field was provided
    email_or_username = credentials.email or credentials.username

    if not email_or_username:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Either email or username must be provided",
        )

    # Authenticate user with database
    user = authenticate_user(db, email_or_username, credentials.password)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email/username or password",
        )

    # Create JWT token with user role and permissions
    try:
        token_payload = TokenPayload(
            user_id=int(user.id),  # type: ignore[arg-type]
            email=str(user.email),
            role=Role(str(user.role)),
            first_name=str(user.first_name) if user.first_name is not None else None,
            last_name=str(user.last_name) if user.last_name is not None else None,
            desired_name=(
                str(user.desired_name) if user.desired_name is not None else None
            ),
        )
        access_token = JWTManager.create_access_token(token_payload)
    except (ValueError, jwt.InvalidTokenError) as e:
        logger.error("Failed to generate JWT token: %s", str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to generate authentication token",
        )

    # Build user info response with helper function
    try:
        user_info = _build_user_info(user)
    except ValueError as e:
        logger.error("Failed to build user info: %s", str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to build user information",
        )

    return LoginResponse(
        access_token=access_token,
        token_type="bearer",
        user=user_info,
    )


@router.post(
    "/refresh", response_model=RefreshTokenResponse, summary="Refresh Access Token"
)
async def refresh_token(
    request: RefreshTokenRequest, db: Session = Depends(get_db)
) -> RefreshTokenResponse:
    """
    Generate new access token from refresh token.

    Refresh tokens are long-lived (7 days) and used to obtain new access tokens
    without requiring user re-authentication.

    Args:
        request: Contains valid refresh token
        db: Database session

    Returns:
        RefreshTokenResponse: New access token

    Raises:
        HTTPException: 401 if refresh token is invalid or expired
    """
    try:
        # Verify refresh token
        payload = JWTManager.verify_token(request.refresh_token)

        if payload.get("type") != "refresh":
            raise ValueError("Token is not a refresh token")

        # Get user ID from token
        user_id = payload.get("sub")
        if not user_id:
            raise ValueError("Token missing user ID")

        # Retrieve user from database
        user = db.query(User).filter(User.id == user_id).first()
        if not user or user.is_approved is not True:  # type: ignore[comparison-overlap]
            raise ValueError("User not found or not approved")

        # Create new access token
        token_payload = TokenPayload(
            user_id=int(user.id),  # type: ignore[arg-type]
            email=str(user.email),
            role=Role(str(user.role)),
            first_name=str(user.first_name) if user.first_name is not None else None,
            last_name=str(user.last_name) if user.last_name is not None else None,
            desired_name=(
                str(user.desired_name) if user.desired_name is not None else None
            ),
        )
        access_token = JWTManager.create_access_token(token_payload)

        logger.info("Access token refreshed for user: %s", user_id)
        return RefreshTokenResponse(access_token=access_token, token_type="bearer")

    except (ValueError, jwt.InvalidTokenError, jwt.ExpiredSignatureError) as e:
        logger.warning("Refresh token failed: %s", str(e))
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token",
        )
    except SQLAlchemyError as e:
        logger.error("Database error during token refresh: %s", str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to refresh token",
        )


@router.post("/register", response_model=RegisterResponse, summary="User Registration")
async def register(
    user_data: RegisterRequest, db: Session = Depends(get_db)
) -> RegisterResponse:
    """
    Register a new user account.

    New users are automatically assigned to PENDING role and must be
    approved by an administrator before accessing app functionality.

    Password Validation:
    - Minimum 12 characters (or 8 if 3 character classes used)
    - Should include uppercase, lowercase, numbers, special characters
    - Follows NIST SP 800-63B modern security requirements

    Args:
        user_data: User registration details
        db: Database session

    Returns:
        RegisterResponse: Created user information with PENDING status

    Raises:
        HTTPException: 400 if validation fails
        HTTPException: 409 if user already exists
    """
    # Validate password against modern security requirements
    validation_result = validate_password(
        user_data.password, user_data.email.split("@")[0]
    )

    if not validation_result["is_valid"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={
                "message": "Password does not meet security requirements",
                "errors": validation_result["errors"],
                "requirements": validation_result["strength_guide"],
            },
        )

    # Check if email already exists
    if user_exists(db, user_data.email):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered. Please login or reset your password.",
        )

    # Check if username already exists
    try:
        if get_user_by_username(db, user_data.username):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Username already taken. Please choose a different username.",
            )
    except SQLAlchemyError as e:
        logger.error("Database error checking username: %s", str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to check username availability",
        )

    # Create new user with PENDING role
    try:
        new_user = create_user(
            db=db,
            email=user_data.email,
            username=user_data.username,
            password=user_data.password,
            first_name=user_data.first_name,
            last_name=user_data.last_name,
            desired_name=user_data.desired_name,
            phone=user_data.phone,
        )

        if new_user is None:
            raise ValueError("User creation returned None")

        # Ensure user has PENDING role
        if not hasattr(new_user, "role") or new_user.role is None:
            new_user.role = Role.PENDING.value  # type: ignore[assignment]
            db.commit()

        logger.info("New user registered: %s", user_data.email)

        return RegisterResponse(
            id=int(new_user.id),  # type: ignore[arg-type]
            email=str(new_user.email),
            first_name=str(new_user.first_name),
            last_name=str(new_user.last_name),
            desired_name=str(new_user.desired_name),
            role=str(new_user.role),
            is_approved=bool(new_user.is_approved),
            created_at=new_user.created_at.isoformat(),
            message="Account created successfully. You will receive an email once an administrator approves your account.",
        )

    except SQLAlchemyError as e:
        logger.error("Database error creating user: %s", str(e))
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create user account",
        )
    except ValueError as e:
        logger.error("User creation failed: %s", str(e))
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered. Please login or reset your password.",
        )


@router.post("/check-email", summary="Check if Email Exists")
async def check_email(email: EmailStr, db: Session = Depends(get_db)) -> Dict:
    """
    Check if an email address is already registered.

    Used by frontend to show existing account dialog during sign-up.

    Args:
        email: Email address to check
        db: Database session

    Returns:
        Dict: {exists: bool}

    Example:
        POST /api/v1/auth/check-email?email=user@example.com
        Response: {"exists": true}
    """
    exists = user_exists(db, email)
    return {"exists": exists}


# ============================================================================
# Password Reset Endpoints
# ============================================================================


@router.post(
    "/forgot-password",
    response_model=ForgotPasswordResponse,
    summary="Forgot Password",
)
async def forgot_password(
    request: ForgotPasswordRequest, db: Session = Depends(get_db)
) -> ForgotPasswordResponse:
    """
    Request password reset email.

    Sends a secure password reset token to the user's email address.
    If the email doesn't exist, returns generic success message for security.

    Args:
        request: Email address for password reset
        db: Database session

    Returns:
        ForgotPasswordResponse: Confirmation message

    Raises:
        HTTPException: 500 if email service fails (but still returns 200)
    """
    try:
        # Get user by email (don't reveal if email exists for security)
        user = get_user_by_email(db, request.email)

        if user:
            # Generate secure reset token
            reset_token = secrets.token_urlsafe(32)

            # Get expiry time from environment (default 1 hour)
            expiry_hours = int(os.getenv("PASSWORD_RESET_TOKEN_EXPIRY_HOURS", "1"))
            expires_at = datetime.utcnow() + timedelta(hours=expiry_hours)

            # Update user with reset token
            user.password_reset_token = reset_token  # type: ignore[assignment]
            user.password_reset_expires = expires_at  # type: ignore[assignment]
            user.password_reset_requested_at = datetime.utcnow()  # type: ignore[assignment]
            db.add(user)
            db.commit()

            # Send password reset email via AWS SES
            email_service = get_email_service()
            display_name = user.desired_name or user.first_name
            email_service.send_password_reset_email(
                to_email=str(user.email),
                user_name=str(display_name),  # type: ignore[arg-type]
                reset_token=reset_token,
                expires_in_hours=expiry_hours,
            )

            logger.info("Password reset requested for: %s", request.email)

        # Return generic success message (don't reveal if email exists)
        return ForgotPasswordResponse(
            message="If this email is registered, you will receive a password reset link shortly.",
            email=request.email,
        )

    except SQLAlchemyError as e:
        # Log error but return generic success response for security
        logger.error("Database error during password reset request: %s", str(e))
        db.rollback()
        return ForgotPasswordResponse(
            message="If this email is registered, you will receive a password reset link shortly.",
            email=request.email,
        )
    except Exception as e:
        # Log error but return generic success response for security
        logger.error(
            "Error processing password reset for %s: %s", request.email, str(e)
        )
        return ForgotPasswordResponse(
            message="If this email is registered, you will receive a password reset link shortly.",
            email=request.email,
        )


@router.post(
    "/reset-password",
    response_model=ResetPasswordResponse,
    summary="Reset Password",
)
async def reset_password(
    request: ResetPasswordRequest, db: Session = Depends(get_db)
) -> ResetPasswordResponse:
    """
    Reset user password with valid reset token.

    Validates the reset token, verifies it hasn't expired, and updates the password.

    Args:
        request: Reset token and new password
        db: Database session

    Returns:
        ResetPasswordResponse: Success message with email

    Raises:
        HTTPException: 400 if token is invalid or expired
        HTTPException: 400 if password doesn't meet security requirements
    """
    # Validate new password
    validation_result = validate_password(request.new_password)

    if not validation_result["is_valid"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={
                "message": "New password does not meet security requirements",
                "errors": validation_result["errors"],
                "requirements": validation_result["strength_guide"],
            },
        )

    try:
        # Find user by reset token
        user = db.query(User).filter(User.password_reset_token == request.token).first()

        if not user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid or expired password reset link. Please request a new one.",
            )

        # Check if token is still valid (not expired)
        if (
            user.password_reset_expires is None
            or user.password_reset_expires < datetime.utcnow()  # type: ignore[operator]
        ):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Password reset link has expired. Please request a new one.",
            )

        # Update password
        user.hashed_password = pwd_context.hash(request.new_password)  # type: ignore[assignment]

        # Clear reset token fields
        user.password_reset_token = None  # type: ignore[assignment]
        user.password_reset_expires = None  # type: ignore[assignment]
        user.password_reset_requested_at = None  # type: ignore[assignment]

        db.add(user)
        db.commit()

        logger.info("Password reset successful for: %s", str(user.email))

        return ResetPasswordResponse(
            message="✅ Your password has been successfully reset. You can now login with your new password.",
            email=str(user.email),
        )

    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except SQLAlchemyError as e:
        logger.error("Database error during password reset: %s", str(e))
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to reset password",
        )


@router.post("/logout", summary="Logout")
async def logout(current_user: dict = Depends(get_current_user)) -> Dict:
    """
    Logout user and invalidate token.

    Note: Client should remove token from storage.
    Token invalidation can be implemented via:
    - Token blacklist in Redis
    - Short token expiry with refresh tokens
    - Database token tracking

    Args:
        current_user: Current authenticated user from token

    Returns:
        Dict: Logout confirmation message
    """
    logger.info("User logged out: %s", current_user.get("sub"))
    return {"message": "Successfully logged out"}


@router.post(
    "/refresh-token", response_model=LoginResponse, summary="Refresh Token (Legacy)"
)
async def refresh_token_legacy() -> LoginResponse:
    """
    Refresh JWT token (legacy endpoint - deprecated).

    This endpoint is maintained for backward compatibility.
    Use POST /refresh with refresh token instead.

    Returns:
        LoginResponse: Placeholder response

    Raises:
        HTTPException: 501 Not Implemented
    """
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="This endpoint is deprecated. Use POST /api/v1/auth/refresh instead.",
    )


@router.get("/me", summary="Get Current User")
async def get_me(
    current_user: dict = Depends(get_current_user), db: Session = Depends(get_db)
) -> UserInfo:
    """
    Get current authenticated user information.

    Args:
        current_user: Current user from JWT token
        db: Database session

    Returns:
        UserInfo: Current user details

    Raises:
        HTTPException: 401 if not authenticated
        HTTPException: 404 if user not found
    """
    # Retrieve full user from DB using current_user["sub"] to get profile_image
    user_id = current_user.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token"
        )

    try:
        db_user = db.query(User).filter(User.id == user_id).first()
        if not db_user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
            )

        return _build_user_info(db_user)

    except ValueError as e:
        logger.error("Failed to build user info for user %s: %s", user_id, str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve user information",
        )
    except SQLAlchemyError as e:
        logger.error("Database error retrieving user %s: %s", user_id, str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve user information",
        )


# ============================================================================
# Admin User Approval Endpoints
# ============================================================================


class ApproveUserRequest(BaseModel):
    """Request to approve a pending user."""

    user_id: int
    approval_notes: Optional[str] = None
    role: str = "teacher"  # Default role for approved users


class ApproveUserResponse(BaseModel):
    """Response when user is approved."""

    message: str
    user_id: int
    role: str
    is_approved: bool


class RejectUserRequest(BaseModel):
    """Request to reject a pending user."""

    user_id: int
    rejection_reason: str


class RejectUserResponse(BaseModel):
    """Response when user is rejected."""

    message: str
    user_id: int
    is_rejected: bool


@router.post(
    "/admin/approve-user",
    response_model=ApproveUserResponse,
    summary="Approve Pending User",
)
async def approve_user(
    request: ApproveUserRequest,
    current_user: dict = Depends(require_role(Role.ADMIN, Role.SUPER_ADMIN)),
    db: Session = Depends(get_db),
) -> ApproveUserResponse:
    """
    Approve a pending user account.

    Only SUPER_ADMIN and ADMIN users can approve pending accounts.
    Once approved, user role is set and they can access the app.

    Args:
        request: Contains user_id and optional approval notes
        current_user: Current admin user (SUPER_ADMIN or ADMIN)
        db: Database session

    Returns:
        ApproveUserResponse: Confirmation of approval

    Raises:
        HTTPException: 403 if not admin or super admin
        HTTPException: 404 if user not found
    """
    # Get user from database
    try:
        user = db.query(User).filter(User.id == request.user_id).first()

        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"User with ID {request.user_id} not found",
            )

        # Validate role
        try:
            requested_role = Role(request.role)
            if requested_role == Role.PENDING:
                raise ValueError("Cannot approve user as PENDING")
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid role: {request.role}",
            )

        # Update user
        user.is_approved = True  # type: ignore[assignment]
        user.approved_at = datetime.utcnow()  # type: ignore[assignment]
        user.registered_date = datetime.utcnow()  # type: ignore[assignment]
        user.approved_by_id = current_user.get("sub")  # type: ignore[assignment]
        user.role = requested_role.value  # type: ignore[assignment]
        user.is_rejected = False  # type: ignore[assignment]
        user.rejection_reason = None  # type: ignore[assignment]
        user.approval_notes = request.approval_notes  # type: ignore[assignment]

        db.commit()
        db.refresh(user)

        logger.info(
            "User %s (ID: %s) approved as %s by admin %s",
            str(user.email),
            user.id,
            requested_role.value,
            current_user.get("email"),
        )

        return ApproveUserResponse(
            message=f"User {user.email} has been approved as {requested_role.value}",
            user_id=int(user.id),  # type: ignore[arg-type]
            role=str(user.role),
            is_approved=True,
        )

    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except SQLAlchemyError as e:
        logger.error("Database error approving user %s: %s", request.user_id, str(e))
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to approve user",
        )


@router.post(
    "/admin/reject-user",
    response_model=RejectUserResponse,
    summary="Reject Pending User",
)
async def reject_user(
    request: RejectUserRequest,
    current_user: dict = Depends(require_role(Role.ADMIN, Role.SUPER_ADMIN)),
    db: Session = Depends(get_db),
) -> RejectUserResponse:
    """
    Reject a pending user account.

    Only SUPER_ADMIN and ADMIN users can reject pending accounts.
    Rejected users cannot login but their account remains in system for audit.

    Args:
        request: Contains user_id and rejection reason
        current_user: Current admin user (SUPER_ADMIN or ADMIN)
        db: Database session

    Returns:
        RejectUserResponse: Confirmation of rejection

    Raises:
        HTTPException: 403 if not admin or super admin
        HTTPException: 404 if user not found
    """
    # Get user from database
    try:
        user = db.query(User).filter(User.id == request.user_id).first()

        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"User with ID {request.user_id} not found",
            )

        # Update user
        user.is_rejected = True  # type: ignore[assignment]
        user.rejected_at = datetime.utcnow()  # type: ignore[assignment]
        user.rejected_by_id = current_user.get("sub")  # type: ignore[assignment]
        user.rejection_reason = request.rejection_reason  # type: ignore[assignment]
        user.is_active = False  # type: ignore[assignment]  # Disable account

        db.commit()
        db.refresh(user)

        logger.info(
            "User %s (ID: %s) rejected by admin %s",
            str(user.email),
            user.id,
            current_user.get("email"),
        )

        return RejectUserResponse(
            message=f"User {user.email} has been rejected",
            user_id=int(user.id),  # type: ignore[arg-type]
            is_rejected=True,
        )

    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except SQLAlchemyError as e:
        logger.error("Database error rejecting user %s: %s", request.user_id, str(e))
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to reject user",
        )


@router.get("/admin/pending-users", summary="Get Pending Users")
async def get_pending_users(
    current_user: dict = Depends(require_role(Role.ADMIN, Role.SUPER_ADMIN)),
    db: Session = Depends(get_db),
) -> Dict:
    """
    Get all pending users awaiting approval.

    Only SUPER_ADMIN and ADMIN users can view pending user list.

    Args:
        current_user: Current admin user (SUPER_ADMIN or ADMIN)
        db: Database session

    Returns:
        Dict: List of pending users

    Raises:
        HTTPException: 403 if not admin or super admin
        HTTPException: 500 if database error
    """
    try:
        pending_users = (
            db.query(User)
            .filter(
                User.role == Role.PENDING.value,
                User.is_approved == False,
                User.is_rejected == False,
            )
            .all()
        )

        return {
            "count": len(pending_users),
            "users": [
                {
                    "id": u.id,
                    "email": u.email,
                    "username": u.username,
                    "first_name": u.first_name,
                    "last_name": u.last_name,
                    "created_at": u.created_at.isoformat(),
                }
                for u in pending_users
            ],
        }

    except SQLAlchemyError as e:
        logger.error("Database error retrieving pending users: %s", str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve pending users",
        )


@router.get("/admin/educators", summary="Get Educators and Staff")
async def get_educators(
    current_user: dict = Depends(require_role(Role.ADMIN, Role.SUPER_ADMIN)),
    db: Session = Depends(get_db),
) -> Dict:
    """
    Get all approved educators and staff members.

    Only SUPER_ADMIN and ADMIN users can view educators list.

    Args:
        current_user: Current admin user (SUPER_ADMIN or ADMIN)
        db: Database session

    Returns:
        Dict: List of educators and staff

    Raises:
        HTTPException: 403 if not admin or super admin
        HTTPException: 500 if database error
    """
    try:
        educators = (
            db.query(User)
            .filter(
                User.role.in_([Role.TEACHER.value, Role.PARAEDUCATOR.value]),
                User.is_approved == True,
            )
            .all()
        )

        return {
            "count": len(educators),
            "educators": [
                {
                    "id": u.id,
                    "first_name": u.first_name or "",
                    "last_name": u.last_name or "",
                    "email": u.email,
                    "role": u.role,
                    "phone": u.phone or "",
                    "username": u.username or "",
                    "desired_name": u.desired_name,
                }
                for u in educators
            ],
        }

    except SQLAlchemyError as e:
        logger.error("Database error retrieving educators: %s", str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve educators",
        )


class CreateEducatorRequest(BaseModel):
    first_name: str
    last_name: str
    email: str
    role: str
    phone: str
    username: str
    password: str
    desired_name: Optional[str] = None


class UpdateEducatorRequest(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    email: Optional[str] = None
    role: Optional[str] = None
    phone: Optional[str] = None
    username: Optional[str] = None
    password: Optional[str] = None
    desired_name: Optional[str] = None


@router.post("/admin/educators", summary="Create New Educator")
async def create_educator(
    request: CreateEducatorRequest,
    current_user: dict = Depends(require_role(Role.ADMIN, Role.SUPER_ADMIN)),
    db: Session = Depends(get_db),
) -> Dict:
    """
    Create a new educator or staff member.

    Only SUPER_ADMIN and ADMIN users can create educators.

    Args:
        request: Educator information
        current_user: Current admin user (SUPER_ADMIN or ADMIN)
        db: Database session

    Returns:
        Dict: Created educator information

    Raises:
        HTTPException: 400 if email already exists or invalid role
        HTTPException: 403 if not admin or super admin
        HTTPException: 500 if database error
    """
    try:
        # Validate role
        valid_roles = [Role.TEACHER.value, Role.PARAEDUCATOR.value, Role.ADMIN.value]
        if request.role not in valid_roles:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid role. Must be one of: {', '.join(valid_roles)}",
            )

        # Check if email already exists
        existing_user = db.query(User).filter(User.email == request.email).first()
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already exists",
            )

        # Check if username already exists
        if request.username:
            existing_username = (
                db.query(User).filter(User.username == request.username).first()
            )
            if existing_username:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Username already exists",
                )

        # Create new user
        new_user = create_user(
            db=db,
            email=request.email,
            password=request.password,
            first_name=request.first_name,
            last_name=request.last_name,
            username=request.username,
            desired_name=request.desired_name,
            phone=request.phone,
        )

        if not new_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Failed to create educator - user may already exist",
            )

        # Set role and approval status since created by admin
        new_user.role = request.role  # type: ignore[assignment]
        new_user.is_approved = True  # type: ignore[assignment]
        new_user.approved_at = datetime.utcnow()  # type: ignore[assignment]
        new_user.registered_date = datetime.utcnow()  # type: ignore[assignment]
        new_user.approved_by_id = current_user.get("sub")  # type: ignore[assignment]

        db.commit()
        db.refresh(new_user)

        logger.info(
            "Educator %s (ID: %s) created by admin %s",
            new_user.email,
            new_user.id,
            current_user.get("email"),
        )

        return {
            "id": new_user.id,
            "first_name": new_user.first_name or "",
            "last_name": new_user.last_name or "",
            "email": new_user.email,
            "role": new_user.role,
            "phone": new_user.phone or "",
            "username": new_user.username or "",
            "desired_name": new_user.desired_name,
        }

    except HTTPException:
        raise
    except SQLAlchemyError as e:
        logger.error("Database error creating educator: %s", str(e))
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create educator",
        )


@router.put("/admin/educators/{educator_id}", summary="Update Educator")
async def update_educator(
    educator_id: int,
    request: UpdateEducatorRequest,
    current_user: dict = Depends(require_role(Role.ADMIN, Role.SUPER_ADMIN)),
    db: Session = Depends(get_db),
) -> Dict:
    """
    Update an existing educator or staff member.

    Only SUPER_ADMIN and ADMIN users can update educators.

    Args:
        educator_id: ID of educator to update
        request: Updated educator information
        current_user: Current admin user (SUPER_ADMIN or ADMIN)
        db: Database session

    Returns:
        Dict: Updated educator information

    Raises:
        HTTPException: 404 if educator not found
        HTTPException: 400 if invalid role or email/username conflict
        HTTPException: 403 if not admin or super admin
        HTTPException: 500 if database error
    """
    try:
        # Get educator
        educator = db.query(User).filter(User.id == educator_id).first()
        if not educator:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Educator with ID {educator_id} not found",
            )

        # Validate role if provided
        if request.role:
            valid_roles = [
                Role.TEACHER.value,
                Role.PARAEDUCATOR.value,
                Role.ADMIN.value,
            ]
            if request.role not in valid_roles:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Invalid role. Must be one of: {', '.join(valid_roles)}",
                )

        # Check email uniqueness if changing
        if request.email and request.email != educator.email:
            existing = db.query(User).filter(User.email == request.email).first()
            if existing:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Email already exists",
                )

        # Check username uniqueness if changing
        if request.username and request.username != educator.username:
            existing = db.query(User).filter(User.username == request.username).first()
            if existing:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Username already exists",
                )

        # Update fields
        if request.first_name is not None:
            educator.first_name = request.first_name  # type: ignore[assignment]
        if request.last_name is not None:
            educator.last_name = request.last_name  # type: ignore[assignment]
        if request.email is not None:
            educator.email = request.email  # type: ignore[assignment]
        if request.role is not None:
            educator.role = request.role  # type: ignore[assignment]
        if request.phone is not None:
            educator.phone = request.phone  # type: ignore[assignment]
        if request.username is not None:
            educator.username = request.username  # type: ignore[assignment]
        if request.desired_name is not None:
            educator.desired_name = request.desired_name  # type: ignore[assignment]
        if request.password is not None:
            educator.password_hash = pwd_context.hash(
                request.password
            )  # type: ignore[assignment]

        db.commit()
        db.refresh(educator)

        logger.info(
            "Educator %s (ID: %s) updated by admin %s",
            educator.email,
            educator.id,
            current_user.get("email"),
        )

        return {
            "id": educator.id,
            "first_name": educator.first_name or "",
            "last_name": educator.last_name or "",
            "email": educator.email,
            "role": educator.role,
            "phone": educator.phone or "",
            "username": educator.username or "",
            "desired_name": educator.desired_name,
        }

    except HTTPException:
        raise
    except SQLAlchemyError as e:
        logger.error("Database error updating educator %s: %s", educator_id, str(e))
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update educator",
        )


@router.delete("/admin/educators/{educator_id}", summary="Delete Educator")
async def delete_educator(
    educator_id: int,
    current_user: dict = Depends(require_role(Role.ADMIN, Role.SUPER_ADMIN)),
    db: Session = Depends(get_db),
) -> Dict:
    """
    Delete an educator or staff member.

    Only SUPER_ADMIN and ADMIN users can delete educators.

    Args:
        educator_id: ID of educator to delete
        current_user: Current admin user (SUPER_ADMIN or ADMIN)
        db: Database session

    Returns:
        Dict: Confirmation message

    Raises:
        HTTPException: 404 if educator not found
        HTTPException: 403 if not admin or super admin
        HTTPException: 500 if database error
    """
    try:
        educator = db.query(User).filter(User.id == educator_id).first()
        if not educator:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Educator with ID {educator_id} not found",
            )

        email = educator.email
        db.delete(educator)
        db.commit()

        logger.info(
            "Educator %s (ID: %s) deleted by admin %s",
            email,
            educator_id,
            current_user.get("email"),
        )

        return {"message": f"Educator {email} has been deleted", "id": educator_id}

    except HTTPException:
        raise
    except SQLAlchemyError as e:
        logger.error("Database error deleting educator %s: %s", educator_id, str(e))
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to delete educator",
        )


@router.get("/admin/approved-users-recent", summary="Get Recently Approved Users")
async def get_approved_users_recent(
    current_user: dict = Depends(require_role(Role.ADMIN, Role.SUPER_ADMIN)),
    db: Session = Depends(get_db),
) -> Dict:
    """
    Get users approved in the past 7 days.

    Only SUPER_ADMIN and ADMIN users can view this list.
    Returns approved users with their registration date and role information.

    Args:
        current_user: Current admin user (SUPER_ADMIN or ADMIN)
        db: Database session

    Returns:
        Dict: List of recently approved users with registration dates

    Raises:
        HTTPException: 403 if not admin or super admin
        HTTPException: 500 if database error
    """
    try:
        seven_days_ago = datetime.utcnow() - timedelta(days=7)

        approved_users = (
            db.query(User)
            .filter(
                User.is_approved == True,
                User.registered_date >= seven_days_ago,
                User.registered_date.isnot(None),
            )
            .order_by(User.registered_date.desc())
            .all()
        )

        return {
            "count": len(approved_users),
            "users": [
                {
                    "id": u.id,
                    "email": u.email,
                    "username": u.username,
                    "first_name": u.first_name,
                    "last_name": u.last_name,
                    "desired_name": u.desired_name,
                    "role": u.role,
                    "created_at": u.created_at.isoformat(),
                    "registered_date": (
                        u.registered_date.isoformat()
                        if u.registered_date is not None
                        else None
                    ),
                    "approved_at": (
                        u.approved_at.isoformat() if u.approved_at is not None else None
                    ),
                }
                for u in approved_users
            ],
        }

    except SQLAlchemyError as e:
        logger.error("Database error retrieving recently approved users: %s", str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve recently approved users",
        )
