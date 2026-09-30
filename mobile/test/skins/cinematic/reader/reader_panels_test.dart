import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_identity.dart';
import 'package:manhwamaniacs/features/library/providers/bookmarks_provider.dart';
import 'package:manhwamaniacs/features/ocr/controllers/ocr_run_controller.dart';
import 'package:manhwamaniacs/features/ocr/models/page_text.dart';
import 'package:manhwamaniacs/features/ocr/providers/ocr_providers.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_view.dart';
import 'package:manhwamaniacs/features/reader/models/bookmark.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/models/reader_page.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_prefs_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/bubble_pulse.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/margins_panel.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/side_panel_layout.dart';

import '../../../screenshots/support/shot_network.dart';
import 'reader_paged_test.dart' show key;
import 'reader_test_support.dart';

Set<String> texts(WidgetTester tester) => {
      for (final e in find.byType(RichText).evaluate()) (e.widget as RichText).text.toPlainText().replaceAll('￼', ''),
    }..remove('');

ProviderContainer container(WidgetTester tester) => ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

const _text = [
  PageText(
    page: 1,
    text: 'You came back.\nWhy?',
    boxes: [
      OcrTextBox(text: 'You came back.', x: 0.1, y: 0.1, width: 0.5, height: 0.1),
      OcrTextBox(text: 'Why?', x: 0.2, y: 0.4, width: 0.3, height: 0.1),
    ],
  ),
];

List<Override> withOcr() => [
      ocrChapterTextProvider.overrideWith((ref, id) async => _text),
      ocrAvailableProvider.overrideWith((ref) async => true),
    ];

class FakeRun extends OcrRunController {
  final List<ChapterIdentity> started = [];

  @override
  Future<void> runChapter({required ChapterIdentity id, double? chapterNumber}) async {
    started.add(id);
    state = OcrRunState(phase: OcrRunPhase.recognizing, chapter: id, completedPages: 4, totalPages: 40);
  }
}

ReaderChapter savedChapter(String id) => ReaderChapter(
      id: id,
      seriesId: kReaderSeries,
      sourceId: kReaderSource,
      title: 'Chapter 2',
      pageCount: 3,
      pages: [for (var n = 1; n <= 3; n++) ReaderPage(id: '$id-$n', number: n, imageUrl: '', width: 800, height: 2400, localFile: File('/nonexistent/$id-$n.webp'))],
    );

class _Bookmarks extends BookmarksNotifier {
  _Bookmarks(this.list);
  final List<Bookmark> list;

  @override
  Future<BookmarksState> build() async => BookmarksState(bookmarks: list);
}

void main() {
  setUpAll(setUpShotCoverCache);

  testWidgets('a 450 ms press opens the page actions; without dialogue text or a saved chapter only three items show', (tester) async {
    await pumpReader(tester);
    await settleReader(tester, ms: 500);
    await tester.longPressAt(const Offset(195, 422));
    await settleReader(tester, ms: 1200);
    expect(find.byType(CineSheet), findsOneWidget);
    final t = texts(tester);
    expect(t, contains('PAGE 1'));
    expect(t, containsAll(['Bookmark this spot', 'Retry this page', 'Open page image']));
    expect(t, isNot(contains('Show dialogue on this page')));
    expect(t, isNot(contains("Scan this chapter's dialogue")));
    await disposeReader(tester);
  });

  testWidgets('the press does not open below 450 ms', (tester) async {
    await pumpReader(tester);
    await settleReader(tester, ms: 500);
    final g = await tester.startGesture(const Offset(195, 422));
    await tester.pump(const Duration(milliseconds: 400));
    await g.up();
    await settleReader(tester, ms: 600);
    expect(find.byType(CineSheet), findsNothing);
    await disposeReader(tester);
  });

  testWidgets('Shift+F10 opens the same sheet, and so does the setup footer', (tester) async {
    await pumpReader(tester);
    await settleReader(tester, ms: 500);
    await key(tester, LogicalKeyboardKey.f10, shift: true, ms: 1000);
    expect(find.byType(CineSheet), findsOneWidget);
    expect(texts(tester), contains('Bookmark this spot'));
    await tester.tap(find.text('Done', findRichText: true).last);
    await settleReader(tester, ms: 800);
    await key(tester, LogicalKeyboardKey.comma, ms: 900);
    await tester.drag(find.text('READING SETUP', findRichText: true), const Offset(0, -400));
    await tester.pump(const Duration(milliseconds: 700));
    final footer = find.textContaining('Page actions for p.', findRichText: true).last;
    await tester.ensureVisible(footer);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(footer);
    await settleReader(tester, ms: 1200);
    expect(texts(tester), containsAll(['PAGE 1', 'Open page image']));
    await disposeReader(tester);
  });

  testWidgets('Open page image opens the Lightbox with PAGE 1 · 800 × 2400', (tester) async {
    await pumpReader(tester);
    await settleReader(tester, ms: 500);
    await key(tester, LogicalKeyboardKey.f10, shift: true, ms: 1000);
    await tester.tap(find.text('Open page image', findRichText: true));
    await settleReader(tester);
    expect(find.byType(CineSheet), findsNothing);
    expect(texts(tester).any((s) => s.contains('PAGE 1 · 800 × 2400')), isTrue);
    expect(texts(tester), contains('Chapter 2 · page 1'), reason: 'the Lightbox title');
    await disposeReader(tester);
  });

  testWidgets('with OCR text: Show dialogue outlines the bubbles; a tap on one shows its text', (tester) async {
    await pumpReader(tester, extra: withOcr());
    await settleReader(tester, ms: 800);
    await key(tester, LogicalKeyboardKey.f10, shift: true, ms: 1000);
    expect(texts(tester), contains('Show dialogue on this page'));
    await tester.tap(find.text('Show dialogue on this page', findRichText: true));
    await settleReader(tester, ms: 900);
    expect(find.byKey(const ValueKey('ocr-outline')), findsNWidgets(2));
    await tester.tap(find.byKey(const ValueKey('ocr-outline')).first, warnIfMissed: false);
    await settleReader(tester, ms: 400);
    expect(find.byKey(const ValueKey('ocr-popover')), findsOneWidget);
    expect(texts(tester), contains('You came back.'));
    await disposeReader(tester);
  });

  testWidgets("Scan this chapter's dialogue shows for a saved chapter and starts the OCR run", (tester) async {
    final run = FakeRun();
    await pumpReader(tester, chapters: {'c2': savedChapter('c2')}, extra: [ocrAvailableProvider.overrideWith((ref) async => true), ocrRunControllerProvider.overrideWith(() => run)]);
    await settleReader(tester, ms: 800);
    await key(tester, LogicalKeyboardKey.f10, shift: true, ms: 1000);
    expect(texts(tester), contains("Scan this chapter's dialogue"));
    await tester.tap(find.text("Scan this chapter's dialogue", findRichText: true));
    await settleReader(tester, ms: 500);
    expect(run.started.single.chapterKey, 'c2');
    expect(texts(tester), contains('SCANNING 4 OF 40'));
    await disposeReader(tester);
  });

  for (final (platform, min) in [(TargetPlatform.iOS, 44.0), (TargetPlatform.android, 48.0)]) {
    testWidgets('every control in the page actions sheet and the Margins panel is at least $min on $platform', (tester) async {
      await pumpReader(tester, size: const Size(834, 1194), platform: platform, extra: [...withOcr(), circleSeriesProvider.overrideWith((ref, k) async => null)]);
      await settleReader(tester, ms: 800);
      void walk(Finder within, String what) {
        final tappables = find.descendant(of: within, matching: find.byWidgetPredicate((w) => w is Semantics && w.properties.onTap != null && (w.properties.enabled ?? true)));
        for (final e in tappables.evaluate()) {
          final box = e.renderObject! as RenderBox;
          if (!box.hasSize || box.size.isEmpty) continue;
          final label = (e.widget as Semantics).properties.label ?? 'unlabelled';
          expect(box.size.width, greaterThanOrEqualTo(min - 0.01), reason: '$what/$label width');
          expect(box.size.height, greaterThanOrEqualTo(min - 0.01), reason: '$what/$label height');
        }
      }

      await key(tester, LogicalKeyboardKey.f10, shift: true, ms: 1000);
      walk(find.byType(CineSheet), 'page actions');
      await tester.tap(find.text('Done', findRichText: true).last);
      await settleReader(tester, ms: 800);
      await key(tester, LogicalKeyboardKey.bracketRight, ms: 900);
      for (final tab in ['NOTES', 'DIALOGUE']) {
        await tester.tap(find.text(tab, findRichText: true).last);
        await settleReader(tester, ms: 600);
        walk(find.byType(MarginsPanel), 'margins/$tab');
      }
      await disposeReader(tester);
    });
  }

  group('Margins (834 x 1194)', () {
    const tablet = Size(834, 1194);

    testWidgets('] opens Margins with NOTES · DIALOGUE · CIRCLE; opening it closes Contents', (tester) async {
      await pumpReader(
        tester,
        size: tablet,
        extra: [...withOcr(), circleSeriesProvider.overrideWith((ref, k) async => const CircleSeriesData())],
      );
      await settleReader(tester, ms: 800);
      await key(tester, LogicalKeyboardKey.bracketLeft, ms: 900);
      var panels = container(tester).read(readerPrefsProvider('demo:k')).panels;
      expect(panels.left, isTrue);
      await key(tester, LogicalKeyboardKey.bracketRight, ms: 900);
      panels = container(tester).read(readerPrefsProvider('demo:k')).panels;
      expect(panels.right, isTrue);
      expect(panels.left, isFalse, reason: 'one side panel at a time; the last opened wins');
      expect(panels.lastOpened, 'right');
      expect(find.byType(MarginsPanel), findsOneWidget);
      expect(texts(tester), containsAll(['NOTES', 'DIALOGUE', 'CIRCLE', 'MARGINS']));
      expect(SidePanelLayout.panelWidth(834), greaterThanOrEqualTo(320));
      await disposeReader(tester);
    });

    testWidgets('the CIRCLE tab is absent when /circle/series answers 404', (tester) async {
      await pumpReader(tester, size: tablet, extra: [circleSeriesProvider.overrideWith((ref, k) async => null)]);
      await settleReader(tester, ms: 800);
      await key(tester, LogicalKeyboardKey.bracketRight, ms: 900);
      final t = texts(tester);
      expect(t, containsAll(['NOTES', 'DIALOGUE']));
      expect(t, isNot(contains('CIRCLE')));
      await disposeReader(tester);
    });

    testWidgets("NOTES lists this chapter's bookmarks; DIALOGUE lists the transcript and pulses a tapped line", (tester) async {
      final bookmark = Bookmark(
        clientId: 'b1',
        sourceId: kReaderSource,
        seriesKey: kReaderSeries,
        chapterKey: 'c2',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        anchorIndex: 3,
        anchorTotal: 6,
        note: 'The shadow moves',
      );
      await pumpReader(
        tester,
        size: tablet,
        extra: [
          ...withOcr(),
          circleSeriesProvider.overrideWith((ref, k) async => null),
          bookmarksProvider.overrideWith(() => _Bookmarks([bookmark])),
        ],
      );
      await settleReader(tester, ms: 800);
      await key(tester, LogicalKeyboardKey.bracketRight, ms: 900);
      expect(texts(tester), containsAll(['p. 3', 'The shadow moves', 'Add a note to this page']));
      await tester.tap(find.text('DIALOGUE', findRichText: true).last);
      await settleReader(tester, ms: 700);
      expect(texts(tester), containsAll(['p. 1', 'You came back.', 'Why?']));
      await tester.tap(find.text('Why?', findRichText: true).first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(BubblePulse), findsOneWidget, reason: 'the 2 px spot frame is drawn inside the page overlay');
      await tester.pump(const Duration(milliseconds: 1100));
      expect(find.byType(BubblePulse), findsNothing, reason: 'two 480 ms passes, then it goes');
      await disposeReader(tester);
    });

    testWidgets('CIRCLE: guarded rows show "reacted to Ch. 2" and unseal when the chapter completes', (tester) async {
      await pumpReader(
        tester,
        size: tablet,
        extra: [
          circleSeriesProvider.overrideWith(
            (ref, k) async => const CircleSeriesData(
              readers: [CircleReader(member: CircleMemberRef(profileId: 1, name: 'Asha'), chapterKey: 'c2', chapterNumber: 2)],
              chapters: [
                CircleChapterReactions(chapterKey: 'c2', chapterNumber: 2, by: [ReactionBy(profileId: 1, name: 'Asha', kind: ReactionKind.chefsKiss)]),
              ],
            ),
          ),
        ],
      );
      await settleReader(tester, ms: 800);
      await key(tester, LogicalKeyboardKey.bracketRight, ms: 900);
      final circle = find.text('CIRCLE', findRichText: true).last;
      await tester.ensureVisible(circle);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(circle);
      await settleReader(tester, ms: 900);
      expect(texts(tester), contains('reacted to Ch. 2'));
      expect(texts(tester), isNot(contains("CHEF'S KISS")));
      final engine = tester.widget<ReaderEngineView>(find.byType(ReaderEngineView)).controller;
      engine.emitChapterCompleted((sourceId: kReaderSource, seriesKey: kReaderSeries, chapterKey: 'c2'));
      await settleReader(tester, ms: 900);
      expect(texts(tester), contains("CHEF'S KISS"));
      expect(texts(tester), isNot(contains('reacted to Ch. 2')));
      await disposeReader(tester);
    });
  });
}
