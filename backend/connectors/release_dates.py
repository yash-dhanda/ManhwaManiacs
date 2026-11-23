"""Turn the date text a site prints next to a chapter into ISO-8601.

``Chapter.release_date`` is consumed by two clients that only understand an
ISO ``YYYY-MM-DD`` day or a full ISO instant (``frontend/src/features/sources/
chapter-date.ts`` and its Flutter mirror gate on exactly that shape, and show
anything else verbatim). Scraped sites print "21 Nov 2026", "October 1, 2026",
"24-09-2024" or "2 days ago", which is why a chapter row read "21 Nov 2026"
beside "Today" for the chapter above it and could not be ordered or counted.

This module is the one place that turns those strings into a day. It returns
``YYYY-MM-DD`` (a day, not an instant: none of these sources states a time) or
``None`` when the text is not a date it can read, and never guesses:

* A numeric ``dd-mm-yyyy`` / ``mm-dd-yyyy`` date is ambiguous below day 13, so
  the caller says which order its site uses (``day_first``). Left unset, only
  a date that cannot be read the other way (a field above 12) is accepted.
* Relative text ("2 days ago", "an hour ago", "yesterday") is resolved against
  ``now`` (UTC). Months and years are 30 and 365 days, which is as precise as
  the site's own wording.

Parsing is English-only, like every site this is used on.
"""

from __future__ import annotations

import re
from datetime import date, datetime, timedelta, timezone

_MONTHS = {
    name: index
    for index, names in enumerate(
        (
            ("jan", "january"),
            ("feb", "february"),
            ("mar", "march"),
            ("apr", "april"),
            ("may",),
            ("jun", "june"),
            ("jul", "july"),
            ("aug", "august"),
            ("sep", "sept", "september"),
            ("oct", "october"),
            ("nov", "november"),
            ("dec", "december"),
        ),
        start=1,
    )
    for name in names
}

_ISO_RE = re.compile(
    r"^(\d{4})-(\d{2})-(\d{2})(?:[T ](\d{2}):(\d{2})(?::(\d{2})(?:\.\d+)?)?"
    r"\s*(Z|z|[+-]\d{2}:?\d{2})?)?$"
)
_NUMERIC_RE = re.compile(r"^(\d{1,2})[-/.](\d{1,2})[-/.](\d{4})$")
_YMD_SLASH_RE = re.compile(r"^(\d{4})[/.](\d{1,2})[/.](\d{1,2})$")
# "21 Nov 2026", "21st November, 2026"
_DMY_WORDS_RE = re.compile(
    r"^(\d{1,2})(?:st|nd|rd|th)?[\s-]+([A-Za-z]{3,9})\.?,?[\s-]+(\d{4})$"
)
# "Nov 21, 2026", "October 1st, 2026", "Nov 05,2018"
_MDY_WORDS_RE = re.compile(
    r"^([A-Za-z]{3,9})\.?\s+(\d{1,2})(?:st|nd|rd|th)?,?\s*(\d{4}|\d{2})$"
)
_RELATIVE_RE = re.compile(
    r"^(an?|\d+)\s+(second|sec|minute|min|hour|hr|day|week|month|year)s?\s+ago$",
    re.I,
)
_UNIT_DELTA = {
    "second": timedelta(seconds=1),
    "sec": timedelta(seconds=1),
    "minute": timedelta(minutes=1),
    "min": timedelta(minutes=1),
    "hour": timedelta(hours=1),
    "hr": timedelta(hours=1),
    "day": timedelta(days=1),
    "week": timedelta(weeks=1),
    "month": timedelta(days=30),
    "year": timedelta(days=365),
}


def _day(year: int, month: int, day: int) -> str | None:
    try:
        return date(year, month, day).isoformat()
    except ValueError:
        return None


def _iso(match: re.Match[str]) -> str | None:
    year, month, day = int(match.group(1)), int(match.group(2)), int(match.group(3))
    hour, minute, offset = match.group(4), match.group(5), match.group(7)
    if hour is None or offset is None or offset in ("Z", "z"):
        # A bare day, a naive time, or UTC: the day as written.
        return _day(year, month, day)
    # An offset instant is converted so the day is the UTC day, which is what
    # the clients (and ``Chapter.locked_until``) mean by an instant.
    sign = 1 if offset[0] == "+" else -1
    digits = offset[1:].replace(":", "")
    shift = timedelta(hours=int(digits[:2]), minutes=int(digits[2:]))
    try:
        local = datetime(year, month, day, int(hour), int(minute))
    except ValueError:
        return None
    return (local - sign * shift).date().isoformat()


def normalize_release_date(
    value: str | None,
    *,
    now: datetime | None = None,
    day_first: bool | None = None,
) -> str | None:
    """``value`` as an ISO ``YYYY-MM-DD`` day, or None if it is not a date.

    ``now`` (default: the current UTC time) anchors relative text.
    ``day_first`` settles numeric dates: True reads ``03-04-2026`` as 3 April,
    False as 4 March, None refuses it unless a field above 12 decides.
    """
    if not value:
        return None
    text = re.sub(r"\s+", " ", value).strip()
    if not text:
        return None

    match = _ISO_RE.match(text)
    if match:
        return _iso(match)

    match = _YMD_SLASH_RE.match(text)
    if match:
        return _day(int(match.group(1)), int(match.group(2)), int(match.group(3)))

    match = _NUMERIC_RE.match(text)
    if match:
        first, second, year = int(match.group(1)), int(match.group(2)), int(match.group(3))
        if first > 12:
            return _day(year, second, first)
        if second > 12:
            return _day(year, first, second)
        if day_first is None:
            return None
        return _day(year, second, first) if day_first else _day(year, first, second)

    match = _DMY_WORDS_RE.match(text)
    if match:
        month = _MONTHS.get(match.group(2).lower())
        if month:
            return _day(int(match.group(3)), month, int(match.group(1)))
        return None

    match = _MDY_WORDS_RE.match(text)
    if match:
        month = _MONTHS.get(match.group(1).lower())
        if month:
            year = int(match.group(3))
            if len(match.group(3)) == 2:
                year += 2000  # toonily prints "May 31, 23"
            return _day(year, month, int(match.group(2)))
        return None

    return _relative(text, now)


def _relative(text: str, now: datetime | None) -> str | None:
    anchor = now or datetime.now(timezone.utc)
    if anchor.tzinfo is not None:
        anchor = anchor.astimezone(timezone.utc)
    lowered = text.lower()
    if lowered in {"today", "just now", "now"}:
        return anchor.date().isoformat()
    if lowered == "yesterday":
        return (anchor - timedelta(days=1)).date().isoformat()
    match = _RELATIVE_RE.match(text)
    if not match:
        return None
    count = 1 if match.group(1).lower() in {"a", "an"} else int(match.group(1))
    unit = match.group(2).lower()
    return (anchor - count * _UNIT_DELTA[unit]).date().isoformat()
