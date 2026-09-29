# Circle API (backend/08)

Client contract for `web/22`, `mobile/22` (Cinematic) and `web/43`, `mobile/43` (Glass). One API for
both skins; no endpoint takes a skin parameter. Every `/circle/*` route needs `X-Profile-Id`
(`400 profile_required` without a profile). Errors use `{code, message, details}`. Timestamps are
naive-UTC ISO 8601. `backend/09` appends its own sections here.

## The shareable set S(member, viewer)

Implemented once, in `services/circle_service.py`; every endpoint below calls it.

1. Member = profile that is not the viewer, on an active account (any account), with `activity` on.
2. The item's timestamp is at or after the member's `share_activity_since` (nothing is retroactive).
3. The series is not in the member's hidden list (`excluded_series`).
4. `reacted` items need the member's `reactions` switch.
5. A mature series (either side resolves it mature) needs the member's `include_mature` and their own
   open 18+ gate, and the viewer's open gate. Otherwise it is absent: no placeholder, no count.

`CIRCLE_REQUIRES_VIEWER_SHARING = False`: a viewer that shares nothing still sees sharers.

## Shapes

- `ProfileRef`: `{profile_id, name, avatar_key, username}`
- `CircleSeries`: `{source_id, series_key, title, cover_url, ambient, palette, content_kind}`
  (`ambient`/`palette` null until the cover has been served once; `content_kind` is `manga` or `novel`)

## Sharing

- `GET /profiles/{id}/sharing` -> `{activity, reactions, shelves, recommendations, include_mature,
  show_presence, share_streak, excluded_series: [{source_id, series_key, title}]}`. Defaults: activity
  off, reactions/shelves/recommendations on, include_mature/show_presence/share_streak off.
- `PATCH /profiles/{id}/sharing`: partial body, same fields; `excluded_series` replaces the list (max
  500). Unknown field: `422`. Another account's profile: `404 profile_not_found`. Returns the GET shape.
  Turning `activity` on stamps `share_activity_since`; off clears it.

## `GET /circle/members?tz_offset_minutes=`

Array ordered by `last_active_at` desc (nulls last), then name:
`{...ProfileRef, shares: {activity, reactions, shelves, recommendations}, now, last_active_at, streak}`.
`now` = `{source_id, series_key, chapter_key, chapter_number, title, ambient, palette, since}` only when
`show_presence` is on, the newest progress row is within 15 minutes and it passes S; else `null`.
`last_active_at` is sent whether or not presence is on. `streak` = `{current_days, alive_today}` only
when `share_streak` is on, else `null`. Poll every 60 s while visible.

## `GET /circle/members/{profile_id}`

`404 circle_member_not_sharing` for a non-member (unknown, self, inactive account, sharing off).
`{profile, shares, now, last_active_at, streak, reading, finished, reactions, shelves}`:
`reading` = `CircleSeries + last_activity_at` (no progress); `finished` = `CircleSeries + finished_at`;
`reactions` (max 30) = `CircleSeries + chapter_key, chapter_number, reaction, created_at`;
`shelves` is `[]` until `backend/09`.

## `GET /circle/feed?cursor=&limit=&profile_id=&kind=`

`limit` 1-100 (default 50); `kind` = `reading` (started, finished_chapter, finished_series) or
`reaction`, else `422`; `profile_id` narrows to one member (a non-member gives an empty page).
`{items: [{id, kind, actor: ProfileRef, ...CircleSeries, chapter_key, chapter_number, reaction,
followed_by_viewer, created_at}], next_cursor}`. Order `(created_at, id)` desc; a malformed cursor is
`422 invalid_cursor`; `next_cursor` is null on the last page. The server sends every event (Glass
collapses runs client-side).

## `GET /circle/series?source=&series=`

`{followers: [ProfileRef], readers: [{profile, chapter_key, chapter_number, last_read_at}]}`; both
params required (`422`), `series` is percent-decoded.

## `DELETE /circle/activity` -> 204

Deletes the viewer's `circle_events`, resets `share_activity_since` if sharing is on. Idempotent; the
library and statistics are untouched.

## `GET /home`

Adds `circle` ("From the Circle", last 14 days, one item per member+series, max 20) and `circle_top`
("Most read in the circle", last 7 days, top 10 by distinct members, then events, then recency, with
`rank`). Items are `{member: ProfileRef, series: CircleSeries[, rank]}`; `state` is `ready` or `empty`.
Computed per request after the composed cache, never cached. A server with no other active profile gets neither section.

## `GET /library/annual`

Adds `circle`: `null` unless the viewer's own `activity` is on, else
`{overlaps: [{member, series, both: "finished"|"read"}], with: [ProfileRef]}` (max 5 overlaps,
finished first then the viewer's seconds; `with` lists every member in any overlap). Computed per
request, not part of the per-day cache. `shareable` never carries Circle data.

## Additive fields beyond the DESIGN shapes

`palette`, `content_kind`, `followed_by_viewer`, `last_active_at`, `streak`, `now.since`, and Annual
`circle.both`.
