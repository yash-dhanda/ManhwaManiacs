# Reader reports API (backend/06)

Clients do the image work (S1 tint, S11 panel detection); the server only remembers
what they report and serves it in manifests. The server never decodes an image.
All of it is additive.

## Page identity

`page_etag = sha256(page_url.encode("utf-8")).hexdigest()[:32]`, where `page_url` is the
manifest's `pages[].url` (e.g. `/sources/mangadex/pages/<page_key>/image`). The image
proxy's own ETag hashes served bytes (changes with `?w=` and `Accept`) and the server
stores no bytes, so it cannot be known without decoding. The URL embeds the upstream
page key, which changes when a source re-uploads a page, so an old tint or panel list is
never attached to a new image. Helper: `services.page_annotations.page_etag`.

Storage: table `reader_page_annotations` (migration `0024_reader_page_annotations`, follows
`0023_ai_taste_feedback`), a shared cache listed in `CACHE_TABLES`. Reports from one
profile are served to every profile that may see the chapter (the 18+ gate applies when
serving).

## POST /reader/page-tints

Needs `X-Profile-Id` (400 `profile_required`, 404 `profile_not_found`). Answers `204`.

```json
{"source_id": "mangadex", "series_key": "...", "chapter_key": "...",
 "tints": [{"page": 1, "hex": "#3A5F8C"}, {"page": 2, "hex": null}]}
```

`tints` 1..500; `hex` is `#RRGGBB` (stored upper case) or `null` (greyscale page,
ignored, never stored); anything else is 422. Pages are resolved through the gated
manifest path: a hidden or unknown source/chapter is 404 and nothing is stored; any other
upstream error is a silent 204. Pages not in the chapter are ignored.

## POST /reader/panels

Same rules. Body `pages`: 1..500 of `{"page": n, "panels": [{"x","y","w","h"}]}`, page
fractions in reading order, `0<=x,y<=1`, `0<w,h<=1`, `x+w<=1.0001`, `y+h<=1.0001`, at most
64 per page. `[]` is valid ("analysed, no panels") and is served back as `[]`.

## Manifests (single and bulk)

`pages[i].tint` (`"#RRGGBB"`) and `pages[i].panels` (list, maybe empty) appear only when
stored. Top level `panels_ready` is true when every page has stored `panels`. One
annotations query per manifest, one per bulk window. Bulk and single stay equal per chapter.

## GET /reader/panels?source=&series=&chapter=

Stored rows only, no upstream call. 404 for a gated source; an 18+ series on a general
source answers the empty result.

```json
{"source_id": "...", "series_key": "...", "chapter_key": "...", "panels_ready": true,
 "pages": [{"page": 1, "panels": [{"x": 0, "y": 0, "w": 1, "h": 0.31}]}]}
```

`panels_ready` is true when the stored page count equals the reported `page_count`.
No tints here.

## GET /novels/audio/series additions

`chapters[].rendered_at` (ISO UTC, the audio file mtime) and top-level `cast_changed_at`
(`novel_series_cast_state.updated_at`, stamped only by `POST /novels/cast`,
`/novels/cast/alias`, `/novels/narrator`; `null` if never changed). The endpoint is now
gated like `GET /reader/progress/series` (404 for a hidden source; an 18+ series on a
general source answers `chapters: []`, `narratable: []`, `cast_changed_at: null`).

RE-VOICE is a client rule: pick narrated chapters whose `rendered_at` is older than
`cast_changed_at`, then `POST /novels/audio/render {chapter_keys, force: true, priority: 0|9}`.
Without `force`, rendered chapters are skipped as `already_rendered`.
