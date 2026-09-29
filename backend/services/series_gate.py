"""One series, gated for this profile (used by every ``/ai/*`` series endpoint).

Denial is always a 404, never a 403, and happens before any AI call, cache read
or AniList call: a gated profile must not learn a hidden series exists.
"""

from __future__ import annotations

from sqlalchemy import select

from connectors.ids import fully_unquote
from core.errors import AppError
from database.models import FollowedSeries
from services.followed_series_service import FollowedSeriesService


def _not_found() -> AppError:
    return AppError("Series not found.", code="series_not_found", status_code=404)


def require_series_visible(
    library: FollowedSeriesService, source_id: str, series_key: str
) -> str:
    """Raise 404 unless this profile may see the series; returns the unquoted key.

    The source gate first (``source_not_found``). Then, when the profile follows
    the series, the follow's own resolved rating decides (it honours
    ``mature_override``); otherwise the shared cache row's rating does.
    """
    library._require_owner()
    library._browse.ensure_visible(source_id)
    key = fully_unquote(series_key)
    follow = library._db.execute(
        library._scope(
            select(FollowedSeries).where(
                FollowedSeries.source_id == source_id,
                FollowedSeries.series_key == key,
            )
        )
    ).scalar_one_or_none()
    if follow is not None:
        if library._hidden(follow):
            raise _not_found()
    elif library._cache.series_hidden(source_id, key):
        raise _not_found()
    return key
