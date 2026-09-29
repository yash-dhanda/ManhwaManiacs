"""reading_profiles: skin, notify_enabled, onboarding_step, daily_goal_minutes

Revision ID: 0018_profile_redesign_cols
Revises: 0017_world_catalog_cache
Create Date: 2026-09-29

The redesign ships two skins, Cinematic and Glass, and the skin follows the
PROFILE, not the device (stack-decision §2.4): ``skin`` is the source of truth,
NULL meaning "the default skin". Beside it, the per-profile master switch for
update notifications (``notify_enabled``, which the sweep honours), the
onboarding cursor (``onboarding_step``: NULL, '1'..'7' or 'done') and Glass's
daily reading goal (``daily_goal_minutes``, NULL meaning Off).

Every profile that exists before this revision is marked ``'done'``: the people
already reading must never be walked through onboarding. New rows get NULL
because the ORM sets no default.
"""

from __future__ import annotations

from collections.abc import Sequence
from typing import Union

import sqlalchemy as sa
from alembic import op

revision: str = "0018_profile_redesign_cols"
down_revision: Union[str, Sequence[str], None] = "0017_world_catalog_cache"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "reading_profiles", sa.Column("skin", sa.String(length=16), nullable=True)
    )
    op.add_column(
        "reading_profiles",
        sa.Column("notify_enabled", sa.Integer(), nullable=False, server_default="1"),
    )
    op.add_column(
        "reading_profiles",
        sa.Column("onboarding_step", sa.String(length=8), nullable=True),
    )
    op.add_column(
        "reading_profiles",
        sa.Column("daily_goal_minutes", sa.Integer(), nullable=True),
    )
    op.execute("UPDATE reading_profiles SET onboarding_step = 'done'")


def downgrade() -> None:
    # Lossy, and deliberately so: these columns hold each profile's own
    # choices (skin, notifications, goal) and there is nowhere else to put
    # them. Downgrading forgets them, and every profile reads as the default.
    for column in ("daily_goal_minutes", "onboarding_step", "notify_enabled", "skin"):
        op.drop_column("reading_profiles", column)
