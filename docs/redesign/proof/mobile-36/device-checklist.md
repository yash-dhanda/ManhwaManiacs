# mobile/36 device checklist (owner)

iPhone via SideStore after CI builds the IPA; an Android flagship from the CI APK. Glass is behind the debug skin row until `release/01`. Open a novel chapter from a book page.

| Check | iPhone | Android |
|---|---|---|
| Long-press a word: native selection with the platform handles and magnifier; the Glass menu (Copy, Bookmark this paragraph, React to this chapter) stays attached while dragging the handles | [ ] | [ ] |
| Android back with a selection clears the selection first, then leaves | n/a | [ ] |
| Lift turn (Aa → Paged → Page turn Lift) at 120 Hz with 0 dropped frames in Settings → Diagnostics → Show motion timings | [ ] | [ ] |
| Slide turn at 120 Hz with 0 dropped frames | [ ] | [ ] |
| Book open from the book page's Start reading / Continue (needs mobile/33) | [ ] | [ ] |
| Paper ripple spreads from the chosen orb in the Aa sheet | [ ] | [ ] |
| Pinch steps the text size once per x1.15 with a `detent.tick`; "Text size N" shows; the text reflows once on release | [ ] | [ ] |
| Status bar hidden in the reader; chrome sits clear of the notch / Dynamic Island and the Android gesture bar | [ ] | [ ] |
| Rotate to landscape inside the reader; portrait is restored on exit | [ ] | [ ] |
| iOS 20 px edge strip pops in scroll mode only (not in paged mode) | [ ] | n/a |
| Keep screen awake (Aa → Screen) holds the screen on; off when leaving | [ ] | [ ] |
| VoiceOver / TalkBack read "Mira: " before an attributed run, the drop-cap word whole ("Alice", not "A" + "lice") and the chapter announcement on entry and on next chapter | [ ] | [ ] |
| System text scale 1.0, 1.3 and 2.0: a book with no stored size opens at 19, 25 and 30 px; chrome text stops growing at 1.3 | [ ] | [ ] |
| OS Bold Text makes the body heavier (+100 on the weight axis) | [ ] | [ ] |
| Pagination time of the 12,000-word fixture from `flutter logs` ("paginate: … ms", budget 16 ms) | [ ] | [ ] |
