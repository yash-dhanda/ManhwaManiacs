import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/downloads/providers/progress_outbox_provider.dart';
import 'package:manhwamaniacs/features/reader/models/reading_progress.dart';
import 'package:manhwamaniacs/features/reader/repositories/reader_repository.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

import '../../../screenshots/support/shot_network.dart';
import 'reader_test_support.dart';

ReadingProgress _row(String chapter, double number, int page) => ReadingProgress(
      id: 1,
      sourceId: kReaderSource,
      seriesKey: kReaderSeries,
      chapterKey: chapter,
      chapterNumber: number,
      lastPage: page,
      pageCount: 6,
      scrollOffsetPx: 0,
      isCompleted: false,
      timeSpentSeconds: 0,
    );

class _Repo extends FakeReader {
  _Repo(super.rec, this.rows);
  final List<ReadingProgress> rows;
  @override
  Future<Result<List<ReadingProgress>>> seriesProgress({required String sourceId, required String seriesKey}) async => Ok(rows);
}

class _Outbox extends ProgressOutboxController {
  _Outbox(super.ref, this.stream);
  final Stream<({String sourceId, String seriesKey})> stream;
  @override
  Stream<({String sourceId, String seriesKey})> get notAdvanced => stream;
}

void main() {
  setUpAll(setUpShotCoverCache);

  Future<ReaderRig> open(WidgetTester tester, StreamController<({String sourceId, String seriesKey})> events, List<ReadingProgress> rows) {
    final rig = FeatureRig();
    return pumpReader(tester, rig: rig, extra: [
      readerRepositoryProvider.overrideWithValue(_Repo(rig.rec, rows)),
      progressOutboxControllerProvider.overrideWith((ref) => _Outbox(ref, events.stream)),
    ]);
  }

  testWidgets('a save the server did not advance offers the jump to the further chapter', (tester) async {
    final events = StreamController<({String sourceId, String seriesKey})>.broadcast();
    addTearDown(events.close);
    final rig = await open(tester, events, [_row('c3', 3, 4), _row('c1', 1, 6)]);
    await settleReader(tester, ms: 800);
    events.add((sourceId: kReaderSource, seriesKey: kReaderSeries));
    await settleReader(tester, ms: 800);
    expect(find.textContaining('further ahead on another device (CH 3, p.4)', findRichText: true), findsOneWidget);
    await tester.tap(find.text('Jump', findRichText: true));
    await settleReader(tester, ms: 800);
    expect(rig.router.state.uri.path, contains('/reader/demo/k/c3'));
    expect(rig.router.state.uri.queryParameters['page'], '4');
    await disposeReader(tester);
  });

  testWidgets('nothing is offered when the server row is behind, or belongs to another series', (tester) async {
    final events = StreamController<({String sourceId, String seriesKey})>.broadcast();
    addTearDown(events.close);
    await open(tester, events, [_row('c1', 1, 6)]);
    await settleReader(tester, ms: 800);
    events.add((sourceId: kReaderSource, seriesKey: kReaderSeries));
    events.add((sourceId: kReaderSource, seriesKey: 'other'));
    await settleReader(tester, ms: 800);
    expect(find.textContaining('further ahead', findRichText: true), findsNothing);
    await disposeReader(tester);
  });
}
