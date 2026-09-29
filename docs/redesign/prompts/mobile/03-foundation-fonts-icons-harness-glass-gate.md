# Mobile foundation 03: fonts, icons, screenshot harness, request limiter and the Glass device gate

## Goal

Finish the Flutter foundation so the first primitives step (mobile/04) can start drawing. Five pieces, none of which changes what a legacy user sees apart from one debug row:

1. **Fonts.** Bundle every face both skins use (Cinematic: Bodoni Moda, Archivo, Newsreader, IBM Plex Mono and the reading faces Literata, Source Serif 4 and Atkinson Hyperlegible Next; Glass: a `GoogleSansFlexMM` subset that keeps `ROND` and `GRAD`, Google Sans Code, Literata with italic, Atkinson shared) and register every `OFL.txt` with `LicenseRegistry`.
2. **Icons.** Declare the Phosphor TTFs and the `CineGlyphs` / `GlassGlyphs` fonts that shared/02 generated, and build one Icon-role widget per skin on shared/02's generated role tables.
3. **Screenshot harness.** Loop `test/screenshots/marketing_screenshots_test.dart` over both skins at phone 390 × 844 and tablet sizes with fake providers, writing proof PNGs into `docs/redesign/proof/`.
4. **Request limiter.** The sources limiter of cinematic §15.6 in `lib/core/network/`, wired into Dio, with its test.
5. **The Glass device gate** of stack-decision §1: `liquid_glass_widgets` 1.7.2 pinned exactly in its own isolated commit, the shader prewarm before `runApp` for Glass boots, a Diagnostics-only demo (floating tab bar plus a detented sheet over a scrolling rail, with a frosted `BackdropFilter` + `BackdropGroup` twin for comparison), an owner checklist for 120 Hz on the iPhone and the Android flagship, and the decision recorded for mobile/25.

## Read first

Read these before you plan. Section numbers are binding.

1. `docs/redesign/stack-decision.md` §1 "Conditions attached to the decision" (the Glass gate: a `liquid_glass_widgets` 1.7.2 floating tab bar plus a detented sheet over a scrolling rail at 120 Hz on the owner's iPhone, CI IPA → SideStore, and the Android flagship; if it janks or looks wrong on the iPhone, Flutter Glass uses `BackdropFilter` + `BackdropGroup` frost with a painted rim through the `SkinGlass` wrapper), §3 "Dependency changes", §4 risks 1 (the screenshot harness looped over both skins), 3, 4, 5, 11.
2. `docs/redesign/cinematic/DESIGN.md` §2.7 (Phosphor weights Light, Regular and Fill; sizes 16 / 20 / 24 / 32; Light is the default at 24 px, Regular at 20 px and below, Fill for active and selected; never Bold or Duotone; hit areas are the control's job; words first; the ten custom glyphs), §3.1 (families, axes, the Flutter delivery rule: variable TTFs, `fontWeight` plus `FontVariation('wght')`, `opsz` for Bodoni Moda and Newsreader, `wdth` for Archivo, `OFL.txt` through `LicenseRegistry.addLicense`), §3.4 (the five reading faces and their Flutter assets), §3.5 last paragraph (the Flutter family names `BodoniModa`, `Archivo`, `Newsreader`, `IBMPlexMono`, `Literata`, `SourceSerif4`, `AtkinsonHyperlegibleNext`), §15.3 ("Fonts: the five reading faces … added to `pubspec.yaml` `fonts:` with their `OFL.txt` files"), §15.6 (the "One request limiter for the sources bucket" bullet, binding word for word), §15.8 (the Flutter screenshot harness at phone and tablet sizes).
3. `docs/redesign/glass/DESIGN.md` §2.7 (Phosphor on Flutter without `phosphor_flutter`: the six TTFs and their family names `PhosphorRegular` … `PhosphorDuotone`; duotone as two constants with the secondary at opacity 0.20; the weight and size table: Regular 22 / 44 by default, Duotone for active or selected at rest, Fill on press, Regular 20 inline, Light 48–64 ornamental, Bold 14–16 dense), §2.4.3 (the tier table: T3 dock thickness 24, blur 10, saturate 1.8, fill `rgba(255,255,255,0.06)`, specular 0.40; T4 sheet thickness 40, blur 22, saturate 1.8, fill `rgba(28,28,34,0.52)`, specular 0.30, dispersion 0.6 px; the specular rim gradient and the inner light; the Flutter mapping to `LiquidGlassSettings`), §2.4.2 row `frosted` (+6 blur over the variant, no displacement or dispersion), §3.1 (Google Sans Flex subset `GoogleSansFlexMM.ttf`: Latin + Latin Extended-A + punctuation, `fonttools varLib.instancer slnt=0 wdth=100`, keeping `wght`, `opsz`, `ROND`, `GRAD`, budget ≤ 720 KB, drop Latin Extended-A before ever dropping an axis; `GoogleSansCode.ttf` 126,224 B as `GoogleSansCodeMM`; `Literata.ttf` + italic as `LiterataMM`; Atkinson shared), §15.3 (the "Shader prewarm", "Accessibility scope" (`GlassAccessibilityScope`, no `LiquidGlassWidgets.wrap()`), "Fonts" and "Packages" bullets; `GlassModalSheet` is not the final sheet, `smooth_sheets` is, mobile/25+), §15.7 (120 Hz target; the budget of 6 layers and 8 shapes), §15.8 "Device gate" bullet, §15.11 row `liquid_glass_widgets` (1.7.2 exact; fallback frost) and row `phosphor_flutter` ("not used").
4. `docs/redesign/inventory/00-decisions.md` (flagship-only, maximum effects; still honour OS reduced motion).
5. `docs/redesign/inventory/mobile.md` S34 (Diagnostics today), §6a "Prefetch and memory", G11.
6. `docs/redesign/00-baseline.md`.
7. `docs/redesign/prompts/web/03-foundation-reader-seam-limiter-proof.md` §B (the web limiter: API, rules and the exact test vectors; the mobile one matches it) and `docs/redesign/prompts/shared/02-icon-sets-and-custom-glyphs.md` (what it generated and its hand-offs to this step).
8. Upstream outputs (read, never hand-edit): `mobile/assets/fonts/{CineGlyphs.ttf,GlassGlyphs.ttf,phosphor/*.ttf}`, `mobile/lib/skins/cinematic/icons/{cine_glyphs,phosphor,icon_roles}.g.dart` (`CineIconRole`, `CineIconWeight { light, regular, fill }`, `cineIcons`), `mobile/lib/skins/glass/icons/{glass_glyphs,phosphor,icon_roles}.g.dart` (`GlassIconRole`, `GlassIconWeight { regular, duotone, fill, light, bold, thin }`, `glassIcons`, `glassDuotoneSecondary`), `brand/phosphor/SOURCE.md` (the Phosphor MIT licence text), `mobile/lib/skins/{cinematic,glass}/tokens.g.dart` (the family names the type roles use), mobile/01's `skins/`, `app/`, and mobile/02's `pubspec.yaml`, `test/audit/pubspec_pins_test.dart`.
9. Today's code you change: `mobile/pubspec.yaml`, `mobile/lib/main.dart`, `mobile/lib/core/network/dio_client.dart`, `mobile/lib/shared/providers/core_providers.dart`, `mobile/lib/core/diagnostics/performance_monitor.dart` (read only), `mobile/lib/features/settings/screens/diagnostics_screen.dart`, `mobile/test/screenshots/marketing_screenshots_test.dart`, `mobile/test/screenshots/support/{shot_harness,shot_network,shot_fixtures}.dart`, `mobile/test/support/test_overrides.dart`.

## Preconditions (stop and report if any fails)

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs
git branch --show-current                                                       # feat/vps-slim-source-native
ls mobile/lib/skins/skin_haptics.dart mobile/lib/skins/skin_audio.dart           # mobile/02 done
grep -n "audio_service: 0.18.19" mobile/pubspec.yaml                             # mobile/02's dependency commit landed
ls mobile/lib/skins/cinematic/icons/icon_roles.g.dart mobile/lib/skins/glass/icons/icon_roles.g.dart   # shared/02 done
ls mobile/assets/fonts/CineGlyphs.ttf mobile/assets/fonts/GlassGlyphs.ttf mobile/assets/fonts/phosphor/Phosphor-Duotone.ttf
grep -n "phosphor_flutter\|liquid_glass_widgets\|dependency_overrides" mobile/pubspec.yaml   # prints nothing
python3 --version                                                                # 3.14 on this box
```

## Skills to invoke

- `superpowers:writing-plans` first. Save the plan at `docs/redesign/proof/mobile-03/plan.md`, with the CI gate between the `liquid_glass_widgets` commit and the demo commit.
- `superpowers:subagent-driven-development` for A, B, C and D (independent), then `superpowers:executing-plans` for E (it waits on CI). Verify every slice against `git status` and `git diff`, never against a report.
- `superpowers:test-driven-development` for the limiter (write the vectors first), the Icon-role weight rules and the font-manifest checks.
- `impeccable` and `taste-skill:taste-skill` for the gate demo (it must look like the material it is testing, not like a debug page) and `taste-skill:taste-skill` for the icon widgets' defaults.
- `superpowers:verification-before-completion` before you claim anything is done.

## Track rules (every mobile step)

- Work in `mobile/` plus `docs/redesign/proof/mobile-03/`. Never touch `frontend/`, `backend/` (never `backend/connectors/`), `design/`, `brand/` or generated files. Tools that only build assets (the font venv, the google/fonts downloads) live outside the repository.
- Stage explicit paths only; never `git add -A`, `git add .` or `git commit -a`.
- Flutter is `/srv/manhwamaniacs/dev/flutter/bin/flutter`; `pub get`, `analyze` and `test` only after `free -m`, one at a time, never while a `next build` runs; never `flutter build` on this box.
- Proof goes to `docs/redesign/proof/mobile-03/` through the harness; device checks are a checklist for the owner.

## Scope, item by item

### A. Fonts (cinematic §3.1, §3.4, §15.3; glass §3.1, §15.3)

1. Download from the google/fonts commit `23e54b51ddffbc7713c583748e3bd86f62b1fa4a` (the commit shared/04 pins; raw URLs at a commit never change) into a scratch folder outside the repository, with base `https://raw.githubusercontent.com/google/fonts/23e54b51ddffbc7713c583748e3bd86f62b1fa4a/` and `[`, `,`, `]` URL-encoded as `%5B`, `%2C`, `%5D`. Copy each file under its new name into `mobile/assets/fonts/` (flat, no brackets in asset names). Sizes were checked on 2026-09-29; stop and report if a download differs by more than 1 %:

   | Asset (`mobile/assets/fonts/`) | Source path | Bytes |
   |---|---|---|
   | `BodoniModa.ttf` | `ofl/bodonimoda/BodoniModa[opsz,wght].ttf` | 162,104 |
   | `BodoniModa-Italic.ttf` | `ofl/bodonimoda/BodoniModa-Italic[opsz,wght].ttf` | 176,300 |
   | `Archivo.ttf` | `ofl/archivo/Archivo[wdth,wght].ttf` | 658,596 |
   | `Newsreader.ttf` | `ofl/newsreader/Newsreader[opsz,wght].ttf` | 451,664 |
   | `Newsreader-Italic.ttf` | `ofl/newsreader/Newsreader-Italic[opsz,wght].ttf` | 495,684 |
   | `IBMPlexMono-Regular.ttf`, `-Medium.ttf`, `-SemiBold.ttf` | `ofl/ibmplexmono/IBMPlexMono-{Regular,Medium,SemiBold}.ttf` | 135,580 / 136,704 / 140,216 |
   | `Literata.ttf` | `ofl/literata/Literata[opsz,wght].ttf` | 955,132 |
   | `Literata-Italic.ttf` | `ofl/literata/Literata-Italic[opsz,wght].ttf` | 902,728 |
   | `SourceSerif4.ttf` | `ofl/sourceserif4/SourceSerif4[opsz,wght].ttf` | 1,209,508 |
   | `SourceSerif4-Italic.ttf` | `ofl/sourceserif4/SourceSerif4-Italic[opsz,wght].ttf` | 855,432 |
   | `AtkinsonHyperlegibleNext.ttf` | `ofl/atkinsonhyperlegiblenext/AtkinsonHyperlegibleNext[wght].ttf` | 114,552 |
   | `AtkinsonHyperlegibleNext-Italic.ttf` | `ofl/atkinsonhyperlegiblenext/AtkinsonHyperlegibleNext-Italic[wght].ttf` | 123,916 |
   | `GoogleSansCode.ttf` | `ofl/googlesanscode/GoogleSansCode[wght].ttf` | 126,224 |
   | `GoogleSansFlexMM.ttf` | built by item 2 from `ofl/googlesansflex/GoogleSansFlex[GRAD,ROND,opsz,slnt,wdth,wght].ttf` (4,153,392) | ≤ 737,280 |

   Also download each family folder's `OFL.txt` into `mobile/assets/licenses/OFL-<Family>.txt` (`BodoniModa`, `Archivo`, `Newsreader`, `IBMPlexMono`, `Literata`, `SourceSerif4`, `AtkinsonHyperlegibleNext`, `GoogleSansFlex`, `GoogleSansCode`), and write the Phosphor MIT text from `brand/phosphor/SOURCE.md` to `mobile/assets/licenses/MIT-Phosphor.txt`. Write `mobile/assets/fonts/SOURCES.md`: one row per file with its URL, SHA-256 (`sha256sum`) and licence. Note in the report that cinematic §3.4's "≈ 1.9 MB" for the three extra reading faces is really about 4.2 MB with italics; the owner ruled flagship-only, so all ship.
2. `mobile/tool/fonts/subset_google_sans_flex.sh` (bash, `set -euo pipefail`), run with fonttools 4.66.0 from a venv outside the repo (`python3 -m venv /srv/manhwamaniacs/dev/design-ref/.venv-fonttools && /srv/manhwamaniacs/dev/design-ref/.venv-fonttools/bin/pip install fonttools==4.66.0`); the script takes the venv's `bin/` on `PATH`:
   - `fonttools varLib.instancer "$SRC" slnt=0 wdth=100 -o "$TMP/gsf.ttf"` (pins `slnt` and `wdth`, keeps `wght`, `opsz`, `ROND`, `GRAD`);
   - `pyftsubset "$TMP/gsf.ttf" --unicodes="U+0020-007E,U+00A0-00FF,U+0100-017F,U+2000-206F,U+20AC,U+2122,U+2190-2193,U+2212" --layout-features='*' --output-file=mobile/assets/fonts/GoogleSansFlexMM.ttf`;
   - if the result is larger than 737,280 bytes (720 KB), rebuild without `U+0100-017F` (Latin Extended-A); if it is still larger, exit 1 with the size. Never drop an axis (glass §3.1);
   - finish with a Python check through fontTools that the `fvar` axes are exactly `{wght, opsz, ROND, GRAD}` and print the final byte count.
3. `mobile/pubspec.yaml` `fonts:` (keep the five legacy families until the flip). Variable faces get no `weight:` line; italics get `style: italic`. The family names must equal what the generated token files use: run `grep -ho "family: '[A-Za-z0-9]*'" mobile/lib/skins/*/tokens.g.dart | sort -u` and, if a generated name differs from this list, declare the generated name and report it.

   ```yaml
   - family: BodoniModa                 # cinematic §3.1 display
     fonts: [{asset: assets/fonts/BodoniModa.ttf}, {asset: assets/fonts/BodoniModa-Italic.ttf, style: italic}]
   - family: Archivo                    # grotesk (Roman only)
     fonts: [{asset: assets/fonts/Archivo.ttf}]
   - family: Newsreader
     fonts: [{asset: assets/fonts/Newsreader.ttf}, {asset: assets/fonts/Newsreader-Italic.ttf, style: italic}]
   - family: IBMPlexMono
     fonts: [{asset: assets/fonts/IBMPlexMono-Regular.ttf, weight: 400}, {asset: assets/fonts/IBMPlexMono-Medium.ttf, weight: 500}, {asset: assets/fonts/IBMPlexMono-SemiBold.ttf, weight: 600}]
   - family: Literata                   # Cinematic reading face
     fonts: [{asset: assets/fonts/Literata.ttf}, {asset: assets/fonts/Literata-Italic.ttf, style: italic}]
   - family: LiterataMM                 # Glass's name for the same two files (one copy ships)
     fonts: [{asset: assets/fonts/Literata.ttf}, {asset: assets/fonts/Literata-Italic.ttf, style: italic}]
   - family: SourceSerif4
     fonts: [{asset: assets/fonts/SourceSerif4.ttf}, {asset: assets/fonts/SourceSerif4-Italic.ttf, style: italic}]
   - family: AtkinsonHyperlegibleNext   # both skins
     fonts: [{asset: assets/fonts/AtkinsonHyperlegibleNext.ttf}, {asset: assets/fonts/AtkinsonHyperlegibleNext-Italic.ttf, style: italic}]
   - family: GoogleSansFlexMM
     fonts: [{asset: assets/fonts/GoogleSansFlexMM.ttf}]
   - family: GoogleSansCodeMM
     fonts: [{asset: assets/fonts/GoogleSansCode.ttf}]
   - family: CineGlyphs
     fonts: [{asset: assets/fonts/CineGlyphs.ttf}]
   - family: GlassGlyphs
     fonts: [{asset: assets/fonts/GlassGlyphs.ttf}]
   - family: PhosphorRegular            # glass §2.7, one copy for both skins (glass §15.6)
     fonts: [{asset: assets/fonts/phosphor/Phosphor.ttf}]
   - family: PhosphorThin
     fonts: [{asset: assets/fonts/phosphor/Phosphor-Thin.ttf}]
   - family: PhosphorLight
     fonts: [{asset: assets/fonts/phosphor/Phosphor-Light.ttf}]
   - family: PhosphorBold
     fonts: [{asset: assets/fonts/phosphor/Phosphor-Bold.ttf}]
   - family: PhosphorFill
     fonts: [{asset: assets/fonts/phosphor/Phosphor-Fill.ttf}]
   - family: PhosphorDuotone
     fonts: [{asset: assets/fonts/phosphor/Phosphor-Duotone.ttf}]
   ```

   Write it in the file's existing block style (one `- asset:` per line, as the legacy entries are), not in flow style. Add `assets/licenses/` under `flutter: assets:`.
4. `mobile/lib/app/font_licenses.dart`: `void registerFontLicenses()` calls `LicenseRegistry.addLicense(() async* { … })` once and yields one `LicenseEntryWithLineBreaks([name], await rootBundle.loadString(path))` per file, with the package names `Bodoni Moda`, `Archivo`, `Newsreader`, `IBM Plex Mono`, `Literata`, `Source Serif 4`, `Atkinson Hyperlegible Next`, `Google Sans Flex`, `Google Sans Code` and `Phosphor Icons`. `main()` calls it before `runApp`. The legacy About screen's licence page then lists them (Flutter's `showLicensePage`).
5. `mobile/test/screenshots/support/shot_harness.dart` `loadAppFonts()`: add every new family with its asset paths (the map mirrors `pubspec.yaml`, as its comment says).

### B. Icons (cinematic §2.7; glass §2.7)

6. `mobile/lib/skins/cinematic/icons/cine_icon.dart`: `class CineIcon extends StatelessWidget { const CineIcon(this.role, {super.key, this.size = 24, this.weight, this.selected = false, this.color, this.semanticLabel}); }`
   - weight resolution: an explicit `weight` wins; otherwise `selected` → `CineIconWeight.fill`; otherwise `size <= 20` → `regular`; otherwise `light` (Light at 24 and 32, Regular at 20 and 16);
   - sizes are 16, 20, 24 or 32 (`assert` in debug);
   - draws `Icon(cineIcons[role]![weight]!, size: size, color: color ?? IconTheme.of(context).color)`; with `semanticLabel` it is `Semantics(label: …, image: true)`, without one it is wrapped in `ExcludeSemantics` (icon-only buttons carry their own label and tooltip, cinematic §2.7 "Words first");
   - no hit area, no padding: the 44 / 48 hit area is the button's (mobile/04).
7. `mobile/lib/skins/glass/icons/glass_icon.dart`: `GlassIcon(role, {size = 22, GlassIconWeight? weight, bool selected = false, bool pressed = false, Color? color, String? semanticLabel})` and `PhosphorDuotoneIcon` (about 20 lines):
   - weight resolution: explicit `weight`; else `pressed` → `fill`; else `selected` → `duotone`; else `size <= 16` → `bold` (dense meta, 14–16); else `size >= 48` → `light` (ornamental, 48–64); else `regular`;
   - `duotone` draws `PhosphorDuotoneIcon`: a `Stack` of the secondary glyph (`glassDuotoneSecondary[role]`) at opacity 0.20 under the primary glyph, both in the same colour;
   - the Duotone → Fill press morph (spring cross-fade) is the Glass primitives' job (mobile/26); here `pressed` switches the weight at once;
   - the same semantics rule as `CineIcon`.
8. Boundary: `cine_icon.dart` imports only Flutter and `cinematic/icons/*.g.dart`; `glass_icon.dart` only Flutter and `glass/icons/*.g.dart`. `mobile/test/skins/import_boundary_test.dart` (mobile/01) already enforces the cross-skin rule; add one assertion that no file in `lib/` imports `package:phosphor_flutter`.

### C. The screenshot harness (stack risk 1; cinematic §15.8; glass §15.8)

9. `mobile/test/screenshots/support/skin_shots.dart`:

   ```dart
   class SkinShotSize { const SkinShotSize(this.name, this.logical, this.pixelRatio, this.padding); … }
   const kSkinShotSizes = [
     SkinShotSize('phone', Size(390, 844), 3.0, EdgeInsets.only(top: 47, bottom: 34)),
     SkinShotSize('tablet', Size(834, 1194), 2.0, EdgeInsets.only(top: 24, bottom: 20)),
   ];
   // Not in the default loop; a step asks for them by name when its layout needs them.
   const kSkinShotTabletWide = SkinShotSize('tablet-wide', Size(1024, 1366), 2.0, EdgeInsets.only(top: 24, bottom: 20)); // the ≥ 900 px rows of §8.0.9
   const kSkinShotLandscape = SkinShotSize('landscape', Size(844, 390), 3.0, EdgeInsets.only(left: 47, right: 47, bottom: 21)); // landscape phone, §8.0.9
   String? get proofDir => Platform.environment['MM_PROOF_DIR'];            // e.g. ../docs/redesign/proof/mobile-04
   List<ScreenId> get proofScreens;                                          // MM_PROOF_SCREENS=tonight,library … ; default [ScreenId.tonight]
   Future<void> captureSkinScreen(WidgetTester tester, {required SkinId skin, required ScreenId screen,
       required SkinShotSize size, String? location, List<Override> overrides = const []});
   Future<void> captureSkinWidget(WidgetTester tester, {required String name, required SkinShotSize size,
       required Widget child, List<Override> overrides = const [], bool disableAnimations = false, double textScale = 1.0});
   ```

   These sizes, plus one Glass constant, are the only proof sizes of the whole mobile track: every later step captures phones at 390 × 844 and tablets at 834 × 1194 through `kSkinShotSizes`, the ≥ 900 px tablet rows through `kSkinShotTabletWide` and landscape phones through `kSkinShotLandscape`. The one addition is `mobile/29`'s `kSkinShotDesktop` (`SkinShotSize('desktop', Size(1366, 1024), 2.0, EdgeInsets.only(top: 24, bottom: 20))`, outside the default loop), because the Glass desktop frame's 280 px sidebar starts at 1180 px, wider than any size here; do not add it in this step. `captureSkinWidget` is for what is not a route (the primitives gallery sections, a screen pumped with fixture providers in one state, an overlay held open): it sets the view like `captureSkinScreen`, pumps `ProviderScope(overrides: [...the same app-root helpers, ...overrides], child: MediaQuery(data: …copyWith(disableAnimations:, textScaler: TextScaler.linear(textScale)), child: RepaintBoundary(key: kSkinShotKey, child: child)))`, settles with `settleShot`, and writes `<proofDir>/<name>-<size.name>.png` (for example `buttons-phone.png`, `updates-aside-tablet-wide.png`) or rasterises and discards when `MM_PROOF_DIR` is unset. Proof runs always set `MM_PROOF_DIR`; `MM_WRITE_SHOTS` stays reserved for the legacy marketing screenshots, because it writes into `docs/screenshots/`, which the backend serves on the install page.

   `captureSkinScreen` sets `tester.view.physicalSize`, `devicePixelRatio` and `padding` (reset in `addTearDown`), pumps `ProviderScope(overrides: [sharedPrefsProvider …, skinIdProvider.overrideWithValue(skin), returnRouteProvider.overrideWithValue(location ?? <the screen's path with each :param filled from shot_fixtures>), …the helpers of test/support/test_overrides.dart the app root needs (authenticated auth, an active profile, an open profile session, noDownloadsStoreOverrides(), contentModeOverrides()), …kSkinShotOverrides[screen]?.call() ?? const [], …overrides], child: RepaintBoundary(key: kSkinShotKey, child: const SkinApp()))`, settles with `settleShot`, and then either writes `<proofDir>/<skin.name>-<screen.id>-<w>x<h>.png` with `writeShot(…, pixelRatio: size.pixelRatio)` or, when `MM_PROOF_DIR` is unset, rasterises and discards (the `maybeWriteShot` rule: an ordinary `flutter test` still proves every captured screen renders). It ends with `drainCacheTimers(tester)`. `kSkinShotOverrides` is an empty `Map<ScreenId, List<Override> Function()>`; each screen step adds its fixture overrides there.
10. `mobile/test/screenshots/marketing_screenshots_test.dart`: leave every existing marketing test untouched and add `group('skins', …)` that loops `for skin in [SkinId.cinematic, SkinId.glass]`, `for size in kSkinShotSizes`, `for screen in proofScreens`, one `testWidgets('$skin ${screen.id} ${size.name}', …)` per combination calling `captureSkinScreen`. With no environment variables that is 4 tests (Tonight, both skins, both sizes), which keeps the normal suite fast; a proof run sets `MM_PROOF_SCREENS` to the step's screens. The edition preview loops of mobile/18 reuse `captureSkinScreen`; the primitives gallery of mobile/04 and every later `mobile-NN` group use `captureSkinWidget` for non-route captures. Add one `testWidgets('captureSkinWidget writes <name>-<size>.png', …)` that captures a plain `ColoredBox` at `kSkinShotSizes.first` into a temporary `MM_PROOF_DIR` override (a `proofDirOverride` parameter on the helper, used only by this test) and checks the file name.

### D. The sources request limiter (cinematic §15.6)

11. `mobile/lib/core/network/request_limiter.dart`:

    ```dart
    enum RequestPriority { p0, p1, p2, p3 }
    class RequestLimiter {
      RequestLimiter({int capacity = 50, Duration window = const Duration(seconds: 60), int p3MinFree = 20,
          int p3MaxInFlight = 2, DateTime Function()? now, Timer Function(Duration, void Function())? createTimer});
      Future<LimiterTicket> acquire(RequestPriority p, {Future<void>? cancel});   // completes when the request may start
      Future<T> run<T>(RequestPriority p, Future<T> Function() task, {Future<void>? cancel});
      void release(LimiterTicket t);   // ends a P3's in-flight slot
      void refund(LimiterTicket t);    // a response served from a local cache costs nothing
      void pause(Duration d);          // after a 429: P2 and P3 wait until now + d
      int free();                      // capacity − starts within the window, floor 0
    }
    final sourcesLimiterProvider = Provider<RequestLimiter>((ref) => RequestLimiter());
    ```

    Rules, exactly as cinematic §15.6 and web/03: a **sliding window** (a log of start times; each slot frees 60 s after the request that took it; never a refilling bucket, which would admit up to 99 starts in one window and trip the server's 60 per minute); **P0** (the visible reader page and the next) and **P1** (user-initiated lists: browse, search, series, chapters) never wait and only record a start; **P2** (covers in view) waits until `free() >= 1` and no pause is active; **P3** (prefetch: manifests and pages ahead, first rows, the next chapter's manifest, novel chapters, dialogue crops, preview slates) waits until `free() >= 20`, fewer than 2 P3 requests are in flight, and no pause is active; waiters are served P2 before P3, first come first served within a priority; a completed `cancel` future removes a waiter; `run()` acquires, runs, releases in `finally`, and on a `DioException` with status 429 calls `pause(retryAfter ?? 12 s)` and, for P0 only, retries once after that delay. There is no hover dwell on the phones (the 150 ms dwell is the web's).
12. `mobile/lib/core/network/interceptors/sources_limiter_interceptor.dart`: for requests whose `options.path` starts with `/sources`, `onRequest` awaits `acquire(options.extra['mm.priority'] as RequestPriority? ?? RequestPriority.p1)` and stores the ticket in `options.extra`; `onResponse` and `onError` release it; on a 429 it parses `Retry-After` (delta seconds, or an HTTP date through `HttpDate.parse`) and calls `pause`. Register it in `createDioClient` (`mobile/lib/core/network/dio_client.dart`) before `ErrorInterceptor`, with the limiter passed from `core_providers.dart` as `ref.watch(sourcesLimiterProvider)`. Every existing call is P1, so nothing waits that did not wait before; the downloads queue keeps its own concurrency and window logic untouched. Covers (P2) and reader pages (P0) load through `cached_network_image` outside Dio; the steps that build `CinePoster` (mobile/04) and the reader chrome (mobile/12) call `acquire()` for them, and a cache hit never acquires.
13. `mobile/test/core/network/request_limiter_test.dart` with an injected clock and a manual timer queue (no real time): 50 starts inside 60 s leave `free() == 0` and the 51st P2 waits until the first start is 60 s old; P0 and P1 never wait, even at 0 free; a P3 waits while `free() < 20` and while 2 P3 are in flight; a 12 s pause holds P2 and P3 but not P0 or P1; a P0 whose task throws a 429 with `Retry-After: 5` retries once after 5 s; `refund` frees the slot; a cancelled waiter never starts; the regression case: across any 60 s window no more than 50 starts are admitted for P2 (drive 99 attempts and check every window). `mobile/test/core/network/sources_limiter_interceptor_test.dart`: a `/sources/…` request records a start and a `/library/…` request does not; a 429 with `Retry-After: 7` pauses P2 for 7 s; an HTTP-date `Retry-After` parses.

### E. The Glass device gate (stack-decision §1; glass §15.3, §15.8)

14. **Isolated dependency commit** (`build(mobile): pin liquid_glass_widgets 1.7.2 for the Glass gate`): add `liquid_glass_widgets: 1.7.2` (exact) to `mobile/pubspec.yaml`, run `flutter pub get`, append the resolved line to `docs/redesign/proof/mobile-03/pub-deps.txt`, update the pin list in `mobile/test/audit/pubspec_pins_test.dart`, commit those files alone, push, and wait until the `tests` workflow (including `android-apk`) and `build-ios` are green for it (read CI as described under Verification). If it fails, the stack's fallback applies (Flutter Glass uses frost only; record it in `glass-gate.md` and skip items 15–17's LIQUID half). The API to use is the resolved package in `~/.pub-cache/hosted/pub.dev/liquid_glass_widgets-1.7.2/lib/`; `/srv/manhwamaniacs/dev/design-ref/liquid_glass_widgets` is a newer clone, a reading aid only.
15. **Shader prewarm** `mobile/lib/skins/glass/glass_engine.dart`: `Future<void> ensureLiquidGlassReady()` awaits `LiquidGlassWidgets.initialize()` once per process (a static `Future` reused by every caller). `GlassSkin.prepare()` (mobile/01) now returns it, so a Glass boot initialises the shaders before `runApp` (mobile/01's `main` awaits `prepare()` for the boot skin) and a switch into Glass initialises them before the restart; Cinematic and legacy boots never load them (glass §15.3). `LiquidGlassWidgets.wrap()` is not used.
16. **The demo** `mobile/lib/skins/glass/gate/glass_gate_screen.dart` (a throwaway gate page inside the Glass folder, because only Glass code may import `liquid_glass_widgets`; mobile/25 replaces it with the "Glass calibration" page and deletes `skins/glass/gate/`), pushed with `Navigator.push` from a new row "Glass device gate" in the Diagnostics "Edition (debug)" section. It awaits `ensureLiquidGlassReady()` (a black frame until ready) and wraps its body in `GlassAccessibilityScope(reduceMotion: MediaQuery.disableAnimationsOf(context), reduceTransparency: false, child: …)`. Layout, on `#000000`:
    - a `CustomScrollView`: header "Glass device gate" (28 / 34, `w600`, `#F5F5F5`, padding 24); a 96 px band of a 16 px black-and-white checkerboard (to see refraction bend); then 8 rails, each a label (13 / 16 `w600`, `Color(0xA3FFFFFF)`) above a horizontal list of 24 posters 120 × 180, gap 8, radius 12, painted procedurally (poster *j* of rail *i*: a vertical gradient from `HSLColor(hue: (i × 45 + j × 15) % 360, s 0.70, l 0.50)` to `(hue + 40) % 360, s 0.80, l 0.25`; rail 3 is all `#FFFFFF`, rail 6 alternates checkerboard posters), with 120 px of bottom padding;
    - the floating tab bar: `GlassTabBar.minimizable` with `barHeight: 64`, `minimizedBarHeight: 50` (glass §15.3 `GlassDock`), four tabs Home, Library, Sources (drawn with `GlassIcon` roles for `house-simple`, `books`, `globe-hemisphere-west` from `glass_icon.dart`) and You (a 28 px circle with the letter Y), 16 px side margins and 12 px above the bottom safe inset; minimises on scroll down and restores on scroll up; T3 settings: `thickness 24, blur 10, saturation 1.8, glassColor Color(0x0FFFFFFF), lightIntensity 0.40, refractiveIndex 1.2, chromaticAberration 0`, `GlassQuality.premium` (use the parameter names the 1.7.2 source declares);
    - a 44 × 44 "Sheet" capsule top right opens `GlassModalSheet.show(… detents: {GlassSheetDetent.medium, GlassSheetDetent.large} …)` holding a 30-row list (rows 56 tall, text 17 / 22) with T4 settings `thickness 40, blur 22, saturation 1.8, glassColor Color(0x851C1C22), lightIntensity 0.30, chromaticAberration 0.35`. (The final Glass sheet is built on `smooth_sheets` from mobile/25 on; the gate measures the rendering cost of a detented liquid sheet.)
    - a segmented `LIQUID | FROST` switch under the header (each segment ≥ 44 tall): FROST draws the same bar and sheet shapes as `BackdropGroup` + `BackdropFilter.grouped` with `ImageFilter.compose(outer: <saturation 1.8 ColorFilter.matrix>, inner: ImageFilter.blur(sigmaX: 16, sigmaY: 16))` for the bar (T3 blur 10 + 6, glass §2.4.2 `frosted`) and σ 28 for the sheet (22 + 6), the same fills, and a painted rim: a 1 physical px stroke of `LinearGradient` at 135° with stops `rgba(255,255,255,S)` 0 %, `rgba(255,255,255,0.06)` 35 %, `rgba(255,255,255,0.02)` 65 %, `rgba(255,255,255,S × 0.55)` 100 % (S 0.40 bar, 0.30 sheet) plus the inner light (`inset 1 1` at `S × 0.35` white, `inset −1 −1` at 0.35 black) (glass §2.4.3);
    - an "Auto-fling" capsule: for 10 s it animates the vertical scroll to the end and back (2 s each way, `Curves.easeInOut`) while every rail scrolls horizontally, so each run is the same;
    - a readout pill top left (monospace 12 / 16 on `Color(0x99000000)`, radius 8): `FPS 119 · JANK 1.2 % · WORST 14 MS · LIQUID` from `performanceMonitorProvider` (start on enter, stop on leave, `setTargetRefreshRate` from the display mode as the Diagnostics screen does), updated every 500 ms;
    - every control ≥ 44 pt (48 dp on Android), with `Semantics` labels.
17. `mobile/test/skins/glass/glass_gate_screen_test.dart`: pumps the screen with the engine forced to FROST (fragment shaders do not run in `flutter_tester`) and checks the 8 rails, the tab bar's four tabs, the readout and the 44 / 48 minimum sizes; `ensureLiquidGlassReady()` is not called in the test (inject a completed future).
18. **Owner checklist and decision** `docs/redesign/proof/mobile-03/glass-gate.md`: the commit hash under test; setup (iPhone: update through SideStore to the build `ios-build.yml` published for that commit; Android flagship: the signed APK the owner builds; Android: Diagnostics → "Use the highest refresh rate everywhere" on); the runs (LIQUID with the sheet closed, LIQUID with the sheet at medium, FROST closed, FROST at medium; each is one Auto-fling of 10 s, then write down FPS, JANK and WORST from the readout); the visual checks (the rim is visible over black and over white posters, the checkerboard band bends under LIQUID glass, no white flash when the page opens, no flicker when the bar minimises, the sheet snaps between medium and large with no dropped frame you can see); **the pass rule**: on the iPhone, LIQUID passes when both LIQUID runs show FPS ≥ 115, JANK < 5 % and WORST < 16.7 ms with no visual fault; otherwise the decision is FROST (stack §1; the owner ruled flagship-only, so no third option exists). Android results are recorded for glass §15.7 but do not decide. End the file with one line `Decision: LIQUID`, `Decision: FROST`, or, until the owner has reported his numbers to you, `Decision: awaiting the owner's device pass (mobile/25 must not start before this line reads LIQUID or FROST)`. Ask the owner for the numbers in your report.

## File layout (create or change; nothing else)

```
mobile/assets/fonts/{BodoniModa,BodoniModa-Italic,Archivo,Newsreader,Newsreader-Italic,IBMPlexMono-Regular,IBMPlexMono-Medium,IBMPlexMono-SemiBold,Literata,Literata-Italic,SourceSerif4,SourceSerif4-Italic,AtkinsonHyperlegibleNext,AtkinsonHyperlegibleNext-Italic,GoogleSansCode,GoogleSansFlexMM}.ttf   new
mobile/assets/fonts/SOURCES.md, mobile/assets/licenses/*.txt               new
mobile/tool/fonts/subset_google_sans_flex.sh                               new
mobile/pubspec.yaml, mobile/pubspec.lock                                   change (fonts, licences, liquid_glass_widgets)
mobile/lib/app/font_licenses.dart                                          new
mobile/lib/main.dart                                                       change (registerFontLicenses)
mobile/lib/skins/cinematic/icons/cine_icon.dart                            new
mobile/lib/skins/glass/icons/glass_icon.dart                               new
mobile/lib/core/network/request_limiter.dart                               new
mobile/lib/core/network/interceptors/sources_limiter_interceptor.dart      new
mobile/lib/core/network/dio_client.dart, lib/shared/providers/core_providers.dart   change (wiring)
mobile/lib/skins/glass/glass_engine.dart                                   new
mobile/lib/skins/glass/glass_skin.dart                                     change (prepare)
mobile/lib/skins/glass/gate/glass_gate_screen.dart                         new (deleted by mobile/25)
mobile/lib/features/settings/screens/diagnostics_screen.dart               change (one row)
mobile/test/screenshots/support/{shot_harness,skin_shots}.dart             change / new
mobile/test/screenshots/marketing_screenshots_test.dart                    change (skins group)
mobile/test/skins/{fonts,icons}_test.dart                                  new
mobile/test/skins/glass/glass_gate_screen_test.dart                        new
mobile/test/core/network/{request_limiter,sources_limiter_interceptor}_test.dart   new
mobile/test/audit/pubspec_pins_test.dart, test/skins/import_boundary_test.dart     change
docs/redesign/proof/mobile-03/plan.md                                           new
docs/redesign/proof/mobile-03/{pub-deps.txt,glass-gate.md,*.png}            new
```

## Acceptance criteria

- [ ] Every font file of item 1 is in `mobile/assets/fonts/` with its SHA-256 in `SOURCES.md`; `GoogleSansFlexMM.ttf` is ≤ 737,280 bytes and its `fvar` axes are exactly `wght`, `opsz`, `ROND`, `GRAD`.
- [ ] `mobile/test/skins/fonts_test.dart` passes: every `family:` in `pubspec.yaml` has files that exist; every family named by `mobile/lib/skins/*/tokens.g.dart` and `icon_roles.g.dart` is declared; `loadAppFonts()` covers every declared family; `LicenseRegistry.licenses` yields the ten package names of item 4.
- [ ] `mobile/test/skins/icons_test.dart` passes: `CineIcon` at 24 uses `PhosphorLight`, at 20 `PhosphorRegular`, selected `PhosphorFill`, and a glyph role uses `CineGlyphs`; `GlassIcon` defaults to `PhosphorRegular` at 22, selected draws two glyphs with the secondary at opacity 0.20, pressed uses `PhosphorFill`, 14 uses `PhosphorBold`, 56 uses `PhosphorLight`; an icon without a label is excluded from semantics and one with a label is announced.
- [ ] `request_limiter_test.dart` and `sources_limiter_interceptor_test.dart` pass with the exact vectors of item 13; every existing network test still passes.
- [ ] `flutter test` (no environment variables) runs the 4 default skin captures; `MM_PROOF_DIR=../docs/redesign/proof/mobile-03 MM_PROOF_SCREENS=tonight,library,settings` writes 12 PNGs; `kSkinShotTabletWide`, `kSkinShotLandscape` and `captureSkinWidget` exist with the exact values of item 9, and the `captureSkinWidget` naming test passes.
- [ ] The `liquid_glass_widgets` commit is alone, pinned exactly, and CI (`tests` including `android-apk`, and `build-ios`) was green for it before the demo commit.
- [ ] Cinematic and legacy boots never call `LiquidGlassWidgets.initialize()` (a test with a counting fake for `ensureLiquidGlassReady` shows it is only reached from `GlassSkin.prepare()` and the gate screen).
- [ ] `glass-gate.md` exists with the checklist, the pass rule and a `Decision:` line in one of the three allowed forms.
- [ ] `flutter analyze`: no issues. `flutter test`: 0 failed, count ≥ your pre-change count plus the new tests.
- [ ] Hit targets: every gate control is ≥ 44 pt (iOS) / 48 dp (Android); icon widgets add no hit area of their own.
- [ ] Reduced motion: the gate page passes `reduceMotion` to `GlassAccessibilityScope`; Auto-fling still runs (it is a measurement, not decoration); nothing else here animates.
- [ ] Hardware keyboard: Tab reaches the gate page's segmented switch, Sheet, Auto-fling and the four tabs, with visible focus.
- [ ] Per-skin differences: `CineIcon` never offers Bold, Thin or Duotone; `GlassIcon` never renders Cinematic's glyph font; each skin's type families resolve to its own files, with Atkinson and Literata shared as one copy.
- [ ] Legacy parity: legacy screens are unchanged (the legacy font families stay declared; the only new legacy UI is the "Glass device gate" row).

## Verification

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs/mobile
F=/srv/manhwamaniacs/dev/flutter/bin/flutter
free -m && $F test 2>&1 | tail -3                    # BEFORE any change: record the count
bash tool/fonts/subset_google_sans_flex.sh <path to GoogleSansFlex[…].ttf>   # prints the byte count and the axes
free -m && $F pub get
free -m && $F analyze                                # baseline: No issues found!
free -m && $F test test/skins test/core/network test/audit test/screenshots
free -m && $F test 2>&1 | tail -3                    # full suite, 0 failed
free -m && MM_PROOF_DIR=../docs/redesign/proof/mobile-03 MM_PROOF_SCREENS=tonight,library,settings $F test test/screenshots/marketing_screenshots_test.dart --plain-name skins
```

Stop under 1,024 MB available; never alongside a `next build` (`pgrep -fa "next build"`); never `flutter build` here. Web and backend code do not change in this step; the CI `frontend` and `backend` jobs must stay green on every pushed commit.

**Reading CI.** With `gh` available: `gh run list --branch feat/vps-slim-source-native --limit 6`. Without it, the anonymous API at most once every 5 minutes (60 requests per hour per IP, shared with production's `mm-fetch-ios` timer): `https://api.github.com/repos/yash-dhanda/ManhwaManiacs/actions/runs?branch=feat/vps-slim-source-native&per_page=6`, then `/actions/runs/<id>/jobs`, and for a failed job `/check-runs/<job_id>/annotations`. Wait with a background poll loop or the Monitor tool, never a foreground sleep.

**Visual proof.** Open the 12 PNGs in `docs/redesign/proof/mobile-03/` (the Cinematic and Glass pending screens for Tonight, Library and Settings at 390 × 844 and 834 × 1,194; they prove the harness, the skin wiring and the fonts load, because the pending screen's text renders instead of boxes). Also save one screenshot of the gate page in FROST mode from its widget test (`glass-gate-frost-390x844.png`) and open it.

## Git

- Branch `feat/vps-slim-source-native`. Commits, one per working step: plan; font files and sources; subset script and `GoogleSansFlexMM.ttf`; pubspec fonts, licences and the harness font map; icon widgets; harness loop; limiter; limiter wiring; `liquid_glass_widgets` pin (alone, then wait for CI); prewarm and the gate page; checklist and proof. Push after each: `git push origin feat/vps-slim-source-native` (a green push also publishes the iPhone build the owner uses for the gate).
- Stage explicit paths only; never `git add -A`, `git add .` or `git commit -a`. Never commit the fonttools venv or the google/fonts downloads (they live outside the repository).
- No Claude or AI attribution anywhere (no `Co-Authored-By`, no "Generated with" line). Never commit secrets, `.env*` or `.claude/`.

## Guardrails

- Never edit `backend/connectors/`, `frontend/`, `design/`, `brand/`, generated files, or anything under `/srv/manhwamaniacs/{app,data}`; no Docker commands; never touch production containers.
- Never add `phosphor_flutter` (it cannot compile against `final class IconData`) and never force a dependency.
- RAM guard: `free -m` before every pub get, analyze, test and the subset run; stop under 1,024 MB available; one heavy command at a time.

## Report back

Reply with:
1. Done items by section (A–E) with commit hashes, and the CI run ids and conclusions for the `liquid_glass_widgets` commit.
2. Fonts: each file's byte count, the final `GoogleSansFlexMM.ttf` size and whether Latin Extended-A survived, and any family name you had to take from the generated files instead of item 3.
3. Test counts before and after (passed / failed / skipped), the `flutter analyze` result, and the default skin captures run by a plain `flutter test`.
4. The proof folder `docs/redesign/proof/mobile-03/` (the 12 harness PNGs, the gate FROST PNG, `glass-gate.md`), and the harness API later steps call (`kSkinShotSizes`, `kSkinShotTabletWide`, `kSkinShotLandscape`, `captureSkinScreen`, `captureSkinWidget`, `kSkinShotOverrides`).
5. The gate: the `Decision:` line as written, and a direct request to the owner to run `glass-gate.md` on the iPhone and the Android flagship and send back the four FPS / JANK / WORST readings per device.
6. The lowest `free -m` available figure you saw and open issues (for example a `liquid_glass_widgets` parameter name that differed from glass §2.4.3's mapping).

Next prompt in the mobile track: `docs/redesign/prompts/mobile/04-cinematic-primitives-core-and-reveals.md`. Next in the global order: `docs/redesign/prompts/backend/01-cover-ambient-and-palette.md`.
