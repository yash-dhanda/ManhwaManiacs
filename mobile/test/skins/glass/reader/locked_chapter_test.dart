import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_frames.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
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
}
