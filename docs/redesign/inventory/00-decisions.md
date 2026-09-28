# Redesign decisions (owner answers, 2026-09-28) — binding for every concept

These override any default. Concepts that ignore them lose.

## Skins
- Two skins: **Cinematic** (dark cinematic: Netflix / Apple TV+ / Crunchyroll) and **Glass** (Apple Liquid Glass / visionOS depth).
- Picked in Settings; the app restarts; EVERYTHING changes: tokens, type, shapes, motion, transitions, component variants, navigation, layout, and screen implementations. Treat them as two near-separate apps on one shared data layer.
- Dark only, AMOLED `#000000` base. No light theme, no accent picker.
- Name "ManhwaManiacs" stays. Wordmark, icon, splash, and all other brand assets are new.
- Every element is redesigned, down to the smallest icon button. Do not compare with the current app.

## Required signature animations (Cinematic, reusable in Glass if it fits)
- Heading reveal: each letter fades in, slides up, and un-blurs, staggered (H3 section headers, hero banners). Responsive font size, tight tracking, smooth color transition on hover/state.
- Main headline typing reveal: one character every 50 ms.

## Reader references
- Manhwa: Webtoon app (vertical scroll, auto-hide chrome, next-chapter card).
- Novels: Apple Books / Kindle (paper themes, typography controls, page turns).
- Home: Netflix / Crunchyroll browse (hero spotlight, rails, continue reading).

## NEW features to design in (not built yet; give each full screens, entry points, states)
1. **AI home + recommendations** — personalized rails, "because you read X", similar series, a "previously on" recap before continuing a series or chapter. External AI API only. Design loading and "AI unavailable" states.
2. **Reading stats + streaks** — Wrapped-style yearly recap, chapters per day, time read, genre radar, streak flame, shareable stat cards (image export).
3. **Social for 2-3 users** — see what other accounts/profiles are reading (activity feed), reactions on chapters, shared collections, "recommend to" a friend, all respecting per-profile isolation and the 18+ gate.
4. **Ambient reader extras** — auto-scroll with speed control, ambient soundscape while reading, panel-by-panel guided view for manhwa, reader chrome tinted by dynamic color from the current page.

## Feedback
- Haptics: yes, rich, per skin, on iOS and Android. Give a full haptic vocabulary table.
- Sound: a UI sound layer exists per skin but is OFF by default (opt-in toggle in Settings).

## Platforms
- Web gets a FULL desktop design: sidebars, hover states, keyboard-first navigation, a wide reader with side panels. Mobile web mirrors the phone app.
- iOS and Android via the mobile client.

## Performance
- Flagship-only, maximum effects. Do not design degraded fallbacks for low-end devices. Still honor OS reduced-motion for accessibility.
