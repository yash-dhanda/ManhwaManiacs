# App media API

Public (no session): everything under `/app/*`. Every route looks the request name up in a literal allowlist of complete file names; request text is never joined into a path before the lookup succeeds, so traversal can only miss. Every refusal is `404 {"detail": "Not found."}`, including an allowlisted name whose file is missing. Files go through Starlette `FileResponse`: `Accept-Ranges: bytes`, `206` with `Content-Range` for a range, `416` for an unsatisfiable one, `ETag`, `Last-Modified`.

| Route | Serves | Content-Type | Cache-Control |
|---|---|---|---|
| `GET /app/soundscapes/{name}` | 16 Cinematic loops (`projector-room`, `rain-on-glass`, `night-city`, `cafe`, `night-wind`, `low-drone`, `afternoon-park`, `temple-bells`; each `.ogg` and `.m4a`), or `glass-{scene}-{layer}.{ext}` | `audio/ogg`, `audio/mp4` | `public, max-age=31536000, immutable` |
| `GET /app/soundscapes/glass/{name}` | 36 Glass layers: scenes `rain wind ocean hearth stream deep` x layers `bed detail tone` x `.ogg` `.m4a`, from `soundscapes/glass/` | as above | as above |
| `GET /app/fonts/{name}` | the six subsets: `bodoni-moda[-italic]-latin[-ext].woff2`, `archivo-latin[-ext].woff2` (`fonts.json` is not served) | `font/woff2` | immutable |
| `GET /app/brand/{name}` | `og.png`, `apple-touch-icon.png`, `icon-192.png` | `image/png` | `public, max-age=86400` |

`/app/media/{name}` still serves screenshots only.

## Environment

| Variable | Default | Container |
|---|---|---|
| `MM_SOUNDSCAPES_DIR` | `backend/media/soundscapes` | `/app/media/soundscapes` |
| `MM_FONTS_DIR` | `backend/media/fonts` | `/app/media/fonts` |
| `MM_BRAND_DIR` | `frontend/public` | `/app/frontend-public` (read-only bind mount of `frontend/public`) |

## Replacing a file

Clients cache these files for a year. A replaced recording keeps its name, so it reaches devices only when the client steps bump their cache name (web Cache Storage `mm-soundscapes-v1`, the app support directory). Replacing the file on the server alone changes nothing for anyone who already has it.

## Install page (`GET /`)

Dark only, inline CSS, no JavaScript, no cross-origin subresource. Section order: skip link; masthead (inline monogram, `INSTALL` kicker, wordmark `h1`, Oxford rule, version line); four cover lines and the deck; three numbered steps (Android APK, iPhone SideStore source, browser); "Front pages" (only `_SHOWCASE` frames present in `SCREENSHOTS_DIR`); release notes as errata (newest with `LATEST`, three older behind "Earlier versions"); footer. Data sources: `read_android_release`, `read_ios_release`, `_artifact` (file size and date), `_RELEASE_NOTES`, `WEB_APP_URL`, `SIDESTORE_URL`, `_public_base_url` (og:image, feed URL), `fonts.json` for the `@font-face` rules.
