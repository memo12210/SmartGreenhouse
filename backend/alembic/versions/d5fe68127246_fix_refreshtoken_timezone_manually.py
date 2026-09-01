"""Fix RefreshToken timezone manually

Revision ID: d5fe68127246
Revises: 5a90ec9e6a60
Create Date: 2026-05-18 20:11:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'd5fe68127246'
down_revision: Union[str, Sequence[str], None] = '5a90ec9e6a60'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.alter_column('refresh_tokens', 'expires_at',
               existing_type=sa.DateTime(),
               type_=sa.DateTime(timezone=True),
               existing_nullable=False)


def downgrade() -> None:
    op.alter_column('refresh_tokens', 'expires_at',
               existing_type=sa.DateTime(timezone=True),
               type_=sa.DateTime(),
               existing_nullable=False)
