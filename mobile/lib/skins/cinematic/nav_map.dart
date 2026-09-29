/// Where a location sits in the app frame (cinematic 8.0.3): its shell branch, the Library hub
/// tab, the running title and the section folio. Pure; the shell, the running head and the
/// first-run note read it.
class NavInfo {
  const NavInfo({
    required this.branch,
    required this.hubTab,
    required this.title,
    required this.folio,
    required this.firstRunNote,
  });

  /// 0 Tonight, 1 Library, 2 Discover, 3 Downloads, 4 Index; null on the root navigator.
  final int? branch;

  /// 0 SHELF, 1 UPDATES, 2 COLLECTIONS, 3 HISTORY, 4 BOOKMARKS inside branch 1.
  final int? hubTab;
  final String title;

  /// `01` to `12`, `00` for Settings, null for Index and unnumbered pages.
  final String? folio;

  /// Whether the "nothing followed yet" strip may show under the running head.
  final bool firstRunNote;

  bool get inShell => branch != null;
}

/// Section of `/settings/:section`, upper-cased for the running title.
String _section(String s) => s.replaceAll('-', ' ').toUpperCase();

NavInfo navInfoFor(String location) {
  final uri = Uri.parse(location);
  final segs = [for (final s in uri.pathSegments) if (s.isNotEmpty) Uri.decodeComponent(s)];
  NavInfo shell(int branch, String title, {int? hub, String? folio, bool note = true}) =>
      NavInfo(branch: branch, hubTab: hub, title: title, folio: folio, firstRunNote: note);
  const root = NavInfo(branch: null, hubTab: null, title: 'MANHWAMANIACS', folio: null, firstRunNote: false);

  if (segs.isEmpty) return shell(0, 'TONIGHT', folio: '01', note: false);
  switch (segs[0]) {
    case 'library':
      if (segs.length == 1 || (segs.length == 2 && segs[1] == 'browse')) {
        return shell(1, 'LIBRARY', hub: 0, folio: '02', note: false);
      }
      if (segs[1] == 'collections') return shell(1, 'LIBRARY · COLLECTIONS', hub: 2, folio: '06');
      if (segs[1] == 'history' && segs.length == 2) return shell(1, 'LIBRARY · HISTORY', hub: 3, folio: '07');
      if (segs[1] == 'bookmarks' && segs.length == 2) return shell(1, 'LIBRARY · BOOKMARKS', hub: 4, folio: '08');
      if (segs[1] == 'recommendations' && segs.length == 2) return shell(2, 'DISCOVER · PICKS', folio: '12');
      if (segs[1] == 'statistics' && segs.length == 2) return shell(4, 'THE NUMBERS', folio: '10');
      return root; // annual, read aliases, /library/:followedId
    case 'updates':
      return shell(1, 'LIBRARY · UPDATES', hub: 1, folio: '03');
    case 'collections':
      return root; // alias, redirected into branch 1
    case 'search':
      return shell(2, 'DISCOVER', folio: '04', note: false);
    case 'sources':
      if (segs.length == 1) return shell(2, 'DISCOVER · SOURCES', folio: '04', note: false);
      if (segs.length == 2) return shell(2, 'DISCOVER · SOURCES', folio: '04', note: false);
      return root; // feature and the read alias
    case 'ocr':
      return shell(2, 'DISCOVER · DIALOGUE', folio: '09');
    case 'downloads':
      return shell(3, 'DOWNLOADS', folio: '05');
    case 'more':
      return shell(4, 'INDEX');
    case 'settings':
      return segs.length == 1
          ? shell(4, 'SETTINGS', folio: '00')
          : shell(4, 'SETTINGS · ${_section(segs[1])}', folio: '00');
    case 'admin':
      return segs.length == 2 && segs[1] == 'status' ? shell(4, 'STATUS') : root;
    case 'circle':
      return shell(4, 'CIRCLE', folio: '11');
    case 'profiles':
      return segs.length == 2 && segs[1] == 'manage' ? shell(4, 'PROFILES') : root;
  }
  return root;
}
