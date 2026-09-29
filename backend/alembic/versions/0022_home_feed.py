"""home feed: followed_series.last_new_chapter_at and the ai_result_cache table

Revision ID: 0022_home_feed
Revises: 0021_streaks_listen_sessions
Create Date: 2026-09-29

``GET /home`` lists "New this week" from the moment an update check found new
chapters, which is recorded whether or not a notification was allowed, so the
column is backfilled from the newest notification of each follow. The one
``ai_result_cache`` table holds every AI answer this redesign stores (the home
editorial first; similar, tags and recaps later). It is derived data: listed in
``core.cache_tables.CACHE_TABLES`` and safe to lose.
"""

from __future__ import annotations

from collections.abc import Sequence
from typing import Union

import sqlalchemy as sa
from alembic import op

revision: str = "0022_home_feed"
down_revision: Union[str, Sequence[str], None] = "0021_streaks_listen_sessions"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "followed_series",
        sa.Column("last_new_chapter_at", sa.DateTime(), nullable=True),
    )
    op.execute(
        "UPDATE followed_series SET last_new_chapter_at = "
        "(SELECT MAX(created_at) FROM update_notifications "
        "WHERE followed_series_id = followed_series.id)"
    )
    op.create_table(
        "ai_result_cache",
        sa.Column("key", sa.String(64), primary_key=True),
        sa.Column("kind", sa.String(32), nullable=False),
        sa.Column(
            "profile_id",
            sa.Integer(),
            sa.ForeignKey("reading_profiles.id", ondelete="CASCADE"),
            nullable=True,
        ),
        sa.Column("source_id", sa.String(64), nullable=True),
        sa.Column("series_key", sa.String(512), nullable=True),
        sa.Column("payload", sa.Text(), nullable=False),
        sa.Column("model", sa.String(64), nullable=False, server_default=""),
        sa.Column("generated_at", sa.DateTime(), nullable=False),
        sa.Column("expires_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_ai_result_cache_expires_at", "ai_result_cache", ["expires_at"])
    op.create_index(
        "ix_ai_result_cache_series", "ai_result_cache", ["source_id", "series_key"]
    )
    op.create_index("ix_ai_result_cache_profile", "ai_result_cache", ["profile_id"])


def downgrade() -> None:
    op.drop_index("ix_ai_result_cache_profile", table_name="ai_result_cache")
    op.drop_index("ix_ai_result_cache_series", table_name="ai_result_cache")
    op.drop_index("ix_ai_result_cache_expires_at", table_name="ai_result_cache")
    op.drop_table("ai_result_cache")
    with op.batch_alter_table("followed_series") as batch:
        batch.drop_column("last_new_chapter_at")
