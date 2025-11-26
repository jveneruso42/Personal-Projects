"""
Role definitions for Learn by Doing v1
"""

from enum import Enum


class Role(str, Enum):
    """User roles for authorization"""
    PENDING = "pending"
    TEACHER = "teacher"
    PARAEDUCATOR = "paraeducator"
    ADMIN = "admin"
    SUPER_ADMIN = "super_admin"
    SUPERUSER = "superuser"
