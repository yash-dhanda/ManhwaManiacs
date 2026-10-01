import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/series_audio_provider.dart';
import 'package:manhwamaniacs/features/novels/utils/novel_book.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/skins/glass/icons/phosphor.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs_more.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/progress.dart';
import 'package:manhwamaniacs/skins/glass/primitives/text_field.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/paper_frame.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart' show GlassShape;

/// One contents row's height (fixed, so the list pre-scrolls by arithmetic).
const double kNovelContentsRow = 52;

/// Oldest to newest, unnumbered last (the reading order).
List<SourceChapterSummary> novelReadingOrder(List<SourceChapterSummary> chapters) {
  final numbered = chapters.where((c) => c.number != null).toList()..sort((a, b) => a.number!.compareTo(b.number!));
  return [...numbered, ...chapters.where((c) => c.number == null)];
}

/// The Contents body (I), in the paper colours, for the `large` sheet (phone, tablet) and the desktop frame's left panel: "Contents" in
/// Literata 22, the ordered [firstRows] (`mobile/41`'s "Previously on" row), the go-to field, the list pre-scrolled to the current
/// chapter with the book page's marks. A tap opens that chapter.
class NovelContentsBody extends ConsumerStatefulWidget {
  const NovelContentsBody({
    super.key,
    required this.sourceId,
    required this.seriesKey,
    required this.currentChapterKey,
    required this.onOpen,
    this.autofocus = false,
    this.firstRows = const [],
    this.showTitle = true,
  });

  final String sourceId, seriesKey, currentChapterKey;
  final ValueChanged<String> onOpen;

  /// Opened from `t` with a hardware keyboard: the field takes focus.
  final bool autofocus;
  final List<Widget> firstRows;
  final bool showTitle;

  @override
  ConsumerState<NovelContentsBody> createState() => _NovelContentsBodyState();
}

class _NovelContentsBodyState extends ConsumerState<NovelContentsBody> {
  final TextEditingController _q = TextEditingController();
  ScrollController? _scroll;
  String _query = '';

  @override
  void dispose() {
    _q.dispose();
    _scroll?.dispose();
    super.dispose();
  }

  ({String sourceId, String seriesKey}) get _key => (sourceId: widget.sourceId, seriesKey: widget.seriesKey);

  @override
  Widget build(BuildContext context) {
    final colors = PaperScope.of(context);
    final detail = ref.watch(sourceSeriesDetailProvider((sourceId: widget.sourceId, seriesId: widget.seriesKey)));
    final online = ref.watch(deviceOnlineProvider).valueOrNull ?? true;
    final title = Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Semantics(
        header: true,
        child: Text('Contents', textScaler: TextScaler.noScaling, style: TextStyle(fontFamily: 'LiterataMM', fontSize: 22, color: colors.ink, fontVariations: const [FontVariation('opsz', 22), FontVariation('wght', 560)])),
      ),
    );
    final body = detail.when(
      loading: () => const Center(child: GlassSpinner(size: 20, label: 'Loading the contents')),
      error: (e, _) => _Message(
        text: online ? "Couldn't load the contents" : 'The contents need a connection to load',
        action: GlassButton(label: 'Try again', onPressed: () => ref.invalidate(sourceSeriesDetailProvider((sourceId: widget.sourceId, seriesId: widget.seriesKey)))),
      ),
      data: (d) => _list(context, novelReadingOrder(d.chapters)),
    );
    return Material(
      type: MaterialType.transparency,
      child: ColoredBox(
        color: colors.bg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showTitle) title,
            ...widget.firstRows,
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  Widget _list(BuildContext context, List<SourceChapterSummary> chapters) {
    final colors = PaperScope.of(context);
    final current = chapters.indexWhere((c) => c.id == widget.currentChapterKey);
    _scroll ??= ScrollController(initialScrollOffset: contentsScrollOffset(current < 0 ? 0 : current, kNovelContentsRow, rowsAbove: 3));
    final progress = ref.watch(sourceSeriesProgressProvider((sourceId: widget.sourceId, seriesId: widget.seriesKey)));
    final downloads = ref.watch(seriesChapterDownloadStatusProvider(_key)).valueOrNull ?? const {};
    final narrated = ref.watch(seriesAudioProvider(_key)).valueOrNull?.rendered ?? const <String>{};
    final n = goToChapterQuery(_query);
    final matches = n == null ? const <SourceChapterSummary>[] : goToChapterMatches(chapters, _query);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: GlassTextField(
            controller: _q,
            label: 'Chapter number',
            autofocus: widget.autofocus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            textInputAction: TextInputAction.go,
            onChanged: (v) => setState(() => _query = v),
            onSubmitted: (v) {
              final m = goToChapterMatches(chapters, v);
              if (m.isNotEmpty) widget.onOpen(m.first.id);
            },
          ),
        ),
        if (n != null && matches.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('No chapter ${formatChapterNumber(n)} in this book.', style: roleStyle(context, gt.typeBody).copyWith(color: colors.muted), textScaler: TextScaler.noScaling),
          ),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            itemExtent: kNovelContentsRow,
            itemCount: n != null && matches.isNotEmpty ? matches.length : chapters.length,
            itemBuilder: (context, i) {
              final c = n != null && matches.isNotEmpty ? matches[i] : chapters[i];
              final p = progress[c.id];
              final read = p?.completed ?? false;
              final percent = p != null && !read && p.pageCount > 0 ? (p.page * 100 / p.pageCount).round() : null;
              return _Row(
                chapter: c,
                current: c.id == widget.currentChapterKey,
                read: read,
                percent: percent,
                downloaded: downloads[c.id]?.state == DownloadChapterState.complete,
                narrated: narrated.contains(c.id),
                onTap: () => widget.onOpen(c.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.action});
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = PaperScope.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, textAlign: TextAlign.center, style: roleStyle(context, gt.typeBody).copyWith(color: colors.ink), textScaler: TextScaler.noScaling),
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.chapter, required this.current, required this.read, required this.percent, required this.downloaded, required this.narrated, required this.onTap});
  final SourceChapterSummary chapter;
  final bool current, read, downloaded, narrated;
  final int? percent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = PaperScope.of(context);
    final number = chapter.number == null ? '·' : formatChapterNumber(chapter.number!);
    final mono = roleStyle(context, gt.typeMono, size: 13, height: 18, maxScale: 1.3).copyWith(color: colors.muted);
    final titleStyle = roleStyle(context, gt.typeBody, wght: current ? 600 : null, maxScale: 1.3).copyWith(color: colors.ink);
    final marks = [if (read) 'read', if (percent != null) '$percent percent', if (downloaded) 'downloaded', if (narrated) 'narrated'];
    return Semantics(
      selected: current,
      button: true,
      label: 'Chapter $number${chapter.title.isEmpty ? '' : ', ${chapter.title}'}${marks.isEmpty ? '' : ', ${marks.join(', ')}'}',
      excludeSemantics: true,
      onTap: onTap,
      child: GlassPressable(
        material: GlassMaterial.content,
        shape: const GlassShape.superellipse(12),
        sink: 0.99,
        noSemantics: true,
        onTap: onTap,
        builder: (context, info) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(color: current ? colors.ink.withValues(alpha: 0.07) : null, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              SizedBox(width: 52, child: Text(number, style: mono, maxLines: 1)),
              Expanded(child: Text(chapter.title.isEmpty ? 'Chapter $number' : chapter.title, style: titleStyle, maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (percent != null) Padding(padding: const EdgeInsets.only(left: 6), child: Text('$percent %', style: mono)),
              if (read) Padding(padding: const EdgeInsets.only(left: 6), child: GlyphIcon(GlassGlyph.check, size: 16, color: colors.muted)),
              if (downloaded) Padding(padding: const EdgeInsets.only(left: 6), child: GlyphIcon(GlassGlyph28.drop, size: 16, color: colors.muted)),
              if (narrated) Padding(padding: const EdgeInsets.only(left: 6), child: Icon(PhosphorRegular.headphones, size: 16, color: colors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}
