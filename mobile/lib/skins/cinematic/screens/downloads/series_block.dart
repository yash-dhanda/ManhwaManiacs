import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/models/downloaded_series_group.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/downloads/utils/pending_removals.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/a11y/folio.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/cine_icon.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_confirm_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_icon_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_menu.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/downloads/chapter_row.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/downloads/downloads_actions.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/downloads/downloads_copy.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/downloads/save_to_files_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// `40 CHAPTERS · 3 WITH AUDIO · 1.2 GB`, or `12 OF 40 SAVED · 800 MB` while chapters are missing.
String seriesFolio(DownloadedSeriesGroup g) {
  final text = g.chapters.where((c) => !c.kind.isAudio).toList();
  final saved = text.where((c) => c.state == DownloadChapterState.complete).length;
  final audio = g.chapters.where((c) => c.kind.isAudio && c.state == DownloadChapterState.complete).length;
  final size = formatMb(g.totalBytes);
  if (saved < text.length) return '$saved OF ${text.length} SAVED · $size';
  final ch = '${text.length} ${text.length == 1 ? 'CHAPTER' : 'CHAPTERS'}';
  return [ch, if (audio > 0) '$audio WITH AUDIO', size].join(' · ');
}

/// One series of the saved library (cinematic 8.23): cover, title, folio, pin, menu and an
/// expand chevron; expanded it lists its chapters. Long-press opens the same menu as `⋯`.
class DownloadSeriesBlock extends ConsumerStatefulWidget {
  const DownloadSeriesBlock({
    super.key,
    required this.group,
    required this.pendingKeys,
    this.focusNode,
    this.initiallyExpanded = false,
    this.onFocusChanged,
    this.onRemoveRequest,
  });

  final DownloadedSeriesGroup group;
  final Set<String> pendingKeys;
  final FocusNode? focusNode;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onFocusChanged;

  /// Delete on a focused block asks the screen to open its remove dialog.
  final VoidCallback? onRemoveRequest;

  @override
  ConsumerState<DownloadSeriesBlock> createState() => DownloadSeriesBlockState();
}

class DownloadSeriesBlockState extends ConsumerState<DownloadSeriesBlock> {
  late bool _open = widget.initiallyExpanded;
  final List<FocusNode> _rowNodes = [];

  bool get expanded => _open;

  void toggle() => setState(() => _open = !_open);

  @override
  void dispose() {
    for (final n in _rowNodes) {
      n.dispose();
    }
    super.dispose();
  }

  List<SavedChapter> get _rows {
    final rows = [...widget.group.chapters];
    rows.sort((a, b) {
      final an = a.chapterNumber, bn = b.chapterNumber;
      final c = an != null && bn != null ? an.compareTo(bn) : a.chapterKey.compareTo(b.chapterKey);
      return c != 0 ? c : (a.kind.isAudio ? 1 : 0).compareTo(b.kind.isAudio ? 1 : 0);
    });
    return rows;
  }

  String get _title => widget.group.seriesTitle ?? widget.group.seriesKey;

  void _openSeries() {
    final g = widget.group;
    final followed = ref.read(updatesProvider).valueOrNull?.followed;
    final id = followed
        ?.where((f) => f.sourceId == g.sourceId && f.seriesKey == g.seriesKey)
        .firstOrNull
        ?.id;
    unawaited(
      context.push<void>(
        id != null ? Routes.featureByFollow(id) : Routes.feature(g.sourceId, g.seriesKey),
        extra: const <String, String>{'transition': 'match'},
      ),
    );
  }

  void _openChapter(SavedChapter c) {
    final key = c.kind.isNovelSide ? c.chapterKey.replaceAll(':audio', '') : c.chapterKey;
    final route = c.kind.isNovelSide
        ? Routes.novel(c.sourceId, c.seriesKey, key)
        : Routes.reader(c.sourceId, c.seriesKey, key);
    unawaited(context.push<void>(route, extra: const <String, String>{'transition': 'dip'}));
  }

  Future<void> _removeAll() async {
    final ok = await showCineConfirm(
      context,
      title: 'Remove every saved chapter of $_title?',
      body: 'Your reading progress is kept.',
      confirmLabel: 'Remove all downloads',
      destructive: true,
    );
    if (!ok || !mounted) return;
    cineFeedback(context, HapticEvent.deleteConfirm);
    await DownloadsActions(ref).removeSeries(widget.group);
  }

  List<SavedChapter> get _exportable => [
        for (final c in widget.group.chapters)
          if (c.state == DownloadChapterState.complete && !c.kind.isNovelSide) c,
      ];

  Future<void> _saveToFiles([List<SavedChapter>? only]) => showSaveToFilesSheet(
        context,
        ref,
        seriesLabel: _title,
        chapters: only ?? _exportable,
      );

  List<CineMenuEntry<void>> _entries() {
    final pinned = widget.group.pinned;
    return [
      CineMenuEntry<void>(label: pinned ? 'Unpin' : 'Pin', onSelected: () => DownloadsActions(ref).setPinned(widget.group, pinned: !pinned)),
      if (_exportable.isNotEmpty) CineMenuEntry<void>(label: 'Save to Files…', onSelected: _saveToFiles),
      CineMenuEntry<void>(label: 'Remove all downloads', destructive: true, onSelected: _removeAll),
      CineMenuEntry<void>(label: 'Open series', onSelected: _openSeries),
    ];
  }

  Future<void> _menu(BuildContext ctx) => showCineMenu<void>(ctx, anchor: cineAnchorRect(ctx), entries: _entries());

  void _arrow(int index, int delta) {
    final next = index + delta;
    if (next < 0 || next >= _rowNodes.length) {
      if (next < 0) widget.focusNode?.requestFocus();
      return;
    }
    _rowNodes[next].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final g = widget.group;
    final pinned = g.pinned;
    final reduced = CineMotion.reduced(context);
    final base = ref.watch(apiBaseUrlProvider);
    final cover = '$base/sources/${Uri.encodeComponent(g.sourceId)}/series/${Uri.encodeComponent(g.seriesKey)}/cover';
    final rows = _open ? _rows : const <SavedChapter>[];
    while (_rowNodes.length < rows.length) {
      _rowNodes.add(FocusNode(debugLabel: 'download-row'));
    }

    final header = Builder(
      builder: (hctx) => CineFocusRing(
        focusNode: widget.focusNode,
        onActivate: toggle,
        onHighlight: widget.onFocusChanged,
        child: Focus(
          canRequestFocus: false,
          onKeyEvent: (node, e) {
            if (e is KeyDownEvent &&
                (e.logicalKey == LogicalKeyboardKey.delete || e.logicalKey == LogicalKeyboardKey.backspace) &&
                (widget.focusNode?.hasPrimaryFocus ?? false)) {
              (widget.onRemoveRequest ?? _removeAll)();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Semantics(
            label: '$_title, ${folioLabel(seriesFolio(g))}',
            hint: 'Expands to the chapters. Long press for more.',
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onLongPress: () => unawaited(_menu(hctx)),
              child: Container(
              constraints: const BoxConstraints(minHeight: 72),
              decoration: BoxDecoration(border: Border(bottom: c.ruleHair)),
              padding: EdgeInsets.symmetric(vertical: c.space2),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: '$_title, ${folioLabel(seriesFolio(g))}',
                      excludeSemantics: true,
                      onTap: _openSeries,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _openSeries,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 48,
                              height: 72,
                              child: DecoratedBox(
                                decoration: BoxDecoration(color: c.colorPaper1),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CineImage(url: cover, width: 48),
                                    IgnorePointer(
                                      child: DecoratedBox(decoration: BoxDecoration(border: Border.all(color: c.colorRule1))),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: c.space3),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CineRoleText(_title, c.typeTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                                  SizedBox(height: c.space1),
                                  CineRoleText(seriesFolio(g), c.typeFolio, color: c.colorInk60),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _PinButton(
                    pinned: pinned,
                    title: _title,
                    onPressed: () => DownloadsActions(ref).setPinned(g, pinned: !pinned),
                  ),
                  Builder(
                    builder: (mctx) => CineIconButton(
                      label: 'More for $_title',
                      role: CineIconRole.overflow,
                      onPressed: () => unawaited(_menu(mctx)),
                    ),
                  ),
                  Semantics(
                    button: true,
                    expanded: _open,
                    label: _open ? 'Collapse chapters' : 'Expand chapters',
                    excludeSemantics: true,
                    onTap: toggle,
                    child: CinePressable(
                      onTap: toggle,
                      builder: (_, __) => SizedBox(
                        width: 32,
                        height: 32,
                        child: AnimatedRotation(
                          turns: _open ? 0.5 : 0,
                          duration: reduced ? Duration.zero : c.durLine,
                          curve: c.easeSettle,
                          child: CineGlyphIcon(CineGlyph.caretDown, size: 16, color: c.colorInk60),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ),
          ),
        ),
      ),
    );

    return Column(
      key: ValueKey('series-${g.sourceId}-${g.seriesKey}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        if (_open)
          for (var i = 0; i < rows.length; i++)
            DownloadChapterRow(
              key: ValueKey('chapter-${rows[i].rowId}'),
              chapter: rows[i],
              pending: widget.pendingKeys.contains(pendingRemovalKey(rows[i].identity)),
              focusNode: _rowNodes[i],
              onArrow: (d) => _arrow(i, d),
              onOpen: () => _openChapter(rows[i]),
              onRemove: () => DownloadsActions(ref).removeChapter(rows[i]),
              onSaveToFiles: () => _saveToFiles([rows[i]]),
              onRetry: () => unawaited(ref.read(downloadQueueControllerProvider.notifier).retryChapter(rows[i].identity)),
            ),
      ],
    );
  }
}

class _PinButton extends StatelessWidget {
  const _PinButton({required this.pinned, required this.title, required this.onPressed});
  final bool pinned;
  final String title;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Tooltip(
      message: 'Pinned series are never auto-deleted',
      child: Semantics(
        button: true,
        toggled: pinned,
        label: pinned ? 'Unpin series' : 'Pin series',
        hint: title,
        excludeSemantics: true,
        onTap: onPressed,
        child: CinePressable(
          onTap: onPressed,
          builder: (_, __) => SizedBox(
            width: 32,
            height: 32,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CineIcon(
                  CineIconRole.pin,
                  selected: pinned,
                  weight: pinned ? CineIconWeight.fill : CineIconWeight.light,
                  color: pinned ? c.colorInk100 : c.colorInk60,
                ),
                SizedBox(height: 4, child: pinned ? Align(alignment: Alignment.bottomCenter, child: SizedBox(width: 24, height: 2, child: ColoredBox(key: const Key('pin-rule'), color: c.colorSpot))) : null),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
