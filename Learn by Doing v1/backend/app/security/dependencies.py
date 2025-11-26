"""
Security dependencies for FastAPI
Provides authentication and authorization dependencies
"""

import os
import jwt
from typing import Dict, Callable
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from .jwt_manager import JWTManager
from .roles import Role

# HTTP Bearer token security scheme
security = HTTPBearer()


async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)) -> Dict:
    """
    Dependency to get the current authenticated user from JWT token
    
    Args:
        credentials: HTTP Bearer credentials from request
        
    Returns:
        Dictionary with user information from JWT payload
        
    Raises:
        HTTPException: 401 if token is invalid or expired
    """
    token = credentials.credentials
    
    try:
        payload = JWTManager.verify_token(token)
        
        # Verify it's an access token
        if payload.get("type") != "access":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token type",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        return payload
        
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except jwt.InvalidTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token",
            headers={"WWW-Authenticate": "Bearer"},
        )


def require_role(*allowed_roles: Role) -> Callable:
    """
    Dependency factory to require specific roles
    
    Args:
        *allowed_roles: Roles that are allowed to access the endpoint
        
    Returns:
        FastAPI dependency function
        
    Example:
        @app.get("/admin", dependencies=[Depends(require_role(Role.ADMIN))])
    """
    async def role_checker(current_user: Dict = Depends(get_current_user)) -> Dict:
        user_role = current_user.get("role")
        
        # Superuser has access to everything
        if user_role == Role.SUPERUSER.value:
            return current_user
        
        # Check if user has one of the allowed roles
        allowed_role_values = [role.value for role in allowed_roles]
        if user_role not in allowed_role_values:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Insufficient permissions. Required role: {', '.join(allowed_role_values)}",
            )
        
        return current_user
    
    return role_checker
