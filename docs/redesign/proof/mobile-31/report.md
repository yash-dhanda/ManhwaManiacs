# mobile/31 report: Glass Home

Done A to J. `tonight` left Glass `PENDING`. The plan's "gyroscope light" is built on the accelerometer gravity vector (glass 2.4.2 rule 5): `gravityProvider`, subscribed only while Home is visible and allowed (test: 1 sensor subscription, 0 after a tab switch, a pushed route, backgrounding, reduced motion).

Changes outside the Glass screen: `features/home` (`refreshFromServer`, `homeFeedChanged`, palette fields), `features/ai` (`undoNotInterested`, `restore`), `core/color/cover_palette.dart`, `clearLastFeeds`. Primitives (additive): `GlassPoster.radius/onLiftPhase/onMagnetChanged`, `GlassBarAction.iconBuilder`, `GlassScaffold.largeTitleOverride/refreshSliver`, `GlassRail.titleLeading/titleTrailing/belowHeader/aiSkeleton`, magnet registry owners. Fixes found on the way: `GlassLitCaustic` rebuilt during a sheet's build; a claimed press cancelled past the slop (poster throws never worked); `GlassWave` left items a hair below scale 1 (hit areas under 44); Continue stack clipped at large text.

Names for later steps: `continueWithRecap` (mobile/41), `GreetingStreakChip` (42), `liftProvider`, `GlassRecommendOrbs`, `scheduleLetter(container, ...)` (43), `refreshFromServer`, `clearLastFeeds`, `CoverPalette`.

Budget (layers/shapes): phone top 4/7, scrolled 2/5, sheet+toast 4/7, desktop rest 4/4, desktop window 5/5.

Captures map: home-*-phone/tablet/desktop prove the screen and frames; typing, drop, page2, tilt, caught-up, wrapped, letter prove the spotlight; ai-* the AI states; not-interested-throw, friend-orbs, pull-refresh, bell-swing, dock-menu the gestures; loading, new-profile, offline, error, rate-limited, at-risk, novel-mode the states; solid, contrast, reduced the variants; motion-timings the moves.

Open issues: the two spotlight controls are two glass buttons (glass 2.4.1 rule 2 wants one group; one group cannot mix tinted and clear finishes), so 4 layers at the top; AI cards are posters with a `why` line, not `WorldCard` (the throw needs a poster, 8.8); without a server palette the field uses the `ambient` colours, no on-device decode (2.1.8); a dropped poster returns to its origin rather than shrinking into the orb (9.3.4); the dismissed card's gap closes instantly (4.6); phone spotlight cover did not finish loading in one capture; web-31 captures were not present to compare.
