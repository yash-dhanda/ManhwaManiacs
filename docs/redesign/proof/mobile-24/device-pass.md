# Mobile 24 device pass (owner)

Status: awaiting owner. Cinematic only, v1 (3.5.0). `release/00` checks this file before the flip.

Every row: open Settings, Diagnostics, turn on "Show motion timings". Expect no `proof` row, no dropped frame, and no overrun of more than one frame.

Devices: the iPhone with the IPA from the Build iOS workflow through SideStore; the Android flagship with a signed release APK built where the signing key lives (`mobile/RELEASE.md`; never Gradle on the dev box), installed over the existing app so downloads survive.

## Cinematic checklist (run on iPhone and Android flagship)

| # | Check | iPhone | Android | Notes |
|---|---|---|---|---|
| 1 | Column wipe into the manga reader and the novel reader; the Dip out | [ ] | [ ] | |
| 2 | Iris (profile picker to shell) | [ ] | [ ] | |
| 3 | Trailer scrub on Tonight | [ ] | [ ] | |
| 4 | Cut to home at the end of onboarding | [ ] | [ ] | |
| 5 | Lightbox: open, drag to dismiss, close | [ ] | [ ] | |
| 6 | Match cut from a poster and its reverse (iOS: edge swipe reverses it with the finger; Android: predictive back fades through) | [ ] | [ ] | |
| 7 | Reader at 120 Hz with page tint on: a 120-page, 2,880 px webtoon scrolled end to end, 0 dropped frames | [ ] | [ ] | |
| 8 | Rack focus cap: Library wall of 40+ followed series and a Discover page of 40 items, each opened cold: at most 12 covers rack-focus at once, 0 dropped frames | [ ] | [ ] | |
| 9 | Listen highlighter follows the narration; lock-screen controls (audio_service); shake extends the sleep timer | [ ] | [ ] | |
| 10 | Text scale 1.0, 1.3, 2.0 (iOS Larger Text / Android font size); Bold Text; Hyperlegible text on: Tonight, Library, a feature page, reader chrome, Listen, Settings; nothing clips | [ ] | [ ] | |
| 11 | Reduce Motion / Remove animations: Column wipe cross-fades, Lightbox fades, trailer scrub scrolls normally | [ ] | [ ] | |
| 12 | 18+ checklist (cinematic_mature_absence_test on the device): Downloads, counts, Library offline, Tonight offline edition, Bookmarks, History, Discover search show nothing with the gate closed; all back when reopened; seed restored afterwards | [ ] | [ ] | |
| 13 | Every destructive confirm resists a double tap (1000 ms arm) | [ ] | [ ] | |
| 14 | VoiceOver: masthead announced on every route change; reader announces the chapter, not pages; toasts with an action stay; reader chrome stays; every row swipe action reachable as a custom action or row menu | [ ] | [ ] | |
| 15 | Platform: iOS Audio session row reads `ambient`; Android flutter_displaymode reports high refresh rate; Increase Contrast / high-contrast text on | [ ] | [ ] | |

Dropped from v1: the LEGACY/CINEMATIC edition row (old item 1), haptics (13) and UI sounds (14), which are covered by tests.

## Later (Glass)

Re-add when Glass ships: edition row CINEMATIC to GLASS and back with `SKIN RESTART` under 1,500 ms; Glass material, specular and tilt checks; Glass soundscape; Glass text-scale and contrast pass.
