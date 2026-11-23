import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/updates/utils/notification_grouping.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/updates/updates_new.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';


void main() {
  final open = DateTime.utc(2026, 11, 23, 14);
  late DateTime now;

  SeriesUpdate group({DateTime? until, bool openFirst = false}) => SeriesUpdate(
        sourceId: 'asurascans',
        seriesKey: 's',
        title: 'Logging 10,000 Years into the Future',
        coverUrl: null,
        ambient: null,
        newestAt: DateTime.utc(2026, 11, 23, 9),
        chapters: [
          if (openFirst) (notificationId: 1, chapterKey: 'c369', chapterNumber: 369, title: 'Chapter 369', read: false, lockedUntil: null),
          (notificationId: 2, chapterKey: 'c370', chapterNumber: 370, title: 'Chapter 370', read: false, lockedUntil: until),
        ],
      );

  Future<void> overrideClock(WidgetTester t, SeriesUpdate g, {void Function()? onReadFrom}) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(ProviderScope(
      overrides: [clockProvider.overrideWithValue(() => now)],
      child: MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS, extensions: const [cinematicTokens]),
        home: Scaffold(
          body: SingleChildScrollView(
            child: UpdateGroupRow(
              group: g,
              coverUrl: null,
              sourceName: 'AsuraScans',
              now: now,
              fresh: const {},
              onFolio: (_) {},
              onReadFrom: onReadFrom ?? () {},
              onMarkRead: () {},
              onOpenSeries: () {},
              onTyped: (_) {},
            ),
          ),
        ),
      ),
    ),);
  }

  setUp(() => now = open.subtract(const Duration(seconds: 3)));

  testWidgets('a locked first chapter shows the countdown and no Read from button', (t) async {
    await overrideClock(t, group(until: open));
    expect(find.text('Opens in 00:03'), findsOneWidget);
    expect(find.text('Read from 370'), findsNothing);
    expect(find.text('Mark read'), findsOneWidget);
    expect(find.text('opens in 1 min'), findsOneWidget);
  });

  testWidgets('when the instant passes the Read from button returns with no refetch', (t) async {
    var taps = 0;
    await overrideClock(t, group(until: open), onReadFrom: () => taps++);
    now = now.add(const Duration(seconds: 3));
    await t.pump(const Duration(seconds: 3));
    expect(find.textContaining('Opens in'), findsNothing);
    expect(find.text('Read from 370'), findsOneWidget);
    await t.tap(find.byType(CineButton).first);
    expect(taps, 1);
  });

  testWidgets('an open chapter before a locked one keeps Read from; the locked folio is marked', (t) async {
    await overrideClock(t, group(until: open, openFirst: true));
    expect(find.text('Read from 369'), findsOneWidget);
    expect(find.textContaining('Opens in'), findsNothing);
    expect(find.text('opens in 1 min'), findsOneWidget);
  });

  testWidgets('a past instant is just an open chapter', (t) async {
    await overrideClock(t, group(until: open.subtract(const Duration(hours: 1))));
    await t.pump();
    expect(find.text('Read from 370'), findsOneWidget);
    expect(find.textContaining('Opens in'), findsNothing);
  });
}
