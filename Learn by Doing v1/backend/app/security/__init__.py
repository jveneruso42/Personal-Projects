"""
Security package for Learn by Doing v1
Provides JWT authentication and authorization
"""

from .jwt_manager import JWTManager, TokenPayload
from .roles import Role
from .dependencies import get_current_user, require_role

__all__ = [
    "JWTManager",
    "TokenPayload",
    "Role",
    "get_current_user",
    "require_role",
]
