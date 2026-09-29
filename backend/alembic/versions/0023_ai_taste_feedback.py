"""reading_profiles.taste and the ai_feedback table

Revision ID: 0023_ai_taste_feedback
Revises: 0022_home_feed
Create Date: 2026-09-29

The profile's taste (onboarding answers: formats, genre weights, art styles,
seeds) follows the profile to every device, so it is one JSON column beside
``onboarding_step``. ``ai_feedback`` is owned data, not a cache: a reader's
"not interested", liked picks and rejected tags.
"""

from __future__ import annotations

from collections.abc import Sequence
from typing import Union

import sqlalchemy as sa
from alembic import op

revision: str = "0023_ai_taste_feedback"
down_revision: Union[str, Sequence[str], None] = "0022_home_feed"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("reading_profiles", sa.Column("taste", sa.Text(), nullable=True))
    op.create_table(
        "ai_feedback",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("profile_id", sa.Integer(), nullable=False),
        sa.Column("signal", sa.String(16), nullable=False),
        sa.Column("anilist_id", sa.Integer(), nullable=True),
        sa.Column("source_id", sa.String(64), nullable=True),
        sa.Column("series_key", sa.String(512), nullable=True),
        sa.Column("tag", sa.String(64), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(
            ["user_id", "profile_id"],
            ["reading_profiles.user_id", "reading_profiles.id"],
            ondelete="CASCADE",
            name="fk_ai_feedback_scope",
        ),
    )
    op.create_index(
        "ix_ai_feedback_scope", "ai_feedback", ["user_id", "profile_id", "signal"]
    )


def downgrade() -> None:
    op.drop_index("ix_ai_feedback_scope", table_name="ai_feedback")
    op.drop_table("ai_feedback")
    with op.batch_alter_table("reading_profiles") as batch:
        batch.drop_column("taste")
