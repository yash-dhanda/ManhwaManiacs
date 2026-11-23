import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_options.dart' show BandKind;
import 'package:manhwamaniacs/features/reader/engine/reader_frames.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_signals_provider.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/chapter_seam.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/reader_states.dart';

import '../primitives/support.dart';

void main() {
  final open = DateTime.utc(2026, 11, 23, 14);
  late DateTime now;
  late int retries;

  setUp(() {
    now = open.subtract(const Duration(hours: 3, minutes: 27, seconds: 14));
    retries = 0;
  });

  ApiError locked(DateTime? until) => ApiError(
        statusCode: 423,
        code: 'chapter_locked',
        message: 'Early access on AsuraScans.',
        details: {'source_id': 'asurascans', 'locked_until': until?.toIso8601String()},
      );

  Future<void> pump(WidgetTester t, DateTime? until) => t.pumpWidget(primHost(
        GlassReaderFailure(failure: ReaderFailure(error: locked(until), noPages: false, retry: () => retries++, back: () {})),
        overrides: [
          clockProvider.overrideWithValue(() => now),
          sourcesListProvider.overrideWith((ref) async => const [SourceSummary(id: 'asurascans', name: 'AsuraScans', description: '', browsable: true, supportsImport: false)]),
        ],
      ),);

  testWidgets('shows the countdown, no Try again, and never the error copy', (t) async {
    await pump(t, open);
    await t.pump();
    expect(find.text('Opens in 3:27:14'), findsOneWidget);
    expect(find.textContaining("Couldn't open"), findsNothing);
    expect(find.text('Try again'), findsNothing);
    expect(find.textContaining('AsuraScans opens this chapter to everyone at'), findsOneWidget);
  });

  testWidgets('retries once after the grace at zero, then offers Try again', (t) async {
    await pump(t, open);
    now = open;
    await t.pump(const Duration(seconds: 1));
    expect(retries, 0);
    now = now.add(const Duration(seconds: 5));
    await t.pump(const Duration(seconds: 5));
    expect(retries, 1);
    await t.pump(const Duration(seconds: 7));
    expect(retries, 1);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('no instant: message with Try again', (t) async {
    await pump(t, null);
    await t.pump();
    expect(find.text('Try again'), findsOneWidget);
    await t.pump(const Duration(seconds: 30));
    expect(retries, 0);
  });

  testWidgets('the next band shows a lock only when it is the next chapter\'s own', (t) async {
    final stale = (chapterKey: 'other-series-c9', lockedUntil: open, message: 'm', sourceId: 'asurascans');
    await t.pumpWidget(primHost(
      Builder(builder: (context) => GlassReaderBands(
            nextLabel: 'Chapter 371',
            previousLabel: 'Chapter 369',
            nextChapterId: 'c371',
            onRetryNeighbour: () {},
            onOpenNext: () {},
            onDownloadNext: () {},
          ).build(context, BandKind.nextFailed),),
      overrides: [clockProvider.overrideWithValue(() => now), readerLockedNextProvider.overrideWith((ref) => stale)],
    ),);
    await t.pump();
    expect(find.text('Try again'), findsOneWidget, reason: 'another chapter\'s lock does not speak for it');
    expect(find.textContaining('opens in'), findsNothing);
  });

  testWidgets('the next band shows the lock held for its own chapter', (t) async {
    final own = (chapterKey: 'c371', lockedUntil: open, message: 'm', sourceId: 'asurascans');
    await t.pumpWidget(primHost(
      Builder(builder: (context) => GlassReaderBands(
            nextLabel: 'Chapter 371',
            previousLabel: 'Chapter 369',
            nextChapterId: 'c371',
            onRetryNeighbour: () {},
            onOpenNext: () {},
            onDownloadNext: () {},
          ).build(context, BandKind.nextFailed),),
      overrides: [clockProvider.overrideWithValue(() => now), readerLockedNextProvider.overrideWith((ref) => own)],
    ),);
    await t.pump();
    expect(find.textContaining('Chapter 371 opens in 3:27:1'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });
}
