# mobile-42 inventory map: S12 Statistics -> Glass "Your reading"

`docs/redesign/inventory/mobile.md` S12 items 1-17 and the gesture line, mapped to the Glass screen at `/library/statistics` (ScreenId `numbers`, `mobile/lib/skins/glass/screens/stats/`).

| S12 | Legacy element | Glass "Your reading" (glass/DESIGN.md 9.2.1) | Where |
|---|---|---|---|
| 1 | AppBar: back, "Statistics", ContentModeChip | Pushed page with the Glass nav row (back, "Share", the overflow menu); the content mode stays the shell's switch; large title "Your reading" | `statistics_screen.dart` |
| 2 | HeroHeading + subtitle | Large title "Your reading" with the letter reveal (10.1 placement 6) | `statistics_screen.dart` |
| 3 | Mode caveat caption | "Streak, totals and the clock count everything; the lists below follow Manga or Novels." (`footnote` `label2`, novels on) | `statistics_screen.dart` |
| 4 | No-history card | Empty state: the `books` lens "No reading recorded yet" + "Browse sources"; "Nothing read on this profile yet" + Your library card for followed-but-never-read | `statistics_screen.dart` (states) |
| 5 | Streak card (flame, days, longest, 7-day row) | Hero: the physics `StreakFlame` 96 px, "12-day streak", "Longest: 31 days", "Read on 18 of the last 30 days", 14-dot row with per-dot labels, "Last read 2 h ago", the daily goal ring | `stats_hero.dart`, `primitives/streak_flame.dart` |
| 6 | Activity card with ActivityBars, readout, range pill | "Chapters per day" `GlassChart` bars + minutes line, readout capsule while scrubbing, best-day dot; ranges 7 d / 30 d / 90 d / Year (weekly bars in Year) + the Year heatmap | `stats_sections.dart` (`ChaptersPerDay`, `YearHeatmap`) |
| 7 | Reading clock card | "When you read": 24-hour radial clock, "You read most around 23:00", band word | `stats_sections.dart` (`ClockCard`) |
| 8 | Section headers with icons | Panel titles on `StatsPanel` slabs (no icons; 9.2.1 names none) | `stats_sections.dart` |
| 9 | Totals grid of StatCards | Four `StatCard`s (Time read, Chapters, Pages, Series) for the range with all-time second lines and 7-point sparklines; context menu "Share this card" | `stats_sections.dart` (`StatTotalCard`) |
| 10 | Sources breakdown | "Where you read" rows: name, "9 h · 812 pages", share bar, "41 %" | `stats_sections.dart` (`SourcesCard`) |
| 11 | Most read rows | "Most read" rows: 40 x 60 cover, title, "12 h 40 min · 88 chapters" -> series detail | `stats_sections.dart` (`MostRead`) |
| 12 | Recent sessions list | "Recent sessions" rows: time in `mono`, title, "Ch 142 · pages · duration" -> reader | `stats_sections.dart` (`RecentSessions`) |
| 13 | Library shape grid | "Your library": "212 followed · 3 favourites · 1,904 chapters finished" | `stats_sections.dart` (`LibraryCard`) |
| 14 | By reading status card | Per-status bars in the status colours with word and count | `stats_sections.dart` (`LibraryCard`) |
| 15 | Loading skeleton | Skeletons after 180 ms: hero, 4 cards, a chart block, two panels | `statistics_screen.dart` |
| 16 | Error + Retry | "Couldn't load your reading" + "Try again" (offline without a snapshot: "You're offline"); offline with a snapshot: content under "Last updated 2 h ago" | `statistics_screen.dart` |
| 17 | Pull-to-refresh | `GlassPullToRefresh` | `statistics_screen.dart` |
| Gesture | Tap-down on a bar selects a day; tap again clears | Tap selects a day; a horizontal drag scrubs (the chart owns horizontal drags; the back swipe starts only in the leading 24 px), one `select` per day; arrows / Home / End and the semantics increase/decrease actions step the selection | `GlassChart` (mobile/28) |

New in Glass (no S12 counterpart): the Wrapped entry card and the Wrapped story (`/library/statistics/annual/:year`), share cards, the daily goal menu, the footnotes line, the streak events (flare, record sparks, milestones, goal ring on the orbs).
