"""
AWS Email Service for Learn by Doing v1
Provides email sending functionality using AWS SES or fallback to console logging
"""

import logging
from typing import Optional

logger = logging.getLogger(__name__)


class EmailService:
    """Email service for sending emails"""
    
    def __init__(self):
        """Initialize email service"""
        self.enabled = False
        logger.warning("Email service initialized in stub mode - emails will be logged but not sent")
    
    def send_password_reset_email(
        self,
        to_email: str,
        user_name: str,
        reset_token: str,
        expires_in_hours: int = 24
    ) -> bool:
        """
        Send a password reset email
        
        Args:
            to_email: Recipient email address
            user_name: User's display name
            reset_token: Password reset token
            expires_in_hours: Token expiration time in hours
            
        Returns:
            True if email was sent successfully, False otherwise
        """
        logger.info(f"[EMAIL STUB] Password reset email for {to_email}")
        logger.info(f"  User: {user_name}")
        logger.info(f"  Reset Token: {reset_token}")
        logger.info(f"  Expires in: {expires_in_hours} hours")
        logger.info(f"  Reset Link: http://localhost:3000/reset-password?token={reset_token}")
        return True
    
    def send_welcome_email(
        self,
        to_email: str,
        user_name: str
    ) -> bool:
        """
        Send a welcome email to a new user
        
        Args:
            to_email: Recipient email address
            user_name: User's display name
            
        Returns:
            True if email was sent successfully, False otherwise
        """
        logger.info(f"[EMAIL STUB] Welcome email for {to_email}")
        logger.info(f"  User: {user_name}")
        return True


# Singleton instance
_email_service: Optional[EmailService] = None


def get_email_service() -> EmailService:
    """
    Get the email service singleton instance
    
    Returns:
        EmailService instance
    """
    global _email_service
    if _email_service is None:
        _email_service = EmailService()
    return _email_service
