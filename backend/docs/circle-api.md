# Circle API (backend/08)

Client contract for `web/22`, `mobile/22` (Cinematic) and `web/43`, `mobile/43` (Glass). One API for
both skins; no endpoint takes a skin parameter. Every `/circle/*` route needs `X-Profile-Id`
(`400 profile_required` without a profile). Errors use `{code, message, details}`. Timestamps are
naive-UTC ISO 8601. The `backend/09` sections (reactions, letters, shared shelves) follow.

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
`shelves` = that member's shelves effectively shared with the viewer, as `SharedShelf` objects.

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

---

# backend/09: reactions, letters and shared shelves

Every visibility decision about another profile calls `CircleService` (S, `series_mature`, the viewer gate).
The 18+ gate applies when serving, never when storing. Everything below is additive. Validation failures are
`422`. `X-Profile-Id` is required on every call.

## Reactions

One reaction per profile per chapter. **Seven kinds**, the stored values shared by both skins:
`loved`, `shook`, `laughed`, `tears`, `chefs_kiss`, `hype`, `wrecked` (any other value is `422`). Labels are the
clients' (Cinematic shows five stamps plus `HYPE`/`WRECKED`; Glass shows six and renders `laughed` as "Laughed").

- `POST /circle/reactions` `{source_id, series_key, chapter_key, kind}` -> `200 ChapterReactions`. No row: insert;
  same kind: no change; another kind: moved in place. `chapter_number` comes from the viewer's own progress row
  (else null); `shared = activity AND reactions` of the viewer **at that moment**, so a reaction made while
  "Show my reactions" was off never surfaces later. The `reacted` Circle event is replaced (deleted, and re-written
  when `shared`).
- `DELETE /circle/reactions` body `{source_id, series_key, chapter_key}` -> `204`, idempotent (removes the event too).
- `GET /circle/reactions?source=&series=` -> `{chapters: [ChapterReactions]}`, only chapters with a visible reaction,
  `chapter_number` desc (nulls last) then `chapter_key`. `series` is percent-decoded.

`ChapterReactions`: `{chapter_key, chapter_number, counts: {loved, shook, laughed, tears, chefs_kiss, hype, wrecked},
total, by: [{profile_id, name, avatar_key, username, kind, created_at}], mine, sealed}`. `counts` always has all
seven keys. Visible = the viewer's own (always) plus another profile's reaction when it is a member (S), `shared`,
its `reactions` switch is on, it is at or after `share_activity_since`, the series is not hidden and the both-sided
18+ rule passes. `counts`, `total` and `by` are computed after filtering.

### The spoiler guard, server half

The server always returns the full reaction. `sealed` is true when the viewer has **not completed** the chapter (no
`is_completed` progress row with the same `chapter_key`, or the same non-null `chapter_number`); a half-read chapter
is sealed. It is computed per request (no write on unseal): the next read after `POST /reader/progress` says
`sealed: false`. It appears on `ChapterReactions`, on `GET /circle/feed` items of kind `reacted` (null on other
kinds) and on the `reactions` items of `GET /circle/members/{profile_id}`. Clients never guard the viewer's own
reaction (`mine`). The unseal animation (160 ms, 40 ms apart) is the clients'.

## Letters

- `GET /circle/members?source_id=&series_key=`: with both, every member gains `can_receive: bool`; with neither, no
  field; with one, `422`. A recipient can receive when it is a member, its `recommendations` switch is on and, for a
  mature series (either side resolves mature), its own gate is open and its effective `include_mature` is on. No
  reason is ever returned. A sender whose own gate is closed gets `404 series_not_found` for a mature series.
- `POST /circle/letters` `{to_profile_ids: [1-10 unique], source_id, series_key, note?}` -> `201 SentLetter`. `note`
  is stripped, at most 140 characters (`422` above), empty becomes null. Any recipient that cannot receive (itself, an
  unknown id, a non-member) -> `409 recipient_unavailable` with `details: {profile_ids: [...]}` and **nothing is
  written**. One row per recipient sharing one `sent_group`; title and cover are snapshotted from the sender's follow,
  else the source cache, else the key. The sender need not share activity.
- `GET /circle/letters?box=inbox` (default) -> array of `Letter`: `{id (int), from: ProfileRef, ...CircleSeries, note,
  state, created_at}`, states `new`, `read`, `kept`, never `dismissed`, newest first. A letter whose series is mature
  for the viewer is **absent** while the viewer's gate is closed, as is a letter from an inactive account. Every
  "new" count (tab badge, `2 NEW` folio, sidebar, Glass bloom dot) counts `state == "new"` rows of this list.
- `GET /circle/letters?box=sent` -> array of `SentLetter`, one per send: `{id (the sent_group string), to: [ProfileRef +
  state], ...CircleSeries, note, state, created_at}`. A recipient's `state` is `new` or `read` (`kept` and
  `dismissed` read as `read`; never whether it was added). The row's `state` is `new` when any recipient is `new`.
  `box` other than `inbox` or `sent` is `422`.
- `PATCH /circle/letters/{id}` `{state: read|kept|dismissed}` -> `200 Letter`. Recipient only; another profile's
  letter, an unknown id or a letter absent under the gate is `404 not_found`. Cinematic's `Keep` writes `kept`;
  Glass writes `read` and `dismissed` only.

`GET /home` gains `sent_to_you` (inbox letters in `new` or `kept`, newest first, max 10, items are `Letter`,
`note` = the newest item's note, only for a household with other profiles) and the `letter` candidate of `also[]`
(`{kind: "letter", source_id, series_key, title, headline: "{name} recommends {title}", deck, ambient}`, priority
`new_chapters`, `because`, `letter`, `almost_there`). Both are computed per request, never cached.

## Shared shelves

Roles: `owner`, `can_add`, `view_only`. A member needs a `collection_shares` row and an effective membership: the
owner's `activity` on and account active, the member's `activity` and `shelves` on. Otherwise `404 not_found`.

| Call | owner | `can_add` | `view_only` |
|---|---|---|---|
| `GET /library/collections/{id}` | yes | yes | yes |
| `POST /library/collections/{id}/series` | yes | yes | 403 `forbidden` |
| `DELETE /library/collections/{id}/series` | any row | rows it added, else 403 | 403 |
| `PATCH`, `DELETE`, `PUT .../series/order`, `POST .../share` | yes | 403 | 403 |
| `DELETE .../share/me` | 403 | yes | yes |

- `POST /library/collections/{id}/share` `{profile_ids: [0-10 unique], mode: can_add|view_only}` -> `200` owner row.
  Empty ids unshare. Refusals (in order, nothing written): `409 smart_shelf_not_shareable`, `409 sharing_off`,
  `409 member_unavailable` with `details: {profile_ids}` (the owner, unknown, inactive, or `activity`/`shelves` off).
  Series added by a removed member stay.
- `DELETE /library/collections/{id}/share/{profile_ref}` -> `204`; `profile_ref` is `me` or an integer id (else `422`).
  The owner removes a member (idempotent); a member may pass only `me` or its own id and leaves the shelf.
- `PUT .../series/order` (backend/02) still answers `422 order_mismatch` unless the body equals the visible
  membership; on a shared shelf that is the owner's view under the shared-shelf 18+ rule.
- `GET /library/collections`: the bare array of the viewer's own shelves, each with `role: "owner"` and
  `shared: {owner_profile_id, mode, member_profile_ids, members: [ProfileRef]} | null`. **Deliberate deviation:**
  `shared_with_me` cannot be added to a bare array without breaking today's clients, so
  `GET /library/collections?include_shared=true` returns `{collections: [...], shared_with_me: [SharedShelf]}`
  (`X-Total-Count` = length of `collections`).
- `SharedShelf`: the owner-row fields (`id`, `name`, `description`, `series_count`, `preview_covers`,
  `preview_ambient_duo`, `rules` always null, `created_at`) over the rows visible to the viewer, plus `owner`
  (ProfileRef), `role` and `shared`. Ordered by owner name then shelf name.
- `GET /library/collections/{id}` gains `role`, `shared`, `owner` and, on every series row, `title`, `cover_url`,
  `ambient`, `palette`, `added_by_profile_id`, `added_by` (ProfileRef or null). Rows render from the shelf's own
  snapshot, never from the viewer's library. `POST .../series` snapshots title and cover from the adder.
- 18+ on a shared shelf (owner and members alike): a row is visible when it is not mature by
  `series_mature(adder or owner, viewer)` or the viewer's gate is open; hidden rows are absent from `series`,
  `series_count` and the previews. An unshared shelf keeps the original gate path.
- `GET /circle/members/{profile_id}` `shelves` = that member's shelves effectively shared with the viewer.

**Profile deletion.** `fk_collection_series_added_by` cascades: deleting a profile removes the series it added to
other profiles' shelves, its shares, reactions and every letter to or from it, so a reused profile id can never
inherit another profile's add rights.

## Errors added

`recipient_unavailable` (409), `series_not_found` (404), `smart_shelf_not_shareable` (409), `sharing_off` (409),
`member_unavailable` (409), `forbidden` (403), `not_found` (404), `order_mismatch` (422), `validation_error` (422).
