# mobile-11 device checklist (owner)

iPhone via SideStore after CI builds the IPA, and the Android flagship.

- [ ] Poster to series page: the 480 ms match cut, the cover Hero landing on the 4:5 hero (phone) or the spread (tablet).
- [ ] iOS: the edge swipe (20 pt) reverses the match cut with the finger; a swipe from the middle does nothing.
- [ ] Android: predictive back fades the page through (out 1.00 to 0.95, in from 0.4); the button pop takes 336 ms.
- [ ] Title letters set after the route lands, credits set in reading order, the ambient wash dissolves over 800 ms.
- [ ] Column wipe from `Continue` and from a chapter row: 616 ms phone, 744 ms tablet, 0 dropped frames in the motion-timings overlay, `reader.enter` haptic as the blades land.
- [ ] Lightbox: long-press (haptic), pinch, double tap to 250%, drag down past 120 px, `x`, Android back.
- [ ] A real chapter download writes to the sqflite store with the `light` haptic on start and `success` on finish; read it offline.
- [ ] Mark read, up to here, unread and both Undos against the real server; offline the controls read "Needs a connection.".
- [ ] `mature_override` change (true, false, use the source's rating) hides or shows the series' saved chapters with the 18+ gate closed. Needs the backend fix (open issue in report.md).
- [ ] VoiceOver and TalkBack: schedule rows (number, title, read, reading), the seven download marks, the tab row, the selection bar.
- [ ] Text scale 1.3 and 2.0: the FOLLOW / FAVOURITE / NOTIFY / DOWNLOAD row, the Book front matter, the contents rows.
- [ ] Hardware keyboard (iPad or Android with keyboard): every key of D10 and E6, and the focus ring only on keyboard focus.
