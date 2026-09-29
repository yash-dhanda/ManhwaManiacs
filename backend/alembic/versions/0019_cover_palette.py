"""cover_palette: each series cover's ambient and palette colours

Revision ID: 0019_cover_palette
Revises: 0018_profile_redesign_cols
Create Date: 2026-09-29

Both redesign skins colour the room from the cover art: Cinematic's
``ambient {duo, tint, ink}`` and Glass's ``palette {a, l, lMax}``. They are
computed once per cover in the cover proxy and kept here so every series
payload can read them in one batched query. A cache table in every sense:
global (no user, profile or gate in the key), listed in
``core.cache_tables.CACHE_TABLES``, dropped by backups, swept after 30 days,
and safe to lose, so ``downgrade()`` simply drops it.
"""

from __future__ import annotations

from collections.abc import Sequence
from typing import Union

import sqlalchemy as sa
from alembic import op

revision: str = "0019_cover_palette"
down_revision: Union[str, Sequence[str], None] = "0018_profile_redesign_cols"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "cover_palette",
        sa.Column("source_id", sa.String(length=64), primary_key=True),
        sa.Column("series_key", sa.String(length=512), primary_key=True),
        sa.Column("ambient", sa.Text(), nullable=False),  # JSON {"duo","tint","ink"}
        sa.Column("palette", sa.Text(), nullable=False),  # JSON {"a","l","lMax"}
        sa.Column("computed_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_cover_palette_computed_at", "cover_palette", ["computed_at"])


def downgrade() -> None:
    op.drop_index("ix_cover_palette_computed_at", table_name="cover_palette")
    op.drop_table("cover_palette")
