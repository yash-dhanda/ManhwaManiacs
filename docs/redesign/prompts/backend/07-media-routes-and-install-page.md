# Backend 07: soundscape and font routes, and the new install page

## Goal

The backend serves three kinds of static media for the redesign, and one public page. (1) The soundscapes of new feature 4: Cinematic's eight synthesised "house sound" loops (cinematic §9.4.2) and Glass's eighteen recorded layers (glass §9.4.2), as long-cacheable files with byte-range support, from strict allowlists, public under `/app/*` like every other app-distribution file. (2) The Bodoni Moda and Archivo font subsets the install page uses (cinematic §8.34), so that page loads no third-party fonts. (3) The shared brand files the install page needs (`og.png`, the touch icon and the 192 px icon it also uses as its favicon, owned by Cinematic and skin-neutral, glass §12.6). (4) The public install page itself (`GET /` on `app.manhwamaniacs.xyz`, `backend/routes/app_distribution.py`), rebuilt from nothing in the Cinematic brand: the masthead wordmark with its Oxford rule, the four cover lines, numbered install steps with folios, the "Front pages" screenshot set and the release notes set as errata, dark only, inline CSS, no JavaScript. Every file route refuses anything outside its allowlist and every traversal attempt with a 404. The production compose file is updated so the container can read what it needs; production itself is not touched.

## Read first

1. `docs/redesign/prompts-plan.json`, the entry whose `path` is `docs/redesign/prompts/backend/07-media-routes-and-install-page.md` (binding scope).
2. `docs/redesign/cinematic/DESIGN.md`:
   - §9.4.2 Soundscape (the eight loop ids, formats, `SOURCES.md`, the web's `.ogg`/`.m4a` choice).
   - §8.34 Public install page (the whole paragraph), §8.29 What's new (the errata style: version folio, `LATEST` badge, `—` dashes), §12.1 to §12.3 (wordmark, Oxford rule, monogram, icons, display name), §12.5 voice, §12.6 "Front pages" (the five captions and the OG image).
   - §2.1.1 to §2.1.3 colours, §2.3 radius (0 everywhere), §2.6 rules (`rule.oxford`, `rule.hair`), §3.1 families, §3.2 type scale (`type.masthead`, `type.pull`, `type.subhead`, `type.kicker`, `type.label`, `type.caption`, `type.micro` and the fluid `clamp()` formulas), §4.3 curves, §7.1 buttons (`primary`, `secondary`, `quiet`; hover, pressed, focused), §14.4 focus ring, §14.6 touch targets, §14.1 reduced motion.
   - §15.5 rows `GET /app/soundscapes/{id}.{ext}` and `GET /app/fonts/{file}.woff2`.
3. `docs/redesign/glass/DESIGN.md`: §9.4.2 Soundscape (**Recorded layers**: scenes `rain, wind, ocean, hearth, stream, deep`, layers `bed, detail, tone`, `.ogg` Opus and `.m4a` AAC, `Content-Type` rules, cache rule), §12.6 (the install page is Cinematic's and skin-neutral; Glass ships no OG image), §12.7 row **Soundscape recordings**, §15.5 row for the soundscape allowlist, §15.6 row **PWA manifest, startup images, OG image, install page**.
4. `docs/redesign/stack-decision.md` §3 (CI, the SideStore path and the APK channel are unchanged), and `docs/redesign/inventory/00-decisions.md` (new feature 4's ambient soundscape; the name "ManhwaManiacs" stays while the wordmark, icon and every brand asset are new; dark only, `#000000`).
5. `docs/redesign/inventory/capabilities.md` §1 (the public allowlist: anything under `/app/*`), §23 (app distribution, what's new, system status).
6. `docs/redesign/00-baseline.md` and `docs/redesign/proof/backend-00/pytest-baseline.txt`.
7. The steps that produced the files this one serves: `docs/redesign/prompts/shared/03-ui-sounds-and-soundscape-audio.md` (`backend/media/soundscapes/*.ogg|m4a`, `backend/media/soundscapes/SOURCES.md`, the Glass intake folder `backend/media/soundscapes/glass/`) and `docs/redesign/prompts/shared/04-brand-cinematic-and-platform-icons.md` (its section 7 "Install-page fonts": the six `backend/media/fonts/*.woff2` files and `backend/media/fonts/fonts.json`; its asset table: `brand/cinematic/monogram.svg`, `frontend/public/og.png`, `frontend/public/icons/apple-touch-icon.png`, `frontend/public/icons/icon-192.png`; its section 8 SideStore fields, which `release/00` applies).
8. Code: `backend/routes/app_distribution.py` (the install page: `render_landing_html`, `_MARK`, `_render_android`, `_render_iphone`, `_render_release`, `_render_older_releases`, `_render_shots`, `_SHOWCASE`, `_CSS`, `build_ios_source`, `app_media`, `_public_base_url`, `WEB_APP_URL`, `SIDESTORE_URL`, `SCREENSHOTS_DIR`), `backend/routes/system.py` (`GET /` serves the page unconditionally; keep that), `backend/services/auth_service.py` (`_PUBLIC_PREFIXES = ("/app/",)`), `backend/core/config.py` (`REPO_ROOT`), `backend/api/router.py`, `backend/Dockerfile` and `backend/.dockerignore` (the build context is `backend/`, `COPY . .`), `ops/vps/docker-compose.yml` (the backend service's `volumes` and `environment`), `ops/vps/deploy.sh` (it rebuilds the backend image on every deploy), `backend/tests/test_app_distribution.py`.

## Track rule (applies to every `backend/*` prompt)

- Work only in `backend/` (never `backend/connectors/`) plus, because this step says so, `ops/vps/docker-compose.yml`, and `docs/redesign/proof/backend-07/`. This step touches no `frontend/` or `mobile/` file.
- Stage only the paths you changed, by name. Never `git add -A` or `git add .`.
- No migration in this step.
- Changes are additive for the API: the existing `/app/*` routes keep their behaviour. The install page's markup is replaced (that is the point of the step); its factual behaviour (live version, sizes, dates, missing-build messages, no external requests, screenshots only when on disk) is kept.
- Tests run with `backend/.venv/bin/python -m pytest -q --no-header` from `backend/`.

## Preconditions (check before any edit; stop and report if one fails)

1. Branch is `feat/vps-slim-source-native`; `backend/.venv/bin/python -m pytest --version` prints `pytest 9.1.1`.
2. `shared/03` landed: `ls backend/media/soundscapes/` lists the 16 Cinematic files (`projector-room`, `rain-on-glass`, `night-city`, `cafe`, `night-wind`, `low-drone`, `afternoon-park`, `temple-bells`, each `.ogg` and `.m4a`) and `SOURCES.md`, and `backend/media/soundscapes/glass/` exists (it may hold only its `SOURCES.md` template until the owner drops the recordings in; that is fine).
3. `shared/04` landed: `ls backend/media/fonts/` lists `bodoni-moda-latin.woff2`, `bodoni-moda-latin-ext.woff2`, `bodoni-moda-italic-latin.woff2`, `bodoni-moda-italic-latin-ext.woff2`, `archivo-latin.woff2`, `archivo-latin-ext.woff2` and `fonts.json`; `ls brand/cinematic/monogram.svg frontend/public/og.png frontend/public/icons/apple-touch-icon.png frontend/public/icons/icon-192.png` lists all four.
4. `grep -rn "soundscapes\|/app/fonts" backend/routes` finds nothing.
5. `free -m`: `available` is 1024 or more.

## Skills

- `superpowers:writing-plans` first: the plan goes to `docs/redesign/proof/backend-07/plan.md`.
- `superpowers:executing-plans` to run it inline.
- `superpowers:test-driven-development`: the route and page tests first.
- `frontend-design` and `impeccable` for the install page (it is a real, public UI): use them to check the page against cinematic §8.34 and §7, not to invent a different look. `taste-skill:taste-skill` for the final pre-flight pass on the page (hierarchy, spacing rhythm, no template feel).
- `superpowers:verification-before-completion` before claiming done.

## Scope, item by item

### A. Baseline

`cd backend && free -m && timeout 1800 .venv/bin/python -m pytest -q --no-header 2>&1 | tail -25 > ../docs/redesign/proof/backend-07/pytest-before.txt`; list pre-existing failures under `PRE-EXISTING FAILURES:` and leave them alone.

### B. The media routes (`backend/routes/app_media.py`, new; registered in `backend/api/router.py`)

Public by being under `/app/` (the existing `_PUBLIC_PREFIXES`); no session needed. Directories, each overridable by environment for the container and for tests:

```python
BACKEND_DIR = Path(__file__).resolve().parents[1]
SOUNDSCAPES_DIR = Path(os.environ.get("MM_SOUNDSCAPES_DIR", str(BACKEND_DIR / "media" / "soundscapes")))
FONTS_DIR = Path(os.environ.get("MM_FONTS_DIR", str(BACKEND_DIR / "media" / "fonts")))
BRAND_DIR = Path(os.environ.get("MM_BRAND_DIR", str(REPO_ROOT / "frontend" / "public")))
IMMUTABLE = "public, max-age=31536000, immutable"
```

**The allowlists are sets of complete file names.** A request's name is looked up in the set; nothing from the request is ever joined into a path before that lookup succeeds, so `..`, `%2F`, `%2e%2e`, backslashes, absolute paths and doubled extensions can only miss. A name in the set whose file does not exist is also a 404. Every 404 is the plain `HTTPException(status_code=404, detail="Not found.")`.

```python
CINEMATIC_SOUNDSCAPES = frozenset(
    f"{sid}.{ext}"
    for sid in ("projector-room", "rain-on-glass", "night-city", "cafe",
                "night-wind", "low-drone", "afternoon-park", "temple-bells")
    for ext in ("ogg", "m4a")
)
GLASS_LAYERS = frozenset(
    f"{scene}-{layer}.{ext}"
    for scene in ("rain", "wind", "ocean", "hearth", "stream", "deep")
    for layer in ("bed", "detail", "tone")
    for ext in ("ogg", "m4a")
)
AUDIO_TYPES = {".ogg": "audio/ogg", ".m4a": "audio/mp4"}
FONT_FILES = frozenset({
    "bodoni-moda-latin.woff2", "bodoni-moda-latin-ext.woff2",
    "bodoni-moda-italic-latin.woff2", "bodoni-moda-italic-latin-ext.woff2",
    "archivo-latin.woff2", "archivo-latin-ext.woff2",
})
# Published name -> path under BRAND_DIR (literal on both sides; shared/04 writes
# the two icons into frontend/public/icons/).
BRAND_FILES = {
    "og.png": "og.png",
    "apple-touch-icon.png": "icons/apple-touch-icon.png",
    "icon-192.png": "icons/icon-192.png",
}
```

| Route | Serves | Headers |
|---|---|---|
| `GET /app/soundscapes/{name}` | `name` in `CINEMATIC_SOUNDSCAPES` → `SOUNDSCAPES_DIR / name`; `name` of the form `glass-{scene}-{layer}.{ext}` whose remainder after `glass-` is in `GLASS_LAYERS` → `SOUNDSCAPES_DIR / "glass" / remainder` (the id spelling of glass §9.4.2 and §15.5) | `Content-Type` from `AUDIO_TYPES`; `Cache-Control: IMMUTABLE` |
| `GET /app/soundscapes/glass/{name}` | `name` in `GLASS_LAYERS` → `SOUNDSCAPES_DIR / "glass" / name` (the plan's older alias; `web/44` and `mobile/44` request the id spelling of the row above) | as above |
| `GET /app/fonts/{name}` | `name` in `FONT_FILES` → `FONTS_DIR / name` | `Content-Type: font/woff2`; `Cache-Control: IMMUTABLE` |
| `GET /app/brand/{name}` | `name` a key of `BRAND_FILES` → `BRAND_DIR / BRAND_FILES[name]` | `Content-Type: image/png`; `Cache-Control: public, max-age=86400` (not immutable: `web/24` replaces `og.png`'s capture later) |

- Every one returns Starlette's `FileResponse(path, media_type=…, headers={"Cache-Control": …})`. Starlette 1.6.0's `FileResponse` answers a `Range` request with `206 Partial Content`, `Content-Range` and `Accept-Ranges: bytes`, and an unsatisfiable range with `416`; it also sends `ETag` and `Last-Modified`. Do not reimplement any of it.
- **`FONT_FILES`** is the literal set above: the six subsets `shared/04` section 7 writes (Bodoni Moda roman and italic, Archivo; each `latin` and `latin-ext`), never computed from a directory listing at runtime. `fonts.json` beside them (also from `shared/04`) is **not** served; the install page reads it at import time for each file's `family`, `style` and `unicodeRange` (section D). If `ls backend/media/fonts/` shows different names, stop and report: `shared/04` and this step disagree and one of them must be fixed first.
- There is no favicon file on `/app/brand/`: `shared/04` puts `favicon.ico` in `frontend/src/app/` (outside the mount) and `favicon.svg` would be an SVG, which this step never serves under `/app/*`. The install page uses `icon-192.png` as its favicon.
- `/app/media/{name}` keeps serving screenshots only (cinematic §15.5): `/app/media/soundscapes/…`, `/app/media/fonts/…` and `/app/media/og.png` stay 404 (test it).
- Rename safety: a replaced recording keeps its name, and clients cache these files for a year (web Cache Storage `mm-soundscapes-v1`, app support directory), so a changed recording reaches devices only when the client steps bump that cache name. Write this in `backend/media/soundscapes/SOURCES.md` under a heading `Replacing a file` (one paragraph) and in the API note.

### C. The container can read what it needs (`ops/vps/docker-compose.yml`, `backend/.dockerignore`)

1. `backend/media/` reaches the container through the image: the build context is `backend/`, the Dockerfile runs `COPY . .`, `.dockerignore` excludes nothing under `media/`, and `ops/vps/deploy.sh` rebuilds the image on every deploy. Keep it that way; add a test (`test_media_ships_in_the_image`) that reads `backend/.dockerignore` and fails if any pattern matches `media/`, `media/soundscapes/cafe.ogg` or `media/fonts/x.woff2` (use `fnmatch` over each non-comment line, with and without a trailing `/`). In the container `SOUNDSCAPES_DIR` and `FONTS_DIR` resolve to `/app/media/…` by their defaults; also set them explicitly in the compose `environment` (`MM_SOUNDSCAPES_DIR=/app/media/soundscapes`, `MM_FONTS_DIR=/app/media/fonts`), next to the existing `MM_SCREENSHOTS_DIR` line, with a one-line comment each.
2. The brand files live in `frontend/public/`, outside the backend's build context. Add a read-only bind mount to the backend service's `volumes`, in the style of the existing `pubspec.yaml` and screenshots mounts, with a comment: `- ../../frontend/public:/app/frontend-public:ro` and the environment line `MM_BRAND_DIR=/app/frontend-public` (the route serves only the three allowlisted files from it).
3. Validate the edited file without Docker: `python3 -c "import yaml,sys; yaml.safe_load(open('ops/vps/docker-compose.yml'))"` (PyYAML is in the system Python; if it is not, use `backend/.venv/bin/python -m pip install pyyaml` in the venv only and run it there). Do **not** run `docker`, `docker compose`, `ops/vps/deploy.sh` or anything that starts, stops or rebuilds a container: the change goes live with the next release step.

### D. The install page, rebuilt (`backend/routes/app_distribution.py`)

`GET /` keeps answering the page unconditionally (`routes/system.py`, whatever the `Accept` header; the plan's "Accept text/html" describes the browsers that ask for it, not a negotiation to add). Replace `_MARK`, `_CSS`, `_SHOWCASE`, `render_landing_html` and its `_render_*` helpers; keep every data source they read (`read_android_release`, `_artifact`, `read_ios_release`, `_pretty_date`, `_RELEASE_NOTES`, `_feed_url`, `WEB_APP_URL`, `SIDESTORE_URL`). Still one page, one inline `<style>`, **no JavaScript**, and no subresource from another origin: fonts come from `/app/fonts/`, icons and the OG image from `/app/brand/`, screenshots from `/app/media/`.

**Head.**

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
  <meta name="color-scheme" content="dark" />
  <meta name="theme-color" content="#000000" />
  <meta name="description" content="Install ManhwaManiacs: every source, one shelf. Manga, manhwa, manhua and novels for Android, iPhone and the web." />
  <meta property="og:title" content="ManhwaManiacs" />
  <meta property="og:description" content="Every source. One shelf. Novels, read aloud. Your year in chapters. Read together." />
  <meta property="og:image" content="{base}/app/brand/og.png" />
  <meta property="og:image:width" content="1200" />
  <meta property="og:image:height" content="630" />
  <meta name="twitter:card" content="summary_large_image" />
  <link rel="icon" type="image/png" sizes="192x192" href="/app/brand/icon-192.png" />
  <link rel="apple-touch-icon" href="/app/brand/apple-touch-icon.png" />
  <link rel="preload" href="/app/fonts/bodoni-moda-latin.woff2" as="font" type="font/woff2" crossorigin />
  <title>Install ManhwaManiacs</title>
  <style>…</style>
</head>
```

`{base}` is `_public_base_url(request)` (absolute, because link-preview crawlers need it); when it is empty the two `og:image` lines are left out.

**Body, top to bottom** (one column; every string below is the copy, in the voice of cinematic §12.5):

1. A skip link as the first focusable element: `<a class="skip" href="#install">Skip to install steps</a>`, visible only on focus (top-left, `#121211` band, 14/20 Archivo 500, ink `#F3F0E8`).
2. **Masthead** (`<header class="masthead">`): the monogram, inline, 72 × 72 px: the `mm-mark` master `brand/cinematic/monogram.svg` (not `monogram-small.svg` or `monogram-mono.svg`), copied into `_MARK` as markup with its XML prolog, comments and editor metadata stripped, `role="img" aria-label="ManhwaManiacs"`, the bone letters `#F3F0E8` and the intersection `#F4D03F` exactly as the master draws them. Then the kicker `INSTALL` (`<p class="kicker">`), then the wordmark as the page's only `h1`: `<h1 class="wordmark"><span class="upright">Manhwa</span><span class="italic">Maniacs</span></h1>` (no space between the spans, cinematic §12.2), then the Oxford rule (`<div class="oxford" aria-hidden="true"></div>`), then the version line `<p class="version">Version {version} · build {build}</p>` (the APK's numbers, exactly as today).
3. **Cover lines** (`<section class="cover-lines" aria-label="What it does">`): four `<p>`: "Every source. One shelf." / "Novels, read aloud." / "Your year in chapters." / "Read together.", then a deck `<p class="deck">`: "Manga, manhwa, manhua and web novels from every source you add, on one shelf per profile. Save chapters and read them with no signal."
4. **Install steps** (`<section id="install" aria-labelledby="install-h">`, kicker `<p class="kicker">`HOW TO INSTALL`</p>` and a visually hidden `<h2 id="install-h">Install</h2>`), an `<ol class="steps">` of three `<li class="step">`, each `<span class="folio" aria-hidden="true">01</span>` plus an `h3`:
   - `01` "Android: download the APK". Available: the primary button `<a class="btn" href="/app/download">Download for Android</a>`, the meta line `<p class="meta">{size} · updated {date}</p>`, then "Open the file when it has downloaded. Android asks once whether to allow installs from your browser; allow it, then tap Install." Missing: `<p class="unavailable">No Android build published yet.</p>` and "Read in your browser for now: step 03." (no `/app/download` link anywhere on the page, as today).
   - `02` "iPhone: add the SideStore source". Available: "Apple does not let a website install an app, so the iPhone needs <a href="{SIDESTORE_URL}" rel="noopener">SideStore</a>, a free app that installs apps like this one. Install SideStore first." / "Then open SideStore, go to **Sources**, tap **+**, and paste this address:" / `<p class="url">{feed_url}</p>` (selectable, `user-select: all`) / "ManhwaManiacs appears in that source, and every update arrives there." / `<p class="meta">{release} · {size} · updated {date}</p>`. Missing: `<p class="unavailable">No iPhone build published yet.</p>` and "Read in your browser for now: step 03." (no `/app/source.json` on the page, as today).
   - `03` "Or read in your browser": a secondary button `<a class="btn secondary" href="{WEB_APP_URL}">Open {host}</a>` (`host` = `WEB_APP_URL` without the scheme) and "Nothing to install. Works on any phone or computer."
5. **Front pages** (only the frames on disk; the section is omitted when none is): kicker `FRONT PAGES`, then a horizontal strip `<div class="shots" role="region" aria-label="Screenshots" tabindex="0">` of `<figure>`s, each `<img src="/app/media/{name}?v={cache_key}" alt="{caption}" width="1320" height="2868" loading="lazy" decoding="async" />` and a `<figcaption>` with the caption. `_SHOWCASE` becomes the five frames of cinematic §12.6, in this order: `("front-01-every-source.png", "Every source. One shelf.", "")`, `("front-02-long-scroll.png", "Built for the long scroll.", "")`, `("front-03-novels-read-aloud.png", "Novels, read aloud.", "Thirty-one voices")`, `("front-04-year-in-chapters.png", "Your year in chapters.", "")`, `("front-05-read-together.png", "Read together.", "")`. `web/24` captures them into `docs/redesign/proof/web-24/front-pages/`, and `release/00` copies them into `mobile/docs/screenshots/` (the folder the compose file already mounts as `SCREENSHOTS_DIR`) under exactly these five names; until then the section is simply absent. These names are the contract `release/00` reads from `_SHOWCASE`: `brand/cinematic/sidestore.md` from `shared/04` spells two of them differently (`front-03-read-aloud.png`, `front-04-your-year.png`), and `_SHOWCASE` wins. `build_ios_source` lists only the showcase files that exist too (the same `is_file()` filter), so the SideStore manifest never points at a missing screenshot.
6. **Release notes** (`<section class="notes" aria-labelledby="notes-h">`): kicker `WHAT'S NEW`, `<h2 id="notes-h">Release notes</h2>`, then the newest `_RELEASE_NOTES` entry: the folio `<p class="vfolio">{version} · BUILD {build} · {date in upper case, "24 SEP 2026"}</p>` with a `<span class="badge">LATEST</span>`, and its highlights as `<ul class="dashes">`. Then `<details class="older"><summary>Earlier versions</summary>…</details>` with the next three entries in the same folio style (no badge).
7. **Footer**: an Oxford rule, then `<footer><p>ManhwaManiacs · {version} ({build})</p></footer>`.

**Styles** (the whole `_CSS`; Cinematic tokens, cinematic §2 and §3; dark only: there is no light palette and no `prefers-color-scheme` block):

- `@font-face` for each `FONT_FILES` entry, built at import time from `backend/media/fonts/fonts.json` (one rule per file; the file list itself stays the literal `FONT_FILES`, and a `fonts.json` entry whose `file` is not in it is ignored): `font-family` from `family` (`"Bodoni Moda"` or `"Archivo"`), `font-style` from `style` (`normal` or `italic`), `src: url(/app/fonts/{file}) format("woff2")`, `unicode-range` copied from `unicodeRange` (so a `latin-ext` file downloads only when a page needs it), `font-display: swap`, and the axes of `shared/04`'s request: Bodoni Moda `font-weight: 400 900` (its `opsz` 6–96 axis is applied by `font-optical-sizing: auto`), Archivo `font-weight: 400 800` and `font-stretch: 62% 100%` (its `wdth` axis, which the 62 % and 90 % widths below need). Fallback stacks: `"Bodoni Moda", "Didot", "Bodoni 72", Georgia, serif` and `"Archivo", -apple-system, "Segoe UI", Roboto, Arial, sans-serif`.
- Page: `html { background: #000000; color-scheme: dark; }`, `body { margin: 0; color: #F3F0E8; font: 500 16px/24px "Archivo", …; -webkit-text-size-adjust: 100%; }`; `main { max-width: 44rem; margin: 0 auto; padding: max(48px, env(safe-area-inset-top)) 20px 64px; display: grid; gap: 56px; }`; at `min-width: 1024px` the side padding is 32px and the gap 72px. Every length a multiple of 4 px.
- Masthead: the mark 72 px, 16 px below it the kicker; `.wordmark { font-family: "Bodoni Moda", …; font-weight: 800; font-size: clamp(2.5rem, 1.582rem + 3.92vw, 5.5rem); line-height: 1; letter-spacing: -0.035em; font-optical-sizing: auto; margin: 8px 0 0; }`, `.wordmark .italic { font-style: italic; }`; `.oxford { height: 6px; margin-top: 12px; background: linear-gradient(to right, #F4D03F 0 12%, #F3F0E8 12% 100%) 0 0 / 100% 3px no-repeat, linear-gradient(to right, #F4D03F 0 12%, #F3F0E8 12% 100%) 0 5px / 100% 1px no-repeat; }` (3 px + 2 px gap + 1 px, the first 12 % in spot, cinematic §2.6 and §12.2), as wide as the wordmark (`.masthead` is `display: inline-grid` inside a block wrapper, or `width: fit-content`); `.version` 13/16 Archivo `font-stretch: 90%` in `#7A7770`, `font-variant-numeric: tabular-nums`, 12 px below the rule.
- Kickers (`type.kicker`): Archivo 700, `font-stretch: 62%`, 12px/16px (11px/16px under 600 px), `letter-spacing: 0.16em`, upper case, `#7A7770` (on black only).
- Cover lines (`type.pull`): Bodoni Moda italic 500, `font-size: clamp(1.5rem, 1.2rem + 1.3vw, 2.25rem)`, `line-height: 1.25`, `letter-spacing: -0.015em`, `#F3F0E8`, `margin: 0`, each line separated by a 1 px `#2B2A27` rule with 12 px above and below; `.deck` Archivo 17/28 (`font-stretch: 100%`, weight 450) in `#9A978F`, max 36em, 20 px below the last line.
- Steps: `.steps { list-style: none; margin: 16px 0 0; padding: 0; display: grid; gap: 40px; }`; each step has a 1 px `#2B2A27` top rule and 20 px top padding; `.folio` Archivo 600 15/20 `tabular-nums` `#9A978F`; the `h3` is `type.subhead`: Bodoni Moda 600, 20px/24px on phones and 24px/28px from 768 px, `letter-spacing: -0.01em`, `#F3F0E8`, 4 px below the folio; body copy 16/24 `#9A978F` with `strong` in `#F3F0E8`; `.meta` 13/16 `#7A7770` tabular; `.unavailable` 16/24 Archivo 650 `#F3F0E8`; `.url` a `#0B0B0A` well with a 1 px `#3D3C38` border, radius 0, 12px 14px padding, `ui-monospace, "SF Mono", Menlo, Consolas, monospace` 14/20, `word-break: break-all`, `user-select: all`; links `color: #F3F0E8; text-decoration: underline; text-underline-offset: 3px; text-decoration-thickness: 1px`.
- Buttons (cinematic §7.1): `.btn { display: flex; align-items: center; justify-content: center; min-height: 48px; padding: 0 24px; background: #F3F0E8; color: #000000; font: 650 15px/20px "Archivo", …; letter-spacing: 0.005em; text-decoration: none; border-radius: 0; position: relative; }`, full width under 600 px, `width: fit-content` above; hover (`@media (hover: hover)`): an `::after` 2 px `#F4D03F` rule 4 px below the bottom edge, full width, `transform: scaleX(0)` → `scaleX(1)` from the left over 240 ms `cubic-bezier(0.16, 1, 0.3, 1)`, out 160 ms `cubic-bezier(0.7, 0, 0.84, 0)`; active: `transform: translateY(1px); background: #C9C6BE` (80 ms `cubic-bezier(0.2, 0, 0, 1)`). `.btn.secondary { background: transparent; color: #F3F0E8; box-shadow: inset 0 0 0 1px #F3F0E8; }`, hover fill `#232220`, active fill `#1A1A18`. Every interactive element is at least 48 × 48 px on coarse pointers (`@media (pointer: coarse)`, cinematic §14.6: 44 iOS and 48 Android, so 48 covers both) and at least 32 × 32 px on fine pointers; the SideStore link and the `summary` get `display: inline-block; min-height: 48px; line-height: 48px` under `pointer: coarse`.
- Focus (cinematic §14.4): `:focus-visible { outline: 2px solid #F3F0E8; outline-offset: 2px; box-shadow: 0 0 0 6px #000000; }` on links, buttons, `summary` and the shots region; square; never clipped (no `overflow: hidden` on an ancestor of a focusable element except the shots strip, which gets `padding: 8px` so its own ring shows).
- Shots: `display: flex; gap: 16px; overflow-x: auto; scroll-snap-type: x mandatory; padding: 8px; margin: 0 -8px;` each `figure { flex: 0 0 min(46vw, 240px); scroll-snap-align: start; margin: 0; }`, `img { width: 100%; height: auto; display: block; border: 1px solid #2B2A27; border-radius: 0; background: #0B0B0A; }`, `figcaption` Bodoni Moda italic 500 16/24 `#F3F0E8` 8 px below.
- Release notes: `.vfolio` `ui-monospace` 15/20 `#F3F0E8` tabular; `.badge { display: inline-block; margin-left: 8px; padding: 0 6px; background: #F4D03F; color: #000000; font: 700 10px/16px "Archivo", …; font-stretch: 62%; letter-spacing: 0.12em; }` (text on spot is always black, cinematic §2.1.3); `ul.dashes { list-style: none; padding: 0; margin: 12px 0 0; display: grid; gap: 8px; } ul.dashes li::before { content: "— "; color: #7A7770; }`, items 16/24 `#C9C6BE`; `summary` Archivo 650 15/20, `cursor: pointer`.
- Footer: 13/16 `#7A7770`, centred, 16 px below its Oxford rule.
- `@media (prefers-reduced-motion: reduce) { *, *::before, *::after { transition: none !important; animation: none !important; } }` (cinematic §14.1: the only motion here is the hover rule and the press impression).
- `@media (forced-colors: active)`: `.oxford { background: CanvasText; }`, `.btn { border: 1px solid ButtonText; }`, `.badge { forced-color-adjust: none; }`.
- `@media (prefers-contrast: more)`: `#7A7770` roles render `#C9C6BE`.

### E. Tests (write them first)

`backend/tests/test_app_media_routes.py` (monkeypatch `SOUNDSCAPES_DIR`, `FONTS_DIR`, `BRAND_DIR` to `tmp_path` folders holding small fake files; the module-level constants are read at request time through the module, so patch the module attribute):

1. Every name in `CINEMATIC_SOUNDSCAPES` (16) is served 200 with `audio/ogg` or `audio/mp4` and `Cache-Control: public, max-age=31536000, immutable`; so is a sample of 6 `GLASS_LAYERS` names at `/app/soundscapes/glass/{name}`, and the same files at `/app/soundscapes/glass-{name}` return byte-identical bodies.
2. Range: `Range: bytes=0-99` → 206, `Content-Range: bytes 0-99/{size}`, 100 bytes; `Range: bytes={size}-` → 416; a response to a plain GET carries `Accept-Ranges: bytes`.
3. Allowlists: `/app/soundscapes/lofi.ogg`, `/app/soundscapes/cafe.mp3`, `/app/soundscapes/SOURCES.md`, `/app/soundscapes/glass/rain-bass.ogg`, `/app/soundscapes/glass/SOURCES.md`, `/app/soundscapes/glass-rain.ogg`, `/app/fonts/evil.woff2` (a real file in the fonts folder but not allowlisted), `/app/fonts/fonts.json`, `/app/fonts/{allowlisted}.ttf`, `/app/brand/favicon.svg`, `/app/brand/favicon.ico`, `/app/brand/icons/icon-192.png` (only the published name is served), `/app/brand/sw.js` → 404; an allowlisted name whose file is missing → 404.
4. Traversal, each 404 (never 200, never a file outside the folder): `/app/soundscapes/..%2F..%2Fmain.py`, `/app/soundscapes/%2e%2e%2f%2e%2e%2fmain.py`, `/app/soundscapes/glass/..%2Fcafe.ogg`, `/app/soundscapes/glass/%2e%2e/cafe.ogg`, `/app/fonts/..%2Fsoundscapes%2Fcafe.ogg`, `/app/fonts/%2Fetc%2Fpasswd`, `/app/brand/..%2F..%2Fbackend%2Fmain.py`, `/app/soundscapes/cafe.ogg%00.woff2`, `/app/soundscapes/cafe.ogg/..`, and `/app/media/soundscapes/glass/rain-bed.ogg`.
5. Fonts and brand: an allowlisted font → 200 `font/woff2` with the immutable header; `og.png` → 200 `image/png` with `public, max-age=86400`; `/app/brand/icon-192.png` → 200 `image/png` with the bytes of `BRAND_DIR/icons/icon-192.png`.
6. Public: every route above answers without a session cookie (no 401).
7. `test_media_ships_in_the_image` (C1).

`backend/tests/test_app_distribution.py`, updated. Keep every test's intent; change only literal markup assertions, each listed in the report:
- `"<h2>Android</h2>" in html` → `"Android: download the APK" in html`; `"<h2>iPhone</h2>" in html` → `"iPhone: add the SideStore source" in html` (both where they occur, including the missing-build tests).
- `f"What's new in {newest['version']}"` → `f"{newest['version']} · BUILD {newest['build']}"`.
- `test_install_page_omits_screenshots_it_cannot_serve` keeps asserting `"/app/media/" not in html` with no frames on disk.
- `test_install_page_makes_no_external_requests` keeps its rule unchanged (the new `/app/fonts/`, `/app/brand/` and `#install` hrefs start with `/` or `#`).

New page tests in the same file: the page has exactly one `<h1`, containing `Manhwa` and `Maniacs`; it contains the four cover lines; the three step titles appear in order with folios `01`, `02`, `03`; `color-scheme" content="dark"` and `theme-color" content="#000000"` are present and `prefers-color-scheme` is absent; every `FONT_FILES` name appears in an `@font-face` `src` with a `unicode-range`, the Archivo rules carry `font-stretch: 62% 100%` and `font-weight: 400 800`, and `bodoni-moda-latin.woff2` is preloaded; the favicon link points at `/app/brand/icon-192.png`; `og:image` is `{base}/app/brand/og.png` when `MM_PUBLIC_BASE_URL` is set and absent when it is not; with two of the five frames present in a temp `SCREENSHOTS_DIR` exactly those two render, in showcase order, with their captions as `alt`, and `build_ios_source(...)["apps"][0]["screenshots"]` lists exactly those two; the CSS holds `:focus-visible`, `prefers-reduced-motion: reduce`, `min-height: 48px`, and no `border-radius` other than `0`; the monogram SVG is inline (`<svg` in the header, `aria-label="ManhwaManiacs"`) and the old amber `#F5A00B` mark is gone.

### F. Proof (dev stack plus headless Playwright screenshots; never production)

1. `free -m`, then `backend/scripts/dev_stack.sh restart` (the dev stack serves `backend/media` and, by the `BRAND_DIR` default, the checkout's `frontend/public`).
2. `curl -s -D - -o /dev/null -H 'Range: bytes=0-1023' http://127.0.0.1:8010/app/soundscapes/cafe.ogg > docs/redesign/proof/backend-07/range-cafe.txt` (206 with `Content-Range`), and the same for a font file into `font-headers.txt` (200, `font/woff2`, immutable), and `curl -s -o /dev/null -w '%{http_code}\n' 'http://127.0.0.1:8010/app/soundscapes/..%2F..%2Fmain.py' > traversal.txt` (404).
3. Screenshots with the Playwright already installed in `frontend/node_modules` (1.62.1). If `ls ~/.cache/ms-playwright` shows no `chromium-*` folder, run `cd frontend && npx playwright install chromium` once (a download to `~/.cache`, about 170 MB of disk, no build). Write the script to `docs/redesign/proof/backend-07/shoot.mjs`:

```js
import { chromium } from "/srv/manhwamaniacs/dev/ManhwaManiacs/frontend/node_modules/playwright/index.mjs";

const out = "/srv/manhwamaniacs/dev/ManhwaManiacs/docs/redesign/proof/backend-07";
const browser = await chromium.launch();
for (const [width, height, scale] of [[1440, 900, 1], [390, 844, 3]]) {
  const page = await browser.newPage({ viewport: { width, height }, deviceScaleFactor: scale });
  await page.goto("http://127.0.0.1:8010/", { waitUntil: "networkidle" });
  await page.screenshot({ path: `${out}/install-${width}x${height}.png`, fullPage: true });
  await page.close();
}
const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 3, reducedMotion: "reduce" });
await page.goto("http://127.0.0.1:8010/", { waitUntil: "networkidle" });
await page.keyboard.press("Tab");
await page.screenshot({ path: `${out}/install-390x844-skiplink-focus.png` });
await page.keyboard.press("Tab");
await page.keyboard.press("Tab");
await page.screenshot({ path: `${out}/install-390x844-focus.png` });
const fonts = await page.evaluate(() => [...document.fonts].filter((f) => f.status === "loaded").map((f) => `${f.family} ${f.style}`));
console.log(JSON.stringify({ fontsLoaded: fonts }));
await browser.close();
```

Run it with `node docs/redesign/proof/backend-07/shoot.mjs > docs/redesign/proof/backend-07/fonts-loaded.json`. `fonts-loaded.json` must list Bodoni Moda (normal and italic) and Archivo as loaded. Look at every PNG yourself before claiming the page is right (the wordmark on one line at 1440 px, the Oxford rule's spot segment, the focus ring's black halo, 48 px buttons, no horizontal page scroll at 390 px).
4. `backend/scripts/dev_stack.sh stop`.

### G. API note

`backend/docs/app-media-api.md`: the four routes, both Glass spellings, every allowlist, the headers, Range behaviour, the environment variables and their container values, the "Replacing a file" rule, and the install page's section order and data sources.

## File layout

| Path | Change |
|---|---|
| `backend/routes/app_media.py` | new (B) |
| `backend/api/router.py` | include `app_media` |
| `backend/routes/app_distribution.py` | the install page rebuilt (D); `build_ios_source` screenshot filter |
| `backend/media/soundscapes/SOURCES.md` | the "Replacing a file" paragraph |
| `ops/vps/docker-compose.yml` | the `frontend/public` read-only mount and `MM_BRAND_DIR`, `MM_SOUNDSCAPES_DIR`, `MM_FONTS_DIR` (C) |
| `backend/tests/test_app_media_routes.py` | new |
| `backend/tests/test_app_distribution.py` | updated (E) |
| `backend/docs/app-media-api.md` | new (G) |
| `docs/redesign/proof/backend-07/` | `plan.md`, `pytest-before.txt`, `pytest-after.txt`, `range-cafe.txt`, `font-headers.txt`, `traversal.txt`, `shoot.mjs`, `fonts-loaded.json`, `install-1440x900.png`, `install-390x844.png`, `install-390x844-skiplink-focus.png`, `install-390x844-focus.png` |

## Acceptance criteria

- [ ] `pytest-after.txt` shows every test that passed in `pytest-before.txt` still passing (with only the listed literal assertions of `test_app_distribution.py` rewritten), plus the new tests.
- [ ] The 16 Cinematic loops and the 36 Glass layer names (at `/app/soundscapes/glass/{scene}-{layer}.{ext}` and at `/app/soundscapes/glass-{scene}-{layer}.{ext}`) are served with the right `Content-Type`, `Cache-Control: public, max-age=31536000, immutable`, `Accept-Ranges`, 206 for a range and 416 for an unsatisfiable one; anything else under those paths is 404.
- [ ] `/app/fonts/` serves only the literal `FONT_FILES`; `/app/brand/` only its three published names (`og.png`, `apple-touch-icon.png`, `icon-192.png`); `/app/media/` still serves screenshots only.
- [ ] Every traversal case of E4 is a 404, and no route joins request text into a path before the allowlist lookup.
- [ ] All four routes are public (no session needed).
- [ ] `ops/vps/docker-compose.yml` parses as YAML and carries the mount and the three environment lines; `backend/.dockerignore` excludes nothing under `media/`; no Docker command was run.
- [ ] The install page is dark only, in the Cinematic brand: the inline monogram, the `INSTALL` kicker, the two-posture wordmark as the only `h1`, the Oxford rule with its 12 % spot segment, the four cover lines, three numbered steps, Front pages when on disk, release notes as errata with the `LATEST` badge; Bodoni Moda and Archivo load from `/app/fonts/`; there is no `<script>` and no cross-origin subresource.
- [ ] Keyboard: the skip link is the first tab stop and moves to `#install`; every link, button, `summary` and the screenshot strip shows the double focus ring (2 px bone at 2 px offset plus the 6 px black halo); the tab order follows reading order.
- [ ] Touch: every interactive element is at least 48 × 48 px on a coarse pointer (covers iOS 44 pt and Android 48 dp) and at least 32 × 32 px on a fine pointer.
- [ ] Reduced motion: with `prefers-reduced-motion: reduce` the hover rule and the press impression do not animate (they switch instantly).
- [ ] Per-skin: the page is skin-neutral and owned by Cinematic (glass §12.6, §15.6); both skins' clients fetch the soundscape files from these routes (Cinematic's eight loops; Glass's layers through either spelling), and the fonts and brand routes serve only the install page. Nothing branches on the skin.
- [ ] The four screenshots and `fonts-loaded.json` are in `docs/redesign/proof/backend-07/`, and you looked at each.
- [ ] `git show --name-only --format= <hash> -- frontend mobile backend/connectors` for each of your own commits (never a branch or range diff: parallel sessions commit on the same branch) prints nothing.

## Verification

One heavy command at a time, `free -m` before each; stop under 1024 MB available.

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs/backend
free -m
.venv/bin/python -m pytest -q --no-header tests/test_app_media_routes.py tests/test_app_distribution.py
free -m
timeout 1800 .venv/bin/python -m pytest -q --no-header 2>&1 | tail -25 > ../docs/redesign/proof/backend-07/pytest-after.txt
cat ../docs/redesign/proof/backend-07/pytest-after.txt
cd .. && python3 -c "import yaml; yaml.safe_load(open('ops/vps/docker-compose.yml')); print('compose yaml ok')"
```

Then the proof of section F (`free -m` before starting the dev stack and before launching Chromium).

Web and mobile suites are not run because nothing under `frontend/` or `mobile/` changes (`git show --name-only --format= <hash> -- frontend mobile` for each of your own commits (never a branch or range diff: parallel sessions commit on the same branch) prints nothing; installing Playwright's browser writes only to `~/.cache`). Their baseline commands, if you ever touch them: `npm run lint` and `npm run build` in `frontend/`; `/srv/manhwamaniacs/dev/flutter/bin/flutter analyze` and `/srv/manhwamaniacs/dev/flutter/bin/flutter test` in `mobile/`.

## RAM guard

Production and five Minecraft bots share this box (7,746 MB). `free -m` before each pytest run, before starting the dev stack and before launching headless Chromium (about 300 MB); stop and report if `available` is under 1024 MB. Never run two heavy commands at once; never run `next build` here.

## Git

- Branch `feat/vps-slim-source-native`; commit small and often and push after each: `git push origin feat/vps-slim-source-native`.
- Suggested commits: (1) `test(app): media route allowlists, ranges and traversal; install page` (failing), (2) `feat(app): soundscape, font and brand routes`, (3) `chore(ops): compose mounts frontend/public for brand files`, (4) `feat(app): install page in the Cinematic brand`, (5) `docs(backend): app media API note`, (6) `docs(redesign): backend-07 proof`.
- Stage by explicit path only (`git add backend/routes/app_media.py ops/vps/docker-compose.yml …`). No Claude or AI attribution anywhere (no `Co-Authored-By`, no "generated with" line, no AI author). Never commit secrets, `.env`, `.claude/`, `backend/.venv/` or dev data.
- No frontend change, so no `next build` before pushing; if `git status` shows a frontend change you made, stop.

## Never

- Never edit `backend/connectors/`.
- Never run `docker`, `docker compose`, `ops/vps/deploy.sh` or `ops/vps/push.sh`, and never touch production containers, `/srv/manhwamaniacs/app` or `/srv/manhwamaniacs/data`. The compose change goes live with the release step.
- Never serve a file by joining request text into a path, and never allowlist SVG or HTML under `/app/*`.

## Report back

Reply with:
1. Done items A to G, each with its commit SHA.
2. Confirmation that `backend/media/fonts/` held exactly the six `FONT_FILES` names, and that `_MARK` was inlined from `brand/cinematic/monogram.svg`.
3. Backend test counts before and after, the new test files with their case counts, and every literal assertion you rewrote in `test_app_distribution.py`.
4. The proof folder `docs/redesign/proof/backend-07/` with its four screenshots (1440 × 900, 390 × 844, and the two 390 × 844 focus shots), `fonts-loaded.json` and the three header captures.
5. Hand-offs: `release/00` copies `web/24`'s five Front pages frames into `mobile/docs/screenshots/` under the five `_SHOWCASE` names of D5 (the `shared/04` spellings `front-03-read-aloud.png` and `front-04-your-year.png` are not used); the release step deploys the compose change; which Glass recordings were present in `backend/media/soundscapes/glass/`.
6. Open issues.

Next prompt file in the series: `docs/redesign/prompts/web/10-cinematic-updates-collections-history-bookmarks.md`. Next file in the backend track: `docs/redesign/prompts/backend/08-circle-core-sharing-presence.md`.
