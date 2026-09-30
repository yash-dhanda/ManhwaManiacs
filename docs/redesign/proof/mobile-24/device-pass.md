# Mobile 24 device pass (owner)

Status: awaiting owner. `release/00` checks this file before the flip.

Every row: open Settings, Diagnostics, turn on "Show motion timings". Expect no `proof` row, no dropped frame, and no overrun of more than one frame.

Devices: the iPhone with the IPA from the Build iOS workflow through SideStore; the Android flagship with a signed release APK built where the signing key lives (`mobile/RELEASE.md`; never Gradle on the dev box), installed over the existing app so downloads survive.

## iPhone

| # | Check | Result | Notes |
|---|---|---|---|
| 1 | Edition (debug) row: LEGACY to CINEMATIC and back; `SKIN RESTART` under 1,500 ms | [ ] | |
| 2 | Column wipe into the manga reader and the novel reader; the Dip out | [ ] | |
| 3 | Iris (profile picker to shell) | [ ] | |
| 4 | Trailer scrub on Tonight | [ ] | |
| 5 | Cut to home at the end of onboarding | [ ] | |
| 6 | Lightbox: open, drag to dismiss, close | [ ] | |
| 7 | Match cut from a poster and its reverse (iOS: edge swipe reverses it with the finger; Android: predictive back fades through) | [ ] | |
| 8 | Reader at 120 Hz with page tint on: a 120-page, 2,880 px webtoon scrolled end to end, 0 dropped frames | [ ] | |
| 9 | Rack focus cap: Library wall of 40+ followed series and a Discover page of 40 items, each opened cold: at most 12 covers rack-focus at once, 0 dropped frames | [ ] | |
| 10 | Listen highlighter follows the narration; lock-screen controls (audio_service); shake extends the sleep timer | [ ] | |
| 11 | Text scale 1.0, 1.3, 2.0 (iOS Larger Text / Android font size); Bold Text; Hyperlegible text on: Tonight, Library, a feature page, reader chrome, Listen, Settings; nothing clips | [ ] | |
| 12 | Reduce Motion / Remove animations: Column wipe cross-fades, Lightbox fades, trailer scrub scrolls normally | [ ] | |
| 13 | Haptics on the section 5 events with Feedback on, none with it off | [ ] | |
| 14 | UI sounds off by default, on after opting in, silent under narration | [ ] | |
| 15 | 18+ checklist (cinematic_mature_absence_test on the device): Downloads, counts, Library offline, Tonight offline edition, Bookmarks, History, Discover search show nothing with the gate closed; all back when reopened; seed restored afterwards | [ ] | |
| 16 | Every destructive confirm resists a double tap (1000 ms arm) | [ ] | |
| 17 | Audio session (iOS) row in Diagnostics reads `ambient` after sound init and after a Hear sample | [ ] | |
| 18 | Increase Contrast on (iOS) | [ ] | |
| 19 | VoiceOver: masthead announced on every route change; reader announces the chapter, not pages; toasts with an action stay; reader chrome stays; every row swipe action reachable as a custom action or row menu | [ ] | |

## Android flagship

| # | Check | Result | Notes |
|---|---|---|---|
| 1 | Edition (debug) row: LEGACY to CINEMATIC and back; `SKIN RESTART` under 1,500 ms | [ ] | |
| 2 | Column wipe into the manga reader and the novel reader; the Dip out | [ ] | |
| 3 | Iris (profile picker to shell) | [ ] | |
| 4 | Trailer scrub on Tonight | [ ] | |
| 5 | Cut to home at the end of onboarding | [ ] | |
| 6 | Lightbox: open, drag to dismiss, close | [ ] | |
| 7 | Match cut from a poster and its reverse (iOS: edge swipe reverses it with the finger; Android: predictive back fades through) | [ ] | |
| 8 | Reader at 120 Hz with page tint on: a 120-page, 2,880 px webtoon scrolled end to end, 0 dropped frames | [ ] | |
| 9 | Rack focus cap: Library wall of 40+ followed series and a Discover page of 40 items, each opened cold: at most 12 covers rack-focus at once, 0 dropped frames | [ ] | |
| 10 | Listen highlighter follows the narration; lock-screen controls (audio_service); shake extends the sleep timer | [ ] | |
| 11 | Text scale 1.0, 1.3, 2.0 (iOS Larger Text / Android font size); Bold Text; Hyperlegible text on: Tonight, Library, a feature page, reader chrome, Listen, Settings; nothing clips | [ ] | |
| 12 | Reduce Motion / Remove animations: Column wipe cross-fades, Lightbox fades, trailer scrub scrolls normally | [ ] | |
| 13 | Haptics on the section 5 events with Feedback on, none with it off | [ ] | |
| 14 | UI sounds off by default, on after opting in, silent under narration | [ ] | |
| 15 | 18+ checklist (cinematic_mature_absence_test on the device): Downloads, counts, Library offline, Tonight offline edition, Bookmarks, History, Discover search show nothing with the gate closed; all back when reopened; seed restored afterwards | [ ] | |
| 16 | Every destructive confirm resists a double tap (1000 ms arm) | [ ] | |
| 17 | Android flutter_displaymode reports the high refresh rate in Diagnostics | [ ] | |
| 18 | High-contrast text on (Android) | [ ] | |
| 19 | TalkBack: masthead announced on every route change; reader announces the chapter, not pages; toasts with an action stay; reader chrome stays; every row swipe action reachable as a custom action or row menu | [ ] | |

