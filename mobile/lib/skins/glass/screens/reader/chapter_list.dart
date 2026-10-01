import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart' show Material, MaterialType, TextField, InputDecoration, InputBorder;
import 'package:flutter/services.dart' show TextInputAction;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/features/novels/utils/toc_window.dart' show tocWindow;
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/fast_scroll.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/segmented.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

const int kChapterWindow = 400;

/// The rows shown of a long list: [window] rows around [current] (glass 8.14.8, mobile/33's `tocWindow`), widened by the
/// "Show earlier" and "Show more" rows.
({int start, int end}) chapterWindow(int total, int current, {int window = kChapterWindow, int extraBefore = 0, int extraAfter = 0}) {
  final w = tocWindow(total, current, size: window);
  return (start: math.max(0, w.start - extraBefore), end: math.min(total, w.end + extraAfter));
}

/// The in-reader chapter list (glass 8.14.8): a sheet at `large` on phones and tablet frames, the left panel on desktop frames.
/// The current chapter centred and marked by a 2 px `iris500` bar; download marks; the go-to field (`/`); Newest / Oldest; every
/// state of the list. Tapping a row switches chapters in place.
class ReaderChapterList extends ConsumerStatefulWidget {
  const ReaderChapterList({
    super.key,
    required this.sourceId,
    required this.seriesKey,
    required this.currentChapterId,
    required this.onOpen,
    this.offline = false,
    this.rateLimitedFor,
    this.panel = false,
    this.onReadAll,
  });

  final String sourceId, seriesKey, currentChapterId;
  final ValueChanged<String> onOpen;
  final bool offline;
  final Duration? rateLimitedFor;

  /// The desktop frame's left panel: a 48 x 72 first-page box per row and "Read all" at the top.
  final bool panel;
  final VoidCallback? onReadAll;

  @override
  ConsumerState<ReaderChapterList> createState() => _ReaderChapterListState();
}

class _ReaderChapterListState extends ConsumerState<ReaderChapterList> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _goTo = TextEditingController();
  bool _newest = true;
  int _extraBefore = 0, _extraAfter = 0;
  bool _centred = false;

  static const double _row = 56;

  @override
  void dispose() {
    _scroll.dispose();
    _goTo.dispose();
    super.dispose();
  }

  void _centre(int index) {
    if (_centred) return;
    _centred = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final vp = _scroll.position.viewportDimension;
      _scroll.jumpTo((index * _row - vp / 2 + _row / 2).clamp(0.0, _scroll.position.maxScrollExtent));
    });
  }

  @override
  Widget build(BuildContext context) {
    final key = (sourceId: widget.sourceId, seriesId: widget.seriesKey);
    final detail = ref.watch(sourceSeriesDetailProvider(key));
    final downloads = ref.watch(seriesChapterDownloadStatusProvider((sourceId: widget.sourceId, seriesKey: widget.seriesKey))).valueOrNull ?? const {};
    final saved = {for (final e in downloads.entries) if (e.value.state == DownloadChapterState.complete) e.key};
    final header = _Header(
      newest: _newest,
      onOrder: (v) => setState(() {
        _newest = v;
        _centred = false;
      }),
      goTo: _goTo,
      offlineCount: widget.offline ? saved.length : null,
      rateLimitedFor: widget.rateLimitedFor,
      onReadAll: widget.panel ? widget.onReadAll : null,
      onGo: (text) {
        final chapters = detail.valueOrNull?.chapters ?? const <SourceChapterSummary>[];
        final n = double.tryParse(text.trim());
        final hit = chapters.where((c) => c.number == n || c.title.toLowerCase().contains(text.trim().toLowerCase())).firstOrNull;
        if (hit != null) widget.onOpen(hit.id);
      },
    );
    return detail.when(
      loading: () => Column(children: [
        header,
        Expanded(
          child: GlassSkeletonGroup(
            label: 'Loading chapters',
            child: ListView(physics: const NeverScrollableScrollPhysics(), children: [for (var i = 0; i < 8; i++) const _SkeletonRow()]),
          ),
        ),
      ],),
      error: (e, _) => Column(children: [
        header,
        Expanded(child: _ListNotice(text: "Couldn't load the chapter list", onRetry: () => ref.invalidate(sourceSeriesDetailProvider(key)))),
      ],),
      data: (d) {
        if (d.chapters.isEmpty) {
          return Column(children: [
            header,
            Expanded(child: _ListNotice(text: "Chapters didn't come through", onRetry: () => ref.invalidate(sourceSeriesDetailProvider(key)))),
          ],);
        }
        final ordered = _newest ? d.chapters.reversed.toList() : d.chapters;
        final current = math.max(0, ordered.indexWhere((c) => c.id == widget.currentChapterId));
        final w = chapterWindow(ordered.length, current, extraBefore: _extraBefore, extraAfter: _extraAfter);
        final rows = ordered.sublist(w.start, w.end);
        _centre(current - w.start + (w.start > 0 ? 1 : 0));
        final list = ListView.builder(
          controller: _scroll,
          itemExtent: _row,
          itemCount: rows.length + (w.start > 0 ? 1 : 0) + (w.end < ordered.length ? 1 : 0),
          itemBuilder: (context, i) {
            if (w.start > 0 && i == 0) {
              return _MoreRow(text: 'Show earlier chapters (${w.start})', onTap: () => setState(() => _extraBefore += kChapterWindow));
            }
            final j = i - (w.start > 0 ? 1 : 0);
            if (j >= rows.length) {
              return _MoreRow(text: 'Show more chapters (${math.min(kChapterWindow, ordered.length - w.end)})', onTap: () => setState(() => _extraAfter += kChapterWindow));
            }
            final c = rows[j];
            final isSaved = saved.contains(c.id);
            return _ChapterRow(
              chapter: c,
              current: c.id == widget.currentChapterId,
              saved: isSaved,
              dimmed: widget.offline && !isSaved,
              panel: widget.panel,
              onTap: () => widget.onOpen(c.id),
            );
          },
        );
        return Column(
          children: [
            header,
            Expanded(
              child: rows.length > 200
                  ? GlassFastScroll(controller: _scroll, itemCount: rows.length, labelAt: (i) => rows[i.clamp(0, rows.length - 1)].title, child: list)
                  : list,
            ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.newest,
    required this.onOrder,
    required this.goTo,
    required this.onGo,
    this.offlineCount,
    this.rateLimitedFor,
    this.onReadAll,
  });
  final bool newest;
  final ValueChanged<bool> onOrder;
  final TextEditingController goTo;
  final ValueChanged<String> onGo;
  final int? offlineCount;
  final Duration? rateLimitedFor;
  final VoidCallback? onReadAll;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (offlineCount != null)
              Padding(padding: const EdgeInsets.only(bottom: 8), child: GlassText('Offline · $offlineCount downloaded', role: gt.typeFootnote, wght: 600, onGlass: true)),
            if (rateLimitedFor != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Icon(GlassGlyph.warning.regular, size: 16, color: gt.colorWarning),
                  const SizedBox(width: 6),
                  GlassText('The source is rate-limiting · ${rateLimitedFor!.inSeconds} s', role: gt.typeFootnote, color: gt.colorWarning),
                ],),
              ),
            if (onReadAll != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: GlassButton(label: 'Read all', onPressed: onReadAll, size: GlassButtonSize.small)),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(color: gt.colorWellOnGlass, borderRadius: BorderRadius.circular(12)),
                    child: Material(
                      type: MaterialType.transparency,
                      child: TextField(
                        key: const ValueKey('reader-chapter-goto'),
                        controller: goTo,
                        textInputAction: TextInputAction.go,
                        style: roleStyle(context, gt.typeBody, onGlass: true),
                        decoration: InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: 'Go to chapter',
                          hintStyle: roleStyle(context, gt.typeBody, onGlass: true).copyWith(color: gt.colorLabel3),
                        ),
                        onSubmitted: onGo,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 168,
                  child: GlassSegmented<bool>(
                    compact: true,
                    segments: const [GlassSegment(value: true, label: 'Newest'), GlassSegment(value: false, label: 'Oldest')],
                    selected: newest,
                    onSelected: onOrder,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class _ChapterRow extends StatelessWidget {
  const _ChapterRow({required this.chapter, required this.current, required this.saved, required this.dimmed, required this.panel, required this.onTap});
  final SourceChapterSummary chapter;
  final bool current, saved, dimmed, panel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = chapter.number;
    final number = n == null ? '' : (n == n.roundToDouble() ? '${n.round()}' : '$n');
    return Opacity(
      opacity: dimmed ? 0.4 : 1,
      child: Semantics(
        button: !dimmed,
        selected: current,
        label: '${chapter.title}${saved ? ', downloaded' : ''}${dimmed ? ', needs a connection' : ''}',
        excludeSemantics: true,
        onTap: dimmed ? null : onTap,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: dimmed ? null : onTap,
          child: Row(
            children: [
              Container(width: 2, height: 32, color: current ? gt.colorIris500 : const Color(0x00000000)),
              const SizedBox(width: 14),
              if (panel) ...[
                Container(width: 32, height: 48, decoration: BoxDecoration(color: const Color(0xFF0B0B0F), borderRadius: BorderRadius.circular(6))),
                const SizedBox(width: 12),
              ],
              SizedBox(width: 48, child: GlassText(number, role: gt.typeMono, onGlass: true, size: 15)),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlassText(chapter.title, role: gt.typeBody, wght: current ? 600 : null, onGlass: true, maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (dimmed) GlassText('Needs a connection', role: gt.typeCaption1, onGlass: true),
                  ],
                ),
              ),
              if (saved) Padding(padding: const EdgeInsets.only(right: 16), child: Icon(GlassGlyph.checkCircle.fill, size: 18, color: gt.colorSuccess)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreRow extends StatelessWidget {
  const _MoreRow({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Center(child: GlassButton(label: text, onPressed: onTap, variant: GlassButtonVariant.plain, size: GlassButtonSize.small));
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Container(width: 32, height: 14, decoration: BoxDecoration(color: gt.colorFill2, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 16),
          Expanded(child: Container(height: 14, decoration: BoxDecoration(color: gt.colorFill2, borderRadius: BorderRadius.circular(4)))),
        ],),
      );
}

class _ListNotice extends StatelessWidget {
  const _ListNotice({required this.text, required this.onRetry});
  final String text;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          GlassText(text, role: gt.typeHeadline, onGlass: true),
          const SizedBox(height: 12),
          GlassButton(label: 'Try again', onPressed: () => unawaited(Future.sync(onRetry)), size: GlassButtonSize.small),
        ],),
      );
}
