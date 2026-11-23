"""drop_stale_latest_browse_rows: browse rows cached under the old ``latest``

Revision ID: 0028_drop_stale_latest_browse_rows
Revises: 0027_notification_locked_until
Create Date: 2026-11-23

``latest`` used to mean "newly added" on the Madara family, hentai20, elftoon,
galaxymanga, mangakatana, rawkuma, mangadex and omegascans, and now means
"recently updated" (the old list is ``new``). A row stored under it still holds
the old list: it is served until its TTL, and as the stale fallback for as long
as the source keeps failing. ``source_browse_cache`` is a cache, so the rows
are deleted rather than picked out by source: one refetch refills each page.
Nothing to undo on the way down.
"""

from __future__ import annotations

from collections.abc import Sequence
from typing import Union

from alembic import op

revision: str = "0028_drop_stale_latest_browse_rows"
down_revision: Union[str, Sequence[str], None] = "0027_notification_locked_until"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute("DELETE FROM source_browse_cache WHERE sort = 'latest'")


def downgrade() -> None:
    pass
