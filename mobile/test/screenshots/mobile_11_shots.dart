// ignore_for_file: require_trailing_commas, directives_ordering
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/library/models/collection.dart';
import 'package:manhwamaniacs/features/library/models/global_search_result.dart';
import 'package:manhwamaniacs/features/library/models/tag.dart';
import 'package:manhwamaniacs/features/sources/models/source_chapter_progress.dart';
import 'package:manhwamaniacs/features/sources/models/source_search_group.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/gallery/primitives_gallery.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_match_cut_page.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/book/book_view.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_view.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/manga_view.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/repoint_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/offline_edition.dart';

import '../skins/cinematic/feature/feature_test_support.dart';
import 'support/shot_covers.dart';
import 'support/shot_network.dart';
import 'support/series_shots.dart';
import 'support/skin_shots.dart';

const _coverPath = '/sources/demo/series/k/cover';

SourceChapterProgress _p(int page, int count, {bool done = false}) => SourceChapterProgress(
      page: page,
      pageCount: count,
      completed: done,
      updatedAt: DateTime.utc(2026, 9, 29),
    );

/// The mobile-11 proof shots: the Cinematic series page, Book page and chapter
/// downloads at `kSkinShotSizes`, with invented fixtures only.
void mobile11Shots() {
  Future<void> addCovers(WidgetTester tester) async {
    final png = await tester.runAsync(
        () => const ShotCoverArt(title: 'Tower of Dawn', seed: 3).toPng(width: 480, height: 720));
    addShotCovers({_coverPath: png!});
  }

  FeatureRig rig({
    Map<String, ChapterDownloadStatus> statuses = const {},
    bool online = true,
    bool mature = false,
    List<Override> extra = const [],
    DownloadQueuePauseReason? pause,
    int? free,
    bool followed = true,
    Map<String, SourceChapterProgress>? progress,
  }) =>
      FeatureRig(
        online: online,
        statuses: statuses,
        followed: followed
            ? followedRow(
                rating: mature ? 'mature' : 'safe',
                favorite: true,
                notify: true,
                coverUrl: _coverPath,
                tags: const [Tag(id: 1, name: 'slow burn', category: 'custom')],
              )
            : null,
        serverProgress: progress ??
            {
              for (var i = 1; i <= 142; i++) 'c$i': _p(20, 20, done: true),
              'c143': _p(12, 20),
            },
        tags: const [Tag(id: 1, name: 'slow burn', category: 'custom'), Tag(id: 2, name: 'to reread', category: 'custom')],
        shelves: const [
          Collection(id: 1, name: 'Weekend', seriesCount: 1, sortOrder: 0),
          Collection(id: 2, name: 'Someday', seriesCount: 0, sortOrder: 1),
        ],
        suggested: (tags: const ['dungeon', 'rivals', 'tower'], available: true, reason: null),
        ocrWords: {for (var i = 1; i <= 34; i++) 'c$i': 40},
        pauseReason: pause,
        freeBytes: free,
        extra: extra,
      );

  Future<void> shot(
    WidgetTester tester,
    String name, {
    bool phone = true,
    bool tablet = true,
    required Future<void> Function(bool wide) show,
  }) async {
    await addCovers(tester);
    for (final (size, wide, on) in [
      (kSkinShotSizes[0], false, phone),
      (kSkinShotSizes[1], true, tablet),
    ]) {
      if (!on) continue;
      await show(wide);
      await pumpUntilCoversLoad(tester, rounds: 4);
      await captureSeriesShot(tester, name, size);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 11));
    }
  }

  Widget page(FeatureRig r, {String fixture = 'manga-showcase'}) =>
      MangaFeatureView(data: fixtureData(fixture, followed: r.followed));

  Future<void> up(WidgetTester tester, {Duration by = const Duration(seconds: 5)}) =>
      settleFeature(tester, by: by);

  testWidgets('mobile-11 feature phone and tablet', (tester) async {
    await shot(tester, 'feature', show: (wide) async {
      final r = rig();
      await pumpFeature(tester, rig: r, wide: wide, child: page(r));
      await up(tester);
    });
  });

  testWidgets('mobile-11 feature grid tablet', (tester) async {
    await shot(tester, 'feature-grid', phone: false, show: (wide) async {
      final r = rig();
      await pumpFeature(
        tester,
        rig: r,
        wide: true,
        wrap: (home) => Stack(children: [
          home,
          IgnorePointer(
            child: Row(children: [
              for (var i = 0; i < 8; i++)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    color: (i < 4 ? Colors.blue : Colors.orange).withValues(alpha: 0.12),
                  ),
                ),
            ]),
          ),
        ]),
        child: page(r),
      );
      await up(tester);
    });
  });

  testWidgets('mobile-11 feature match cut mid phone', (tester) async {
    await addCovers(tester);
    final r = rig();
    final f = loadSeriesFixture('manga-showcase');
    final app = await pumpFeatureRouter(
      tester,
      rig: r,
      extra: [
        sourceSeriesDetailProvider.overrideWith(
            (ref, p) async => SourceSeriesDetailData(series: f.series, chapters: f.chapters)),
      ],
      routes: [
        GoRoute(
          path: '/',
          builder: (c, s) => Scaffold(
            body: Center(
              child: Hero(
                tag: 'cover-demo-k',
                child: Container(width: 120, height: 180, color: const Color(0xFF3E8B7F), child: const Center(child: Text('poster'))),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/sources/:sourceId/series/:seriesKey',
          pageBuilder: (c, s) => cineMatchCutPage(
            s,
            FeatureScreen(sourceId: s.pathParameters['sourceId']!, seriesKey: s.pathParameters['seriesKey']!),
          ),
        ),
      ],
    );
    unawaited(app.router.push<void>('/sources/demo/series/k'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));
    await captureSeriesShot(tester, 'feature-match-cut-mid', kSkinShotSizes[0]);
    await settleFeature(tester, by: const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('mobile-11 feature details', (tester) async {
    await shot(tester, 'feature-details', show: (wide) async {
      final r = rig();
      await pumpFeature(tester, rig: r, wide: wide, size: wide ? null : const Size(390, 1400), child: page(r));
      await tester.tap(find.textContaining('02 DETAILS'));
      await frames(tester, 700);
      await scrollToPanels(tester);
      await up(tester, by: const Duration(seconds: 2));
    });
    await shot(tester, 'feature-at-a-glance', tablet: false, show: (wide) async {
      final r = rig();
      await pumpFeature(tester, rig: r, size: const Size(390, 1400), child: page(r));
      await tester.tap(find.textContaining('02 DETAILS'));
      await frames(tester, 700);
      await scrollToPanels(tester);
      await up(tester, by: const Duration(seconds: 2));
    });
  });

  testWidgets('mobile-11 feature overflow and mature override', (tester) async {
    await shot(tester, 'feature-overflow', tablet: false, show: (wide) async {
      final r = rig();
      await pumpFeature(tester, rig: r, child: page(r));
      await up(tester, by: const Duration(seconds: 2));
      await tester.tap(find.byTooltip('More'));
      await frames(tester, 600);
    });
    await shot(tester, 'feature-mature-override', tablet: false, show: (wide) async {
      final r = rig(mature: true);
      await pumpFeature(tester, rig: r, child: page(r));
      await up(tester, by: const Duration(seconds: 2));
      await tester.tap(find.byTooltip('More'));
      await frames(tester, 600);
      await tester.drag(find.byType(SingleChildScrollView).last, const Offset(0, -300));
      await frames(tester, 300);
    });
  });

  testWidgets('mobile-11 feature rating card', (tester) async {
    await shot(tester, 'feature-rating-card', tablet: false, show: (wide) async {
      final r = rig(mature: true);
      await pumpFeature(tester, rig: r, child: page(r, fixture: 'manga-mature'));
      await tester.pump(const Duration(milliseconds: 900));
    });
  });

  testWidgets('mobile-11 feature lightbox', (tester) async {
    await shot(tester, 'feature-lightbox', show: (wide) async {
      final r = rig();
      await pumpFeature(tester, rig: r, wide: wide, child: page(r));
      await up(tester, by: const Duration(seconds: 2));
      await tester.longPress(find.byType(Hero).first);
      await frames(tester, 900);
    });
  });

  testWidgets('mobile-11 feature repoint', (tester) async {
    const asura = GlobalSearchItem(kind: 'source', source: 'asura', seriesId: 'tower', title: 'Tower of Dawn', extra: {'chapter_count': 150});
    const other = GlobalSearchItem(kind: 'source', source: 'flame', seriesId: 'tod', title: 'Tower of Dawn (Official)', extra: {'chapter_count': 143});
    final sources = FakeSources(
      groups: [
        const SourceSearchGroup(source: 'asura', sourceName: 'Asura', status: SourceGroupStatus.ok, items: [asura]),
        const SourceSearchGroup(source: 'flame', sourceName: 'Flame', status: SourceGroupStatus.ok, items: [other]),
        const SourceSearchGroup(source: 'reaper', sourceName: 'Reaper', status: SourceGroupStatus.error),
      ],
      chapters: [
        for (var i = 1; i <= 150; i++)
          SourceChapterSummary(id: 'x$i', sourceId: 'asura', seriesId: 'tower', title: 'Chapter $i', number: i.toDouble(), pageCount: 10),
      ],
    );
    await addCovers(tester);
    for (final mapping in [false, true]) {
      final r = rig(extra: [sourcesRepositoryProvider.overrideWithValue(sources)]);
      final data = fixtureData('manga-showcase', followed: r.followed);
      await pumpFeature(
        tester,
        rig: r,
        child: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showRepointSheet(context, data, sourceIsDown: false),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await frames(tester, 700);
      if (mapping) {
        await tester.tap(find.text('Tower of Dawn'));
        await frames(tester, 500);
      }
      await pumpUntilCoversLoad(tester, rounds: 3);
      await captureSeriesShot(
          tester, 'feature-repoint-${mapping ? 'mapping' : 'candidates'}', kSkinShotSizes[0]);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 11));
    }
  });

  final ten = {for (var i = 1; i <= 10; i++) 'c$i'};

  testWidgets('mobile-11 feature select and downloads', (tester) async {
    Future<void> select(WidgetTester tester, FeatureRig r, bool wide) async {
      await pumpFeature(tester, rig: r, wide: wide, size: wide ? null : const Size(390, 1500), child: page(r));
      await up(tester, by: const Duration(seconds: 2));
      await scrollToPanels(tester);
      await tester.tap(find.text('Select'));
      await frames(tester);
    }

    await shot(tester, 'feature-select', show: (wide) async {
      final r = rig(progress: {});
      await select(tester, r, wide);
      await tester.tap(find.text('NEXT 10'));
      await frames(tester, 300);
    });
    await shot(tester, 'feature-downloading', tablet: false, show: (wide) async {
      final r = rig(progress: {}, statuses: {
        for (final k in ten) k: (state: k == 'c3' ? DownloadChapterState.downloading : (k.compareTo('c3') < 0 && k.length == 2 ? DownloadChapterState.complete : DownloadChapterState.queued), error: null),
      });
      await select(tester, r, wide);
      await tester.tap(find.text('NEXT 10'));
      await frames(tester, 300);
      await tester.tap(find.text('Download 10'));
      await frames(tester, 500);
    });
    await shot(tester, 'feature-download-card', tablet: false, show: (wide) async {
      final r = rig(progress: {}, statuses: {
        for (var i = 1; i <= 12; i++) 'c$i': (state: DownloadChapterState.complete, error: null),
        'c13': (state: DownloadChapterState.downloading, error: null),
        'c14': (state: DownloadChapterState.queued, error: null),
        'c15': (state: DownloadChapterState.failed, error: 'x'),
      });
      await pumpFeature(tester, rig: r, size: const Size(390, 1500), child: page(r));
      await up(tester, by: const Duration(seconds: 2));
      await scrollToPanels(tester);
    });
    await shot(tester, 'feature-download-summary-saved', tablet: false, show: (wide) async {
      final r = rig(progress: {}, statuses: {
        for (final k in ten) k: (state: DownloadChapterState.complete, error: null),
      });
      await select(tester, r, wide);
      await tester.tap(find.text('NEXT 10'));
      await frames(tester, 300);
      await tester.tap(find.text('Download 10'));
      await frames(tester, 500);
    });
    await shot(tester, 'feature-download-summary-out-of-room', tablet: false, show: (wide) async {
      final r = rig(
        progress: {},
        pause: DownloadQueuePauseReason.freeSpaceFloor,
        free: 380 * 1024 * 1024,
        statuses: {
          for (final k in ten) k: (state: DownloadChapterState.queued, error: null),
        },
      );
      await select(tester, r, wide);
      await tester.tap(find.text('NEXT 10'));
      await frames(tester, 300);
      await tester.tap(find.text('Download 10'));
      await frames(tester, 600);
    });
  });

  testWidgets('mobile-11 feature states', (tester) async {
    final f = loadSeriesFixture('manga-showcase');
    Future<void> view(WidgetTester tester, FeatureRig r, bool wide) => pumpFeature(
          tester,
          rig: r,
          wide: wide,
          child: const FeatureView(sourceId: 'demo', seriesKey: 'k'),
        );
    FeatureRig detail(Future<SourceSeriesDetailData> Function() d,
            {bool online = true, List<Override> extra = const []}) =>
        FeatureRig(online: online, extra: [
          sourceSeriesDetailProvider.overrideWith((ref, p) => d()),
          ...extra,
        ]);

    await shot(tester, 'feature-loading', show: (wide) async {
      await view(tester, detail(() => Completer<SourceSeriesDetailData>().future), wide);
      await tester.pump(const Duration(milliseconds: 200));
    });
    for (final (name, listed, online) in [
      ('feature-chapters-offline', 201, false),
      ('feature-chapters-unavailable', 201, true),
      ('feature-no-chapters', 0, true),
    ]) {
      await shot(tester, name, show: (wide) async {
        final s = f.series;
        final series = SourceSeriesSummary(id: s.id, sourceId: s.sourceId, title: s.title, chapterCount: listed, genres: s.genres, coverUrl: '', description: s.description, author: s.author, artist: s.artist, status: s.status);
        await view(
            tester,
            detail(() async => SourceSeriesDetailData(series: series, chapters: const []), online: online),
            wide);
        await up(tester, by: const Duration(seconds: 4));
        await scrollToPanels(tester);
      });
    }
    await shot(tester, 'feature-error', show: (wide) async {
      await view(tester, detail(() async => throw const ApiError(statusCode: 500, code: 'boom', message: 'x')), wide);
      await up(tester, by: const Duration(seconds: 3));
    });
    await shot(tester, 'feature-offline-saved', show: (wide) async {
      final saved = (series: f.series, chapters: f.chapters.take(12).toList());
      await view(
          tester,
          detail(() async => throw const NetworkError(message: 'offline'), online: false, extra: [
            offlineEditionProvider.overrideWith((ref, k) async => saved),
          ]),
          wide);
      await up(tester, by: const Duration(seconds: 4));
    });
    await shot(tester, 'feature-notavailable', show: (wide) async {
      await view(tester, detail(() async => throw const ApiError(statusCode: 404, code: 'series_not_found', message: 'x')), wide);
      await up(tester, by: const Duration(seconds: 3));
    });
  });

  testWidgets('mobile-11 book', (tester) async {
    Widget book(FeatureRig r, {String fixture = 'novel-long', String? focus}) =>
        BookView(data: fixtureData(fixture, followed: r.followed), focusChapter: focus);

    await shot(tester, 'book', show: (wide) async {
      final r = rig();
      await pumpFeature(tester, rig: r, novel: true, wide: wide, child: book(r, fixture: 'novel-short'));
      await up(tester, by: const Duration(seconds: 4));
    });
    await shot(tester, 'book-contents-window', phone: false, show: (wide) async {
      final r = rig();
      await pumpFeature(tester, rig: r, novel: true, wide: true, child: book(r, focus: 'c600'));
      await up(tester, by: const Duration(seconds: 4));
    });
    await shot(tester, 'book-contents-sheet-search', tablet: false, show: (wide) async {
      final r = rig();
      await pumpFeature(tester, rig: r, novel: true, child: book(r, fixture: 'novel-short'));
      await up(tester, by: const Duration(seconds: 3));
      await tester.tap(find.byKey(const Key('book-go-to')));
      await frames(tester, 600);
      await tester.enterText(find.byKey(const Key('contents-go-to')), '7');
      await tester.pump();
    });
    await shot(tester, 'book-pick-chapters', tablet: false, show: (wide) async {
      final r = rig();
      await pumpFeature(tester, rig: r, novel: true, size: const Size(390, 1500), child: book(r, fixture: 'novel-short'));
      await up(tester, by: const Duration(seconds: 3));
      await tester.tap(find.text('Pick chapters'));
      await frames(tester, 300);
      await tester.tap(find.text('WHOLE BOOK'));
      await frames(tester, 300);
    });
    await shot(tester, 'book-loading', tablet: false, show: (wide) async {
      await pumpFeature(
        tester,
        rig: FeatureRig(extra: [
          sourceSeriesDetailProvider.overrideWith((ref, p) => Completer<SourceSeriesDetailData>().future),
        ]),
        novel: true,
        child: const FeatureView(sourceId: 'demo', seriesKey: 'k'),
      );
      await tester.pump(const Duration(milliseconds: 200));
    });
    await shot(tester, 'book-error', tablet: false, show: (wide) async {
      await pumpFeature(
        tester,
        rig: FeatureRig(extra: [
          sourceSeriesDetailProvider.overrideWith((ref, p) async => throw const ApiError(statusCode: 500, code: 'boom', message: 'x')),
        ]),
        novel: true,
        child: const FeatureView(sourceId: 'demo', seriesKey: 'k'),
      );
      await up(tester, by: const Duration(seconds: 3));
    });
    await shot(tester, 'book-contents-empty', tablet: false, show: (wide) async {
      final r = rig();
      await pumpFeature(
        tester,
        rig: r,
        novel: true,
        child: BookView(data: fixtureData('novel-short', followed: r.followed).withChapters(const [])),
      );
      await up(tester, by: const Duration(seconds: 3));
    });
  });

  testWidgets('mobile-11 gallery, text scale and reduced motion', (tester) async {
    await pumpFeature(tester, child: const Scaffold(body: SeriesPrimitivesGallery()), size: const Size(390, 640));
    await captureSeriesShotPlain(tester, 'download-marks-gallery');
    await tester.pumpWidget(const SizedBox());
    await addCovers(tester);
    final r = rig();
    await pumpFeature(tester, rig: r, textScale: 2.0, child: page(r));
    await up(tester, by: const Duration(seconds: 4));
    await pumpUntilCoversLoad(tester, rounds: 3);
    await captureSeriesShot(tester, 'feature-text-2.0', kSkinShotSizes[0]);
    await tester.pumpWidget(const SizedBox());
    final r2 = rig();
    await pumpFeature(tester, rig: r2, reducedMotion: true, child: page(r2));
    await tester.pump(const Duration(milliseconds: 300));
    await pumpUntilCoversLoad(tester, rounds: 3);
    await captureSeriesShot(tester, 'feature-reduced-motion', kSkinShotSizes[0]);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 11));
  });
}
