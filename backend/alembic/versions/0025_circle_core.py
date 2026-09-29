"""circle_core: sharing switches, hidden series and the Circle activity record

Revision ID: 0025_circle_core
Revises: 0024_reader_page_annotations
Create Date: 2026-09-30

The Circle is social for two or three people on one server. Nothing is visible
until a profile turns ``share_activity`` on (``share_activity_since`` records
when, so nothing is shared retroactively). ``circle_events`` is the activity
record every Circle surface reads through one rule (``CircleService``);
``circle_hidden_series`` is the per-profile "hide this series" list. Both are
user data, so neither is in ``CACHE_TABLES`` and both are backed up.
"""

from __future__ import annotations

from collections.abc import Sequence
from typing import Union

import sqlalchemy as sa
from alembic import op

revision: str = "0025_circle_core"
down_revision: Union[str, Sequence[str], None] = "0024_reader_page_annotations"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

_SWITCHES = (
    ("share_activity", "0"),
    ("share_reactions", "1"),
    ("share_shelves", "1"),
    ("share_recommendations", "1"),
    ("share_include_mature", "0"),
    ("share_presence", "0"),
    ("share_streak", "0"),
)


def upgrade() -> None:
    for name, default in _SWITCHES:
        op.add_column(
            "reading_profiles",
            sa.Column(name, sa.Integer(), nullable=False, server_default=default),
        )
    op.add_column(
        "reading_profiles",
        sa.Column("share_activity_since", sa.DateTime(), nullable=True),
    )
    op.create_table(
        "circle_hidden_series",
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column(
            "profile_id",
            sa.Integer(),
            sa.ForeignKey("reading_profiles.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("source_id", sa.String(64), nullable=False),
        sa.Column("series_key", sa.String(512), nullable=False),
        sa.Column("title", sa.String(512), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint("profile_id", "source_id", "series_key"),
        sa.ForeignKeyConstraint(
            ["user_id", "profile_id"],
            ["reading_profiles.user_id", "reading_profiles.id"],
            ondelete="CASCADE",
            name="fk_circle_hidden_series_scope",
        ),
    )
    op.create_table(
        "circle_events",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column(
            "profile_id",
            sa.Integer(),
            sa.ForeignKey("reading_profiles.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("kind", sa.String(24), nullable=False),
        sa.Column("source_id", sa.String(64), nullable=False),
        sa.Column("series_key", sa.String(512), nullable=False),
        sa.Column("chapter_key", sa.String(512), nullable=True),
        sa.Column("chapter_number", sa.Float(), nullable=True),
        sa.Column("reaction", sa.String(16), nullable=True),
        sa.Column("title", sa.String(512), nullable=False),
        sa.Column("cover_url", sa.String(1024), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(
            ["user_id", "profile_id"],
            ["reading_profiles.user_id", "reading_profiles.id"],
            ondelete="CASCADE",
            name="fk_circle_events_scope",
        ),
    )
    op.create_index(
        "ix_circle_events_profile_created",
        "circle_events",
        ["profile_id", "created_at", "id"],
    )
    op.create_index("ix_circle_events_created", "circle_events", ["created_at", "id"])
    op.create_index(
        "ix_circle_events_series", "circle_events", ["source_id", "series_key"]
    )


def downgrade() -> None:
    op.drop_index("ix_circle_events_series", table_name="circle_events")
    op.drop_index("ix_circle_events_created", table_name="circle_events")
    op.drop_index("ix_circle_events_profile_created", table_name="circle_events")
    op.drop_table("circle_events")
    op.drop_table("circle_hidden_series")
    with op.batch_alter_table("reading_profiles") as batch:
        batch.drop_column("share_activity_since")
        for name, _ in reversed(_SWITCHES):
            batch.drop_column(name)
