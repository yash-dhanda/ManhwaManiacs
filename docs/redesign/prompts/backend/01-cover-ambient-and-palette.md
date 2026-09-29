# Backend 01: cover ambient colours and palettes

## Goal

Both skins colour the room from the art. Cinematic paints every series in its "issue colour": `ambient {duo, tint, ink}` drives duotones, the page spill and the kicker ink (cinematic §2.1.5). Glass floats its chrome over an ambient field of three blobs taken from the cover's `palette {a, l, lMax}` (glass §2.1.8). Both are computed **once per cover on the server**, in one Pillow pass inside the cover proxy, the first time a cover is served at any width, and stored in a new `cover_palette` cache table with a 30-day TTL. Every series-shaped payload then carries `ambient` and `palette` (null until the cover has been served once), read from that table in one batched query. List, search and browse endpoints never fetch or decode a cover to fill them, and the image proxy never analyses chapter pages. World recommendations (AniList items) get the same colours through a background fetch of the AniList cover, limited to 20 per minute. When this step is done both clients can paint real colour on day one of their home, library and series clusters.

## Read first

1. `docs/redesign/cinematic/DESIGN.md` §2.1.5 (the whole subsection: "When `ambient` exists", the extraction rule, the three roles, the fallbacks, the "Where each colour is computed" table, the contrast check), §15.5 (rows `ambient`, `backend/tests/test_ambient.py`), §15.6 (performance guards), §14.2 (contrast).
2. `docs/redesign/glass/DESIGN.md` §2.1.8 (the field, its sources, and **Extraction** items 1, 2 and 4), §2.1.7 (why `l` and `lMax` both exist), §15.5 (row `palette: {a: [hex, hex, hex], l, lMax}`), §15.8 (the `dimFor(lMax = 1.0) == 0.64` check that consumes `lMax`), §15.10 G6 (cover palettes stay on the backend; page samples are the client's, not this step).
3. `docs/redesign/stack-decision.md` §2.6 item 2 (per-cover palettes are server-side logic that must agree across clients).
4. `docs/redesign/inventory/00-decisions.md` (item 4 of the new features: reader chrome tinted by dynamic colour; this step is only the cover half).
5. `docs/redesign/inventory/capabilities.md` §1, §7 (Library), §16.3 and §16.4 (series detail and the image proxy), §9 (world recommendations).
6. `docs/redesign/00-baseline.md`, and `docs/redesign/proof/backend-00/pytest-baseline.txt` (the backend pass count you must keep).
7. Code: `backend/services/image_resize.py` (the module docstring, `_DECODABLE_FORMATS`, `_MAX_SOURCE_PIXELS`, `_flatten_to_rgb`, `COVER_WIDTHS`), `backend/routes/sources.py` (`get_source_series_cover`, `list_source_series`, `federated_search`, `get_source_series`, `_release_pooled_connection`), `backend/services/source_cache_service.py` (`get_series_cover`, `CACHE_RETENTION_RULES`, `sweep_cache_retention`), `backend/services/browse_service.py` (`_serialize_series`, the federated search item builder), `backend/services/followed_series_service.py` (`serialize`, `list_series`, `get_detail`, `continue_reading`, `search`), `backend/services/progress_service.py` (`reading_history`, `_with_titles`), `backend/services/bookmark_service.py`, `backend/services/update_service.py` (`serialize_notification`), `backend/services/suggestion_service.py` (the suggest item builder), `backend/services/world_recs.py` (`_items`, `WorldCatalog._read/_write`, `USER_AGENT`, `HTTP_TIMEOUT`), `backend/core/cache_tables.py`, `backend/database/models.py` (`SourceCoverCache`, `WorldCatalogCache`), `backend/tests/test_cover_resize.py`, `backend/tests/test_audit_caches_cover_negative.py`, `backend/tests/test_world_recs.py`, `backend/tests/_fakes.py`, `backend/tests/conftest.py`, `backend/scripts/README-dev-stack.md`.

## Track rule (every `backend/*` prompt)

- Work only in `backend/` (never `backend/connectors/`) plus `docs/redesign/proof/backend-01/`.
- Stage only the paths you changed, by name; never `git add -A`.
- Alembic revisions continue after `0017_world_catalog_cache`; this step's revision is `0019_cover_palette`. Ids stay at or under 32 characters.
- Every endpoint is profile-scoped and applies the 18+ gate when **serving**, never when storing. `cover_palette` is a global cache like `source_cover_cache`: no user, profile or gate in its key.
- Additive only: payloads gain `ambient` and `palette`; nothing is renamed or removed.
- Tests: `backend/.venv/bin/python -m pytest -q --no-header` from `backend/`.

## Preconditions

1. Branch is `feat/vps-slim-source-native`.
2. `backend/.venv/bin/python` exists and `backend/alembic/versions/0018_profile_redesign_cols.py` exists (backend/00 has landed). The newest file in `backend/alembic/versions/` must be `0018_profile_redesign_cols.py`; if a later one exists, stop and report.
3. `free -m` shows 1024 MB or more available.

## Skills

- `superpowers:writing-plans` first; plan to `docs/redesign/proof/backend-01/plan.md`.
- `superpowers:executing-plans` to run it inline.
- `superpowers:test-driven-development`: `test_ambient.py` comes before the extractor.
- `superpowers:verification-before-completion` before reporting.
- Not `impeccable`, `taste-skill:taste-skill` or `frontend-design`: no UI in this step.

## Scope, item by item

### A. The extractor: `backend/services/cover_colour.py` (new, one module)

Pure functions first (bytes in, dicts out, no I/O), then the small DB helpers, then the AniList worker, all in this one file.

**Decode** (`_decode(data) -> PIL.Image | None`): open with Pillow from `io.BytesIO`; refuse any format outside `image_resize._DECODABLE_FORMATS` and any image over `image_resize._MAX_SOURCE_PIXELS` (import both; they are the proxy's own guards against hostile upstream bytes); for JPEG call `img.draft("RGB", (192, 288))` before loading so a 1.5 MB original decodes cheaply; take frame 0; flatten alpha with `image_resize._flatten_to_rgb`; convert to `RGB`; resize to width 96 with `Image.Resampling.BILINEAR`, keeping the aspect ratio (`height = max(1, round(96 * h / w))`), unless it is already 96 px wide or narrower. This is "the `w=96` cover" of glass §2.1.8. Return `None` on any exception.

**Cinematic ambient** (`ambient_from(img) -> {"duo", "tint", "ink"}`), cinematic §2.1.5, stdlib `colorsys` (HLS, all channels 0–1):

1. `img.resize((48, 48), Image.Resampling.BILINEAR).quantize(colors=8, method=Image.Quantize.MEDIANCUT)`; swatches and their counts from `getcolors()` and `getpalette()`.
2. Per swatch compute `(h, l, s) = colorsys.rgb_to_hls(r/255, g/255, b/255)`. Ignore swatches with `l < 0.08` or `l > 0.94` (paper and ink). Also ignore swatches with `s < 0.08`: they carry no hue. This makes "greyscale cover" decidable, which §2.1.5 leaves undefined; the 0.08 threshold is the page picker's greyscale threshold from the same section. A cover is **greyscale** when no swatch survives.
3. Score each survivor `count × (0.35 + s)`; the highest score gives the seed hue `h` and saturation `s` (ties: the more populous swatch).
4. Derive, then convert with `colorsys.hls_to_rgb` and format as uppercase `#RRGGBB`:

| Role | Rule (cinematic §2.1.5) |
|---|---|
| `duo` | `h`, L 0.62, S = `clamp(s, 0.45, 0.90)` |
| `tint` | `h`, L 0.06, S = `min(s, 0.35)` |
| `ink` | `h`, L 0.78, S = `clamp(s, 0.35, 0.70)`; raise L by 0.03 until contrast on `#000000` is at least 7:1, capping L at 1.0 |

5. Greyscale cover, undecodable art or missing cover: the fallbacks `duo #B8B2A4`, `tint #0E0D0B`, `ink #F3F0E8` (cinematic §2.1.5). An undecodable cover stores nothing (see C); a decodable greyscale cover stores the fallbacks.

Contrast is WCAG 2.x: linearise each sRGB channel `c` as `c / 12.92` when `c <= 0.04045`, else `((c + 0.055) / 1.055) ** 2.4`; relative luminance `Y = 0.2126 R + 0.7152 G + 0.0722 B`; contrast on black is `(Y + 0.05) / 0.05`. Put `relative_luminance(hex)` and `contrast(a, b)` in the module; the test imports them. Expose `derive_ambient(h: float, s: float) -> dict` (steps 4 only) so the 1,440-case loop can drive it without images.

**Glass palette** (`palette_from(img) -> {"a": [...], "l": float, "lMax": float}`), glass §2.1.8 Extraction item 1:

1. `img.quantize(colors=6, method=Image.Quantize.MEDIANCUT)` on the 96-wide image; population per colour from `getcolors()`.
2. Convert each colour to OKLCH (Björn Ottosson's OKLab, sRGB D65). Linearise as above, then
   `l = 0.4122214708 r + 0.5363325363 g + 0.0514459929 b`,
   `m = 0.2119034982 r + 0.6806995451 g + 0.1073969566 b`,
   `s = 0.0883024619 r + 0.2817188376 g + 0.6299787005 b`,
   take cube roots `l_ m_ s_`, then
   `L = 0.2104542553 l_ + 0.7936177850 m_ − 0.0040720468 s_`,
   `A = 1.9779984951 l_ − 2.4285922050 m_ + 0.4505937099 s_`,
   `B = 0.0259040371 l_ + 0.7827717662 m_ − 0.8086757660 s_`,
   `C = sqrt(A² + B²)`.
3. Discard colours with `L < 0.12`, `L > 0.94` or `C < 0.025`. If all six would go, keep the two most populous instead.
4. Rank the rest by `population × (0.5 + C)`; `a` is the top three as uppercase `#RRGGBB` (one to three entries; glass §2.1.8 item 4 says the client reuses the first at 60 % size when there are fewer than three).
5. `l` is the mean relative luminance over every pixel of the 96-wide image; `lMax` is its 95th percentile (nearest rank on the sorted per-pixel luminances). Both rounded to 3 decimals.

`extract(data: bytes) -> tuple[dict, dict] | None` runs `_decode` once and returns `(ambient, palette)`, or `None` when the bytes do not decode.

### B. The table: migration `0019_cover_palette`

`backend/alembic/versions/0019_cover_palette.py`, `down_revision = "0018_profile_redesign_cols"`, docstring in the house style ("a cache table in every sense … safe to lose").

```python
op.create_table(
    "cover_palette",
    sa.Column("source_id", sa.String(length=64), primary_key=True),
    sa.Column("series_key", sa.String(length=512), primary_key=True),
    sa.Column("ambient", sa.Text(), nullable=False),   # JSON {"duo","tint","ink"}
    sa.Column("palette", sa.Text(), nullable=False),   # JSON {"a","l","lMax"}
    sa.Column("computed_at", sa.DateTime(), nullable=False),
)
op.create_index("ix_cover_palette_computed_at", "cover_palette", ["computed_at"])
```

Model `CoverPalette` in `backend/database/models.py` beside `SourceCoverCache`, with a docstring saying it is global like `source_cover_cache` (no user, profile or gate in the key; the gate is applied when a payload is served). `series_key` is stored `fully_unquote`d, the same normalisation the cover cache keys use.

- Add `"cover_palette"` to `CACHE_TABLES` in `backend/core/cache_tables.py` (backups drop it; it rebuilds on the next cover serve).
- Add `CacheRetentionRule(CoverPalette, "computed_at", 30)` to `CACHE_RETENTION_RULES` in `source_cache_service.py`, so the daily sweep and the startup sweep delete rows older than 30 days and rows of sources this build no longer defines. Update the comment above the tuple that says "four connector caches".
- `backend/tests/test_migrations_alembic.py`: `_HEAD = "0019_cover_palette"`, append the file to `_REVISIONS`, add `"cover_palette"` to `_EXPECTED_TABLES`.

### C. Computing in the cover proxy only

`ensure_cover_colours(db, source_id, series_key, data) -> None` in `cover_colour.py`: one primary-key `db.get(CoverPalette, (source_id, fully_unquote(series_key)))`; when a row exists with `computed_at` within 30 days, return. Otherwise `extract(data)`; if it returns `None`, return without writing (an undecodable cover is retried on a later serve, which costs one failed `Image.open`); else upsert the row with `computed_at = utcnow()` and commit. The whole body is wrapped so that any exception is logged at `warning` with `exc_info`, rolled back, and swallowed: a colour failure never breaks a cover.

Call it from `get_source_series_cover` in `backend/routes/sources.py` on **both** branches, after the bytes are known and before `_conditional_image_response`: the `w is None` branch (the original bytes) and the `?w=` branch (whatever bytes are being served: the downscale, a cached downscale, or the original from a negative entry). "The first time a cover URL is served at any width" is therefore literal: any serve with no fresh row computes it; every later serve costs one primary-key read.

The page-image route `/{source_id}/pages/{page_id}/image` and `image_resize.resize_page` are **not** touched: the image proxy never analyses chapter pages (page tint is the client's, cinematic §15.10 S1, glass §15.10 G6).

### D. Serving: `ambient` and `palette` on every series payload

`attach_cover_colours(db, items, key=lambda item: (item["source_id"], item["series_key"])) -> list` in `cover_colour.py`: collects the keys (each `series_key` passed through `fully_unquote`, the normalisation the stored rows use), reads `cover_palette` rows with `computed_at` within 30 days in chunks of 400 pairs (`tuple_(source_id, series_key).in_(chunk)`), and sets `item["ambient"]` and `item["palette"]` (parsed JSON) on every item, `None` for a miss. It never fetches, decodes or enqueues anything. It returns `items` so a call can wrap a return value.

Wire it into these payloads (null until the cover has been served once; cinematic §2.1.5 "Where each colour is computed", first row; glass §15.5 `palette` row). The key function for each is named in the right column:

| Endpoint | Where to attach | Key |
|---|---|---|
| `GET /sources/{id}/series` (browse page and source search) | `list_source_series`, on the listing's items after the service returns | `(source_id, item["id"])` |
| `GET /sources/search` (federated) | `federated_search`, on the result items (after the `await`, with the route's `db`) | `(item["source"], item["series_id"])` |
| `GET /sources/{id}/series/{key}` (detail) | `get_source_series`, on the one payload | `(item["source_id"], item["id"])` |
| `GET /library/series`, `GET /library/series/{id}`, `GET /library/search`, `POST /library/follow`, `PATCH /library/series/{id}` | `FollowedSeriesService` list, detail, search and single-row returns (attach in the route or at the end of the service method; one query per response) | `(source_id, series_key)` |
| `GET /library/continue-reading` | `continue_reading` rows | `(source_id, series_key)` |
| `GET /reader/history`, `GET /reader/bookmarks`, `GET /updates/notifications` | the list routes (cinematic §2.1.5 lists history, bookmark and notification payloads too) | `(source_id, series_key)` |
| `POST /library/suggest` | the suggest items | `(item["source"], item["series_id"])` |

Where a route calls `_release_pooled_connection(db)` before an upstream fetch, attaching afterwards simply checks a connection out again; that is fine (one indexed read).

A mature series can only appear in these payloads when the caller's gate already allows the row itself, so the colours inherit the gate the row was served under; no colour is ever served for a row the caller cannot see.

### E. WorldItem colours: a background AniList-cover fetch, 20 per minute

WorldItems (`GET /library/world/recommendations`, `POST /library/world/suggest`, both built by `WorldRecs._items`) have no source cover, so their colours come from the AniList cover through the same `extract`. They are stored in the existing `world_catalog_cache` table (already a cache table, already pruned after 30 days by `WorldCatalog._write`) under the key `al:colour:{anilist_id}` with the JSON payload `{"ambient": {...}, "palette": {...}}`. Using that table keeps AniList ids out of `cover_palette`, whose orphan rule would delete any `source_id` that is not a connector.

- In `WorldRecs._items`, after the items are built, read the `al:colour:*` keys for the visible items in one query (30-day freshness), set `ambient` and `palette` on each item (null on a miss), and enqueue the misses whose `cover_url` host is exactly `s4.anilist.co` over `https`. Items hidden by the gate are never built, so they are never enqueued or served.
- The worker in `cover_colour.py`: a module-level `queue.Queue(maxsize=200)` plus a `set` of pending ids (duplicates are dropped; a full queue drops the id, which a later visit re-enqueues); one daemon thread named `anilist-colour`, started lazily on the first enqueue; a sliding window limiter of **20 fetch starts per 60 s** (a `collections.deque` of `time.monotonic()` start times; before a fetch, if 20 starts lie within the last 60 s, sleep until the oldest is 60 s old). Each fetch is `httpx.get(url, timeout=world_recs.HTTP_TIMEOUT, follow_redirects=False, headers={"User-Agent": world_recs.USER_AGENT})` streamed and aborted past 5 MiB; a non-200 answer or an oversize body is skipped. The worker writes through its own `SessionLocal()` session, closed after every item.
- The drain loop is a plain function `drain_anilist_colours(db, *, fetch, clock, sleep, max_items)` that the thread calls with the real `httpx` fetch, `time.monotonic` and `time.sleep`. Tests call it directly with fakes. A module flag `ANILIST_WORKER_ENABLED = True` gates the thread start, and `reset_anilist_colour_worker()` empties the queue, the pending set and the limiter.
- `backend/tests/conftest.py` gains one autouse fixture that sets `ANILIST_WORKER_ENABLED = False` and calls `reset_anilist_colour_worker()` around every test, beside the existing reset fixtures, so no test ever starts a thread or reaches the network.

### F. Tests: `backend/tests/test_ambient.py` (new)

1. **Ink contrast over 360 hues** (cinematic §2.1.5 contrast check): for hue 0–359 in 1° steps × saturation {0.08, 0.35, 0.60, 0.90} (1,440 cases), `contrast(derive_ambient(h / 360, s)["ink"], "#000000") >= 7.0`. It must run in well under a second.
2. **Role rules**: for a solid saturated red cover (a 200 × 300 PNG of `#D0202A`), `duo` equals `hls_to_rgb(h_seed, 0.62, clamp(s_seed, 0.45, 0.90))` formatted, and `tint` recomputed from its hex has L within 0.005 of 0.06 and S within 0.03 of `min(s_seed, 0.35)` (hex rounding moves a near-black colour's HLS saturation by up to about 0.02; recompute via `colorsys` in the test).
3. **Greyscale rules**: a vertical grey gradient PNG, an all-`#000000` PNG and an all-`#FFFFFF` PNG each give exactly `{"duo": "#B8B2A4", "tint": "#0E0D0B", "ink": "#F3F0E8"}`; the grey gradient's Glass palette keeps the two most populous greys (`len(a) == 2`); junk bytes and an HTML body make `extract` return `None`.
4. **Glass palette**: a PNG that is 60 % `#1E5BFF` and 40 % `#FF8A3D` gives `a[0]` blue-ish and `a[1]` orange-ish (assert OKLab hue sectors, not exact hexes), `0 <= l <= lMax <= 1`, and a 96 × 144 all-black PNG with one 48 × 48 white square (16.7 % of the pixels, so above the 5 % the 95th percentile needs) gives `lMax == 1.0` and `0.1 <= l <= 0.2`, the "dark cover with one white patch" case glass §15.8 feeds to `dimFor`.
5. **Cover proxy computes once**: with the fake-connector pattern of `test_audit_caches_cover_negative.py`, the first `GET .../cover?w=240` writes one `cover_palette` row; a second serve does not call `extract` (monkeypatch it to count calls); a `GET .../cover` without `w` also computes when no row exists.
6. **TTL expiry**: a row with `computed_at` 31 days ago is served as `ambient: null` and `palette: null` on `GET /library/series`, the next cover serve recomputes it and refreshes `computed_at`, and `sweep_cache_retention` deletes a 31-day-old row.
7. **Lists never decode**: monkeypatch `cover_colour.extract` and `cover_colour._decode` to raise, then call `GET /library/series`, `GET /library/continue-reading`, `GET /sources/{id}/series` and `GET /sources/search`; all answer 200 with the stored colours or null.
8. **No page analysis**: monkeypatch `cover_colour.extract` to raise and fetch a page image through `/{source_id}/pages/{page_id}/image`; it answers as before.
9. **Profile isolation and the gate**: a row for a mature series exists; a profile with the gate closed gets no item for that series in `GET /library/series` (and therefore no colours), a gate-open profile gets the item with its `ambient`.
10. **WorldItem gating on serve**: seed `world_catalog_cache` with an AniList answer containing one `isAdult: true` media and one safe media, plus `al:colour:{id}` rows for both. A gate-closed profile's `GET /library/world/recommendations` has no adult item and no adult colours; a gate-open profile sees the adult item with its `ambient` and `palette`.
11. **20 per minute**: enqueue 25 ids, run `drain_anilist_colours` with a fake clock and a fake sleep; the fake fetch is called 20 times before the fake clock passes 60 s, and 25 times in total; a URL on any host other than `s4.anilist.co` is never fetched.

### G. Proof

After `backend/scripts/dev_stack.sh restart` (the migration runs on boot):

1. `backend/scripts/dev_stack.sh api GET /library/series > docs/redesign/proof/backend-01/library-before.json` (colours null if the dev stack never served these covers).
2. Serve each seeded follow's cover once at `w=96` through the dev stack with `curl -s -b /srv/manhwamaniacs/dev/data/cookies.txt -H "X-Profile-Id: <Riya id>" -o /tmp/<n>.webp "http://127.0.0.1:8010/sources/<source>/series/<quoted key>/cover?w=96"` (use your session scratchpad directory instead of `/tmp`).
3. `backend/scripts/dev_stack.sh api GET /library/series > docs/redesign/proof/backend-01/library-after.json` (colours filled).
4. `docs/redesign/proof/backend-01/swatches.png`: with Pillow from the venv, one row per follow: the 96-px cover, then 48 × 48 swatches for `duo`, `tint`, `ink`, `a[0]`, `a[1]`, `a[2]`, each with its hex in 11 px text under it, on `#000000`. This is the visual check that the colours belong to the art.
5. `docs/redesign/proof/backend-01/timing.txt`: median `extract()` time over 20 runs for one 720 × 1080 WebP (the dev stack's `w=720` cover) and one full-resolution original. Target: under 40 ms and under 150 ms respectively on this box; record the numbers either way.
6. `docs/redesign/proof/backend-01/pytest-after.txt`: the last 25 lines of the full suite.

## File layout

Created: `backend/services/cover_colour.py`, `backend/alembic/versions/0019_cover_palette.py`, `backend/tests/test_ambient.py`, `docs/redesign/proof/backend-01/*`.

Changed: `backend/database/models.py` (`CoverPalette`), `backend/core/cache_tables.py`, `backend/services/source_cache_service.py` (retention rule only), `backend/routes/sources.py`, `backend/routes/library.py`, `backend/routes/reader.py`, `backend/routes/updates.py`, `backend/services/followed_series_service.py` (only if attaching inside the service reads better than in the route), `backend/services/world_recs.py` (`_items`), `backend/tests/conftest.py` (one autouse fixture), `backend/tests/test_migrations_alembic.py`.

## Acceptance criteria

- [ ] `extract()` implements cinematic §2.1.5 (48 × 48 bilinear, 8-colour median cut, HLS, L filter 0.08–0.94, score `count × (0.35 + S)`, the three role rules, the fallbacks) and glass §2.1.8 item 1 (6-colour median cut on the 96-wide cover, OKLCH discard `L < 0.12`, `L > 0.94`, `C < 0.025` with the keep-two rule, rank `population × (0.5 + C)`, top three, `l` mean and `lMax` 95th percentile).
- [ ] `ambient.ink` is at least 7:1 on `#000000` for all 1,440 hue × saturation cases.
- [ ] Greyscale covers get `#B8B2A4` / `#0E0D0B` / `#F3F0E8`; undecodable bytes store nothing and never break the cover response.
- [ ] Colours are computed only inside `get_source_series_cover`, on first serve at any width, and stored in `cover_palette` with a 30-day TTL; the page-image route performs no analysis.
- [ ] `ambient` and `palette` appear (null until computed) on every payload in section D's table and on WorldItems; no list, search or browse request decodes or fetches a cover.
- [ ] WorldItem colours come from a background AniList-cover fetch through the same extractor, at most 20 fetch starts per 60 s, only from `https://s4.anilist.co`, stored as `al:colour:{id}`.
- [ ] The 18+ gate holds on serve: a gated profile never receives a mature row, so never its colours; `cover_palette` holds no user, profile or gate column.
- [ ] `cover_palette` is in `CACHE_TABLES` and in `CACHE_RETENTION_RULES`; revision `0019_cover_palette` is the head and matches the models.
- [ ] Per-skin difference: Cinematic reads `ambient` (duotones, page spill, issue ink); Glass reads `palette` (the ambient field blobs, rim tints, `l` for the field term and `lMax` for surfaces over the cover, glass §2.1.7). Both ride on the same payloads; neither skin computes a cover colour on the device when the field is present.
- [ ] No UI changes: `git show --name-only --format= <hash> -- frontend mobile` for each of your own commits (never a branch or range diff: parallel sessions commit on the same branch) is empty, so reduced-motion, keyboard access and 44 pt hit targets are unaffected by construction.
- [ ] The full backend suite passes with the backend-00 pass count plus the new tests; no test that passed before fails.

## Verification

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs/backend
free -m
.venv/bin/python -m pytest -q --no-header tests/test_ambient.py tests/test_cover_resize.py tests/test_audit_caches_cover_negative.py tests/test_world_recs.py tests/test_migrations_alembic.py tests/test_audit_backup_cache_tables.py
free -m
timeout 1800 .venv/bin/python -m pytest -q --no-header
```

Web and mobile suites are not run: `git show --name-only --format= <hash> -- frontend mobile` for each of your own commits (never a branch or range diff: parallel sessions commit on the same branch) must print nothing. Their baseline commands, for the record: `npm run lint` and `npm run build` in `frontend/`; `/srv/manhwamaniacs/dev/flutter/bin/flutter analyze` and `/srv/manhwamaniacs/dev/flutter/bin/flutter test` in `mobile/`.

## RAM guard

Check `free -m` before each pytest run and before `dev_stack.sh restart`; stop and report if `available` is under 1024 MB. One heavy command at a time; never `next build` in this step.

## Git

- Branch `feat/vps-slim-source-native`; commit small and often and push after each working step (`git push origin feat/vps-slim-source-native:master`).
- Suggested commits: (1) `test(backend): ambient and palette extraction cases`, (2) `feat(backend): cover_palette cache and the Pillow colour pass in the cover proxy`, (3) `feat(backend): ambient and palette on series payloads`, (4) `feat(backend): WorldItem colours from a rate-limited AniList cover fetch`, (5) `docs(redesign): backend-01 proof`.
- Stage explicit paths only. No Claude or AI attribution anywhere (no `Co-Authored-By`, no "generated with" line). Never commit secrets, `.claude/`, `backend/.venv/` or dev data.

## Never

- Never edit `backend/connectors/`.
- Never touch production containers, `/srv/manhwamaniacs/app` or `/srv/manhwamaniacs/data`.
- Never add colour analysis to the page-image path.

## Report back

1. Done items A to G with commit SHAs.
2. Backend test counts before and after (passed/failed) and the new test names.
3. Proof path `docs/redesign/proof/backend-01/` (JSON before/after, `swatches.png`, `timing.txt`, pytest tail).
4. The measured `extract()` medians.
5. Open issues, and a note for backend/04: `GET /home` items must call `attach_cover_colours` too (glass §15.5 lists `palette` on `/home` items).

Next prompt file in the series: `docs/redesign/prompts/shared/04-brand-cinematic-and-platform-icons.md`. Next file in the backend track: `docs/redesign/prompts/backend/02-library-series-ocr-extensions.md`.
