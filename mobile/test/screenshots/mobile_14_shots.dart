// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/ambient.dart';
import 'package:manhwamaniacs/features/novels/models/novel_typography.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/novel_paragraph.dart';

import '../skins/cinematic/novel/novel_test_support.dart';
import 'support/series_shots.dart';
import 'support/skin_shots.dart';

/// The mobile-14 proof shots: the Cinematic novel reader, "The page", in every stock, face, layout
/// and state, over the invented Alice fixture chapter (public domain).
void mobile14Shots() {
  const landscape = kSkinShotLandscape;

  SourceSeriesSummary withAmbient() {
    final f = loadSeriesFixture('manga-ongoing').series;
    return SourceSeriesSummary(
      id: f.id,
      sourceId: f.sourceId,
      title: f.title,
      chapterCount: f.chapterCount,
      genres: f.genres,
      coverUrl: f.coverUrl,
      status: f.status,
      ambient: const Ambient(duo: Color(0xFFD98C3F), tint: Color(0xFF17100A), ink: Color(0xFFF0C98F)),
    );
  }

  Future<void> show(
    WidgetTester tester,
    String name, {
    SkinShotSize size = const SkinShotSize('phone', Size(390, 844), 3.0, EdgeInsets.only(top: 47, bottom: 34)),
    bool chrome = false,
    Map<String, dynamic> settings = const {},
    Future<void> Function(NovelPreferencesControllerLike c)? book,
    Future<void> Function(WidgetTester tester, NovelRig rig)? act,
    bool reduced = false,
    double textScale = 1,
    bool bold = false,
    bool offline = false,
    bool cacheStale = false,
    bool issue = false,
    Map<String, Object> failing = const {},
    Map<String, Future<void>> holds = const {},
    bool alt = false,
    TargetPlatform platform = TargetPlatform.android,
    List<String>? paragraphs,
    bool attribution = false,
    String chapterKey = '1',
  }) async {
    final rig = await pumpNovel(
      tester,
      size: size.logical,
      padding: size.padding,
      chapterKey: chapterKey,
      reduced: reduced,
      textScale: textScale,
      boldText: bold,
      offline: offline,
      cacheStale: cacheStale,
      failing: failing,
      holds: holds,
      platform: platform,
      paragraphs: paragraphs,
      attribution: attribution ? fixtureAttribution() : null,
      series: issue ? withAmbient() : null,
      boundaryKey: kSkinShotKey,
    );
    await settleNovel(tester, ms: 800);
    if (settings.isNotEmpty) await rig.settings(settings);
    if (book != null) await rig.book((c) => book(c as NovelPreferencesControllerLike));
    await settleNovel(tester, ms: 400);
    if (act != null) await act(tester, rig);
    if (chrome) {
      await tester.tapAt(Offset(size.logical.width / 2, size.logical.height / 2));
      await settleNovel(tester, ms: 500);
    }
    await captureSeriesShot(tester, name, size);
    await disposeNovel(tester);
  }

  testWidgets('mobile-14 stocks', (tester) async {
    await show(tester, 'novel-nitrate', chrome: true);
    for (final (id, name) in const [('ink', 'ink'), ('sepiaNight', 'sepia-night'), ('dusk', 'dusk'), ('moss', 'moss'), ('rosewood', 'rosewood')]) {
      await show(tester, 'novel-$name', settings: {'stock': id});
    }
    await show(tester, 'novel-issue', settings: {'stock': 'issue'}, issue: true);
    await show(tester, 'novel-nitrate', size: kSkinShotSizes[1], chrome: true);
    await show(tester, 'novel', size: landscape);
  });
}

typedef NovelPreferencesControllerLike = dynamic;
