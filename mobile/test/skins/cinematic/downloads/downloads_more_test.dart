// ignore_for_file: directives_ordering
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/platform/media_store.dart';
import 'package:manhwamaniacs/features/downloads/models/downloaded_series_group.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart';
import 'package:manhwamaniacs/features/downloads/models/series_storage_usage.dart';
import 'package:manhwamaniacs/features/downloads/models/storage_cap.dart';
import 'package:manhwamaniacs/features/downloads/providers/download_switches_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/storage_settings_provider.dart';
import 'package:manhwamaniacs/features/downloads/services/chapter_export.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_slug_lines.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/downloads/save_to_files_sheet.dart';
import 'package:mocktail/mocktail.dart';

import 'downloads_rig.dart';

const gb = 1024 * 1024 * 1024;

class FakeExporter extends ChapterExporter {
  FakeExporter(this.result, {this.fail = false}) : super(documentsDirectory: Future.value(Directory.systemTemp));
  final ChapterExportResult result;
  final bool fail;
  ChapterExportFormat? formatSeen;

  @override
  Future<ChapterExportResult> export({
    required store,
    required String seriesLabel,
    required List<SavedChapter> chapters,
    required ChapterExportFormat format,
  }) async {
    formatSeen = format;
    if (fail) throw const FileSystemException('disk full');
    return result;
  }
}

class FakeMedia extends MediaStoreChannel {
  FakeMedia(this.dest);
  final ExportDestination dest;
  int saved = 0;

  @override
  Future<ExportDestination> destination({TargetPlatform? platform}) async => dest;

  @override
  Future<int> saveExport({required Directory seriesDirectory, required String seriesFolderName}) async => saved++;
}

ChapterExportResult exported({int chapters = 12, int pages = 480, int skipped = 2}) => ChapterExportResult(
      directory: Directory.systemTemp,
      seriesFolderName: 'Solo Leveling',
      format: ChapterExportFormat.cbz,
      chapterCount: chapters,
      pageCount: pages,
      skippedCount: skipped,
    );

MockStore store() {
  final s = MockStore();
  when(() => s.setSeriesPinned(series: any(named: 'series'), pinned: any(named: 'pinned'))).thenAnswer((_) async {});
  when(() => s.deleteDownload(any())).thenAnswer((_) async {});
  return s;
}

Rig libraryRig({MockStore? st, List<Override> extra = const [], int series = 1}) => Rig(
      store: st ?? store(),
      bytes: 2 * gb,
      extra: extra,
      groups: [
        for (var i = 0; i < series; i++)
          seriesOf(i, [
            chapter(i * 10 + 1, '11', seriesKey: 's$i', seriesTitle: 'Series $i', bytes: (9 - i) * 1024 * 1024),
            chapter(i * 10 + 2, '12', seriesKey: 's$i', seriesTitle: 'Series $i'),
          ]),
      ],
    );

DownloadedSeriesGroup seriesOf(int i, List<SavedChapter> cs) => series(cs, seriesKey: 's$i', title: 'Series $i');

void main() {
  setUpAll(() {
    registerFallbackValue((sourceId: '', seriesKey: '', chapterKey: ''));
    registerFallbackValue((sourceId: '', seriesKey: ''));
  });

  group('series block', () {
    testWidgets('the pin toggles through the store and reads Pin series / Unpin series', (tester) async {
      final st = store();
      await pumpDownloads(tester, rig: libraryRig(st: st));
      expect(find.bySemanticsLabel('Pin series'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Pin series'));
      await settle(tester, ms: 300);
      verify(() => st.setSeriesPinned(series: (sourceId: 'asura', seriesKey: 's0'), pinned: true)).called(1);
    });

    testWidgets('a pinned series shows the pin rule', (tester) async {
      await pumpDownloads(
        tester,
        rig: Rig(
          store: store(),
          groups: [
            series([chapter(1, '1', pinned: true)]),
          ],
        ),
      );
      expect(find.bySemanticsLabel('Unpin series'), findsOneWidget);
      expect(find.byKey(const Key('pin-rule')), findsOneWidget);
    });

    testWidgets('the overflow menu lists Pin, Save to Files…, Remove all downloads, Open series', (tester) async {
      await pumpDownloads(tester, rig: libraryRig());
      await tester.tap(find.bySemanticsLabel('More for Series 0'));
      await settle(tester, ms: 500);
      for (final t in ['Pin', 'Save to Files…', 'Remove all downloads', 'Open series']) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
    });

    testWidgets('Remove all downloads asks first, then removes every chapter', (tester) async {
      final st = store();
      await pumpDownloads(tester, rig: libraryRig(st: st));
      await tester.tap(find.bySemanticsLabel('More for Series 0'));
      await settle(tester, ms: 500);
      await tester.tap(find.text('Remove all downloads'));
      await settle(tester, ms: 600);
      expect(find.text('Remove every saved chapter of Series 0?'), findsOneWidget);
      expect(find.text('Your reading progress is kept.'), findsOneWidget);
      await settle(tester, ms: 1200);
      await tester.tap(find.byKey(const Key('confirm-commit')));
      await settle(tester, ms: 400);
      verify(() => st.deleteDownload(any())).called(2);
    });

    testWidgets('long-press opens the same menu', (tester) async {
      await pumpDownloads(tester, rig: libraryRig());
      await tester.longPress(find.text('Series 0').last);
      await settle(tester, ms: 500);
      expect(find.text('Remove all downloads'), findsOneWidget);
    });
  });

  group('hardware keys', () {
    testWidgets('j / k walk the series blocks; Enter expands; p pauses and resumes', (tester) async {
      final r = await pumpDownloads(tester, rig: libraryRig(series: 3));
      await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
      await tester.pump();
      final first = FocusManager.instance.primaryFocus;
      await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, isNot(same(first)));
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, same(first));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settle(tester, ms: 400);
      expect(find.text('CH 11'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.pump();
      expect(r.queueLog, contains('pause'));
    });
  });

  group('Save to Files', () {
    Future<Rig> open(WidgetTester tester, {required ExportDestination dest, FakeExporter? exporter, MockStore? st, TargetPlatform platform = TargetPlatform.android}) async {
      final r = await pumpDownloads(
        tester,
        platform: platform,
        rig: libraryRig(
          st: st,
          extra: [
            chapterExporterProvider.overrideWithValue(exporter ?? FakeExporter(exported())),
            mediaStoreChannelProvider.overrideWithValue(FakeMedia(dest)),
          ],
        ),
      );
      await tester.tap(find.bySemanticsLabel('More for Series 0'));
      await settle(tester, ms: 500);
      await tester.tap(find.text('Save to Files…'));
      await settle(tester, ms: 900);
      return r;
    }

    testWidgets('the sheet offers Page images and CBZ file', (tester) async {
      await open(tester, dest: ExportDestination.mediaStoreDownloads);
      expect(find.text('SAVE TO FILES'), findsOneWidget);
      expect(find.text('Page images'), findsOneWidget);
      expect(find.text('A numbered folder per chapter.'), findsOneWidget);
      expect(find.text('CBZ file'), findsOneWidget);
      expect(find.text('One file per chapter, for comic reader apps.'), findsOneWidget);
    });

    testWidgets('Android 10+: the result dialog names Files › Downloads and the skipped count', (tester) async {
      final ex = FakeExporter(exported());
      await open(tester, dest: ExportDestination.mediaStoreDownloads, exporter: ex);
      await tester.tap(find.byKey(const Key('export-format-cbz')));
      await settle(tester, ms: 1200);
      expect(ex.formatSeen, ChapterExportFormat.cbz);
      expect(find.text('Saved 12 chapters · 480 pages'), findsOneWidget);
      expect(find.text('Files › Downloads › ManhwaManiacs › Exports › Solo Leveling'), findsOneWidget);
      expect(find.text('2 chapters were still downloading and were skipped.'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Share'), findsNothing);
    });

    testWidgets('iOS: the Files route and Open Files', (tester) async {
      await open(tester, dest: ExportDestination.iosFiles, platform: TargetPlatform.iOS);
      await tester.tap(find.byKey(const Key('export-format-images')));
      await settle(tester, ms: 1200);
      expect(find.text('Files › On My iPhone › ManhwaManiacs › Exports › Solo Leveling'), findsOneWidget);
      expect(find.text('Open Files'), findsOneWidget);
    });

    testWidgets('Android 7-9: Share instead of a path', (tester) async {
      await open(tester, dest: ExportDestination.shareOnly);
      await tester.tap(find.byKey(const Key('export-format-cbz')));
      await settle(tester, ms: 1200);
      expect(find.text('Share'), findsOneWidget);
      expect(find.byKey(const Key('export-path')), findsNothing);
    });

    testWidgets('a failing export is a toast, never a crash', (tester) async {
      final r = await open(tester, dest: ExportDestination.mediaStoreDownloads, exporter: FakeExporter(exported(), fail: true));
      await tester.tap(find.byKey(const Key('export-format-cbz')));
      await settle(tester, ms: 1200);
      expect(r.container.read(cineToastsProvider).any((t) => t.text == kSaveFailed), isTrue);
    });
  });

  group('storage tab', () {
    testWidgets('the cap, chapters at once, retention and the three switches write through', (tester) async {
      final r = await pumpDownloads(tester, tab: 'storage', size: const Size(390, 3000), rig: Rig(store: store(), bytes: 4 * gb));
      Future<void> tap(String label) async {
        await tester.tap(find.text(label));
        await settle(tester, ms: 300);
      }

      await tap('5 GB');
      expect(r.container.read(storageCapProvider), StorageCap.gb5);
      // The slug line scrolls sideways on a phone: bring its last chip in.
      await tester.drag(find.byType(CineSlugLines).first, const Offset(-250, 0));
      await settle(tester, ms: 300);
      await tap('UNLIMITED');
      expect(r.container.read(storageCapProvider), StorageCap.unlimited);
      await tap('7 D');
      await tap('Save the next chapter while I read');
      expect(r.container.read(saveNextProvider), isFalse);
      await tap('Download new chapters of followed series automatically');
      expect(r.container.read(autoNewProvider), isTrue);
    });

    testWidgets('BY SERIES lists credits rows with the pin mark', (tester) async {
      await pumpDownloads(
        tester,
        tab: 'storage',
        rig: Rig(
          breakdown: const [
            SeriesStorageUsage(sourceId: 'a', seriesKey: 'k', seriesTitle: 'Solo Leveling', bytes: 240 * 1024 * 1024, chapterCount: 12, pinnedChapterCount: 12),
          ],
        ),
      );
      await tester.scrollUntilVisible(find.text('Solo Leveling'), 200, scrollable: find.byType(Scrollable).last);
      expect(find.text('12 CH · 240 MB'), findsOneWidget);
    });

    testWidgets('the meter tap on SAVED switches to STORAGE', (tester) async {
      await pumpDownloads(tester, rig: Rig(bytes: 4 * gb));
      await tester.tap(find.textContaining('FREE ON THIS PHONE'));
      await settle(tester, ms: 600);
      expect(find.text('STORAGE CAP'), findsOneWidget);
    });
  });

  group('meter and tablets', () {
    testWidgets('the cap tick and the floor / cap notes', (tester) async {
      await pumpDownloads(tester, rig: Rig(bytes: 4 * gb, free: gb));
      expect(find.byKey(const Key('meter-tick')), findsOneWidget);
      expect(find.textContaining('Downloads stop before the last 1.5 GB of this phone', findRichText: true), findsOneWidget);
    });

    testWidgets('a full cap reads Your 10 GB limit is full.', (tester) async {
      await pumpDownloads(tester, rig: Rig(bytes: 10 * gb));
      expect(find.textContaining('Your 10 GB limit is full.', findRichText: true), findsOneWidget);
    });

    testWidgets('tablet: THIS TABLET, and two library columns from 900 dp', (tester) async {
      await pumpDownloads(tester, size: const Size(1024, 1366), rig: libraryRig(series: 4));
      expect(find.textContaining('FREE ON THIS TABLET'), findsOneWidget);
      expect(find.text('ON THIS TABLET — BIGGEST FIRST'), findsOneWidget);
      final a = tester.getTopLeft(find.text('Series 0').last).dx;
      final b = tester.getTopLeft(find.text('Series 1').last).dx;
      expect(b, greaterThan(a + 200));
    });

    testWidgets('tablet 834: one column', (tester) async {
      await pumpDownloads(tester, size: const Size(834, 1194), rig: libraryRig(series: 2));
      final a = tester.getTopLeft(find.text('Series 0').last).dx;
      final b = tester.getTopLeft(find.text('Series 1').last).dx;
      expect(b, closeTo(a, 2));
    });
  });

  group('reduced motion', () {
    testWidgets('the meter segments change at once', (tester) async {
      await pumpDownloads(tester, reduced: true, rig: Rig(bytes: 4 * gb));
      final app = tester.widget<AnimatedContainer>(find.byKey(const Key('meter-app')));
      expect(app.duration, Duration.zero);
    });

    testWidgets('the chevron rotation applies at once', (tester) async {
      await pumpDownloads(tester, reduced: true, rig: libraryRig());
      final rot = tester.widget<AnimatedRotation>(find.byType(AnimatedRotation).first);
      expect(rot.duration, Duration.zero);
    });
  });

  group('a11y', () {
    testWidgets('Android and iOS tap targets and labeled targets on the saved tab', (tester) async {
      final h = tester.ensureSemantics();
      await pumpDownloads(tester, rig: libraryRig());
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      h.dispose();
    });

    testWidgets('iOS tap targets', (tester) async {
      final h = tester.ensureSemantics();
      await pumpDownloads(tester, rig: libraryRig(), platform: TargetPlatform.iOS);
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      h.dispose();
    });

    testWidgets('text contrast on the saved tab', (tester) async {
      final h = tester.ensureSemantics();
      await pumpDownloads(tester, rig: libraryRig());
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      h.dispose();
    });
  });
}
