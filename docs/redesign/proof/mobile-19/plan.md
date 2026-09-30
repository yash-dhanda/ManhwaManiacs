# mobile/19 plan: Cinematic AI (Picks, More like this, Previously on)

One task per Scope item; status at the end of the sitting.

| Item | Task | Status |
|---|---|---|
| A1 | `features/recap/sse.dart` (utf8 + LineSplitter parser) | done, `sse_test` |
| A2 | `RecapRepository` availability + open (stream or JSON), fake `HttpClientAdapter` tests | done |
| A3 | `recapAvailabilityProvider` (60 s keep-alive), `recapStreamProvider` (30 ms word pacing, `completeNow`) | done |
| A4 | `should_open_recap.dart` (`shouldOpenRecapFirst`, `mayAutoOpen`, `chipVisible`) | done |
| A5 | `RecapOrigin` + `readRecapOrigin` | done |
| A6 | `recap_countdown.dart` reducer | done |
| A7 | `ai_state.dart` | done |
| A8 | `AiRepository.similar`, `similarProvider`, `aiFeedbackProvider`, `dismissedPicksProvider` | done |
| A9 | `localSuggest` + `localSuggestionsProvider` | done |
| A10 | `rerank.dart` + Tonight `planSections(noted:)` | done |
| B | Picks screen, Ask block, World card behaviour, every state | done |
| C | `03 MORE LIKE THIS`, Quick look rows, Tonight rails (dismissed, rerank), suggested tags verified | done; credits rails as stand-ins (reader lane) |
| D | "Previously on" takeover, every state | done |
| E | `continueTo` for every Continue, entry points, reader chip widget | done; chip and credits mounted by the reader steps |
| F | Fallbacks verified (Tonight `From your shelf`, slate, genre fallback) | done |
| G | One state file, one copy module (`cineAiUnavailableCopy` now delegates to `ai_copy.dart`) | done |
| H | Reduced motion, screen readers, keys, hit targets, contrast | done, widget tests |
