"""circle_social: chapter reactions, letters and shared shelves

Revision ID: 0026_circle_social
Revises: 0025_circle_core
Create Date: 2026-09-30

The second half of the Circle. ``circle_reactions`` holds one reaction per
profile per chapter (``shared`` is fixed at write time from the author's
switches, so a reaction made while "Show my reactions" was off never surfaces
later). ``circle_letters`` is Recommend to / Pass it on, one row per
recipient. ``collections.share_mode`` plus ``collection_shares`` make a shelf
readable by chosen members, and ``collection_series`` now snapshots the title
and cover the adder saw and records who added the row (its composite foreign
key cascades, so deleting a profile removes the series it added to other
profiles' shelves). All of it is user data: none of it is in ``CACHE_TABLES``.
"""

from __future__ import annotations

from collections.abc import Sequence
from typing import Union

import sqlalchemy as sa
from alembic import op

revision: str = "0026_circle_social"
down_revision: Union[str, Sequence[str], None] = "0025_circle_core"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

_BACKFILL = """
UPDATE collection_series SET
  added_by_user_id = (
    SELECT c.user_id FROM collections c WHERE c.id = collection_series.collection_id),
  added_by_profile_id = (
    SELECT c.profile_id FROM collections c WHERE c.id = collection_series.collection_id),
  title = COALESCE(
    (SELECT f.title FROM followed_series f JOIN collections c
       ON c.user_id = f.user_id AND c.profile_id = f.profile_id
      WHERE c.id = collection_series.collection_id
        AND f.source_id = collection_series.source_id
        AND f.series_key = collection_series.series_key),
    (SELECT NULLIF(s.title, '') FROM source_series_cache s
      WHERE s.source_id = collection_series.source_id
        AND s.series_key = collection_series.series_key),
    series_key),
  cover_url = COALESCE(
    (SELECT f.cover_url FROM followed_series f JOIN collections c
       ON c.user_id = f.user_id AND c.profile_id = f.profile_id
      WHERE c.id = collection_series.collection_id
        AND f.source_id = collection_series.source_id
        AND f.series_key = collection_series.series_key),
    (SELECT s.cover_url FROM source_series_cache s
      WHERE s.source_id = collection_series.source_id
        AND s.series_key = collection_series.series_key))
"""


def _profile_fk(column: str) -> sa.Column:
    return sa.Column(
        column,
        sa.Integer(),
        sa.ForeignKey("reading_profiles.id", ondelete="CASCADE"),
        nullable=False,
    )


def _scope(user_col: str, profile_col: str, name: str) -> sa.ForeignKeyConstraint:
    return sa.ForeignKeyConstraint(
        [user_col, profile_col],
        ["reading_profiles.user_id", "reading_profiles.id"],
        ondelete="CASCADE",
        name=name,
    )


def upgrade() -> None:
    op.create_table(
        "circle_reactions",
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        _profile_fk("profile_id"),
        sa.Column("source_id", sa.String(64), nullable=False),
        sa.Column("series_key", sa.String(512), nullable=False),
        sa.Column("chapter_key", sa.String(512), nullable=False),
        sa.Column("chapter_number", sa.Float(), nullable=True),
        sa.Column("kind", sa.String(16), nullable=False),
        sa.Column("shared", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint("profile_id", "source_id", "series_key", "chapter_key"),
        _scope("user_id", "profile_id", "fk_circle_reactions_scope"),
    )
    op.create_index(
        "ix_circle_reactions_chapter",
        "circle_reactions",
        ["source_id", "series_key", "chapter_key"],
    )
    op.create_table(
        "circle_letters",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("from_user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        _profile_fk("from_profile_id"),
        sa.Column("to_user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        _profile_fk("to_profile_id"),
        sa.Column("sent_group", sa.String(32), nullable=False),
        sa.Column("source_id", sa.String(64), nullable=False),
        sa.Column("series_key", sa.String(512), nullable=False),
        sa.Column("title", sa.String(512), nullable=False),
        sa.Column("cover_url", sa.String(1024), nullable=True),
        sa.Column("note", sa.String(140), nullable=True),
        sa.Column("state", sa.String(16), nullable=False, server_default="new"),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        _scope("from_user_id", "from_profile_id", "fk_circle_letters_from_scope"),
        _scope("to_user_id", "to_profile_id", "fk_circle_letters_to_scope"),
    )
    op.create_index("ix_circle_letters_to", "circle_letters", ["to_profile_id", "created_at"])
    op.create_index(
        "ix_circle_letters_from", "circle_letters", ["from_profile_id", "sent_group"]
    )

    op.add_column("collections", sa.Column("share_mode", sa.String(16), nullable=True))
    op.create_table(
        "collection_shares",
        sa.Column(
            "collection_id",
            sa.Integer(),
            sa.ForeignKey("collections.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        _profile_fk("profile_id"),
        sa.Column("created_at", sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint("collection_id", "profile_id"),
        _scope("user_id", "profile_id", "fk_collection_shares_scope"),
    )
    op.create_index("ix_collection_shares_profile", "collection_shares", ["profile_id"])

    with op.batch_alter_table("collection_series", recreate="always") as batch:
        batch.add_column(sa.Column("title", sa.String(512), nullable=True))
        batch.add_column(sa.Column("cover_url", sa.String(1024), nullable=True))
        batch.add_column(sa.Column("added_by_user_id", sa.Integer(), nullable=True))
        batch.add_column(sa.Column("added_by_profile_id", sa.Integer(), nullable=True))
        batch.create_foreign_key(
            "fk_collection_series_added_by",
            "reading_profiles",
            ["added_by_user_id", "added_by_profile_id"],
            ["user_id", "id"],
            ondelete="CASCADE",
        )
        batch.create_index("ix_collection_series_added_by", ["added_by_profile_id"])
    op.execute(_BACKFILL)


def downgrade() -> None:
    with op.batch_alter_table("collection_series", recreate="always") as batch:
        batch.drop_index("ix_collection_series_added_by")
        batch.drop_constraint("fk_collection_series_added_by", type_="foreignkey")
        for name in ("added_by_profile_id", "added_by_user_id", "cover_url", "title"):
            batch.drop_column(name)
    op.drop_index("ix_collection_shares_profile", table_name="collection_shares")
    op.drop_table("collection_shares")
    with op.batch_alter_table("collections") as batch:
        batch.drop_column("share_mode")
    op.drop_index("ix_circle_letters_from", table_name="circle_letters")
    op.drop_index("ix_circle_letters_to", table_name="circle_letters")
    op.drop_table("circle_letters")
    op.drop_index("ix_circle_reactions_chapter", table_name="circle_reactions")
    op.drop_table("circle_reactions")
