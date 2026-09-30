# mobile/13 plan

Order of work (each step committed with its tests):
1. Pure helpers: `engine/spread.dart` (wide-page rule), `engine/page_turn.dart` (`shouldCommitTurn`, `turnDecision`), `engine/read_all_window.dart`, `core/network/bulk_limiter.dart`, `ocr/utils/ocr_boxes.dart`, `CinePagePhysics`.
2. Engine: `setLayout`, `turnTo`, `pageAtReadingLine`, `ReadAllState`, page overlay slot, long press, hero and retry slots; `PagedReaderView` (a sibling of the strip view, so the strip path stays untouched).
3. Cinematic reader: layout switching that keeps the page, tap zones and bands, K01 toast, keys, running-head buttons.
4. Reading setup sheet (`setup_rows.dart` ordered rows per tab), `SpeedRuler`, reset dialog.
5. Margins panel (NOTES, DIALOGUE, CIRCLE), circle repository, page actions sheet, OCR overlay.
6. Read-all: `ReadAllFeedController` (windowed batches, limiter, failed placeholders), `ReadAllScreen`, divider, global ruler, list failure.
7. Proof: `test/screenshots/mobile_13_shots.dart`, `device-checklist.md`, `report.md`.
