import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/nav_map.dart';

void main() {
  void check(String loc, int? branch, String title, {int? hub, String? folio, bool? note}) {
    final i = navInfoFor(loc);
    expect(i.branch, branch, reason: '$loc branch');
    expect(i.title, title, reason: '$loc title');
    expect(i.hubTab, hub, reason: '$loc hub');
    expect(i.folio, folio, reason: '$loc folio');
    if (note != null) expect(i.firstRunNote, note, reason: '$loc note');
  }

  test('branches, titles, folios', () {
    check('/', 0, 'TONIGHT', folio: '01', note: false);
    check('/library', 1, 'LIBRARY', hub: 0, folio: '02', note: false);
    check('/library/browse', 1, 'LIBRARY', hub: 0, folio: '02');
    check('/updates', 1, 'LIBRARY · UPDATES', hub: 1, folio: '03', note: true);
    check('/library/collections', 1, 'LIBRARY · COLLECTIONS', hub: 2, folio: '06');
    check('/library/collections/4', 1, 'LIBRARY · COLLECTIONS', hub: 2, folio: '06');
    check('/library/history', 1, 'LIBRARY · HISTORY', hub: 3, folio: '07');
    check('/library/bookmarks', 1, 'LIBRARY · BOOKMARKS', hub: 4, folio: '08');
    check('/search', 2, 'DISCOVER', folio: '04', note: false);
    check('/sources', 2, 'DISCOVER · SOURCES', folio: '04', note: false);
    check('/sources/mangadex', 2, 'DISCOVER · SOURCES', folio: '04', note: false);
    check('/ocr', 2, 'DISCOVER · DIALOGUE', folio: '09');
    check('/library/recommendations', 2, 'DISCOVER · PICKS', folio: '12');
    check('/downloads', 3, 'DOWNLOADS', folio: '05');
    check('/more', 4, 'INDEX');
    check('/settings', 4, 'SETTINGS', folio: '00');
    check('/settings/reading-manga', 4, 'SETTINGS · READING MANGA', folio: '00');
    check('/settings/storage', 4, 'SETTINGS · STORAGE', folio: '00');
    check('/admin/status', 4, 'STATUS');
    check('/library/statistics', 4, 'THE NUMBERS', folio: '10');
    check('/circle', 4, 'CIRCLE', folio: '11');
    check('/circle/3', 4, 'CIRCLE', folio: '11');
    check('/profiles/manage', 4, 'PROFILES');
  });

  test('root-navigator routes have no branch', () {
    for (final l in [
      '/setup',
      '/login',
      '/profiles',
      '/profiles/new',
      '/profiles/3/edit',
      '/welcome',
      '/library/statistics/annual/2026',
      '/library/42',
      '/library/read/a/b/c',
      '/sources/a/series/b',
      '/sources/a/series/b/chapters/c/read',
      '/reader/a/b/c',
      '/read-all/a/b',
      '/novels/a/b/c',
      '/recap/a/b',
      '/collections',
    ]) {
      final i = navInfoFor(l);
      expect(i.branch, isNull, reason: l);
      expect(i.inShell, isFalse, reason: l);
      expect(i.firstRunNote, isFalse, reason: l);
    }
  });

  test('percent-encoded segments decode once', () {
    expect(navInfoFor('/settings/some%20thing').title, 'SETTINGS · SOME THING');
  });
}
