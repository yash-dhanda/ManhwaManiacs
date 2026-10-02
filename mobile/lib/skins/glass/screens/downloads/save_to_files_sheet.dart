import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/platform/media_store.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloaded_series_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/services/chapter_export.dart';
import 'package:manhwamaniacs/skins/glass/primitives/alert.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/row_shell.dart';
import 'package:manhwamaniacs/skins/glass/primitives/progress.dart' show GlassSpinner;
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart';
import 'package:manhwamaniacs/skins/glass/routes/sheet_registry.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/library_common.dart' show sheetOnGlass, sheetParams;
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

const String kNothingToSave = 'Nothing to save yet: these chapters are still downloading';
const String kSaveFailed = "Couldn't save to Files. Check your free space.";

/// `?sheet=save-files&series={sourceId}:{seriesKey}[&chapter={key}]` (medium): Page images or CBZ file, then a progress alert and a
/// result alert with the path (a Share action on Android 7 to 9). Every label reads "Save to Files" on both platforms.
final GlassSheetSpec glassSaveToFilesSheetSpec = GlassSheetSpec(
  title: 'Save to Files',
  builder: (_) => const GlassSaveToFilesBody(),
  detents: const [GlassDetent.medium],
  opening: GlassDetent.medium,
);

void registerSaveToFilesSheet() => registerGlobalSheet('save-files', glassSaveToFilesSheetSpec);

class GlassSaveToFilesBody extends ConsumerWidget {
  const GlassSaveToFilesBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = sheetOnGlass(context);
    Widget row(String title, String caption, ChapterExportFormat f) => GlassRowShell(
          semanticsLabel: '$title. $caption',
          minHeight: 72,
          onTap: () => unawaited(_go(context, ref, f)),
          builder: (context, stacked, info) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              GlassLabel(title, role: gt.typeHeadline, onGlass: on),
              GlassLabel(caption, role: gt.typeFootnote, onGlass: on, color: gt.colorLabel2, maxLines: 3),
            ],),
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        row('Page images', 'A numbered folder per chapter', ChapterExportFormat.images),
        row('CBZ file', 'One file per chapter, for comic reader apps', ChapterExportFormat.cbz),
      ],),
    );
  }

  Future<void> _go(BuildContext context, WidgetRef ref, ChapterExportFormat format) async {
    final q = sheetParams(context);
    final series = q['series'] ?? '';
    final cut = series.indexOf(':');
    final source = cut < 0 ? series : series.substring(0, cut);
    final key = cut < 0 ? '' : series.substring(cut + 1);
    final only = q['chapter'];
    final groups = ref.read(downloadedSeriesProvider).valueOrNull ?? const [];
    final g = groups.where((x) => x.sourceId == source && x.seriesKey == key).firstOrNull;
    final chapters = <SavedChapter>[
      if (g != null)
        for (final c in g.chapters)
          if (c.state == DownloadChapterState.complete && !c.kind.isNovelSide && (only == null || c.chapterKey == only)) c,
    ];
    final root = Navigator.of(context, rootNavigator: true).context;
    final label = g?.seriesTitle ?? key;
    Navigator.of(context).pop();
    await runSaveToFiles(root, ref, seriesLabel: label, chapters: chapters, format: format);
  }
}

/// Runs the export behind a progress alert and answers with the result alert or a toast.
Future<void> runSaveToFiles(BuildContext context, WidgetRef ref, {required String seriesLabel, required List<SavedChapter> chapters, required ChapterExportFormat format}) async {
  void toast(String m) => showGlassToast(ref, GlassToastSpec(m, kind: GlassToastKind.error));
  if (chapters.isEmpty) {
    toast(kNothingToSave);
    return;
  }
  final store = ref.read(downloadsStoreProvider);
  if (store == null) return;
  final exporter = ref.read(chapterExporterProvider);
  final media = ref.read(mediaStoreChannelProvider);
  unawaited(showGlassAlert<void>(context, title: 'Saving to Files…', extra: const Padding(padding: EdgeInsets.only(top: 12), child: Center(child: GlassSpinner(size: 24, label: 'Saving'))), actions: const []));
  ChapterExportResult? result;
  ExportDestination? destination;
  var failed = false;
  try {
    destination = await media.destination();
    result = await exporter.export(store: store, seriesLabel: seriesLabel, chapters: chapters, format: format, fresh: destination != ExportDestination.iosFiles);
    if (destination == ExportDestination.mediaStoreDownloads && !result.isEmpty) {
      await media.saveExport(seriesDirectory: result.directory, seriesFolderName: result.seriesFolderName);
      // The copy in MediaStore is the user's; the private staging copy would only double the size.
      // Not awaited: clean-up only, and the result dialog must not wait on the disk.
      unawaited(result.directory.delete(recursive: true).then((_) {}, onError: (Object _) {}));
    }
  } catch (_) {
    failed = true;
  }
  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop();
  if (failed || result == null || destination == null) {
    toast(kSaveFailed);
    return;
  }
  if (result.isEmpty) {
    toast(kNothingToSave);
    return;
  }
  final share = destination == ExportDestination.shareOnly;
  final r = result;
  await showGlassAlert<void>(
    context,
    title: 'Saved to Files · ${r.chapterCount} ${r.chapterCount == 1 ? 'chapter' : 'chapters'} · ${r.pageCount} ${r.pageCount == 1 ? 'page' : 'pages'}',
    body: [
      if (!share) exportPathLine(destination, r.seriesFolderName),
      if (r.skippedCount > 0) '${r.skippedCount} ${r.skippedCount == 1 ? 'chapter was' : 'chapters were'} still downloading and ${r.skippedCount == 1 ? 'was' : 'were'} skipped.',
    ].join('\n'),
    actions: [
      if (share)
        GlassAlertAction<void>('Share', run: () async {
          final files = <XFile>[
            await for (final e in r.directory.list(recursive: true))
              if (e is File) XFile(e.path),
          ];
          await SharePlus.instance.share(ShareParams(files: files));
        },),
      const GlassAlertAction<void>('Done'),
    ],
  );
}

/// The Files folder of an iOS export (for an "Open Files" action).
String documentsOf(ChapterExportResult r) => p.dirname(p.dirname(r.directory.path));
