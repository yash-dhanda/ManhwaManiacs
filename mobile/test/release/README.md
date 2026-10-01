# Cross-skin release suite (mobile)

The checks `docs/redesign/prompts/release/01-glass-final-release.md` F3 asks for before a release, run through the real boot of
both skins. `release_rig.dart` pumps what `main.dart` does (`AppRestart` re-running `SkinBoot.read` into a fresh `ProviderScope`
and `SkinApp`) over fakes that live outside the scope, as the device stores and the server do, so a skin restart keeps them:
prefs, the `/profiles` API (records each `PATCH {skin}`), the library, the saved downloads, the icon plugin spy and the
download queue's launch counter. Nothing touches the network.

```
cd mobile && flutter test test/release      # about a minute
```

## What it guards

`cross_skin_release_test.dart`, on iOS and Android:

- Boot into the stored skin (both) on the return route, with no restart.
- A stored `legacy` (or unknown) value boots Cinematic; a leftover `mm.skin.debug` is removed and ignored.
- Cinematic to Glass from Settings: same route, same profile (no sign-out, no picker), the outbox `PATCH` reaches the server,
  `SKIN RESTART` reads and clears `mm.skin.t0`, the download queue resumes, the arrival toast shows in the skin's face (no
  underline, never Flutter's yellow fallback) and is gone after 10 s.
- Glass's Undo restarts back with no alert and no second toast.
- Glass to Cinematic through the alert and the 615 ms melt; Cinematic's Undo goes back to Glass.
- App icon rule: on, an explicit choice and its Undo move the icon (iOS at once; Android at the next pause, for the skin running
  then); off, nothing does; a profile switch or a boot mismatch never does.
- Each profile boots its own skin: a mismatch at boot and a profile switch restart with no toast, no icon and no `PATCH`.
- The library and the saved downloads are there after each restart, in both skins.

`nav_reader_release_test.dart`, on iOS:

- Every main tab of each skin, a series page pushed on it and an edge swipe back, twice; every transition finishes, no gesture is
  left in progress and the popped page is disposed.
- Both reader entry points (library `ReaderScreen`, `SourceReaderScreen`) open in each skin; a single tap leaves the menu shut, a
  double tap opens it; the reader closes (edge swipe, then a pop) back to the Library.
- Discover's genre AI grid hides an 18+ title while the gate is closed and shows it when open; its text is in the skin's face.

Not covered here: the onboarding and profile-form entry points of the switch (their own tests in `test/skins/**`).
