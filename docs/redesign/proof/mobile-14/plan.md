# mobile/14 plan

1. Foundation: `NovelFace`/`NovelType` (typography), profile settings getters, attribution spans + fingerprint, chapter `cache`.
2. Pure logic with tests: speaker slots, tap zones, key reducer, stocks, preference resolution, paragraph layout, paginator.
3. `NovelReaderController` extraction (legacy screen renders its state, no pixel change).
4. Cinematic parts: paragraph painter, opener, head, end matter, bars, folio, Type sheet, Contents, paged columns, Margins panel, states.
5. Screen, route (`novel_route.dart`, page key = book + nonce), removal from `PENDING`.
6. Widget tests, proof shots, docs.
