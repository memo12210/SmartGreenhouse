"""Add fcm tokens table

Revision ID: 8bc0da880381
Revises: ecf129853a14
Create Date: 2026-05-22
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "8bc0da880381"
down_revision: Union[str, None] = "ecf129853a14"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "fcm_tokens",
        sa.Column("user_id", sa.UUID(), nullable=False),
        sa.Column("token", sa.String(length=512), nullable=False),
        sa.Column("platform", sa.String(length=50), nullable=False),
        sa.Column("device_name", sa.String(length=100), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False),
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_index(
        "ix_fcm_tokens_token",
        "fcm_tokens",
        ["token"],
        unique=True,
    )


def downgrade() -> None:
    op.drop_index("ix_fcm_tokens_token", table_name="fcm_tokens")
    op.drop_table("fcm_tokens")