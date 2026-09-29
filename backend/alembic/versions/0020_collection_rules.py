"""collections.rules: smart-shelf rules stored for the devices to evaluate

Revision ID: 0020_collection_rules
Revises: 0019_cover_palette
Create Date: 2026-09-29

A smart shelf (cinematic §8.11) is a collection whose membership is computed
on the device from ``{"all": [{field, op, value}]}``. The server only stores
the JSON so every device shows the same shelf; NULL is a plain collection.
"""

from __future__ import annotations

from collections.abc import Sequence
from typing import Union

import sqlalchemy as sa
from alembic import op

revision: str = "0020_collection_rules"
down_revision: Union[str, Sequence[str], None] = "0019_cover_palette"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("collections", sa.Column("rules", sa.Text(), nullable=True))


def downgrade() -> None:
    # Lossy: every smart shelf loses its rules and becomes a plain collection.
    op.drop_column("collections", "rules")
