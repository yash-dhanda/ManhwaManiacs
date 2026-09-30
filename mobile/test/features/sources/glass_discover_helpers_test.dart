import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/ocr/utils/engine_label.dart';
import 'package:manhwamaniacs/features/sources/utils/discover_scope.dart';
import 'package:manhwamaniacs/features/sources/utils/source_latest.dart';
import 'package:manhwamaniacs/features/updates/models/update_notification.dart';

UpdateNotification note(String source, DateTime? at) => UpdateNotification(
      id: 1,
      followedSeriesId: null,
      sourceId: source,
      seriesKey: 's',
      chapterKey: 'c',
      chapterTitle: 't',
      isRead: false,
      createdAt: at,
    );

void main() {
  group('parseGlassDiscoverScope', () {
    GlassDiscoverScope p(String? v, {bool ai = true, bool d = true, bool n = true, bool picks = true}) =>
        parseGlassDiscoverScope(v, aiAvailable: ai, dialogueAvailable: d, novelsEnabled: n, picksReady: picks);
    test('known values pass through', () {
      expect(p('library'), GlassDiscoverScope.library);
      expect(p('sources'), GlassDiscoverScope.sources);
      expect(p('dialogue'), GlassDiscoverScope.dialogue);
      expect(p('text'), GlassDiscoverScope.text);
      expect(p('ask'), GlassDiscoverScope.ask);
    });
    test('unknown and null are all', () {
      expect(p(null), GlassDiscoverScope.all);
      expect(p('nope'), GlassDiscoverScope.all);
      expect(p('all'), GlassDiscoverScope.all);
    });
    test('dialogue falls back to all when unavailable', () {
      expect(p('dialogue', d: false), GlassDiscoverScope.all);
    });
    test('text falls back to all when novels are off', () {
      expect(p('text', n: false), GlassDiscoverScope.all);
    });
    test('ask needs AI and a built picks screen', () {
      expect(p('ask', ai: false), GlassDiscoverScope.all);
      expect(p('ask', picks: false), GlassDiscoverScope.all);
    });
    test('Cinematic parser is unchanged', () {
      expect(parseDiscoverScope('text', aiAvailable: true, dialogueAvailable: true), DiscoverScope.all);
    });
  });

  group('engineName', () {
    test('names', () {
      expect(engineName('vision'), 'Vision');
      expect(engineName('Apple_Vision'), 'Vision');
      expect(engineName('apple-vision'), 'Vision');
      expect(engineName('mlkit'), 'ML Kit');
      expect(engineName('ML_KIT'), 'ML Kit');
      expect(engineName('ml-kit'), 'ML Kit');
      expect(engineName('tesseract'), 'tesseract');
      expect(engineName(null), 'Unknown');
    });
  });

  group('latestUpdateBySource', () {
    test('newest per source, ignores undated', () {
      final a = DateTime.utc(2026, 9);
      final b = DateTime.utc(2026, 9, 2);
      final m = latestUpdateBySource([note('x', a), note('x', b), note('y', a), note('z', null)]);
      expect(m, {'x': b, 'y': a});
    });
    test('the line', () {
      final now = DateTime.utc(2026, 9, 10, 12);
      expect(latestUpdateLine(null, now), 'No updates yet');
      expect(latestUpdateLine(now.subtract(const Duration(hours: 2)), now), 'Updated 2 h ago');
      expect(latestUpdateLine(now.subtract(const Duration(minutes: 3)), now), 'Updated 3 min ago');
      expect(latestUpdateLine(now.subtract(const Duration(days: 4)), now), 'Updated 4 d ago');
    });
  });
}
