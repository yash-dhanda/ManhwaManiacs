# mobile/07 report

Done: 1.1 to 1.9 (data layer), 2 Setup, 3 splash outcomes (router + splash condition, tested), 4 Login, 5 Register, 6 picker and Iris, 7 profile form, 8 Manage profiles, 9 gate switch, certificate flow, rating card, 10 gallery (`auth` section: lockups, 18+ switch states, rating card; whole-screen states are scripted in the harness), 11 tests and proof. `setup`, `login`, `register`, `profiles`, `profileNew`, `profileEdit`, `profilesManage` left `PENDING`.

Decisions: the mature predicate follows the server's `resolve_series_rating` order over cinematic 7.24's wording (online and offline agree). Register moved from Dip to Page (spec 8.4). Glass restart branch of the picker lands on Tonight until `Flags.glassAvailable`; the Edition row is unit-tested and hidden. `CineOxfordRule` (LayoutBuilder based) does not paint in the golden harness; Setup and Login use `AuthRule`.

Tests: `flutter test` 3339 passed, 0 failed; `flutter analyze` No issues found; harness group `mobile-07` 90 PNGs (phone, tablet, picker tablet-wide, -reduced, -scale2). free -m available before heavy runs: 17-21 GB.

Data API: `isMatureLocal`, `filterMature`, `matureGateOpenProvider`, `MatureStamper.restampSeries/restampMissing`, `sessionEndReasonProvider`, `serverCheckProvider`, `Profile.skin/onboardingStep/notifyEnabled/dailyGoalMinutes`; screens: `MatureGateSwitch.settings/.form`, `showMatureRatingCard`, `decidePickerOutcome`, `decideEditionSave`.

Critiques of the captures (judged against cinematic/DESIGN.md): changed the missing masthead rule, the running head overlapping the form and Manage mastheads, the picker top bar not reaching the right edge on wide tablets, the unlabelled Keep-me-signed-in switch, cramped footer link, manage rows overflowing phones (actions now on a second line). Rejected: showing edit/delete only in the row menu (spec lists them as trailing buttons).

Differences against web twin: not compared (no web-07 phone shots in this tree). Owner checklists: device-checklist.md, 18plus-checklist.md. Nothing pushed.
