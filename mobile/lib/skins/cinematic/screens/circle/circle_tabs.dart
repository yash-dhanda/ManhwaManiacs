import 'package:manhwamaniacs/skins/cinematic/primitives/cine_contents_tabs.dart';

/// The Circle's five tabs (cinematic 9.3.2), in order.
enum CircleTabId { all, reading, reactions, letters, shelves }

/// `?tab=all|reading|reactions|letters|shelves`; anything else opens ALL.
CircleTabId circleTabFromQuery(String? q) {
  for (final t in CircleTabId.values) {
    if (t.name == q) return t;
  }
  return CircleTabId.all;
}

/// The feed kind a tab reads: `null` all, `reading`, `reaction`; letters and shelves read their own.
String? feedKindOf(CircleTabId t) => switch (t) {
      CircleTabId.reading => 'reading',
      CircleTabId.reactions => 'reaction',
      _ => null,
    };

List<CineTab> circleCineTabs(int newLetters) => [
      const CineTab(folio: '01', label: 'ALL'),
      const CineTab(folio: '02', label: 'READING'),
      const CineTab(folio: '03', label: 'REACTIONS'),
      CineTab(folio: '04', label: 'LETTERS', count: newLetters > 0 ? newLetters : null),
      const CineTab(folio: '05', label: 'SHELVES'),
    ];
