"""streak_milestones and listen_sessions: per-profile user data

Revision ID: 0021_streaks_listen_sessions
Revises: 0020_collection_rules
Create Date: 2026-09-29

``streak_milestones`` records which streak milestone cards a profile has seen
so they show once across devices. ``listen_sessions`` records narration time
per voice for the Annual's colophon. Both are scoped like ``chapter_progress``.
"""

from __future__ import annotations

from collections.abc import Sequence
from typing import Union

import sqlalchemy as sa
from alembic import op

revision: str = "0021_streaks_listen_sessions"
down_revision: Union[str, Sequence[str], None] = "0020_collection_rules"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "streak_milestones",
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column(
            "profile_id",
            sa.Integer(),
            sa.ForeignKey("reading_profiles.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("days", sa.Integer(), nullable=False),
        sa.Column("seen_at", sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint("user_id", "profile_id", "days"),
        sa.ForeignKeyConstraint(
            ["user_id", "profile_id"],
            ["reading_profiles.user_id", "reading_profiles.id"],
            ondelete="CASCADE",
            name="fk_streak_milestones_scope",
        ),
    )
    op.create_index(
        "ix_streak_milestones_profile_id", "streak_milestones", ["profile_id"]
    )
    op.create_table(
        "listen_sessions",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column(
            "profile_id",
            sa.Integer(),
            sa.ForeignKey("reading_profiles.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("source_id", sa.String(64), nullable=False),
        sa.Column("series_key", sa.String(512), nullable=False),
        sa.Column("chapter_key", sa.String(512), nullable=False),
        sa.Column("seconds", sa.Integer(), nullable=False),
        sa.Column("voice_ids", sa.Text(), nullable=False, server_default="[]"),
        sa.Column("started_at", sa.DateTime(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(
            ["user_id", "profile_id"],
            ["reading_profiles.user_id", "reading_profiles.id"],
            ondelete="CASCADE",
            name="fk_listen_sessions_scope",
        ),
        sa.UniqueConstraint(
            "user_id",
            "profile_id",
            "source_id",
            "series_key",
            "chapter_key",
            "started_at",
            name="uq_listen_sessions_push",
        ),
    )
    op.create_index(
        "ix_listen_sessions_started_at",
        "listen_sessions",
        ["user_id", "profile_id", "started_at"],
    )
    op.create_index("ix_listen_sessions_profile_id", "listen_sessions", ["profile_id"])


def downgrade() -> None:
    op.drop_table("listen_sessions")
    op.drop_table("streak_milestones")
