"""connectors.release_dates: every shape the 2026-11-23 source probe printed."""

from __future__ import annotations

from datetime import datetime, timezone

import pytest

from connectors.release_dates import normalize_release_date

NOW = datetime(2026, 11, 23, 12, 30, tzinfo=timezone.utc)


@pytest.mark.parametrize(
    ("text", "kwargs", "expected"),
    [
        # Already ISO: a day stays, an instant becomes its UTC day.
        ("2026-11-21", {}, "2026-11-21"),
        ("2026-11-21T09:15:00Z", {}, "2026-11-21"),
        ("2026-11-21T09:15:00.123Z", {}, "2026-11-21"),
        ("2026-11-21T01:00:00+03:00", {}, "2026-11-20"),
        ("2026-11-21T23:30:00-02:00", {}, "2026-11-22"),
        # manhwa18.cc / manhwa18.net
        ("21 Nov 2026", {}, "2026-11-21"),
        ("1 November 2026", {}, "2026-11-01"),
        ("18 Mar 2021", {}, "2021-03-18"),
        # hentai20.io
        ("October 1, 2026", {}, "2026-10-01"),
        ("Nov 05,2018", {}, "2018-11-05"),
        ("November 3rd, 2026", {}, "2026-11-03"),
        ("Sept 9, 2026", {}, "2026-09-09"),
        # toonily.com: two-digit year
        ("May 31, 23", {}, "2023-05-31"),
        ("Sep 24, 21", {}, "2021-09-24"),
        # 18porncomic: day first
        ("24-09-2024", {"day_first": True}, "2024-09-24"),
        ("06-11-2026", {"day_first": True}, "2026-11-06"),
        ("06-11-2026", {"day_first": False}, "2026-06-11"),
        # Ambiguous without a stated order is refused; decided by a field > 12.
        ("06-11-2026", {}, None),
        ("24-09-2024", {}, "2024-09-24"),
        ("09/24/2024", {}, "2024-09-24"),
        ("2019/07/13", {}, "2019-07-13"),
        # Relative text resolves against ``now``.
        ("2 days ago", {"now": NOW}, "2026-11-21"),
        ("11 hours ago", {"now": NOW}, "2026-11-23"),
        ("13 hours ago", {"now": NOW}, "2026-11-22"),
        ("an hour ago", {"now": NOW}, "2026-11-23"),
        ("a day ago", {"now": NOW}, "2026-11-22"),
        ("1 week ago", {"now": NOW}, "2026-11-16"),
        ("3 months ago", {"now": NOW}, "2026-08-25"),
        ("Yesterday", {"now": NOW}, "2026-11-22"),
        ("Today", {"now": NOW}, "2026-11-23"),
        ("just now", {"now": NOW}, "2026-11-23"),
        # Not dates.
        ("", {}, None),
        (None, {}, None),
        ("Updating", {}, None),
        ("31 Foo 2026", {}, None),
        ("2026-13-45", {}, None),
        ("32-01-2026", {"day_first": True}, None),
    ],
)
def test_normalize_release_date(text, kwargs, expected):
    assert normalize_release_date(text, **kwargs) == expected
