"""
Password validation module for Learn by Doing v1
Provides password strength validation and requirements checking
"""

import re
from typing import Dict, List, Tuple, Any


class PasswordValidator:
    """Password validator class with comprehensive security checks"""

    # Password requirements
    MIN_LENGTH = 12
    REQUIRE_UPPERCASE = True
    REQUIRE_LOWERCASE = True
    REQUIRE_DIGIT = True
    REQUIRE_SPECIAL = True
    SPECIAL_CHARS = "!@#$%^&*()_+-=[]{}|;:,.<>?"

    @classmethod
    def validate(cls, password: str) -> Tuple[bool, List[str]]:
        """
        Validate password against security requirements
        
        Args:
            password: The password to validate
            
        Returns:
            Tuple of (is_valid, list_of_errors)
        """
        errors = []

        # Check minimum length
        if len(password) < cls.MIN_LENGTH:
            errors.append(f"Password must be at least {cls.MIN_LENGTH} characters long")

        # Check for uppercase letter
        if cls.REQUIRE_UPPERCASE and not re.search(r"[A-Z]", password):
            errors.append("Password must contain at least one uppercase letter")

        # Check for lowercase letter
        if cls.REQUIRE_LOWERCASE and not re.search(r"[a-z]", password):
            errors.append("Password must contain at least one lowercase letter")

        # Check for digit
        if cls.REQUIRE_DIGIT and not re.search(r"\d", password):
            errors.append("Password must contain at least one digit")

        # Check for special character
        if cls.REQUIRE_SPECIAL and not any(char in cls.SPECIAL_CHARS for char in password):
            errors.append(f"Password must contain at least one special character ({cls.SPECIAL_CHARS})")

        return (len(errors) == 0, errors)


def validate_password(password: str, username: str = "") -> Dict[str, Any]:
    """
    Validate password with comprehensive checks including username similarity
    
    Args:
        password: The password to validate
        username: Optional username to check for similarity
        
    Returns:
        Dictionary with validation results:
        {
            "is_valid": bool,
            "errors": list of error messages,
            "strength_guide": list of requirements
        }
    """
    is_valid, errors = PasswordValidator.validate(password)
    
    # Additional check: password shouldn't contain username
    if username and username.lower() in password.lower():
        is_valid = False
        errors.append("Password should not contain your username or email")
    
    # Provide strength guide
    strength_guide = [
        f"At least {PasswordValidator.MIN_LENGTH} characters long",
        "Contains uppercase and lowercase letters",
        "Contains at least one number",
        f"Contains at least one special character ({PasswordValidator.SPECIAL_CHARS})",
        "Does not contain your username or email"
    ]
    
    return {
        "is_valid": is_valid,
        "errors": errors,
        "strength_guide": strength_guide
    }
