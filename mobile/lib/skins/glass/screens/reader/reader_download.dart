import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/downloads/utils/download_mark.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/reader_host.dart';
import 'package:manhwamaniacs/skins/glass/shell/bar_icon.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_common.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The text the compact download control shows beside its glyph (glass 7.29): progress, the warn states, the remove question.
String? readerDownloadText(DownloadMarkState mark, {required int done, required int total, required bool asking}) => switch (mark) {
      MarkSaved() when asking => 'Remove download?',
      MarkDownloading() when total > 0 => '$done/$total · ${(done / total * 100).round()} %',
      MarkStale() => 'Save again',
      MarkFailed() when done > 0 => 'Resume $done/$total',
      MarkFailed() => 'Save again',
      _ => null,
    };

/// The compact chapter download control of the top-right group (glass 8.14.2, 7.29), through the shared chapter download state:
/// Download, then "18/40 · 45 %" with a cancel, then the Saved check; a tap on Saved asks "Remove download?" inline and reverts
/// after 4 s. Every coloured glyph sits on the backing disc.
class ReaderDownloadControl extends ConsumerStatefulWidget {
  const ReaderDownloadControl({super.key, required this.host, required this.chapterId});
  final GlassReaderHost host;
  final String chapterId;

  /// The group shape's width for the current state: the glyph alone, or the glyph and its text.
  static double widthFor(BuildContext context, WidgetRef ref, GlassReaderHost host, String chapterId, double side) {
    final f = _facts(ref, host, chapterId);
    final text = readerDownloadText(f.mark, done: f.done, total: f.total, asking: _asking.contains(chapterId));
    if (text == null) return side;
    return side + measureText(context, text, roleStyle(context, gt.typeFootnote, onGlass: true, wght: 600)).width + 12;
  }

  static final Set<String> _asking = {};

  static ({DownloadMarkState mark, int done, int total}) _facts(WidgetRef ref, GlassReaderHost host, String chapterId) {
    final series = (sourceId: host.sourceId, seriesKey: host.seriesKey);
    final status = ref.watch(seriesChapterDownloadStatusProvider(series)).valueOrNull?[chapterId];
    final active = ref.watch(seriesActiveChapterProgressProvider(series));
    final isActive = active != null && active.chapterKey == chapterId;
    final done = isActive ? active.progress.pagesDone : 0;
    final total = isActive ? active.progress.pageTotal : 0;
    final paused = ref.watch(downloadQueueControllerProvider.select((q) => q.pauseReason)) != DownloadQueuePauseReason.none;
    return (mark: downloadMarkState(status?.state, progress: total > 0 ? done / total : 0.0, paused: paused), done: done, total: total);
  }

  @override
  ConsumerState<ReaderDownloadControl> createState() => _ReaderDownloadControlState();
}

class _ReaderDownloadControlState extends ConsumerState<ReaderDownloadControl> {
  Timer? _revert;

  ({String sourceId, String seriesKey, String chapterKey}) get _id =>
      (sourceId: widget.host.sourceId, seriesKey: widget.host.seriesKey, chapterKey: widget.chapterId);

  @override
  void dispose() {
    _revert?.cancel();
    ReaderDownloadControl._asking.remove(widget.chapterId);
    super.dispose();
  }

  void _setAsking(bool v) {
    setState(() => v ? ReaderDownloadControl._asking.add(widget.chapterId) : ReaderDownloadControl._asking.remove(widget.chapterId));
    _revert?.cancel();
    if (v) {
      _revert = Timer(const Duration(seconds: 4), () {
        if (mounted) _setAsking(false);
      });
    }
  }

  Future<void> _tap(DownloadMarkState mark) async {
    final queue = ref.read(downloadQueueControllerProvider.notifier);
    switch (mark) {
      case MarkSaved():
        if (ReaderDownloadControl._asking.contains(widget.chapterId)) {
          _setAsking(false);
          await ref.read(downloadsStoreProvider)?.deleteDownload(_id);
          queue.retryAfterStorageChange();
          ref.invalidate(seriesChapterDownloadStatusProvider((sourceId: widget.host.sourceId, seriesKey: widget.host.seriesKey)));
        } else {
          _setAsking(true);
        }
      case MarkDownloading() || MarkQueued() || MarkPaused():
        unawaited(queue.cancelChapter(_id));
      case MarkNone() || MarkFailed() || MarkStale():
        glassFire(ref, HapticEvent.downloadStart);
        unawaited(queue.enqueueChapter(id: _id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = ReaderDownloadControl._facts(ref, widget.host, widget.chapterId);
    final asking = ReaderDownloadControl._asking.contains(widget.chapterId);
    final text = readerDownloadText(f.mark, done: f.done, total: f.total, asking: asking);
    final (icon, label, color) = switch (f.mark) {
      MarkSaved() => (GlassButtonIcon.glyph(GlassGlyph.checkCircle), asking ? 'Remove download' : 'Saved on this device', gt.colorSuccess),
      MarkDownloading() || MarkQueued() => (GlassButtonIcon.glyph(GlassGlyph.x), 'Cancel download', null),
      MarkPaused() => (GlassButtonIcon.glyph(GlassGlyph.x), 'Cancel download (paused)', gt.colorWarning),
      MarkFailed() || MarkStale() => (roleIcon(GlassIconRole.download), text ?? 'Save again', gt.colorWarning),
      MarkNone() => (roleIcon(GlassIconRole.download), 'Download chapter', null),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (text != null)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: GlassText(text, role: gt.typeFootnote, wght: 600, onGlass: true, color: f.mark is MarkFailed || f.mark is MarkStale ? gt.colorWarning : null),
          ),
        GlassBarIcon(
          icon: icon,
          label: label,
          onPressed: () => unawaited(_tap(f.mark)),
          iconBuilder: color == null ? null : (c) => Icon(icon.fill, size: 22, color: color),
        ),
      ],
    );
  }
}
