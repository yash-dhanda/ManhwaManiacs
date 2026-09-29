// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/collection.dart';
import 'package:manhwamaniacs/features/library/models/tag.dart';
import 'package:manhwamaniacs/features/sources/models/series_enrichment.dart';
import 'package:manhwamaniacs/features/sources/models/source_chapter_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/dashed_token.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/drop_cap_paragraph.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/manga_view.dart';

import 'feature_test_support.dart';

SourceChapterProgress _read() => SourceChapterProgress(
      page: 20,
      pageCount: 20,
      completed: true,
      updatedAt: DateTime.utc(2026, 9, 29),
    );

Future<FeatureRig> _details(
  WidgetTester tester, {
  FeatureRig? rig,
  String fixture = 'manga-long',
  bool wide = false,
}) async {
  final r = await pumpFeature(
    tester,
    rig: rig ?? FeatureRig(followed: followedRow()),
    wide: wide,
    size: wide ? null : const Size(390, 1800),
    child: MangaFeatureView(data: fixtureData(fixture, followed: (rig ?? FeatureRig(followed: followedRow())).followed)),
  );
  await tester.tap(find.textContaining('02 DETAILS'));
  await frames(tester, 600);
  await scrollToPanels(tester);
  return r;
}

void main() {
  testWidgets('At a glance: the Stat block, status, time and OCR coverage', (tester) async {
    await _details(
      tester,
      rig: FeatureRig(
        followed: followedRow(),
        serverProgress: {for (var i = 1; i <= 5; i++) 'c$i': _read()},
        ocrWords: const {'c1': 12, 'c2': 30},
      ),
    );
    expect(find.text('CHAPTERS READ'), findsOneWidget);
    expect(find.text('5 / 201'), findsOneWidget);
    expect(find.text('YOUR TIME HERE —'), findsOneWidget);
    expect(find.text('Dialogue indexed for 2 of 201 chapters'), findsOneWidget);
    for (final label in ['READING', 'PLAN TO READ', 'ON HOLD', 'DONE', 'DROPPED', 'NOT STARTED']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('choosing a reading status patches the follow', (tester) async {
    final r = await _details(tester);
    await tester.tap(find.text('ON HOLD'));
    await frames(tester, 200);
    expect(r.rec.patches.single['reading_status'], 'on_hold');
  });

  testWidgets('own tags are removable tokens: x untags', (tester) async {
    final r = await _details(
      tester,
      rig: FeatureRig(followed: followedRow(tags: const [Tag(id: 4, name: 'slow burn', category: 'custom')])),
    );
    expect(find.byKey(const Key('own-tag-4')), findsOneWidget);
    await tester.tap(find.byTooltip('Remove tag slow burn'));
    await frames(tester, 200);
    expect(r.rec.tagCalls, ['remove:4']);
    expect(find.byKey(const Key('own-tag-4')), findsNothing);
  });

  testWidgets('Add tag opens a sheet of the profile tags, and New tag creates one', (tester) async {
    final r = await _details(
      tester,
      rig: FeatureRig(
        followed: followedRow(),
        tags: const [Tag(id: 9, name: 'favourite arc', category: 'custom')],
      ),
    );
    await tester.tap(find.byKey(const Key('add-tag')));
    await frames(tester);
    expect(find.text('favourite arc'), findsOneWidget);
    await tester.tap(find.text('favourite arc'));
    await frames(tester, 200);
    expect(r.rec.tagCalls, ['add:9']);
    // `New tag…` opens the shared tag sheet; its `New tag` adds a row whose field creates the tag.
    await tester.tap(find.text('New tag…'));
    await frames(tester, 400);
    await tester.tap(find.text('New tag'));
    await frames(tester, 300);
    await tester.enterText(find.byType(TextField).last, 'to reread');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await frames(tester);
    expect(r.rec.tagCalls, containsAllInOrder(['add:9', 'create:to reread']));
  });

  testWidgets('SUGGESTED dashed tokens: accept adds a tag, reject records feedback', (tester) async {
    final r = await _details(
      tester,
      rig: FeatureRig(
        followed: followedRow(),
        suggested: (tags: const ['dungeon', 'rivals'], available: true, reason: null),
        tags: const [Tag(id: 3, name: 'dungeon', category: 'custom')],
      ),
    );
    expect(find.text('SUGGESTED'), findsOneWidget);
    expect(find.byType(DashedToken), findsNWidgets(2));
    await tester.tap(find.byTooltip('Add tag dungeon'));
    await frames(tester, 200);
    expect(r.rec.tagCalls, ['add:3']);
    await tester.tap(find.byTooltip('Reject tag rivals'));
    await frames(tester, 200);
    expect(r.ai.rejected, ['rivals']);
  });

  testWidgets('the SUGGESTED line is absent when the desk is closed', (tester) async {
    await _details(tester, rig: FeatureRig(followed: followedRow()));
    expect(find.text('SUGGESTED'), findsNothing);
    expect(find.byType(DashedToken), findsNothing);
  });

  testWidgets('shelves that hold the series are links, with Add to shelf', (tester) async {
    final r = await _details(
      tester,
      rig: FeatureRig(
        followed: followedRow(),
        shelves: const [
          Collection(id: 1, name: 'Weekend', seriesCount: 1, sortOrder: 0),
          Collection(id: 2, name: 'Someday', seriesCount: 0, sortOrder: 1),
        ],
      ),
    );
    expect(find.byKey(const Key('shelf-1')), findsOneWidget);
    expect(find.byKey(const Key('shelf-2')), findsNothing);
    await tester.tap(find.byKey(const Key('add-to-shelf')));
    await frames(tester, 500);
    await tester.tap(find.text('Someday'));
    await frames(tester);
    expect(r.rec.shelfCalls, ['add:2']);
  });

  testWidgets('DETAILS: drop cap synopsis, genre links, no enrichment lines for a null answer', (tester) async {
    await _details(tester);
    expect(find.byType(DropCapParagraph), findsOneWidget);
    expect(find.text('ACTION'), findsOneWidget);
    expect(find.textContaining('ANILIST'), findsNothing);
    expect(find.textContaining('Read on'), findsNothing);
  });

  testWidgets('DETAILS: enrichment credits and official platform links', (tester) async {
    await _details(
      tester,
      rig: FeatureRig(
        followed: followedRow(),
        enrichment: const SeriesEnrichment(
          anilistId: 1,
          format: 'MANHWA',
          score: 8.4,
          official: [(site: 'Demo Comics', url: 'https://example.test/read')],
        ),
      ),
    );
    expect(find.text('FORMAT  MANHWA'), findsOneWidget);
    expect(find.text('ANILIST ★ 8.4'), findsOneWidget);
    expect(find.text('Read on Demo Comics ↗'), findsOneWidget);
  });

  testWidgets('offline: the status slug line is disabled with Needs a connection', (tester) async {
    final r = await _details(tester, rig: FeatureRig(followed: followedRow(), online: false));
    expect(find.byTooltip('Needs a connection.'), findsWidgets);
    await tester.tap(find.text('DONE'));
    await frames(tester, 200);
    expect(r.rec.patches, isEmpty);
  });
}
