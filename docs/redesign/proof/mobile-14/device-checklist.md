# mobile/14 owner device checklist (iPhone via SideStore, Android flagship)

- [ ] Each of the five faces renders from the bundle with no network.
- [ ] Pagination time of the 12,000-word fixture chapter from `flutter logs` (`paginate: N paragraphs, T ms`); budget 16 ms per page turn. Record the figure. Test-host figure: ~345 ms for the whole chapter (256 paragraphs) on the JIT.
- [ ] Slide turns at 120 Hz with 0 dropped frames.
- [ ] Status bar appears and hides with the chrome (iOS and Android).
- [ ] iOS edge back works in the scroll layout only.
- [ ] Android back plays the Dip.
- [ ] Drop cap at sizes 14, 18 and 40.
- [ ] VoiceOver and TalkBack read "Alice: " before a tinted run and announce the chapter on entry and on a seamless next.
- [ ] System text scale 1.0, 1.3, 2.0 (Newsreader opens at 36 px at 2.0).
- [ ] OS Bold Text on.
