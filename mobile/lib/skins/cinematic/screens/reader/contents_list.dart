import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/features/downloads/utils/download_mark.dart';
import 'package:manhwamaniacs/features/sources/models/source_chapter_progress.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/utils/chapter_date.dart';
import 'package:manhwamaniacs/features/sources/utils/chapter_label.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_download_mark.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_segmented_control.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_text_field.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_series.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The Contents list of the manga reader (cinematic 8.14.3, 8.14.12): schedule rows (7.16), the
/// current chapter on a `spot.wash` band with the 2 px `spot` left bar and pre-scrolled to the
/// centre, a NEWEST | OLDEST control and a go-to field. Virtualised.
class ContentsList extends StatefulWidget {
  const ContentsList({
    super.key,
    required this.chapters,
    required this.currentKey,
    required this.progress,
    required this.downloads,
    required this.onPick,
    required this.onMarkTap,
    this.activeKey,
    this.activeProgress = 0,
    this.scrollController,
  });

  /// Oldest to newest.
  final List<SourceChapterSummary> chapters;
  final String currentKey;
  final Map<String, SourceChapterProgress> progress;
  final Map<String, ChapterDownloadStatus> downloads;
  final ValueChanged<SourceChapterSummary> onPick;
  final void Function(SourceChapterSummary chapter, DownloadMarkState state) onMarkTap;

  /// The chapter the queue is fetching, and how far (0..1).
  final String? activeKey;
  final double activeProgress;
  final ScrollController? scrollController;

  @override
  State<ContentsList> createState() => _ContentsListState();
}

class _ContentsListState extends State<ContentsList> {
  static const double _rowExtent = 64;
  late final ScrollController _scroll = widget.scrollController ?? ScrollController();
  final TextEditingController _goto = TextEditingController();
  bool _newestFirst = true;
  String? _flash;
  Timer? _flashTimer;
  bool _centred = false;

  List<SourceChapterSummary> get _ordered => _newestFirst ? widget.chapters.reversed.toList() : widget.chapters;

  @override
  void dispose() {
    _flashTimer?.cancel();
    _goto.dispose();
    if (widget.scrollController == null) _scroll.dispose();
    super.dispose();
  }

  void _centreOn(String key, {bool animate = false}) {
    final i = _ordered.indexWhere((c) => c.id == key);
    if (i < 0 || !_scroll.hasClients) return;
    final viewport = _scroll.position.viewportDimension;
    final target = (i * _rowExtent - (viewport - _rowExtent) / 2).clamp(0.0, _scroll.position.maxScrollExtent);
    if (animate) {
      unawaited(_scroll.animateTo(target, duration: context.cine.durColumn, curve: CineCurves.settle));
    } else {
      _scroll.jumpTo(target);
    }
  }

  void _go(String text) {
    final n = double.tryParse(text.trim());
    if (n == null) return;
    final match = widget.chapters.where((c) => c.number == n).firstOrNull;
    if (match == null) return;
    setState(() => _flash = match.id);
    _centreOn(match.id, animate: true);
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _flash = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    if (!_centred) {
      _centred = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _centreOn(widget.currentKey));
    }
    final rows = _ordered;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(c.space4, c.space2, c.space4, c.space2),
          child: Row(
            children: [
              Expanded(
                child: CineSegmentedControl(
                  labels: const ['NEWEST', 'OLDEST'],
                  index: _newestFirst ? 0 : 1,
                  onChanged: (i) {
                    setState(() => _newestFirst = i == 0);
                    WidgetsBinding.instance.addPostFrameCallback((_) => _centreOn(widget.currentKey));
                  },
                ),
              ),
              SizedBox(width: c.space4),
              SizedBox(
                width: 132,
                child: CineTextField(
                  label: 'Chapter number',
                  controller: _goto,
                  numeric: true,
                  textAlign: TextAlign.end,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  textInputAction: TextInputAction.done,
                  onSubmitted: _go,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            itemExtent: _rowExtent,
            itemCount: rows.length,
            itemBuilder: (context, i) {
              final chapter = rows[i];
              final status = widget.downloads[chapter.id];
              final active = widget.activeKey == chapter.id;
              final mark = downloadMarkState(status?.state, progress: active ? widget.activeProgress : 0);
              return ContentsRow(
                chapter: chapter,
                progress: widget.progress[chapter.id],
                mark: mark,
                current: chapter.id == widget.currentKey,
                highlighted: chapter.id == _flash,
                onTap: () => widget.onPick(chapter),
                onMarkTap: () => widget.onMarkTap(chapter, mark),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// One chapter row (7.16): the number in `typeFolioLg` right-aligned in a 56 px column, the title,
/// a caption with the date and page count, `14/27` in `spot` while in progress, `READ` and a
/// dimmed row once complete, and the download mark.
class ContentsRow extends StatelessWidget {
  const ContentsRow({
    super.key,
    required this.chapter,
    required this.progress,
    required this.mark,
    required this.current,
    required this.highlighted,
    required this.onTap,
    required this.onMarkTap,
  });

  final SourceChapterSummary chapter;
  final SourceChapterProgress? progress;
  final DownloadMarkState mark;
  final bool current, highlighted;
  final VoidCallback onTap, onMarkTap;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final label = chapterLabel(number: chapter.number, title: chapter.title);
    final read = progress?.completed ?? false;
    final date = chapterDateLabel(chapter.releaseDate);
    final caption = [if (date != null) date, if (chapter.pageCount > 0) '${chapter.pageCount} PAGES'].join(' · ');
    final ink = read ? c.colorInk45 : c.colorInk100;
    final p = progress;
    return Semantics(
      button: true,
      selected: current,
      label: '${label.primary}${label.secondary != null ? ', ${label.secondary}' : ''}${read ? ', read' : ''}${current ? ', current chapter' : ''}',
      excludeSemantics: true,
      onTap: onTap,
      child: CineFocusRing(
        onActivate: onTap,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            decoration: BoxDecoration(
              color: current || highlighted ? c.colorSpotWash : null,
              border: current ? Border(left: BorderSide(color: c.colorSpot, width: 2)) : null,
            ),
            padding: const EdgeInsets.only(left: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  child: CineRoleText(chapterNumberText(chapter.number), c.typeFolioLg, color: ink, textAlign: TextAlign.right),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CineRoleText(label.secondary ?? label.primary, c.typeTitle, color: ink, maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (caption.isNotEmpty) CineRoleText(caption, c.typeCaption, color: c.colorInk60, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (p != null && !read && p.pageCount > 0)
                  Padding(padding: const EdgeInsets.only(right: 4), child: CineRoleText('${p.page}/${p.pageCount}', c.typeFolio, color: c.colorSpot))
                else if (read)
                  Padding(padding: const EdgeInsets.only(right: 4), child: CineRoleText('READ', c.typeMicro, color: c.colorInk45)),
                CineDownloadMark(state: mark, onTap: onMarkTap),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Whether a chapter's saved state counts as on the device.
bool isSaved(ChapterDownloadStatus? s) => s?.state == DownloadChapterState.complete;
