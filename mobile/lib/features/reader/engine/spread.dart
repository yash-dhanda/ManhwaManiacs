/// Page numbers shown together on one screen, in reading order (lowest first).
typedef PageView1 = List<int>;

/// Pairs pages into double-page spreads, the same way `frontend/src/features/reader/spread.ts`
/// does: the cover stands alone so the drawn spreads (2,3), (4,5) line up. Cinematic 8.14.7 adds
/// one rule the web port lacks: a wide page ([isWide], manifest `width > height`) occupies a
/// spread alone and pairing resumes after it.
List<PageView1> buildSpreads(int pageCount, {bool coverAlone = true, bool Function(int page)? isWide}) {
  if (pageCount < 1) return const [];
  bool wide(int p) => isWide?.call(p) ?? false;
  final views = <PageView1>[];
  var page = 1;
  if (coverAlone) {
    views.add([1]);
    page = 2;
  }
  while (page <= pageCount) {
    if (!wide(page) && page + 1 <= pageCount && !wide(page + 1)) {
      views.add([page, page + 1]);
      page += 2;
    } else {
      views.add([page]);
      page++;
    }
  }
  return views;
}

/// One page per view (the single layout).
List<PageView1> buildSingles(int pageCount) => pageCount < 1 ? const [] : List.generate(pageCount, (i) => [i + 1]);

/// Reading order to display order: a right-to-left spread puts the earlier page on the right.
List<int> spreadDisplayOrder(List<int> view, {required bool rtl}) => rtl ? view.reversed.toList() : List.of(view);

/// Index of the view holding [page], clamped to the ends.
int findViewIndex(List<PageView1> views, int page) {
  if (views.isEmpty) return 0;
  final i = views.indexWhere((v) => v.contains(page));
  if (i != -1) return i;
  return page < views.first.first ? 0 : views.length - 1;
}

/// The page a view is on for navigation: the first one read.
int viewLeadPage(List<int> view) => view.isEmpty ? 1 : view.reduce((a, b) => a < b ? a : b);

/// The page a paged reader reports as progress: the view's last (both pages of a spread are on
/// screen), capped at [pageCount].
int viewProgressPage(List<int> view, int pageCount) =>
    view.isEmpty ? 1 : view.reduce((a, b) => a > b ? a : b).clamp(1, pageCount);
