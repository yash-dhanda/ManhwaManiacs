# mobile/40 device checks (owner)

iPhone through SideStore from the CI IPA; the Android flagship from the CI APK. Turn on Settings -> Diagnostics -> "Show motion timings"
first. One line per check; fill the result box.

| # | Check | iPhone | Android |
|---|---|---|---|
| 1 | Orb lift on the first visit to You after a cold start: 120 Hz, 0 dropped frames in the motion-timings overlay ("ORB LIFT 558 -> … MS … 0 DROP") | [ ] | [ ] |
| 2 | Settings -> Notifications: the interval slider ticks once per 5 min and the 30 min magnet is felt (stronger tap) | [ ] | [ ] |
| 3 | Settings -> Security: the hold ramp of "Sign out everywhere" (ticks every 150 ms, a firm tap on completion); release early to cancel | [ ] | [ ] |
| 4 | Settings -> Backup: "Export backup" shares the file to Files (iOS) / Files or Drive (Android) | [ ] | [ ] |
| 5 | Settings -> Server: a wrong address (http:// or a typo) shows the Setup line under the field with the shake | [ ] | [ ] |
| 6 | Settings -> Diagnostics while scrolling Home: FPS, jank and the "Glass layers on screen" count move; above 6 layers or 8 shapes it turns amber | [ ] | [ ] |
| 7 | System status: the backend bead pulses once every 15 s | [ ] | [ ] |
| 8 | VoiceOver / TalkBack read every You row with its badge ("Updates, 3 new") and offer "Sign out this device" and Members' Deactivate / Delete as custom actions | [ ] | [ ] |
| 9 | Reduce Motion: Orb lift and routes cross-fade, beads only change colour, the hold fill steps | [ ] | [ ] |
| 10 | Reduce Transparency: You, Security and System status show the solid surfaces | [ ] | [ ] |
