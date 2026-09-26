"""world_catalog_cache: answers from AniList and MangaUpdates, by lookup key

Revision ID: 0017_world_catalog_cache
Revises: 0016_backfill_last_login
Create Date: 2026-09-26

Recommendations now come from the worldwide catalogs, not only from series a
connector has already served. Their answers are cached here so a page visit
does not re-ask two public APIs the same questions. A cache table in every
sense: listed in ``core.cache_tables.CACHE_TABLES``, dropped by backups, and
safe to lose, so ``downgrade()`` simply drops it.
"""

from __future__ import annotations

from collections.abc import Sequence
from typing import Union

import sqlalchemy as sa
from alembic import op

revision: str = "0017_world_catalog_cache"
down_revision: Union[str, Sequence[str], None] = "0016_backfill_last_login"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "world_catalog_cache",
        sa.Column("key", sa.String(length=300), primary_key=True),
        sa.Column("payload", sa.Text(), nullable=False),
        sa.Column("fetched_at", sa.DateTime(), nullable=False),
    )
    op.create_index(
        "ix_world_catalog_cache_fetched_at", "world_catalog_cache", ["fetched_at"]
    )


def downgrade() -> None:
    op.drop_index("ix_world_catalog_cache_fetched_at", table_name="world_catalog_cache")
    op.drop_table("world_catalog_cache")
