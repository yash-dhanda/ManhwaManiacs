# Glass device pass (mobile/45 N): owner checklist

Build under test: the CI IPA of `ios-build.yml` and the release APK of the `tests.yml` build job for the SHA the integrator pushes. Reach Glass with Settings > Diagnostics > the debug row. Turn on Diagnostics > "Show motion timings".

**120 Hz pass condition (every row marked 120 Hz):** read Diagnostics > Rendering performance after the gesture. Mean FPS at least 114, Jank % in the `success` colour (under 5 %), at most 2 dropped frames per second, and no motion row turning `danger`.

Result column: write PASS, or the number and the screen.

| # | Area | Steps | Pass condition | iPhone | Android |
|---|---|---|---|---|---|
| 1 | Dock (120 Hz) | Drag across the four tabs; scroll down to minimise and up to restore; drag past the last tab to merge with the search orb; long-press a tab | The droplet follows and ticks; minimise and restore are smooth; the merge opens search on release | | |
| 2 | Sheets (120 Hz) | Open series detail; drag between medium and large; catch it mid-flight; fling it closed at 1,500 px/s or more; on Android also a predictive back gesture | 1:1 tracking, no dropped frame, the flick closes it, predictive back shrinks it | | |
| 3 | Poster zoom (120 Hz) | Open series detail from a poster; catch and drag the zoom back before 80 % | The cover flies to its slot and back without a pop | | |
| 4 | Stack overview (120 Hz) | Push four levels in the Library tab; long-press Back for 450 ms; pick a level; swipe a card away | The fan opens in about 436 ms; picking a level pops there; a swiped card removes that level and those above | | |
| 5 | Reader with the hit lens (120 Hz) | Open a dialogue search result | The T1 lens hops bubble to bubble across a page boundary with `n` and the capsule | | |
| 6 | Cruise (120 Hz) | Tap (the ramp); drag the pill (magnet click at 1.0x); flick gently; touch to pause; run the whole 120-page demo webtoon | Speed follows the pill; the magnet clicks; touching pauses and it resumes 800 ms later | | |
| 7 | Rain (120 Hz) | Start Rain over a white demo page | Droplets refract the page on the capsules and the pill; "Glass layers on screen" goes up by one | | |
| 8 | Wrapped (120 Hz) | Advance cards; watch the page pile fall; flip to share | Smooth; the flip works; no card advances while a screen reader is on | | |
| 9 | VoiceOver / TalkBack | From the rotor or actions menu reach: a swipe row's actions, the reaction strip, Back's "All levels", a toast's "Dismiss", locked mode's "Unlock controls", the cruise pill's adjust, guided view next and previous panel | Every action is reachable and does what the gesture does | | |
| 10 | Text size | iOS Larger Text default, xxL (1.24), AX2 (1.94); Android font scale 1.0, 1.3, 2.0. Look at Home, Library, series detail, manga reader, novel reader, Settings, Wrapped | Nothing clips; dock labels hide from 1.6 | | |
| 11 | System accessibility | iOS Reduce Transparency, Increase Contrast, Reduce Motion; Android Remove animations and contrast 0.5 or more | Glass goes solid live and back; the 1 px border and the higher dims appear; motion matches glass 4.11 | | |
| 12 | Calibration | Screenshot Settings > Diagnostics > Glass calibration | Save as `calibration-flutter-premium-ios.png` and `calibration-flutter-premium-android.png` in this folder. The harness capture shows no refraction (flutter_tester has no shader), so these two are the ones that count against the web | | |
| 13 | Skin switch timing | Switch both ways through the debug row | `SKIN RESTART` in Diagnostics under 1,500 ms; the return route is restored | | |
| 14 | Motion-timings walk | For each cluster, trigger every move of glass 4.10 listed for its screens and read the overlay (list below) | No row turns `danger` | | |

## Row 14: moves per cluster ("Where used" column of 4.10)

- **Shell and navigation:** Materialise, Dematerialise, Press swell, Content sink, Stretch, Bloom, Push, Pop, Stack fan, Tab droplet, Tab switch, Minimise, Title capsule, Dock merge, Sheet present, Sheet snap, Recede, Toast fall.
- **Home and Library:** Wave, Surface from depth, Deal, Letter reveal, Typing reveal, Throw, Catch, Rubber band, Meniscus refresh, Density reflow, Pin fly, Fan open, Highlight band, Lozenge morph.
- **Series, reader and novel:** Zoom, Dive, Book open, Surface, Scrub lens, Chapter card rise, Novel next, Seam chip, Cruise ramp, Panel camera, Hit lens, Page slide, Page lift, Paper ripple, Follow scroll, Lens hop, Rain on glass.
- **Listen:** Liquid fill, Hold fill (the 18+ gate), Speaking orb pulse, Preview orb pulse, Level bars, Quick type, Card drop.
- **Auth, profiles, onboarding, skin switch:** Address drain, Slab condense, Lens split, Orb lift, Dots merge, Cover arc, Avatar arc, Orbs fly out, Tag flight, Skin melt, Droplet reveal, Skin preview.
- **Statistics, Wrapped, You, Circle:** Streak flare, Record sparks, Goal ring close, Count-up, Count pop, Page pile, Podium drop, Card flip, Deck lift-off, Story stack, Reaction bloom and arc, Presence drift, Live ring breathe, Plus one, Row pulse, Spoiler unseal.
- **AI and status:** Thinking orbit, Word stream, Light follows the story, Dim shift, Step into the light, Bead flicker, Bead pulse, Error shake, Skeleton shimmer, Liquid spinner.
