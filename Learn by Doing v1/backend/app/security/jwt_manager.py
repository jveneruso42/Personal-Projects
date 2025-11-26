"""
JWT Manager for Learn by Doing v1
Handles JWT token creation and verification
"""

import os
import jwt
from datetime import datetime, timedelta
from typing import Dict, Any, Optional
from pydantic import BaseModel
from .roles import Role


class TokenPayload(BaseModel):
    """JWT Token Payload structure"""
    user_id: int
    email: str
    role: Role
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    desired_name: Optional[str] = None


class JWTManager:
    """Manages JWT token operations"""
    
    # Get secret from environment or use default for development
    SECRET_KEY = os.getenv("JWT_SECRET_KEY", "your-secret-key-change-in-production")
    ALGORITHM = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES = 30
    REFRESH_TOKEN_EXPIRE_DAYS = 7
    
    @classmethod
    def create_access_token(cls, payload: TokenPayload) -> str:
        """
        Create a JWT access token
        
        Args:
            payload: Token payload data
            
        Returns:
            Encoded JWT token string
        """
        to_encode = payload.model_dump()
        to_encode["type"] = "access"
        to_encode["role"] = payload.role.value  # Convert enum to string
        expire = datetime.utcnow() + timedelta(minutes=cls.ACCESS_TOKEN_EXPIRE_MINUTES)
        to_encode["exp"] = expire
        to_encode["iat"] = datetime.utcnow()
        
        return jwt.encode(to_encode, cls.SECRET_KEY, algorithm=cls.ALGORITHM)
    
    @classmethod
    def create_refresh_token(cls, payload: TokenPayload) -> str:
        """
        Create a JWT refresh token
        
        Args:
            payload: Token payload data
            
        Returns:
            Encoded JWT refresh token string
        """
        to_encode = {"user_id": payload.user_id, "email": payload.email}
        to_encode["type"] = "refresh"
        expire = datetime.utcnow() + timedelta(days=cls.REFRESH_TOKEN_EXPIRE_DAYS)
        to_encode["exp"] = expire
        to_encode["iat"] = datetime.utcnow()
        
        return jwt.encode(to_encode, cls.SECRET_KEY, algorithm=cls.ALGORITHM)
    
    @classmethod
    def verify_token(cls, token: str) -> Dict[str, Any]:
        """
        Verify and decode a JWT token
        
        Args:
            token: JWT token string
            
        Returns:
            Decoded token payload
            
        Raises:
            jwt.InvalidTokenError: If token is invalid or expired
        """
        return jwt.decode(token, cls.SECRET_KEY, algorithms=[cls.ALGORITHM])
