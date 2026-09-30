# mobile-41 plan

One task per scope item (see the prompt file for the full text).

- A1 to A8: shared data layer in `mobile/lib/features/{library,recap,ai}` with Dart tests (suggest calls, deck reducer, entry decisions, keep-alive, cache, feedback and similar, the one-shot Ask draft). Done first, committed on its own.
- B1 to B14: `skins/glass/screens/picks/*` (ask controller, Ask box, controls, states, sections, answer list with the Deal, genre chip) and `parts/ai/not_interested.dart`. Router maps `picks`.
- C1 to C10: `parts/recap/*` (continue path, offer, chapter pill, How it works, ready listener) and `screens/recap/*` (deck, cards, footer, compact, states). Router maps `recap`; sheets `offer` and `how-it-works` are registered with the global sheets.
- D1 to D3: `parts/ai/more_like_this_rail.dart`.
- E1 to E2: one-voice test over `copy/ai.dart`; the 18+ purge hooks live in `recap_ready_listener.dart`.
- Proof: widget tests, `mobile_41_ai_shots_test.dart` captures, report.
