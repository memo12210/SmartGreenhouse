"""add_predictions_table

Revision ID: f3e8b4d1a2c3
Revises: 8bc0da880381
Create Date: 2024-05-24 15:00:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = 'f3e8b4d1a2c3'
down_revision: Union[str, Sequence[str], None] = '8bc0da880381'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table('predictions',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('greenhouse_id', sa.UUID(), nullable=False),
        sa.Column('yield_kg_per_m2', sa.Float(), nullable=False),
        sa.Column('model_version', sa.String(length=50), nullable=False),
        sa.Column('timestamp', sa.DateTime(timezone=True), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['greenhouse_id'], ['greenhouses.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_predictions_greenhouse_id'), 'predictions', ['greenhouse_id'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_predictions_greenhouse_id'), table_name='predictions')
    op.drop_table('predictions')
