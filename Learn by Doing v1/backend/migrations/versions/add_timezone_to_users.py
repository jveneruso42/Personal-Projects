"""add timezone to users

Revision ID: add_timezone_to_users
Revises:
Create Date: 2025-11-25

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "add_timezone_to_users"
down_revision = "h8i9j0k1l2m3"  # Latest head
branch_labels = None
depends_on = None


def upgrade():
    """Add timezone column to users table"""
    op.add_column("users", sa.Column("timezone", sa.String(), nullable=True))


def downgrade():
    """Remove timezone column from users table"""
    op.drop_column("users", "timezone")
