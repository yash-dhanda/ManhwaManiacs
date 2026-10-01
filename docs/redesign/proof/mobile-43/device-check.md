# mobile/43 device checks (owner)

iPhone through SideStore and the Android flagship, CI builds, two profiles on the dev or owner server (one with its 18+ gate
closed). Glass stays behind the debug skin row until `release/01`. One line per check; fill the box.

| # | Check | iPhone | Android |
|---|---|---|---|
| 1 | Presence arc: the other profile starts reading with "Show me in presence" on; its orb drifts to the front and the ring breathes (2.4 s) | [ ] | [ ] |
| 2 | Same with "Show me in presence" off: the orb never moves to the front | [ ] | [ ] |
| 3 | Reaction hold-to-bloom: 300 ms hold, `reaction.bloom` haptic, a tick per bubble while sliding, the `pop` on send, smooth at 120 Hz | [ ] | [ ] |
| 4 | Mouse or trackpad click on the reaction button opens the picker (iPad trackpad, Android mouse) | [ ] | [ ] |
| 5 | Lift a poster on Home: the orbs materialise at the top, the dock steps aside, the magnet catch with its haptic, the Undo toast | [ ] | [ ] |
| 6 | Recommend sheet: Send, the selected orbs fly out of the sheet, "Sent to …" | [ ] | [ ] |
| 7 | Friend sheet: the tapped orb flies into the header; close by drag, back and the iOS swipe; focus returns to the orb | [ ] | [ ] |
| 8 | A letter arrives on the other profile: the `bloom` dot on the dock's You tab and on the sidebar Circle item | [ ] | [ ] |
| 9 | The gate-closed profile sees no mature activity, letter, shelf member or reaction anywhere in the Circle | [ ] | [ ] |
| 10 | VoiceOver and TalkBack read the arc front to back ("Aarav, reading … now") and offer the reaction custom actions | [ ] | [ ] |
| 11 | Reduce Motion: no ring breath, no bubble travel, 150 ms fades, the orb flight a cross-fade | [ ] | [ ] |
