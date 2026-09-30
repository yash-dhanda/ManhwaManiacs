import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/models/reader_page.dart';

import '../../../screenshots/support/shot_network.dart';
import 'reader_test_support.dart';

Set<String> _texts(WidgetTester tester) => {
      for (final e in find.byType(RichText).evaluate()) (e.widget as RichText).text.toPlainText().replaceAll('\uFFFC', ''),
    }..remove('');

void main() {
  setUpAll(setUpShotCoverCache);

  testWidgets('a removed and a gated series get the identical NOT IN THIS ISSUE notice', (tester) async {
    Future<Set<String>> shown(String message) async {
      await pumpReader(tester, failing: {'c2': ApiError(statusCode: 404, code: 'series_not_found', message: message)});
      await settleReader(tester, ms: 2500);
      final t = _texts(tester);
      await disposeReader(tester);
      return t;
    }

    final removed = await shown('That series was removed by its source.');
    final gated = await shown('That series is behind the 18+ gate.');
    expect(removed, contains('NOT IN THIS ISSUE'));
    expect(removed, contains("This series isn't available here any more."));
    expect(removed, contains('Back to Tonight'));
    expect(gated, removed, reason: 'the words never say which of the two it is');
    expect(removed.any((t) => t.contains('removed by its source') || t.contains('18+')), isFalse);
  });

  testWidgets('the source reader path shows the same notice', (tester) async {
    await pumpReader(
      tester,
      origin: ReaderRigOrigin.source,
      failing: {'c2': const ApiError(statusCode: 404, code: 'series_not_found', message: 'gone')},
    );
    await settleReader(tester, ms: 2500);
    expect(_texts(tester), containsAll(['NOT IN THIS ISSUE', "This series isn't available here any more."]));
    await disposeReader(tester);
  });

  testWidgets('a chapter with no pages says so and offers Back to the series', (tester) async {
    final rig = await pumpReader(tester, chapters: {'c2': readerChapter('c2', pages: 0)});
    await settleReader(tester, ms: 2500);
    expect(_texts(tester), contains('This chapter has no pages.'));
    expect(_texts(tester), contains('Back to the series'));
    await tester.tap(find.text('Back to the series', findRichText: true).last);
    await settleReader(tester, ms: 1200);
    expect(find.text('series page'), findsOneWidget);
    expect(rig.router.state.uri.path, '/');
    await disposeReader(tester);
  });

  testWidgets('the offline edition ends with "Next chapter isn\'t saved on this device" and Back to Downloads', (tester) async {
    final dir = Directory.systemTemp.createTempSync('mm-offline-seam');
    addTearDown(() => dir.deleteSync(recursive: true));
    final png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==');
    final files = [for (var n = 1; n <= 3; n++) File('${dir.path}/$n.png')..writeAsBytesSync(png)];
    final local = ReaderChapter(
      id: 'c2',
      seriesId: kReaderSeries,
      title: 'Chapter 2',
      pageCount: 3,
      sourceId: kReaderSource,
      seriesTitle: 'Tower of Dawn',
      pages: [for (var n = 1; n <= 3; n++) ReaderPage(id: 'c2-$n', number: n, imageUrl: '', localFile: files[n - 1], width: 800, height: 2400)],
    );
    final rig = await pumpReader(tester, chapters: {'c2': local}, neighbours: {'c2': (prev: null, next: null)});
    await settleReader(tester, ms: 800);
    for (var i = 0; i < 3; i++) {
      final position = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
      position.jumpTo(position.maxScrollExtent);
      await settleReader(tester, ms: 500);
    }
    expect(_texts(tester), contains("NEXT CHAPTER ISN'T SAVED ON THIS DEVICE"));
    expect(_texts(tester), contains('Back to Downloads'));
    await tester.tap(find.text('Back to Downloads', findRichText: true));
    await settleReader(tester, ms: 500);
    expect(rig.router.routeInformationProvider.value.uri.path, contains('downloads'), reason: 'leaves for Downloads');
    await disposeReader(tester);
  });
}
