# mobile/17 report

Lane L09, branch `redesign/L09`. Not pushed (the integrator pushes). No CI run for the native commit yet: this box has no Gradle or Xcode.

## Acceptance
All boxes hold except where noted.
- PENDING: `downloads`, `indexHub` and `status` left the Cinematic set; completeness and import-boundary tests pass.
- Downloads, Activity, queue rows, scan and narration blocks, library, chapter rows, STORAGE tab, meter: built and widget-tested (48 tests under `test/skins/cinematic/downloads`).
- Removal: `REMOVING…`, 8 s Undo toast, expiry deletes, `flushAll` on pause (unit test with the injected timer, widget tests, and the shell test that sends `AppLifecycleState.paused`).
- Save to Files: `mm/media` `saveDownload` into `Download/ManhwaManiacs/Exports/{series}/` on Android 10+, Share on 7-9, Files path and `Open Files` on iOS. CI for the native commit is NOT confirmed (see above).
- 18+: widget test on a real store: absent from list, count (thumb-index badge), queue and captions; the meter keeps its bytes; reopening restores it. The queue's silent pause is `mature_queue_test`.
- Resume after restart and lifecycle under the Cinematic skin: widget tests.
- Auto-download planner and runner: unit and widget tests.
- Index, What's new (auto-open once per build, never over a reader), System status: widget tests; reduced motion, tap target, label and contrast guidelines pass on the three screens, Downloads and the sheet.
- `flutter analyze`: No issues found.

## Commits
See `git log redesign/L09` (12 commits prefixed `feat|refactor|test(mobile/17)`). The native commit is `feat(mobile/17): media store export and device total space`.

## Proof
`docs/redesign/proof/mobile-17/`: 63 screenshots, every state of the prompt on phone and tablet plus `-reduced` copies of Downloads (saved, storage), Index, What's new and System status. The test harness does not load the brand fonts, so text renders as blocks and icons as squares; the shots prove layout and state only.

## Tests
`flutter test`: 4246 passed, 1 failed of 4247 (baseline was 2012; other lanes added tests too). The one failure, `glass_overlays_shots_test: image-viewer-zoomed`, is a Glass timing flake: it passes when its file runs alone (88 of 88).

## Lowest free -m available
14142 MB.

## Open issues
- `TODO(mobile/08)`: the Index's Numbers row uses a plain flame icon until `StreakFlame` exists.
- `TODO(mobile/15)`: `activeNarrationJobsProvider` (`features/novels/providers/narration_jobs_provider.dart`) is an empty stand-in and the narration block/Index row are stand-ins for `NarratingIndicator`.
- `TODO(mobile/12)`: the next-chapter auto-queue reads `saveNextProvider` directly until the engine's `saveNextEnabled` input lands.
- Mobile/16's screens still use their local key registry and kit stand-ins; the new screens use the real `RegisteredShortcuts` and primitives.
- `getTotalDiskSpace` and `MediaChannel.kt` are unbuilt here; device checks are in `device-checklist.md` and `owner-todo.md`.
