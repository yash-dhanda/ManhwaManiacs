import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/routes/route_table.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';

void main() {
  test('tabOf classifies every branch path', () {
    for (final p in ['/', '/updates', '/library/recommendations']) {
      expect(tabOf(p), GlassTab.home, reason: p);
    }
    for (final p in ['/library', '/library/browse', '/library/collections', '/library/collections/4', '/library/history', '/library/bookmarks', '/downloads', '/collections']) {
      expect(tabOf(p), GlassTab.library, reason: p);
    }
    for (final p in ['/sources', '/sources/mangadex', '/search', '/ocr']) {
      expect(tabOf(p), GlassTab.sources, reason: p);
    }
    for (final p in ['/more', '/settings', '/settings/reading', '/circle', '/library/statistics', '/library/statistics/annual/2026', '/admin/status', '/profiles/manage']) {
      expect(tabOf(p), GlassTab.you, reason: p);
    }
    expect(tabOf('/library?sheet=x'), GlassTab.library);
    expect(tabOf('/library/'), GlassTab.library);
  });

  test('sheet routes', () {
    expect(isSheetRoute('/sources/a/series/b'), isTrue);
    expect(isSheetRoute('/library/12'), isTrue);
    expect(isSheetRoute('/library/collections'), isFalse);
    expect(isSheetRoute('/recap/a/b'), isTrue);
    expect(isSheetRoute('/circle/7'), isTrue);
    expect(isSheetRoute('/circle'), isFalse);
    expect(isSheetRoute('/profiles/new'), isTrue);
    expect(isSheetRoute('/profiles/3/edit'), isTrue);
    expect(isSheetRoute('/profiles/manage'), isFalse);
  });

  test('takeovers and readers hide the dock', () {
    expect(isTakeover('/welcome'), isTrue);
    expect(isTakeover('/library/statistics/annual/2026'), isTrue);
    expect(isTakeover('/library'), isFalse);
    expect(isReader('/reader/a/b/c'), isTrue);
    expect(isReader('/novels/a/b/c'), isTrue);
    expect(isReader('/read-all/a/b'), isTrue);
    expect(hidesDock('/reader/a/b/c'), isTrue);
    expect(hidesDock('/'), isFalse);
  });
}
