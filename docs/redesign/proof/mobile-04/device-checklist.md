# mobile/04 device checklist

Owner checks. Open Settings -> Diagnostics -> Primitives gallery with "Show motion timings" on. iPhone: IPA from CI through SideStore. Android flagship: APK from CI. Result box first, then the check.

- [ ] iPhone: the `reveals` section's letter reveal and typing reveal run with 0 dropped frames at 120 Hz (timings panel: `LETTER SET`, `TYPE`, no red rows).
- [ ] Android flagship: the same, 0 dropped frames at the panel's refresh rate.
- [ ] iPhone (Impeller Metal): the grain shader renders in `grain-duotone`, and freezes with reduced motion on (Settings -> Accessibility -> Reduce Motion).
- [ ] Android flagship (Impeller Vulkan): the grain shader renders, and freezes with reduced motion on (Remove animations).
- [ ] `posters`: the wall of 24 plates racks at most 12 at once (timings panel shows 12 `RACK FOCUS` rows and 12 `DEVELOP` rows after a cold load, with the network on).
- [ ] iPhone: the primary button's `impress` haptic and the slug lines' `selection` haptic fire, and stop when the haptic switch (K13) is off.
- [ ] Android flagship: the same haptics fire and stop with the switch off.
- [ ] VoiceOver reads "Library, heading" for the masthead and the folio labels in full ("Chapter 142, 63 percent read").
- [ ] TalkBack reads the same.
- [ ] iPad or Android tablet with a hardware keyboard: `Tab` reaches one poster per rail, the double focus ring shows, `Space` opens the slate, `Esc` closes it and returns focus to the poster.
- [ ] iPad or Android tablet with a trackpad: hovering a poster zooms it inside its frame, dims its siblings and, after 600 ms, opens the slate; hovering a linked heading wipes its letters to yellow.
- [ ] Text: Settings -> Display -> Larger text at the second-largest step; the gallery does not clip or overlap; rails show 2.3 posters.
- [ ] Diagnostics on `LEGACY`: the app looks and behaves as before apart from the "Cinematic (debug)" card.
