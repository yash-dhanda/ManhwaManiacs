"""notification_locked_until: when an announced chapter opens to everyone

Revision ID: 0027_notification_locked_until
Revises: 0026_circle_social
Create Date: 2026-11-23

AsuraScans lists a chapter six hours before it serves it to non-members. The
update sweep announced it the moment it was listed, and opening it answered
"Chapter not found". ``update_notifications.locked_until`` records the instant
the source gave for the unlock (an ISO-8601 UTC string ending in ``Z``, exactly
as clients read it), so the Updates list can count down to it in place of a
Read button that cannot work yet. NULL for every existing row and for every
chapter that was open when announced.
"""

from __future__ import annotations

from collections.abc import Sequence
from typing import Union

import sqlalchemy as sa
from alembic import op

revision: str = "0027_notification_locked_until"
down_revision: Union[str, Sequence[str], None] = "0026_circle_social"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "update_notifications",
        sa.Column("locked_until", sa.String(32), nullable=True),
    )


def downgrade() -> None:
    with op.batch_alter_table("update_notifications") as batch:
        batch.drop_column("locked_until")
