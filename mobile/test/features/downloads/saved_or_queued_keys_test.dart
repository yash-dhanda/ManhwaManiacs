import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_selection.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';

import '../../support/downloads_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  initSqfliteFfiForTests();

  test('"download next 10" skips chapters already queued or saved', () async {
    final harness = await TestDownloadsHarness.create();
    addTearDown(harness.dispose);
    final store = harness.storeFor('u1p1');
    for (var i = 1; i <= 10; i++) {
      await store.ensureQueued(id: (sourceId: 's', seriesKey: 'x', chapterKey: '$i'), chapterNumber: i.toDouble());
    }
    final saved = await savedOrQueuedChapterKeys(store, (sourceId: 's', seriesKey: 'x'));
    final keys = nextUnreadUndownloadedKeys([
      for (var i = 1; i <= 20; i++) (key: '$i', number: i.toDouble(), title: null, isRead: false, isDownloaded: saved.contains('$i')),
    ]);
    expect(keys.first, '11');
    expect(keys, hasLength(10));
  });
}
