import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/app/theme/app_theme.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/models/reader_feed.dart';
import 'package:manhwamaniacs/features/reader/models/reader_page.dart';
import 'package:manhwamaniacs/features/reader/utils/page_extents.dart';
import 'package:manhwamaniacs/features/reader/widgets/reader_content.dart';
import 'package:manhwamaniacs/features/settings/models/reader_defaults.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../screenshots/support/shot_harness.dart';
import '../../screenshots/support/shot_network.dart';

/// Pixel parity for the reader.
///
/// Taken on the code as it stood before the reader engine was extracted, and
/// never regenerated since: the extraction (and anything after it that claims
/// to change no pixel) has to pass these untouched. Pages are painted here —
/// four hues, one white, one near-black — never real artwork.

const _pageColors = <Color>[
  Color(0xFFD64545), // red
  Color(0xFF3D8BD9), // blue
  Color(0xFF4DB36B), // green
  Color(0xFFE0A53A), // amber
  Color(0xFFFFFFFF), // all white
  Color(0xFF0B0B0D), // near black
];

const _host = 'http://example.test';
const _brokenPath = '/reader/page/broken/image';

String _pagePath(String chapterId, int number) =>
    '/reader/page/$chapterId-$number/image';

/// An 800 x 1200 page: a flat fill with a darker band, so where one page ends
/// and the next begins is visible in the capture.
Future<Uint8List> _paintPage(Color color) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 800, 1200),
    Paint()..color = color,
  );
  canvas.drawRect(
    const Rect.fromLTWH(0, 520, 800, 160),
    Paint()..color = Color.lerp(color, const Color(0xFF000000), 0.35)!,
  );
  final image = await recorder.endRecording().toImage(800, 1200);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

ReaderChapter _chapter(
  String id,
  String title,
  int pages, {
  Set<int> broken = const {},
}) {
  return ReaderChapter(
    id: id,
    seriesId: 's',
    title: title,
    pageCount: pages,
    pages: [
      for (var n = 1; n <= pages; n++)
        ReaderPage(
          id: '$id-$n',
          number: n,
          imageUrl: broken.contains(n)
              ? '$_host$_brokenPath'
              : '$_host${_pagePath(id, n)}',
          width: 800,
          height: 1200,
        ),
    ],
  );
}

class _Size {
  const _Size(this.width, this.height, this.ratio);
  final double width;
  final double height;
  final double ratio;
  String get label => '${width.toInt()}x${height.toInt()}';
}

const _sizes = [_Size(390, 844, 3), _Size(834, 1194, 2)];

void _useSize(WidgetTester tester, _Size size) {
  tester.view.physicalSize = Size(size.width, size.height) * size.ratio;
  tester.view.devicePixelRatio = size.ratio;
}

/// Lets the real page fetches and decodes finish while moving the fake clock
/// as little as possible, so the controls' auto-hide has not fired yet.
Future<void> _loadPages(WidgetTester tester, {int rounds = 30}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<void> _pumpReader(
  WidgetTester tester, {
  required ReaderFeed feed,
  int initialPage = 1,
  Map<String, Object> prefs = const {},
  VoidCallback? onNextChapter,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sharedPrefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      // A fresh container per scene: reader UI state (zoom, lock, controls)
      // must not carry from one scene into the next.
      key: UniqueKey(),
      overrides: [sharedPrefsProvider.overrideWithValue(sharedPrefs)],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: ReaderContent(
          feed: feed,
          scrollStorageKey: 'parity-${feed.chapters.first.id}',
          initialPage: initialPage,
          onBack: () {},
          onOpenSeries: () {},
          onNextChapter: onNextChapter,
        ),
      ),
    ),
  );
  await tester.pump();
  await _loadPages(tester);
}

Future<void> _expectGolden(String scene, _Size size) async {
  await expectLater(
    find.byType(ReaderContent),
    matchesGoldenFile('goldens/reader_parity_${scene}_${size.label}.png'),
  );
}

ScrollController _listController(WidgetTester tester) =>
    tester.widget<ListView>(find.byType(ListView)).controller!;

/// Lets the real-clock tap cooldown after a scroll (300 ms) run out.
Future<void> _waitOutTapCooldown(WidgetTester tester) => tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 350)),
    );

typedef _Scene = Future<void> Function(WidgetTester tester, _Size size);

final _scenes = <String, _Scene>{
  'strip_chrome': (tester, size) async {
    await _pumpReader(
      tester,
      feed: ReaderFeed.single(_chapter('a', 'Chapter 1', 12)),
      initialPage: 3,
    );
    await tester.pump(const Duration(milliseconds: 400));
  },
  'strip_bare': (tester, size) async {
    await _pumpReader(
      tester,
      feed: ReaderFeed.single(_chapter('a', 'Chapter 1', 12)),
      initialPage: 3,
    );
    await tester.pump(const Duration(milliseconds: 3100));
    // The bars start sliding out on the frame the auto-hide fires.
    await tester.pump(const Duration(milliseconds: 400));
  },
  'seam': (tester, size) async {
    final feed = ReaderFeed.of([
      _chapter('a', 'Chapter 1', 4),
      _chapter('b', 'Chapter 2', 4),
    ]);
    await _pumpReader(tester, feed: feed);
    final viewport = MediaQuery.sizeOf(tester.element(find.byType(ListView)));
    final metrics = ReaderPageMetrics.of(
      ReaderPageExtents(feed.pages),
      direction: ReadingDirection.vertical,
      fitMode: ReaderFitMode.width,
      viewportWidth: viewport.width,
      viewportHeight: viewport.height,
      leadingInsets: {feed.startOfChapter(1): kChapterSeamExtent},
    );
    // The seam divider's top edge is the top of chapter 2's first page.
    final seamTop = metrics.offsetToPage(feed.startOfChapter(1) + 1);
    _listController(tester).jumpTo(
      seamTop + kChapterSeamExtent / 2 - viewport.height / 2,
    );
    await tester.pump();
    await _loadPages(tester);
  },
  'ltr': (tester, size) async {
    await _pumpReader(
      tester,
      feed: ReaderFeed.single(_chapter('a', 'Chapter 1', 12)),
      prefs: {
        'settings_reading_direction': ReadingDirection.leftToRight.name,
      },
    );
    await tester.pump(const Duration(milliseconds: 400));
  },
  'broken': (tester, size) async {
    await _pumpReader(
      tester,
      feed: ReaderFeed.single(_chapter('c', 'Chapter 3', 12, broken: {1})),
    );
    // A 404 takes the cache manager longer to give up on than a hit takes
    // to load.
    for (var i = 0; i < 200 && find.text('Retry').evaluate().isEmpty; i++) {
      await _loadPages(tester, rounds: 1);
    }
    await tester.pump(const Duration(milliseconds: 3100));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Failed to load page'), findsOneWidget);
  },
  'locked_end': (tester, size) async {
    await _pumpReader(
      tester,
      feed: ReaderFeed.single(_chapter('a', 'Chapter 1', 12)),
      prefs: {
        'settings_lock_reader_controls': true,
        'settings_auto_next_chapter': false,
      },
      onNextChapter: () {},
    );
    final controller = _listController(tester);
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump();
    await _loadPages(tester, rounds: 10);
    await tester.pump(const Duration(milliseconds: 3100));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Next chapter'), findsWidgets);
  },
  'zoom2': (tester, size) async {
    await _pumpReader(
      tester,
      feed: ReaderFeed.single(_chapter('a', 'Chapter 1', 12)),
      initialPage: 3,
    );
    await _waitOutTapCooldown(tester);
    final centre = tester.getCenter(find.byType(ListView));
    // The reader detects a double tap itself, against the wall clock: two
    // taps with nothing in between.
    await tester.tapAt(centre);
    await tester.tapAt(centre);
    await tester.pump();
    await _loadPages(tester, rounds: 10);
    await tester.pump(const Duration(milliseconds: 3100));
    await tester.pump(const Duration(milliseconds: 400));
  },
};

void main() {
  setUpAll(() async {
    await loadAppFonts();
    setUpShotCoverCache();
    final painted = <Uint8List>[
      for (final color in _pageColors) await _paintPage(color),
    ];
    final covers = <String, Uint8List>{};
    for (final id in ['a', 'b', 'c']) {
      for (var n = 1; n <= 12; n++) {
        covers[_pagePath(id, n)] = painted[(n - 1) % painted.length];
      }
    }
    // [_brokenPath] is deliberately left out: the server answers it 404.
    addShotCovers(covers);
  });

  // One test for every scene: the image cache manager is a process-wide
  // singleton, and a fetch left in flight by one test's fake clock never
  // completes and holds one of its few download slots for good. In a single
  // test every fetch finishes on the same clock.
  testWidgets('reader parity goldens', (tester) async {
    addTearDown(tester.view.reset);
    for (final size in _sizes) {
      for (final scene in _scenes.entries) {
        _useSize(tester, size);
        await scene.value(tester, size);
        await _expectGolden(scene.key, size);
        // Let every fetch the scene started land before the next one.
        await _loadPages(tester, rounds: 10);
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpUntilCoversLoad(tester, rounds: 5);
    await tester.pump(const Duration(seconds: 11));
  });
}
