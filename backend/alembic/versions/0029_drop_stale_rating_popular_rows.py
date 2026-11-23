"""drop_stale_rating_popular_rows: browse rows cached under the old ``rating`` / ``popular``

Revision ID: 0029_drop_stale_rating_popular_rows
Revises: 0028_drop_stale_latest_browse_rows
Create Date: 2026-11-24

``rating`` on the Madara family used to send a value the sites ignore, so it
returned the newly-added list; it now sends the real rating order. 18porncomic's
``popular`` used to send a parameter the site ignored and is now a real
popularity listing, and several other sources replaced a stand-in ``popular``
(a home page, or a chapter-count sort) with the site's own ordering. A row
stored under either sort still holds the old list: it is served until its TTL,
and as the stale fallback for as long as the source keeps failing.
``source_browse_cache`` is a cache, so the rows are deleted rather than picked
out by source: one refetch refills each page. Nothing to undo on the way down.
"""

from __future__ import annotations

from collections.abc import Sequence
from typing import Union

from alembic import op

revision: str = "0029_drop_stale_rating_popular_rows"
down_revision: Union[str, Sequence[str], None] = "0028_drop_stale_latest_browse_rows"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute("DELETE FROM source_browse_cache WHERE sort IN ('rating', 'popular')")


def downgrade() -> None:
    pass
