import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/platform/media_store.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/services/chapter_export.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/dialog_route.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_route.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

const String kNothingToSave = 'Nothing to save yet — these chapters are still downloading.';
const String kSaveFailed = "Couldn't save to Files. Check your free space.";

/// Save to Files (cinematic 8.23, mobile M5): a content-fit sheet asking for the format, a
/// non-dismissible progress dialog, then the result dialog with the path (or Share on Android 7-9).
Future<void> showSaveToFilesSheet(
  BuildContext context,
  WidgetRef ref, {
  required String seriesLabel,
  required List<SavedChapter> chapters,
  ChapterExportFormat? format,
}) async {
  final ready = [for (final c in chapters) if (c.state == DownloadChapterState.complete) c];
  final toasts = ref.read(cineToastsProvider.notifier);
  if (ready.isEmpty) {
    toasts.error(kNothingToSave);
    return;
  }
  final chosen = format ??
      await showCineSheet<ChapterExportFormat>(
        context,
        kicker: 'SAVE TO FILES',
        title: seriesLabel,
        builder: (ctx) => const _FormatRows(),
      );
  if (chosen == null || !context.mounted) return;

  final store = ref.read(downloadsStoreProvider);
  if (store == null) return;
  final exporter = ref.read(chapterExporterProvider);
  final media = ref.read(mediaStoreChannelProvider);

  unawaited(showCineDialog<void>(context, builder: (_) => const _ProgressDialog()));
  ChapterExportResult? result;
  ExportDestination? destination;
  var failed = false;
  try {
    destination = await media.destination();
    result = await exporter.export(store: store, seriesLabel: seriesLabel, chapters: ready, format: chosen, fresh: destination != ExportDestination.iosFiles);
    if (destination == ExportDestination.mediaStoreDownloads && !result.isEmpty) {
      await media.saveExport(seriesDirectory: result.directory, seriesFolderName: result.seriesFolderName);
      // The copy in MediaStore is the user's; the private staging copy would only double the size.
      await result.directory.delete(recursive: true).then((_) {}, onError: (Object _) {});
    }
  } catch (_) {
    failed = true;
  }
  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop();
  if (failed || result == null || destination == null) {
    toasts.error(kSaveFailed);
    return;
  }
  if (result.isEmpty) {
    toasts.error(kNothingToSave);
    return;
  }
  await showCineDialog<void>(context, builder: (_) => SaveResultDialog(result: result!, destination: destination!));
}

class _FormatRows extends StatelessWidget {
  const _FormatRows();

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    Widget row(Key key, String title, String caption, ChapterExportFormat f) => Semantics(
          key: key,
          button: true,
          label: '$title. $caption',
          excludeSemantics: true,
          onTap: () => Navigator.of(context).pop(f),
          child: CinePressable(
            hit: false,
            onTap: () => Navigator.of(context).pop(f),
            builder: (context, st) => ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72),
              child: Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.symmetric(horizontal: c.space4, vertical: c.space2),
                decoration: BoxDecoration(border: Border(bottom: c.ruleHair), color: st.pressed ? c.colorPaper3 : null),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CineRoleText(title, c.typeTitle),
                    CineRoleText(caption, c.typeCaption, color: c.colorInk60),
                  ],
                ),
              ),
            ),
          ),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row(const Key('export-format-images'), 'Page images', 'A numbered folder per chapter.', ChapterExportFormat.images),
        row(const Key('export-format-cbz'), 'CBZ file', 'One file per chapter, for comic reader apps.', ChapterExportFormat.cbz),
        SizedBox(height: c.space4),
      ],
    );
  }
}

class _ProgressDialog extends StatefulWidget {
  const _ProgressDialog();

  @override
  State<_ProgressDialog> createState() => _ProgressDialogState();
}

class _ProgressDialogState extends State<_ProgressDialog> {
  @override
  void initState() {
    super.initState();
    // Copying a long series is real I/O; nothing dismisses this until it is done.
    WidgetsBinding.instance.addPostFrameCallback((_) => cineDialogRouteOf(context)?.locked = true);
  }

  @override
  Widget build(BuildContext context) => const PopScope(
        canPop: false,
        child: CineDialog(
          title: 'Saving to Files…',
          content: Center(child: CineLeaderDial(size: 24, showAfter: Duration.zero, semanticLabel: 'Saving')),
          actions: [],
        ),
      );
}

class SaveResultDialog extends StatelessWidget {
  const SaveResultDialog({super.key, required this.result, required this.destination});
  final ChapterExportResult result;
  final ExportDestination destination;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final path = exportPathLine(destination, result.seriesFolderName);
    final share = destination == ExportDestination.shareOnly;
    return CineDialog(
      title: 'Saved ${result.chapterCount} ${result.chapterCount == 1 ? 'chapter' : 'chapters'} · ${result.pageCount} ${result.pageCount == 1 ? 'page' : 'pages'}',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!share)
            SelectableText(
              path,
              key: const Key('export-path'),
              style: CineText.style(context, c.typeFolio).copyWith(color: c.colorInk80),
            ),
          if (result.skippedCount > 0) ...[
            SizedBox(height: c.space3),
            CineRoleText(
              '${result.skippedCount} ${result.skippedCount == 1 ? 'chapter was' : 'chapters were'} still downloading and ${result.skippedCount == 1 ? 'was' : 'were'} skipped.',
              c.typeCaption,
              color: c.colorInk60,
            ),
          ],
        ],
      ),
      actions: [
        if (share)
          CineButton(label: 'Share', variant: CineButtonVariant.secondary, onPressed: () => unawaited(_share())),
        if (destination == ExportDestination.iosFiles)
          CineButton(label: 'Open Files', variant: CineButtonVariant.secondary, onPressed: () => unawaited(openFilesApp(result))),
        CineButton(label: 'Done', onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }

  Future<void> _share() async {
    final files = <XFile>[
      await for (final e in result.directory.list(recursive: true))
        if (e is File) XFile(e.path),
    ];
    await SharePlus.instance.share(ShareParams(files: files));
  }
}

/// iOS `Open Files`: `shareddocuments://` the app's Documents directory.
Future<void> openFilesApp(ChapterExportResult result) async {
  final documents = p.dirname(p.dirname(result.directory.path));
  await launchUrl(Uri.parse('shareddocuments://$documents'));
}

/// The Files app at the app's Documents directory (iOS), for `Open Files` outside an export.
Future<void> openFilesFromDocuments() async {
  final dir = await getApplicationDocumentsDirectory();
  await launchUrl(Uri.parse('shareddocuments://${dir.path}'));
}
