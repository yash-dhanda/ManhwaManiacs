"""reader_page_annotations: client-reported page tints and panel boxes

Revision ID: 0024_reader_page_annotations
Revises: 0023_ai_taste_feedback
Create Date: 2026-09-29

A shared cache (derived, safe to lose): a page's colour and panel layout are the
same for every reader, so clients report once and every profile's manifest
carries them.
"""

from __future__ import annotations

from collections.abc import Sequence
from typing import Union

import sqlalchemy as sa
from alembic import op

revision: str = "0024_reader_page_annotations"
down_revision: Union[str, Sequence[str], None] = "0023_ai_taste_feedback"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "reader_page_annotations",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("source_id", sa.String(64), nullable=False),
        sa.Column("series_key", sa.String(512), nullable=False),
        sa.Column("chapter_key", sa.String(512), nullable=False),
        sa.Column("page_number", sa.Integer(), nullable=False),
        sa.Column("page_etag", sa.String(32), nullable=False),
        sa.Column("page_count", sa.Integer(), nullable=False),
        sa.Column("tint", sa.String(7), nullable=True),
        sa.Column("panels", sa.Text(), nullable=True),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.UniqueConstraint(
            "source_id", "series_key", "chapter_key", "page_etag",
            name="uq_reader_page_annotations_page",
        ),
    )
    op.create_index(
        "ix_reader_page_annotations_chapter",
        "reader_page_annotations",
        ["source_id", "series_key", "chapter_key"],
    )
