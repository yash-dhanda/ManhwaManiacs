import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_frames.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_signals_provider.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/end_states.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_states.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

ApiError _locked(DateTime? until) => ApiError(
      statusCode: 423,
      code: 'chapter_locked',
      message: 'Early access on AsuraScans. This chapter opens to everyone at 14:00 UTC on 23 Nov.',
      details: {'source_id': 'asurascans', 'chapter_id': 'c370', 'locked_until': until?.toIso8601String()},
    );

void main() {
  final open = DateTime.utc(2026, 11, 23, 14);
  late DateTime now;
  late int retries, backs;

  setUp(() {
    now = open.subtract(const Duration(hours: 3, minutes: 27, seconds: 14));
    retries = 0;
    backs = 0;
  });

  Future<void> pumpFailure(WidgetTester t, AppError error) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => now),
        sourcesListProvider.overrideWith((ref) async => const [SourceSummary(id: 'asurascans', name: 'AsuraScans', description: '', browsable: true, supportsImport: false)]),
      ],
      child: MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS, extensions: const [cinematicTokens]),
        home: Scaffold(
          body: ReaderFailureView(failure: ReaderFailure(error: error, noPages: false, retry: () => retries++, back: () => backs++)),
        ),
      ),
    ),);
  }

  Future<void> tick(WidgetTester t, Duration d) async {
    now = now.add(d);
    await t.pump(d);
  }

  testWidgets('shows EARLY ACCESS and the ticking countdown, never the error copy', (t) async {
    await pumpFailure(t, _locked(open));
    expect(find.text('EARLY ACCESS'), findsOneWidget);
    expect(find.text('Opens in 3:27:14'), findsOneWidget);
    expect(find.text('CORRECTION'), findsNothing);
    expect(find.textContaining('not found'), findsNothing);
    expect(find.text('Go to the series'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
    await tick(t, const Duration(seconds: 1));
    expect(find.text('Opens in 3:27:13'), findsOneWidget);
    await t.pump();
    expect(find.textContaining('AsuraScans opens this chapter to everyone at'), findsOneWidget);
  });

  testWidgets('at zero it retries once after the grace, then shows the message with Try again', (t) async {
    await pumpFailure(t, _locked(open));
    now = open;
    await t.pump(const Duration(seconds: 1));
    expect(retries, 0, reason: 'not before the grace');
    expect(find.text('Opening now'), findsOneWidget);
    await tick(t, const Duration(seconds: 5));
    expect(retries, 1);
    await tick(t, const Duration(seconds: 7));
    expect(retries, 1, reason: 'exactly once');
    expect(find.textContaining('Early access on AsuraScans'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Go to the series'), findsWidgets);
  });

  testWidgets('no instant: the server message with both actions, no retry loop', (t) async {
    await pumpFailure(t, _locked(null));
    expect(find.textContaining('Early access on AsuraScans'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Go to the series'), findsOneWidget);
    await tick(t, const Duration(seconds: 30));
    expect(retries, 0);
  });

  testWidgets('an instant already past (retry came back locked) does not retry again by itself', (t) async {
    now = open.add(const Duration(minutes: 1));
    await pumpFailure(t, _locked(open));
    await tick(t, const Duration(seconds: 30));
    expect(retries, 0);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('the strip band says the next chapter opens in a countdown', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(ProviderScope(
      overrides: [clockProvider.overrideWithValue(() => now)],
      child: MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS, extensions: const [cinematicTokens]),
        home: Scaffold(body: NextLockedNotice(label: 'Chapter 371', lockedUntil: open, message: 'm', onRetry: () => retries++, onOpen: () {})),
      ),
    ),);
    await t.pump(const Duration(seconds: 2));
    expect(find.text('EARLY ACCESS'), findsOneWidget);
    expect(find.textContaining('Chapter 371 opens in 3:27:1'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
    now = open;
    await t.pump(const Duration(seconds: 1));
    await tick(t, const Duration(seconds: 5));
    expect(retries, 1);
  });

  test('the strip band uses a lock only when it is held for the next chapter itself', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(readerLockedForProvider('c371')), isNull);
    c.read(readerLockedNextProvider.notifier).state = (chapterKey: 'c9', lockedUntil: open, message: 'm', sourceId: 's');
    expect(c.read(readerLockedForProvider('c371')), isNull, reason: 'another chapter\'s lock');
    expect(c.read(readerLockedForProvider(null)), isNull);
    expect(c.read(readerLockedForProvider('c9')), isNotNull);
  });
}
