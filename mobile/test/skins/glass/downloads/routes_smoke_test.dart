import 'package:flutter_test/flutter_test.dart';

import '../../../screenshots/support/shot_harness.dart';
import '../library/library_rig.dart';

void main() {
  setUpAll(loadAppFonts);

  for (final r in ['/downloads', '/updates', '/library/collections', '/library/history', '/library/bookmarks']) {
    testWidgets('Glass renders $r without throwing', (t) async {
      await pumpLibrary(t, FakeLib(), start: r);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('downloads shows Chapters, Queue and Storage tabs', (t) async {
    await pumpLibrary(t, FakeLib(), start: '/downloads');
    for (final s in ['Chapters', 'Queue', 'Storage']) {
      expect(find.text(s), findsWidgets);
    }
  });
}
