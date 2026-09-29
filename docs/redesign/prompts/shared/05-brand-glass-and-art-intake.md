# Shared 05: Glass brand masters, the alternate icon and the art intake

## Goal

Draw the Glass brand ("MM column": two stacked M's joined by a meniscus gutter bar, rendered as Liquid Glass) as reproducible code on the toolchain shared/04 built, and prepare everything the Glass alternate app icon needs without switching it on. You will build the SVG masters in `brand/glass/` (the stacked "MM column" wordmark on the 1024 geometry, the single-line fallback, the flat neutral mark, the favicon silhouette, the aurora field with its three blobs, the three icon slabs `bottom-m`, `gutter-bar` and `top-m`, and the droplet texture), an export script that renders the Glass icon sets for iOS (1024 opaque, iOS 18 dark and tinted, plus the iOS 26 Icon Composer bundle `mobile/ios/Runner/AppIcon-Glass.icon/`) and Android (adaptive field, flattened foreground inside the 66 dp circle, monochrome), the web favicon `frontend/public/favicon-glass.svg` for the per-skin link swap, the alternate-icon registration for `flutter_dynamic_icon_plus` 1.4.1 written down but deliberately not applied while `flags.glass_available` is false, `brand/check.mjs` rules for all of it, and the art intake the owner needs: the exact brief for the art-style crops, a licence ledger, and a script that turns delivered masters into the sized WebP files and names every file still missing. The Droplet logo reveal is code in web/29 and mobile/29; the skin preview loops are captured later by the harness (web/39, mobile/39).

## Read first

Read these before planning. The DESIGN files win where this file disagrees, except where "Decisions this step makes" says otherwise and why.

1. `docs/redesign/prompts-plan.json`, the entry whose `path` is `docs/redesign/prompts/shared/05-brand-glass-and-art-intake.md` (binding scope) and the TRACK RULE in the `shared/00` entry.
2. `docs/redesign/prompts/shared/04-brand-cinematic-and-platform-icons.md` (what already exists: `brand/package.json` with `@resvg/resvg-js` 2.6.2, `sharp` 0.34.5, `fontkit` 2.0.4; `brand/lib/{fonts,text,tokens,img,render}.mjs`; `brand/check.mjs`; `brand/proof.mjs`; `brand/demo/`; the shared native frame; `frontend/src/skins/brand.generated.ts` already maps `glass` to `/favicon-glass.svg`). Run `git log --oneline -- brand/` to confirm shared/04 is committed; if it is not, stop and report.
3. `docs/redesign/inventory/00-decisions.md` (all).
4. `docs/redesign/stack-decision.md` §2.1, §2.3 (mobile layout), §3 ("Release model": Glass stays behind the debug row until its own flip), §4 risks 3, 9 and 11.
5. `docs/redesign/glass/DESIGN.md`:
   - §12.1 to §12.7 (lines 3889 to 3960): the wordmark and its geometry, the app icon (field, blobs, slabs, iOS 26 Icon Composer, Xcode 26 pin, PNG fallback, Android, web, the per-skin rule), the shared splash and the neutral mark, the Droplet table (so the masters fit it), screenshots, the pipeline, the asset brief;
   - §2.1.1 to §2.1.3 (`g0` `#000000`, `iris400` `#A99BFF`, `iris600` `#7563F2`), §2.8.1 row `color.brandFrost` `#F5F7FA`, §3.1 (Google Sans Flex axes and the OFL note), §8.2 (splash and first paint, the web inline neutral mark), §8.7 step 5 (the art-style picker: nine crops, their accessible names and order), §8.25.1 and §8.25.2 step 4 (the "App icon follows the skin" switch, off by default, and when the icon changes), §9.4.2 "Rain on glass" (the static droplet texture `frontend/public/glass/droplets.webp`, 6 drops, 60 % opacity), §15.5 and §15.6 (rows "App icon", "PWA manifest, startup images, OG image, install page", "Taste": the eleven `styles` ids), §15.10 row G13, §15.11 ledger rows `@resvg/resvg-js`, `flutter_dynamic_icon_plus`, `flutter_native_splash`, `flutter_launcher_icons`.
6. `docs/redesign/cinematic/DESIGN.md` §8.7 row "4 Art style" (Cinematic's nine crops, their file names `01-painted.webp` to `09-chibi.webp`, 600 × 600 WebP at quality 80, ≤ 60 KB, `LICENSE.md` beside the files, the typographic fallback), §12.3 "Per-skin icon" (Android alias behaviour with `flutter_dynamic_icon_plus`), §8.0.7 (what `glass_available` gates).
7. `docs/redesign/00-baseline.md`.
8. Code to read, not rewrite: `mobile/android/app/src/main/AndroidManifest.xml`, `mobile/ios/Runner.xcodeproj/project.pbxproj` (the three `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;` lines), `mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json` (as written by shared/04), `design/contract.json` (`flags.glass_available`), `design/tokens/glass.json` (shared/01).

## Skills to invoke

- `superpowers:writing-plans` before any code (the commit plan below is the skeleton).
- `superpowers:subagent-driven-development` to run it (or `superpowers:executing-plans` inline); verify subagent output against `git status` and the rendered PNGs, never against a report.
- `impeccable` (critique and polish modes) and `taste-skill:taste-skill` on the proof sheet: the slabs must read as three pieces of glass bending the aurora, not as grey plastic; the column must survive at 16 px; the meniscus must be visible at 60 pt.
- `frontend-design` for `favicon-glass.svg` (light and dark tab strips, 16 and 32 px).
- `superpowers:verification-before-completion` before claiming done.

## Guardrails

- **Track rule.** The shared track owns `design/` and `brand/` plus the generated files they write into `frontend/`, `mobile/` and `backend/media/`. In this step you may create or change only the paths in "File layout" and `docs/redesign/proof/shared-05/**`. Stage with explicit `git add <path>`; never `git add -A`, `git add .` or `git commit -a`.
- **Do not register the alternate icon.** While `flags.glass_available` is `false` you must not edit `AndroidManifest.xml`, `Info.plist` or `project.pbxproj`, must not add `flutter_dynamic_icon_plus` code, and must not change `ASSETCATALOG_COMPILER_*` settings. Release/01 applies `brand/glass/icon-registration.md`.
- Never edit `backend/connectors/` or backend code. Never touch production containers or `/srv/manhwamaniacs/{app,data}`.
- **RAM guard.** Before every heavy command (`npm install`, `npm run typecheck`, `npm run test`, `npm run build`, `flutter analyze`, `flutter test`, the Playwright capture):
  ```bash
  avail=$(free -m | awk '/^Mem:/{print $7}'); echo "available ${avail} MB"; [ "$avail" -ge 1024 ] || { echo "STOP: under 1 GB available"; exit 1; }
  ```
  Never start a command under 1024 MB available; never run two at once; never run `flutter build` or Gradle.
- **Git.** Branch `feat/vps-slim-source-native`. One commit per working step, `git push origin feat/vps-slim-source-native` after each; before pushing any commit that touches `frontend/`, `npm run lint` and `npm run build` must pass. No Claude or AI attribution anywhere (no `Co-Authored-By`, no "Generated with" line, no AI author). Never commit secrets or `.claude/`.
- Never write outputs to a folder named `out/` (the root `.gitignore` ignores it); intermediates go to `brand/glass/export/`.
- If a message arrives mid-task that changes the task, finish this file's scope first and report the message.

## Decisions this step makes

1. **iOS alternate icon name is `AppIcon-Glass`, not `GlassIcon`.** The plan entry says "iOS CFBundleAlternateIcons 'GlassIcon'"; glass §12.2, revised after verification (glass/verify STACK-25), uses the asset-catalog method: `ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = YES`, `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES = AppIcon-Glass`, `setAlternateIconName("AppIcon-Glass")`. With that method `actool` writes the `CFBundleAlternateIcons` entry into the built `Info.plist` itself, so no hand-written plist entry exists. The Android aliases keep the plan's names `.CinematicIcon` and `.GlassIcon`.
2. **Same-name fallback.** `mobile/ios/Runner/AppIcon-Glass.icon` (iOS 26) and `mobile/ios/Runner/Assets.xcassets/AppIcon-Glass.appiconset` (iOS 18 and earlier) share the name `AppIcon-Glass`; Xcode 26 uses the `.icon` where supported and falls back to the same-named asset-catalog set.
3. **The Glass PNG fallback set is written by `brand/glass/export.mjs`, not by `flutter_launcher_icons`.** Glass §12.2 names `flutter_launcher_icons` for it, but that tool always writes the primary set (`AppIcon.appiconset`, `ic_launcher`, `ic_launcher_foreground`, `mipmap-anydpi-v26/ic_launcher.xml`) and rewrites the manifest icon, which would overwrite Cinematic's. The export writes `AppIcon-Glass.appiconset` and the `ic_launcher_glass*` resources directly.
4. **Registration is written, not applied** (Guardrails): `brand/glass/icon-registration.md` holds the exact Android, iOS and CI edits for release/01, and `brand/check.mjs` fails if any of them appears while `glass_available` is false, and fails if they are missing once it is true.
5. **Wordmark capsule.** Glass §12.1 puts the M's in "a glass capsule (corner radius 40 % of its width)" but gives only the column box (x 240 to 784, y 192 to 832). A capsule of that exact box would cut the M's stem ends at its rounded corners, so the capsule is the column box grown by 96 units on every side: x 144 to 880, y 96 to 928, corner radius 294.4 (40 % of its 736 width). The engraving values not in §12.1 (capsule film, rim) are set in item 2 below.
6. **Leading.** §12.1 gives leading 0.84 and a column whose baselines are 352 units apart (y 480 and 832). The column geometry wins; the lowercase is sized so its cap height equals the M's 288 units (Google Sans Flex cap height 1432 of 2000 units per em, so 402.23 units), which makes the effective leading 0.875. Report it.
7. **No Glass PWA icons.** Glass §12.2's web bullet lists a Glass PNG set, but its own "Per skin" bullet and §15.6 make the PWA manifest and its icons shared and skin-neutral (owned by shared/04). Only `favicon-glass.svg` ships. The "PWA 40 % safe circle" rule stays on the shared `maskable-512.png`; the Glass section of the check re-runs it.
8. **Favicon ground and small variant.** A Frost mark disappears on a light tab strip, so `favicon-glass.svg` draws on a 32 × 32 rounded square (radius 7.2) filled with the field gradient `#0A0F1F` → `#000000`. §12.2's "below 32 px a single M on the bar" is one file: an internal `@media (max-width: 31px)` rule swaps the column for the single-M variant.
9. **Art intake covers eleven ids.** Glass's nine crops (§12.7) and Cinematic's nine (§8.7) share seven styles; the server's `styles` enum is the union of eleven (glass §15.6 "Taste"). One commission of eleven masters of the same subject serves both skins: the intake writes Glass's 320 × 320 set and Cinematic's 600 × 600 set from the same master files.
10. **Colours come from the tokens:** `color.brandFrost` and `color.iris400` from `design/tokens/glass.json`, `color.paper.0` from `cinematic.json`, through `brand/lib/tokens.mjs`. The field and blob colours (`#0A0F1F`, `#8FD8FF`, `#A99BFF`, `#FF9ED8`) are brand constants of §12.2 and live in `brand/glass/mark.mjs`.

## Scope: what this step delivers, item by item

### 1. Construction module: `brand/glass/mark.mjs`

All masters and generated code import this one module. Geometry on the 1024 master (§12.1, origin top-left), every M a stroked centreline with `stroke-width` 88, round caps and round joins:

- **Top M** (band y 192 to 480): `(284, 436) → (284, 236) → (512, 386) → (740, 236) → (740, 436)`.
- **Bottom M** (band y 544 to 832): the same shifted down 352: `(284, 788) → (284, 588) → (512, 738) → (740, 588) → (740, 788)`.
- **Gutter bar / meniscus** (band y 480 to 544): the quadratic centreline `M 272 512 Q 512 530 752 512` stroked 64 with round caps, so it spans x 240 to 784, is 64 thick and bows 9 units down in the middle (2 px at a 64 px cap height, §12.1 and §12.2).
- **Column box** x 240 to 784, y 192 to 832 (checked by computing each shape's stroked extent).
- **Capsule** (Decision 5) x 144 to 880, y 96 to 928, `rx` 294.4.
- **Field**: a vertical linear gradient `#0A0F1F` (y 0) → `#000000` (y 1024); three radial gradients, each from its colour at the centre to transparent at r: `#8FD8FF` at (240, 700) r 260, `#A99BFF` at (420, 860) r 300, `#FF9ED8` at (160, 940) r 220; the blob group at opacity 0.45 through `feGaussianBlur stdDeviation="180"` with a user-space filter region x −512, y −512, 2048 × 2048 so the blur is not clipped.

Also export the lowercase settings: Google Sans Flex `{wght: 620, ROND: 100, opsz: 144, GRAD: 0, wdth: 100, slnt: 0}`, size 402.23, tracking −0.020 em, Frost; and the single-line settings `{wght: 640, ROND: 100, opsz: 20, GRAD: 0, wdth: 100, slnt: 0}`, tracking −0.020 em. Add the font id `gsf` to `brand/lib/fonts.mjs`: `ofl/googlesansflex/GoogleSansFlex[GRAD,ROND,opsz,slnt,wdth,wght].ttf` and `ofl/googlesansflex/OFL.txt` at the same pinned commit `23e54b51ddffbc7713c583748e3bd86f62b1fa4a` (measured: 2000 units per em, cap height 1432; axes `opsz` 6 to 144, `wdth` 25 to 151, `wght` 1 to 1000, `GRAD` 0 to 100, `ROND` 0 to 100, `slnt` −10 to 0).

### 2. SVG masters in `brand/glass/`

Outlines and geometry only, no `<text>`. Masks (never `clipPath`, which ignores strokes) whenever a stroked shape limits another.

| File | Content |
|---|---|
| `field.svg` | 1024 canvas: the field of item 1 |
| `top-m.svg`, `gutter-bar.svg`, `bottom-m.svg` | 1024 canvas, transparent, one slab each, flat Frost `#F5F7FA`. These are the Icon Composer layers: the system draws the glass |
| `icon.svg` | The flattened iOS 1024 composition: `field.svg`, then for each slab from back to front (bottom M, gutter bar, top M): (a) a neutral shadow, the slab in `#000000` offset 12 units down, `feGaussianBlur stdDeviation="20"`, opacity 0.5; (b) a rim, the centreline stroked 6 units wider than the slab (94 for the M's, 70 for the bar) in `rgba(255,255,255,0.40)`, for the top M a linear gradient from `rgba(255,255,255,0.55)` at (240, 192) to `rgba(255,255,255,0.20)` at (784, 480) (the specular edge along its top-left, §12.2); (c) refraction, `<use href="#field">` transformed `translate(512 512) scale(1.06) translate(-512 -512) translate(-10 -14)` (the bar: `scale(1.10)` and `translate(0 9)`, so its meniscus bends the field more), through `feGaussianBlur stdDeviation="6"` plus `feComponentTransfer` linear slope 1.35 on R, G and B, masked by the slab; (d) a Frost film over the slab at opacity 0.22 (bottom M), 0.10 (bar, the clear layer) and 0.30 (top M) |
| `icon-dark.svg` | Transparent: the three slabs in Frost at opacity 0.85 with their rims, no field, no refraction (iOS 18 dark: "the mark only") |
| `icon-tinted.svg` | Opaque `#000000`; top M `#FFFFFF`, bar `#FFFFFF` at 0.55, bottom M `#FFFFFF` at 0.80 (iOS 18 tinted: grayscale mark) |
| `icon-foreground.svg` | Android foreground, 1024 canvas = 108 dp, transparent: the slabs exactly as in `icon.svg` (shadow, rim, refraction of the field, film), the whole group scaled by 0.69718 about (512, 512) so the column box becomes 379.26 × 446.20 (160 × 188 px at xxxhdpi, §12.2) |
| `icon-monochrome.svg` | Same geometry, the column silhouette (three slabs) in `#FFFFFF` |
| `neutral-mark.svg` | `viewBox="240 192 544 640"`: the three slabs flat Frost (the mark the first frame fades in at 96 px tall, §12.3) |
| `column-small.svg` | `viewBox="240 192 544 640"`: the two M's in Frost with the bar omitted, so the meniscus reads as a gap (the MM column below 32 px, §12.1) |
| `wordmark-stacked.svg` | The capsule (Decision 5) filled `rgba(245,247,250,0.08)` with a 4.5-unit rim `rgba(255,255,255,0.30)`; inside it the two M's engraved: Frost fill, an inner shadow `rgba(0,0,0,0.45)` offset 9 units down-right and blurred 9 (2 px at a 64 px cap height, scaled by 288 / 64 = 4.5), and a 4.5-unit specular edge `rgba(255,255,255,0.55)` on the top-left (a gradient stroke fading to 0 by the middle of each M); the bar as a clear seam, `rgba(245,247,250,0.18)` with a 2.25-unit `rgba(255,255,255,0.55)` line on its upper edge. Lowercase "anhwa" on baseline y 480 and "aniacs" on baseline y 832, both starting at x 920, in Frost with item 1's settings (Decision 6). `viewBox` tight around capsule and lowercase |
| `wordmark-stacked-flat.svg` | The same lockup without capsule and engraving: `column-small.svg`'s M's in Frost with the meniscus gap, and the lowercase |
| `wordmark-line.svg` | "ManhwaManiacs" on one line at size 100 units with the single-line settings, both M's in `iris400` `#A99BFF`, the rest Frost |
| `favicon.svg` | Decision 8: `viewBox="0 0 32 32"`, the rounded field square; group `.full` = `neutral-mark.svg` scaled to 24 units tall, centred; group `.small` = the top M plus the bar (the "single M on the bar", source box x 240 to 784, y 192 to 544) scaled to 26 units wide, centred; `<style>.small{display:none}@media (max-width: 31px){.full{display:none}.small{display:inline}}</style>` |
| `droplets.svg` | 480 × 480 transparent (the tier-B texture at 3× for a 160 × 160 CSS px tile, glass §9.4.2): six drops at (72, 96) r 15, (208, 60) r 9, (356, 132) r 18, (120, 280) r 12, (300, 330) r 10.5, (410, 420) r 13.5; each a radial gradient `rgba(255,255,255,0.06)` at the centre, `rgba(255,255,255,0.02)` at 70 %, `rgba(0,0,0,0.22)` at the rim (a hemispherical lens edge), plus a specular dot of radius 3 (1 px at 3×) in `rgba(255,255,255,0.35)` offset (−0.35 r, −0.35 r) from the centre (the light from the top-left) |

`brand/glass/mark.json`: the geometry of item 1 as data (column centrelines, stroke widths, bar curve, capsule, field stops and blobs, Frost and iris400 hex) for the generated code in item 3.

### 3. `brand/glass/export.mjs`: renders and generated files

`node brand/glass/export.mjs` writes every row below and `brand/glass/export/manifest.json` (paths and pixel sizes). A second run must leave `git status` clean.

| Output | Size | From |
|---|---|---|
| `brand/glass/export/field-1024.png` | 1024, opaque | `field.svg` |
| `brand/glass/export/icon-ios-1024.png` | 1024, opaque RGB (colour type 2) | `icon.svg` |
| `brand/glass/export/icon-ios-dark-1024.png` | 1024, RGBA | `icon-dark.svg` |
| `brand/glass/export/icon-ios-tinted-1024.png` | 1024, opaque RGB, greyscale | `icon-tinted.svg` |
| `brand/glass/export/android-foreground-1024.png`, `android-monochrome-1024.png` | 1024, RGBA | `icon-foreground.svg`, `icon-monochrome.svg` |
| `mobile/ios/Runner/Assets.xcassets/AppIcon-Glass.appiconset/AppIcon-Glass-1024.png`, `-dark.png`, `-tinted.png` and `Contents.json` | 1024 | the three iOS renders; `Contents.json` below |
| `mobile/ios/Runner/AppIcon-Glass.icon/icon.json` and `Assets/field.png`, `Assets/bottom-m.svg`, `Assets/gutter-bar.svg`, `Assets/top-m.svg` | 1024 canvas | `field-1024.png` and the three slab SVGs; `icon.json` below |
| `mobile/android/app/src/main/res/drawable-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher_glass_foreground.png`, `ic_launcher_glass_background.png`, `ic_launcher_glass_monochrome.png` | 108, 162, 216, 324, 432 | the two Android renders and `field-1024.png`, resized |
| `mobile/android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher_glass.png` | 48, 72, 96, 144, 192 | `icon-ios-1024.png`, resized (the pre-API-26 launcher icon) |
| `mobile/android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_glass.xml` | xml | below |
| `frontend/public/favicon-glass.svg` | vector | `favicon.svg`, whitespace between tags stripped |
| `frontend/public/glass/droplets.webp` | 480, lossless with alpha | `droplets.svg` |
| `frontend/src/skins/glass/mark.generated.ts` | code | `mark.json` |
| `mobile/lib/skins/glass/brand_mark.g.dart` | code | `mark.json` |

`AppIcon-Glass.appiconset/Contents.json`:

```json
{
  "images" : [
    { "filename" : "AppIcon-Glass-1024.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" },
    { "appearances" : [ { "appearance" : "luminosity", "value" : "dark" } ], "filename" : "AppIcon-Glass-1024-dark.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" },
    { "appearances" : [ { "appearance" : "luminosity", "value" : "tinted" } ], "filename" : "AppIcon-Glass-1024-tinted.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
```

`AppIcon-Glass.icon/icon.json` (groups are written front to back, the first group drawn on top, as Icon Composer writes them; glass §12.2: Liquid Glass on, translucency 0.5, specular on, neutral shadow, the bar clear; tinted: the three layers as a grayscale silhouette, the field hidden):

```json
{
  "fill" : { "linear-gradient" : [ "extended-srgb:0.03922,0.05882,0.12157,1.00000", "extended-srgb:0.00000,0.00000,0.00000,1.00000" ] },
  "groups" : [
    { "name" : "top-m", "lighting" : "individual", "specular" : true,
      "shadow" : { "kind" : "neutral", "opacity" : 0.5 }, "translucency" : { "enabled" : true, "value" : 0.5 },
      "layers" : [ { "name" : "top-m", "image-name" : "top-m.svg", "glass" : true,
        "fill-specializations" : [ { "value" : { "solid" : "extended-srgb:0.96078,0.96863,0.98039,1.00000" } }, { "appearance" : "tinted", "value" : { "solid" : "extended-gray:1.00000,1.00000" } } ],
        "position" : { "scale" : 1, "translation-in-points" : [ 0, 0 ] } } ] },
    { "name" : "gutter-bar", "lighting" : "individual", "specular" : true,
      "shadow" : { "kind" : "neutral", "opacity" : 0.5 }, "translucency" : { "enabled" : true, "value" : 0.9 },
      "layers" : [ { "name" : "gutter-bar", "image-name" : "gutter-bar.svg", "glass" : true, "opacity" : 0.35,
        "fill-specializations" : [ { "value" : { "solid" : "extended-srgb:0.96078,0.96863,0.98039,1.00000" } }, { "appearance" : "tinted", "value" : { "solid" : "extended-gray:1.00000,0.55000" } } ],
        "position" : { "scale" : 1, "translation-in-points" : [ 0, 0 ] } } ] },
    { "name" : "bottom-m", "lighting" : "individual", "specular" : true,
      "shadow" : { "kind" : "neutral", "opacity" : 0.5 }, "translucency" : { "enabled" : true, "value" : 0.5 },
      "layers" : [ { "name" : "bottom-m", "image-name" : "bottom-m.svg", "glass" : true,
        "fill-specializations" : [ { "value" : { "solid" : "extended-srgb:0.96078,0.96863,0.98039,1.00000" } }, { "appearance" : "tinted", "value" : { "solid" : "extended-gray:1.00000,0.80000" } } ],
        "position" : { "scale" : 1, "translation-in-points" : [ 0, 0 ] } } ] },
    { "name" : "field", "specular" : false,
      "shadow" : { "kind" : "none", "opacity" : 0 }, "translucency" : { "enabled" : false, "value" : 0 },
      "layers" : [ { "name" : "field", "image-name" : "field.png", "glass" : false,
        "opacity-specializations" : [ { "value" : 1 }, { "appearance" : "tinted", "value" : 0 } ],
        "position" : { "scale" : 1, "translation-in-points" : [ 0, 0 ] } } ] }
  ],
  "supported-platforms" : { "squares" : "shared" }
}
```

`mipmap-anydpi-v26/ic_launcher_glass.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_glass_background" />
    <foreground android:drawable="@drawable/ic_launcher_glass_foreground" />
    <monochrome android:drawable="@drawable/ic_launcher_glass_monochrome" />
</adaptive-icon>
```

These resources and the asset-catalog set are inert until registration (no manifest, alias or build-setting references them).

**Generated code** (header `GENERATED by brand/glass/export.mjs — do not edit`):
- `frontend/src/skins/glass/mark.generated.ts`: `export const GLASS_MARK = { viewBox: "240 192 544 640", stroke: 88, topM: [[284, 436], [284, 236], [512, 386], [740, 236], [740, 436]], bottomM: [[284, 788], [284, 588], [512, 738], [740, 588], [740, 788]], bar: { d: "M 272 512 Q 512 530 752 512", stroke: 64 }, capsule: { x: 144, y: 96, width: 736, height: 832, radius: 294.4 }, frost: "#F5F7FA", iris400: "#A99BFF" } as const;` (web/29 builds the inline neutral mark and the Droplet lens from it).
- `mobile/lib/skins/glass/brand_mark.g.dart`: `import 'dart:ui';` and `abstract final class GlassMarkGeometry` with `static const Rect column = Rect.fromLTRB(240, 192, 784, 832)`, `static const double stroke = 88`, `static const double barStroke = 64`, `static const List<Offset> topM = [...]`, `bottomM`, `static Path bar() => Path()..moveTo(272, 512)..quadraticBezierTo(512, 530, 752, 512);`, `static const Color frost = Color(0xFFF5F7FA)`, `static const Color iris400 = Color(0xFFA99BFF)`. Because `**/*.g.dart` is excluded from the analyzer, add `mobile/test/skins/glass/brand_mark_test.dart`: the stroked extents of `topM`, `bottomM` and `bar()` lie inside `column` (± 1), and `bar()` bows 9 units (sample the midpoint).

### 4. `brand/glass/icon-registration.md` (applied by release/01, not now)

Write the exact edits, each with the file, the anchor and the text to insert:

- **Android** (`mobile/android/app/src/main/AndroidManifest.xml`): remove the MAIN/LAUNCHER `<intent-filter>` from `.MainActivity` (keep the activity, `android:exported="true"` and its NormalTheme meta-data); add `<activity-alias android:name=".CinematicIcon" android:targetActivity=".MainActivity" android:label="Maniacs" android:icon="@mipmap/ic_launcher" android:roundIcon="@mipmap/ic_launcher" android:enabled="true" android:exported="true">` and `<activity-alias android:name=".GlassIcon" android:targetActivity=".MainActivity" android:label="Maniacs" android:icon="@mipmap/ic_launcher_glass" android:roundIcon="@mipmap/ic_launcher_glass" android:enabled="false" android:exported="true">`, each with the NormalTheme `<meta-data>` and the MAIN/LAUNCHER intent filter; add `<service android:name="com.solusibejo.flutter_dynamic_icon_plus.FlutterDynamicIconPlusService" android:stopWithTask="false" />`. Dart names: the plugin compares fully qualified class names, and `namespace` and `applicationId` are both `com.manhwamaniacs.reader`, so Glass is `setAlternateIconName(iconName: 'com.manhwamaniacs.reader.GlassIcon')` and Cinematic `'com.manhwamaniacs.reader.CinematicIcon'`, with empty `blacklistBrands`, `blacklistManufactures` and `blacklistModels` (cinematic §12.3); the plugin's service applies the alias when the task is removed, and glass §8.25.2 step 4 queues the call until `AppLifecycleState.paused`. Warn: moving the launcher to an alias makes existing home-screen shortcuts to `.MainActivity` stop working once; put that line in the release notes.
- **iOS** (`mobile/ios/Runner.xcodeproj/project.pbxproj`): a `PBXFileReference` for `AppIcon-Glass.icon` (`lastKnownFileType = folder.iconcomposer.icon; path = "AppIcon-Glass.icon"; sourceTree = "<group>";`) as a child of the Runner group, a `PBXBuildFile` for it in the Runner target's Resources build phase (24-character uppercase hex ids that do not already occur in the file), and in the Runner target's Debug, Release and Profile configurations `ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = YES;` and `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES = "AppIcon-Glass";` next to the existing `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;`. Dart: `setAlternateIconName(iconName: 'AppIcon-Glass')` for Glass and `iconName: null` for Cinematic (the primary `AppIcon`).
- **CI** (glass §12.2): `.github/workflows/ios-build.yml` adds `maxim-lobanov/setup-xcode@v1` with `xcode-version: '26.0'` before the build step on a runner image that carries Xcode 26; `codemagic.yaml` sets `xcode: 26.0`. The iOS dry run must then show `actool` compiling `AppIcon-Glass.icon`.
- **Gate**: apply all three only in the same change that sets `flags.glass_available` to `true`; `brand/check.mjs` enforces it (item 5).

### 5. `brand/check.mjs`: the Glass section

Add a "Glass brand" section beside shared/04's, stdlib only:

- Sizes: every entry of `brand/glass/export/manifest.json` exists at its size; the five `ic_launcher_glass_*` densities of each layer are 108, 162, 216, 324 and 432; the legacy mipmaps 48 to 192; the three appiconset PNGs are 1024; `droplets.webp` is 480 × 480.
- Alpha: `icon-ios-1024.png`, `icon-ios-tinted-1024.png`, `AppIcon-Glass-1024.png` and `AppIcon-Glass-1024-tinted.png` are colour type 2; `AppIcon-Glass-1024-dark.png` has transparent corners.
- 66 dp circle: in `android-foreground-1024.png` and `android-monochrome-1024.png` every pixel with alpha > 8 is within 312.89 units of the centre; in each `drawable-xxxhdpi/ic_launcher_glass_foreground.png` and `_monochrome.png` within 132 px.
- PWA 40 % circle: re-run shared/04's rule on `frontend/public/icons/maskable-512.png` (Decision 7).
- Icon Composer bundle: `icon.json` parses; its groups are named `top-m`, `gutter-bar`, `bottom-m`, `field` in that order; every `image-name` exists under `Assets/`; the three SVGs have `viewBox="0 0 1024 1024"`.
- Favicon: `frontend/public/favicon-glass.svg` has `viewBox="0 0 32 32"`, a `.full` and a `.small` group and the `max-width: 31px` rule.
- Registration gate (Decision 4): read `flags.glass_available` from `design/contract.json`; while `false`, fail if `AndroidManifest.xml` contains `activity-alias` or `FlutterDynamicIconPlusService`, or `project.pbxproj` contains `AppIcon-Glass` or `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES`; while `true`, fail if any of them is missing.
- Art intake: print `art intake: N of 11 masters missing (node brand/onboarding/styles/intake.mjs --check)` as a warning line; it never fails the check.

### 6. The art intake: `brand/onboarding/styles/`

Nothing here may be publisher art, a real series' cover or a real series' name; every file is CC0 1.0 or the project's own work, credited in About → Licences as "Onboarding art © ManhwaManiacs contributors, CC0" (glass §8.7, §12.7).

**`BRIEF.md`** for the owner, containing:
- The one subject for every crop: a young swordsman looking over his shoulder at a city at dusk, so only the style differs.
- Delivery: one master per style at `brand/onboarding/styles/masters/{id}.png` (sRGB PNG, square, at least 1200 × 1200, minimum 600 × 600; a non-square master is centre-cropped), one subject, one panel crop, no text, no signature, no watermark, no nudity or gore; line widths below are at the 320 px crop size, as glass §12.7 gives them, so scale them with the master.
- Rights: drawn by the owner or commissioned as work for hire and released under CC0 1.0; a generated draft may be used only if its licence allows CC0 release and nothing in it imitates a named artist (no artist names in prompts, no "in the style of" a person).
- The table of eleven ids (Glass order number, Cinematic order number, brief):

| id | Glass | Cinematic | Brief |
|---|---|---|---|
| `painted` | 1 | 1 | Full-colour webtoon painting: soft cel base, painted light, saturated teal-orange palette, no line art on the background |
| `cel` | 2 | 2 | Crisp cel shading: 2-tone shadows, 3 px black line, flat bright colours |
| `screentone` | 3 | 3 | Black-and-white screentone: 2 px ink line, dot tone at 20 % and 40 %, pure white paper |
| `manhua-3d` | 4 | 4 | Manhua 3D/CG: rendered figure, rim light, depth-of-field background |
| `watercolour` | 5 | — | Watercolour: wet edges, paper texture, muted blues and ochres, 1 px pencil line |
| `sketch` | 6 | 5 | Sketchy indie: loose 1 to 3 px graphite line, 2 flat spot colours |
| `retro` | 7 | 6 | Retro 1990s: thick 4 px line, airbrushed gradients, pastel sky |
| `pastel` | — | 7 | Soft pastel: 1 px coloured line (never black), flat pale peach `#FAD4C0`, mint `#CDEFE0` and lavender `#DCD0F5`, airbrushed blush, low contrast, no pure black anywhere |
| `noir` | — | 8 | High-contrast noir: pure black and pure white only, no mid greys, at least 60 % of the frame solid black, one hard rim light carving the silhouette, one slash of light across the city |
| `chibi` | 8 | 9 | Chibi comedy: 3-head-tall proportions, 3 px round line, candy palette, a sweat-drop symbol |
| `dark-realism` | 9 | — | Dark realism: heavy blacks, 1 px hatching, desaturated reds |

- Where each output goes (below) and that the Cinematic onboarding step shows typographic plates until all nine of its files exist (cinematic §8.7), while Glass's step 5 needs its nine.

**`LICENSE.md`**: a table with one row per id: `id`, `artist`, `date` (YYYY-MM-DD), `licence` (`CC0-1.0`), `source` (`own work`, `commission`, or `generated draft: <tool>`), `notes`; rows start empty. The intake copies this file beside every output folder.

**`intake.mjs`** (uses `sharp` from `brand/node_modules`):
- For every master present, centre-crop to square and write:
  - Glass (glass §12.7, order 01 to 09 = painted, cel, screentone, manhua-3d, watercolour, sketch, retro, chibi, dark-realism): `brand/onboarding/styles/{nn}-{id}.webp`, 320 × 320, sRGB, under 40,000 bytes, plus the same files at `frontend/public/onboarding/styles/glass/` and `mobile/assets/onboarding/styles/glass/` (a `glass/` subfolder, because Cinematic's files use the same names at a different size);
  - Cinematic (cinematic §8.7, order 01 to 09 = painted, cel, screentone, manhua-3d, sketch, retro, pastel, noir, chibi): `frontend/public/onboarding/styles/{nn}-{id}.webp` and `mobile/assets/onboarding/styles/{nn}-{id}.webp`, 600 × 600, at most 60,000 bytes.
  - Quality starts at 80 and steps down by 5 to a floor of 50 until the file fits its budget; a file that still does not fit stops the script with its name.
- `--check` (Node stdlib and `brand/lib/img.mjs` only): prints each missing master by path, with the skin or skins that need it (for example `missing brand/onboarding/styles/masters/watercolour.png (Glass 05)`), each master without a complete `LICENSE.md` row, and each output that is absent, the wrong size or over budget; exits 1 when anything is missing, 0 when all eleven are delivered and in sync.
- `brand/onboarding/styles/masters/.gitkeep` so the folder exists.

Do not declare these assets in `mobile/pubspec.yaml` and do not wire them into any screen (web/20, mobile/20, web/30, mobile/30 do).

### 7. Proof: `docs/redesign/proof/shared-05/`

`node brand/proof.mjs shared-05 brand/glass/export/manifest.json` (shared/04's script) with these sections: the field alone; the three slab layers; the flattened iOS icon under a 22.37 % rounded mask at 1024, 180 and 60 px, and the dark and tinted variants; the Android foreground over the field with the 66 dp circle drawn, and the monochrome layer tinted `#A8C7FA` on `#1F1F1F`; the neutral mark at 96 px; the column at 32, 24 and 16 px; the stacked wordmark at 1× and at its 28 px minimum height; the single-line wordmark at 12 px cap height; `favicon-glass.svg` at 16 and 32 px on a white and a `#202124` strip, next to Cinematic's `favicon.svg`; the droplet texture at 60 % over a white and over a black 160 × 160 tile; the Cinematic and Glass iOS icons side by side at 60 px. Screenshots `sheet-1440.png` and `sheet-390.png` (full page, 1440 × 900 and 390 × 844).

## File layout

Create or change only these:

```
brand/lib/fonts.mjs (add the gsf id)
brand/glass/mark.mjs, brand/glass/mark.json, brand/glass/export.mjs, brand/glass/icon-registration.md
brand/glass/{field,top-m,gutter-bar,bottom-m,icon,icon-dark,icon-tinted,icon-foreground,icon-monochrome,neutral-mark,column-small,wordmark-stacked,wordmark-stacked-flat,wordmark-line,favicon,droplets}.svg
brand/glass/export/*.png, brand/glass/export/manifest.json
brand/check.mjs (Glass section)
brand/onboarding/styles/BRIEF.md, brand/onboarding/styles/LICENSE.md, brand/onboarding/styles/intake.mjs, brand/onboarding/styles/masters/.gitkeep
mobile/ios/Runner/AppIcon-Glass.icon/icon.json, mobile/ios/Runner/AppIcon-Glass.icon/Assets/{field.png,bottom-m.svg,gutter-bar.svg,top-m.svg}
mobile/ios/Runner/Assets.xcassets/AppIcon-Glass.appiconset/{Contents.json,AppIcon-Glass-1024.png,AppIcon-Glass-1024-dark.png,AppIcon-Glass-1024-tinted.png}
mobile/android/app/src/main/res/drawable-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher_glass_{foreground,background,monochrome}.png
mobile/android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher_glass.png
mobile/android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_glass.xml
mobile/lib/skins/glass/brand_mark.g.dart, mobile/test/skins/glass/brand_mark_test.dart
frontend/public/favicon-glass.svg, frontend/public/glass/droplets.webp
frontend/src/skins/glass/mark.generated.ts
docs/redesign/proof/shared-05/**
```

Not in this step: `AndroidManifest.xml`, `Info.plist`, `project.pbxproj`, `pubspec.yaml`, any CI file, any layout or screen.

## Acceptance criteria

- [ ] `node brand/glass/export.mjs` writes every output in item 3; a second run leaves `git status` clean.
- [ ] The column's measured extents are x 240 to 784 and y 192 to 832 (± 1), the bar bows 9 units, the capsule is x 144 to 880, y 96 to 928 with radius 294.4 (printed by the export script).
- [ ] The blobs are at (240, 700) r 260 `#8FD8FF`, (420, 860) r 300 `#A99BFF`, (160, 940) r 220 `#FF9ED8`, opacity 0.45, blur 180, over `#0A0F1F` → `#000000`; the blur is not clipped at the canvas edge (look at `field-1024.png`).
- [ ] `icon.json` lists `top-m`, `gutter-bar`, `bottom-m` (each with `"glass": true`, translucency 0.5 for the M's and 0.9 for the bar, specular on, neutral shadow) and `field`; `Assets/` holds exactly the four named files.
- [ ] The Android foreground's column box is 379.26 × 446.20 on the 1024 master (160 × 188 at xxxhdpi) and inside the 66 dp circle; the monochrome layer has the same geometry.
- [ ] `favicon-glass.svg` shows the column at 32 px and the single M on the bar at 16 px on both tab-strip colours in the proof sheet.
- [ ] `node --test brand/lib/` passes; `node brand/check.mjs` exits 0 with every Glass rule passing and prints the art-intake warning line.
- [ ] Registration gate: with `flags.glass_available` false the check's gate rule passes, and `grep -c "activity-alias\|FlutterDynamicIconPlusService" mobile/android/app/src/main/AndroidManifest.xml` and `grep -c "AppIcon-Glass\|ALTERNATE_APPICON_NAMES" mobile/ios/Runner.xcodeproj/project.pbxproj` both print `0` (quote them).
- [ ] `brand/glass/icon-registration.md` contains the Android XML, the pbxproj entries and settings, the CI edits, the Dart icon names and the shortcut warning of item 4.
- [ ] `brand/onboarding/styles/BRIEF.md` states the subject, the delivery format, the rights rule and all eleven briefs; `LICENSE.md` has eleven empty rows; `node brand/onboarding/styles/intake.mjs --check` lists all eleven missing masters by path with their skins and exits 1 (the expected state until the owner delivers).
- [ ] Intake proof without owner art: copy two demo covers to `masters/painted.png` and `masters/noir.png` in a scratch run (`sharp` converts them), run `intake.mjs`, confirm the Glass 320 file is under 40,000 bytes and the Cinematic 600 file at most 60,000 bytes and both have the right size, then delete the scratch masters and outputs and confirm `git status` shows none of them.
- [ ] The droplet texture is 480 × 480 with alpha and six drops; nothing animates.
- [ ] Reduced motion: this step ships no animation; the Droplet reveal, its 200 ms reduced-motion cross-fade and Rain on glass are web/29, mobile/29, web/44 and mobile/44.
- [ ] Keyboard access on web: no interactive element is added; `npm run build` proves nothing else changed.
- [ ] 44 pt: the neutral mark and the column read at 44 px (the smallest control size where the mark may act as a button) in the proof sheet.
- [ ] Per-skin differences: Glass has its own favicon, alternate icon sets and wordmark; the PWA manifest, its icons, the startup images, `og.png`, the install page, the native frame and `ic_stat_mm` stay shared (glass §12.6, §15.6); "App icon follows the skin" stays off by default and nothing registers the alternate icon.
- [ ] `frontend`: `npm run lint` 0 errors 0 warnings, `npm run typecheck` passes, `npm run test` passes with a count not lower than before, `npm run build` passes.
- [ ] `mobile`: `flutter analyze` no issues; `flutter test` 0 failed, at least the count shared/04 reported plus `brand_mark_test.dart` (glass).
- [ ] `docs/redesign/proof/shared-05/sheet-1440.png` and `sheet-390.png` exist and you looked at both.
- [ ] Every commit touches only "File layout" paths, carries no AI attribution, and was pushed.

## Verification commands

From the repo root, one heavy command at a time, the RAM guard line before each heavy one.

```bash
git log --oneline -3 -- brand/
npm ls --prefix brand
node --test brand/lib/
node brand/glass/export.mjs
node brand/check.mjs; echo "brand check exit $?"
node brand/onboarding/styles/intake.mjs --check; echo "intake exit $? (1 expected until the owner delivers)"
node design/build.mjs --check; echo "design check exit $?"
grep -c "activity-alias\|FlutterDynamicIconPlusService" mobile/android/app/src/main/AndroidManifest.xml
grep -c "AppIcon-Glass\|ALTERNATE_APPICON_NAMES" mobile/ios/Runner.xcodeproj/project.pbxproj
git status --short

cd frontend
npm run lint
npm run typecheck
npm run test
npm run build
cd ..

cd mobile
/srv/manhwamaniacs/dev/flutter/bin/flutter analyze
/srv/manhwamaniacs/dev/flutter/bin/flutter test
cd ..

node brand/proof.mjs shared-05 brand/glass/export/manifest.json
```

Backend: no backend change. If `backend/.venv` exists, run `cd backend && .venv/bin/python -m pytest -q --no-header` and quote the summary; the CI `backend` job must stay green.

## Commit plan

1. `feat(brand): Glass column construction and masters` — `brand/lib/fonts.mjs`, `brand/glass/mark.mjs`, `mark.json`, every `brand/glass/*.svg`.
2. `feat(brand): Glass alternate icon sets and Icon Composer bundle (unregistered)` — `brand/glass/export.mjs`, `brand/glass/export/**`, `AppIcon-Glass.icon/**`, `AppIcon-Glass.appiconset/**`, the `ic_launcher_glass*` resources, `brand_mark.g.dart`, `brand_mark_test.dart`.
3. `feat(web): Glass favicon, droplet texture and mark geometry` — `frontend/public/favicon-glass.svg`, `frontend/public/glass/droplets.webp`, `frontend/src/skins/glass/mark.generated.ts` (lint and build before pushing).
4. `docs(brand): Glass icon registration for the Glass release` — `brand/glass/icon-registration.md`.
5. `ci(brand): Glass brand checks and the registration gate` — `brand/check.mjs`.
6. `feat(brand): onboarding art-style intake` — `brand/onboarding/styles/**`.
7. `docs(redesign): shared-05 brand proof sheet` — `docs/redesign/proof/shared-05/**`.

Push after each, with explicit `git add <path>` lists.

## Report back

Reply with:
- the acceptance checklist, each box ticked with evidence or explained;
- the ten decisions above, one line each, plus any further interpretation;
- the measured column, bar and capsule extents and the effective leading;
- output lines of `node --test brand/lib/`, `node brand/check.mjs`, `node brand/onboarding/styles/intake.mjs --check` (the eleven missing paths), `node design/build.mjs --check`, the two `grep -c` zeros, `npm run lint`, `npm run typecheck`, `npm run test` (count), `npm run build`, `flutter analyze`, `flutter test` (count), and pytest if run;
- the lowest `available` value `free -m` showed;
- the proof paths `docs/redesign/proof/shared-05/sheet-1440.png` and `sheet-390.png`;
- the pushed commit hashes;
- what the owner must do next: deliver the eleven masters and fill `LICENSE.md` per `brand/onboarding/styles/BRIEF.md`, then run `node brand/onboarding/styles/intake.mjs` and commit the outputs; optionally open `AppIcon-Glass.icon` in Icon Composer on a Mac to tune translucency;
- hand-offs: web/29 and mobile/29 use `GLASS_MARK` and `GlassMarkGeometry` for the neutral mark and the Droplet; web/06 and web/29 swap the favicon through `SKIN_FAVICONS`; web/44 uses `droplets.webp`; web/30 and mobile/30 read the Glass crops from `onboarding/styles/glass/`, web/20 and mobile/20 read Cinematic's from `onboarding/styles/`; mobile/39 codes the icon switch against the names in `icon-registration.md`; release/01 applies `icon-registration.md` together with `glass_available: true`;
- open issues.

**Next prompt file:** the shared track ends here. The next file in the series order is `docs/redesign/prompts/web/04-cinematic-primitives-core-and-reveals.md`.
