import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_selection.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_series_providers.dart';
import 'package:manhwamaniacs/features/novels/providers/series_audio_provider.dart';
import 'package:manhwamaniacs/features/novels/utils/novel_book.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';
import 'package:manhwamaniacs/features/sources/utils/chapter_sort_store.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/drop_cap_paragraph.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/downloads/selection_bar.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_data.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_lightbox.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_states.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/chapters_panel.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/feature_overflow.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The novel Book page: typographic front matter, actions, windowed contents.
class BookView extends ConsumerStatefulWidget {
  const BookView({super.key, required this.data, this.focusChapter});
  final FeatureData data;

  /// `?chapter=`: the row to centre with the current band.
  final String? focusChapter;

  @override
  ConsumerState<BookView> createState() => _BookViewState();
}

class _BookViewState extends ConsumerState<BookView> {
  final _selection = ChapterSelectionController();
  bool _more = false;
  bool _narratedOnly = false;
  String? _order;
  ({int start, int end})? _window;
  String? _focus;

  FeatureData get d => widget.data;
  static const double rowExtent = 48;

  @override
  void initState() {
    super.initState();
    _focus = widget.focusChapter;
  }

  @override
  void dispose() {
    _selection.dispose();
    super.dispose();
  }

  String get order =>
      _order ??
      chapterSortFor(
        ref.read(sharedPrefsProvider),
        profileId: ref.read(activeProfileProvider)?.id.toString(),
        sourceId: d.sourceId,
        seriesKey: d.seriesKey,
        novel: true,
      );

  void _setOrder(String o) {
    setState(() {
      _order = o;
      _window = null;
    });
    saveChapterSort(
      ref.read(sharedPrefsProvider),
      profileId: ref.read(activeProfileProvider)?.id.toString(),
      sourceId: d.sourceId,
      seriesKey: d.seriesKey,
      order: o,
    );
  }

  void _open(SourceChapterSummary c, {bool listen = false}) => context
      .push(Routes.novel(d.sourceId, d.seriesKey, c.id, listen ? {'listen': '1'} : const {}));

  Future<void> _downloadSelected() async {
    final keys = _selection.selected;
    final chapters = d.chapters.where((c) => keys.contains(c.id)).toList();
    _selection.end();
    await ref
        .read(downloadQueueControllerProvider.notifier)
        .enqueueChapters(queueRequests(d, chapters, kind: DownloadKind.novel));
  }

  Future<void> _goToSheet(List<SourceChapterSummary> shown) async {
    final picked = await showModalBottomSheet<SourceChapterSummary>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cineOf(context).colorPaper2,
      builder: (ctx) => _ContentsSearch(chapters: d.chapters),
    );
    if (picked != null && mounted) {
      final i = shown.indexWhere((c) => c.id == picked.id);
      setState(() {
        _focus = picked.id;
        _window = tocWindowAround(shown.length, i < 0 ? 0 : i);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = cineOf(context);
    final s = d.series;
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final key = (sourceId: d.sourceId, seriesKey: d.seriesKey);
    final counts =
        ref.watch(novelSeriesWordCountsProvider(d.identity)).valueOrNull ?? const <String, int>{};
    final estimate = estimateSeriesLength(d.chapters.length, counts.values);
    final audio = ref.watch(seriesAudioProvider(key)).valueOrNull;
    final narrated = audio?.rendered ?? const <String>{};
    final progress =
        ref.watch(sourceSeriesProgressProvider((sourceId: d.sourceId, seriesId: d.seriesKey)));
    final statuses =
        ref.watch(seriesChapterDownloadStatusProvider(d.identity)).valueOrNull ?? const {};

    final reading = d.readingOrder;
    var shown = order == 'oldest' ? reading : reading.reversed.toList();
    if (_narratedOnly) {
      shown = [
        for (final c in shown)
          if (narrated.contains(c.id)) c,
      ];
    }
    final focusIndex =
        _focus == null ? 0 : shown.indexWhere((c) => c.id == _focus).clamp(0, shown.length);
    final win = _window ?? tocWindowAround(shown.length, focusIndex);
    final visible =
        shown.isEmpty ? const <SourceChapterSummary>[] : shown.sublist(win.start, win.end);

    final blurb = shelfBlurb(s.description);
    final collapsed =
        blurb != null && !_more && blurb.length > 220 ? '${blurb.substring(0, 220)}…' : blurb;
    final facts = [
      formatChapterCount(d.chapters.length)?.toUpperCase(),
      if (formatEstimatedWords(estimate) != null) formatEstimatedWords(estimate)!.toUpperCase(),
      if (formatEstimatedTotal(estimate) != null) formatEstimatedTotal(estimate)!.toUpperCase(),
      formatStatus(s.status)?.toUpperCase(),
    ].whereType<String>().join(' · ');

    // Resume: the most recently touched chapter, else the first.
    String? lastKey;
    DateTime? at;
    for (final e in progress.entries) {
      if (at == null || e.value.updatedAt.isAfter(at)) {
        lastKey = e.key;
        at = e.value.updatedAt;
      }
    }
    final resumeChapter = reading.isEmpty
        ? null
        : reading.firstWhere((c) => c.id == lastKey, orElse: () => reading.first);
    final p = resumeChapter == null ? null : progress[resumeChapter.id];
    final caughtUp =
        resumeChapter != null && reading.last.id == resumeChapter.id && (p?.completed ?? false);

    final plate = Container(
      width: wide ? 168 : 96,
      height: wide ? 248 : 144,
      decoration: BoxDecoration(color: t.colorPaper1, border: Border.all(color: t.colorRule2)),
      alignment: Alignment.center,
      child: Text(
        s.title.isEmpty ? '' : s.title[0],
        style: TextStyle(fontSize: 48, color: t.colorInk100),
      ),
    );

    final selectable = [
      for (final c in reading)
        (
          key: c.id,
          number: c.number,
          title: c.title,
          isRead: progress[c.id]?.completed ?? false,
          isDownloaded: statuses[c.id]?.state == DownloadChapterState.complete,
        ),
    ];
    final unsaved = selectable.where((c) => !c.isDownloaded).length;
    final f = d.followed;

    return PopScope(
      canPop: !_selection.isActive,
      child: Scaffold(
        backgroundColor: t.colorPaper0,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            tooltip: 'Back',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          ),
          actions: [
            IconButton(
              tooltip: 'More',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              icon: const Icon(Icons.more_horiz),
              onPressed: () => showFeatureOverflow(
                context,
                ref,
                d,
                onCover: () => showCoverLightbox(context, imageUrl: '', title: d.title),
              ),
            ),
          ],
        ),
        bottomNavigationBar: ListenableBuilder(
          listenable: _selection,
          builder: (context, _) => _selection.isActive
              ? SelectionBar(
                  controller: _selection,
                  chapters: selectable,
                  onDownload: _downloadSelected,
                  showWholeBook: true,
                )
              : const SizedBox.shrink(),
        ),
        body: ListenableBuilder(
          listenable: _selection,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
            children: [
              Text(
                'NOVEL · ${(formatStatus(s.status) ?? '').toUpperCase()} · ${d.sourceId.toUpperCase()}',
                style: kickerStyle(context, color: t.colorAmbientFallbackInk),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            s.title,
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: wide ? 56 : 40,
                              height: 1,
                              color: t.colorInk100,
                            ),
                          ),
                        ),
                        if (byline(s.author) != null)
                          Text(
                            byline(s.author)!,
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontStyle: FontStyle.italic,
                              fontSize: 22,
                              color: t.colorInk80,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onLongPress: () => showCoverLightbox(context, imageUrl: '', title: d.title),
                    child: plate,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(width: 56, height: 1, color: t.colorInk100),
              const SizedBox(height: 12),
              Text(facts, style: kickerStyle(context)),
              if (estimate.sampleSize > 0)
                Text(
                  'Length estimated from ${estimate.sampleSize} chapters read so far.',
                  style: TextStyle(fontSize: 12, color: t.colorInk60),
                ),
              if (collapsed != null) ...[
                const SizedBox(height: 12),
                DropCapParagraph(
                  text: collapsed,
                  style: TextStyle(fontSize: 16, height: 24 / 16, color: t.colorInk80),
                  capStyle: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 72,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: t.colorInk100,
                  ),
                ),
                if (blurb!.length > 220)
                  TextButton(
                    style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                    onPressed: () => setState(() => _more = !_more),
                    child: Text(_more ? 'Less' : 'More'),
                  ),
              ],
              Wrap(
                spacing: 8,
                children: [
                  for (final g in shelfGenres(s.genres))
                    TextButton(
                      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                      onPressed: () => context
                          .push('/sources/${d.sourceId}?genre=${Uri.encodeQueryComponent(g)}'),
                      child: Text(
                        g.toUpperCase(),
                        style: const TextStyle(fontSize: 12, letterSpacing: 1),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              FilledButton(
                key: const Key('primary-action'),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                onPressed: resumeChapter == null || caughtUp ? null : () => _open(resumeChapter),
                child: Text(
                  caughtUp
                      ? 'All caught up'
                      : lastKey == null || p == null
                          ? 'Start reading  │  CH ${reading.isEmpty ? '' : formatChapterNumber(reading.first.number ?? 1)}'
                          : 'Continue  │  CH ${formatChapterNumber(resumeChapter?.number ?? 0)}'
                              '${p.pageCount > 0 ? ' · ${(p.page * 100 / p.pageCount).round()}%' : ''}',
                ),
              ),
              const SizedBox(height: 8),
              if (audio != null && narrated.isNotEmpty && resumeChapter != null)
                OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                  onPressed: () => _open(resumeChapter, listen: true),
                  child: const Text('Listen'),
                )
              else if (audio != null)
                Text(
                  "Narration isn't available for this book.",
                  style: TextStyle(fontSize: 12, color: t.colorInk60),
                ),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                      icon: Icon(f == null ? Icons.add : Icons.check),
                      label: Text(f == null ? 'LIBRARY' : 'IN YOUR LIBRARY'),
                      onPressed: () async {
                        final n = ref.read(updatesProvider.notifier);
                        if (f == null) {
                          await n.followSeries(sourceId: d.sourceId, seriesKey: d.seriesKey);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added ${d.title}. New chapters will notify you.'),
                              ),
                            );
                          }
                        } else {
                          await n.unfollow(f.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text('Removed ${d.title}.')));
                          }
                        }
                      },
                    ),
                  ),
                  if (unsaved > 0)
                    Expanded(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                        icon: const Icon(Icons.cloud_download_outlined),
                        label: Text('DOWNLOAD $unsaved'),
                        onPressed: _selection.begin,
                      ),
                    ),
                ],
              ),
              Divider(color: t.colorRule1),
              Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: 'oldest', label: Text('FIRST → LAST')),
                          ButtonSegment(value: 'newest', label: Text('LAST → FIRST')),
                        ],
                        selected: {order},
                        onSelectionChanged: (v) => _setOrder(v.first),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Go to chapter',
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    icon: const Icon(Icons.search),
                    onPressed: () => _goToSheet(shown),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                    onPressed: _selection.isActive ? _selection.end : _selection.begin,
                    child: Text(_selection.isActive ? 'Done' : 'Pick chapters'),
                  ),
                  Semantics(
                    button: true,
                    toggled: _narratedOnly,
                    child: FilterChip(
                      label: const Text('Narrated only'),
                      selected: _narratedOnly,
                      onSelected: (v) => setState(() => _narratedOnly = v),
                    ),
                  ),
                ],
              ),
              if (shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    d.chapters.isEmpty ? 'No chapters yet.' : "Contents didn't come through.",
                  ),
                ),
              if (win.start > 0)
                TextButton(
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  onPressed: () =>
                      setState(() => _window = extendTocWindow(win, shown.length, earlier: true)),
                  child: Text('Show earlier chapters (${win.start})'),
                ),
              for (final c in visible)
                _ContentsRow(
                  chapter: c,
                  read: progress[c.id]?.completed ?? false,
                  percent:
                      (progress[c.id]?.pageCount ?? 0) > 0 && !(progress[c.id]?.completed ?? false)
                          ? (progress[c.id]!.page * 100 / progress[c.id]!.pageCount).round()
                          : null,
                  narrated: narrated.contains(c.id),
                  saved: statuses[c.id]?.state == DownloadChapterState.complete,
                  current: c.id == _focus,
                  selecting: _selection.isActive,
                  selected: _selection.isSelected(c.id),
                  onTap: () {
                    if (_selection.isActive) {
                      if (statuses[c.id]?.state != DownloadChapterState.complete) {
                        _selection.toggle(c.id);
                      }
                    } else {
                      _open(c);
                    }
                  },
                ),
              if (win.end < shown.length)
                OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
                  onPressed: () =>
                      setState(() => _window = extendTocWindow(win, shown.length, earlier: false)),
                  child: Text('Show more chapters (${shown.length - win.end})'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContentsRow extends StatelessWidget {
  const _ContentsRow({
    required this.chapter,
    required this.read,
    required this.percent,
    required this.narrated,
    required this.saved,
    required this.current,
    required this.selecting,
    required this.selected,
    required this.onTap,
  });

  final SourceChapterSummary chapter;
  final bool read;
  final int? percent;
  final bool narrated;
  final bool saved;
  final bool current;
  final bool selecting;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = cineOf(context);
    final e = tocEntry(number: chapter.number, title: chapter.title);
    final ink = read ? t.colorInk45 : t.colorInk100;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: _BookViewState.rowExtent),
        decoration: BoxDecoration(
          color: selected ? t.colorPaper3 : (current ? t.colorSpotWash : null),
          border:
              (selected || current) ? Border(left: BorderSide(color: t.colorSpot, width: 2)) : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            if (selecting)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  selected || saved ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 20,
                ),
              ),
            SizedBox(
              width: 40,
              child: Text(
                e.ordinal ?? '·',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 12, color: t.colorSpot),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                e.title ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: 'serif', fontSize: 16, color: ink),
              ),
            ),
            if (percent != null)
              Text('$percent%', style: TextStyle(fontSize: 12, color: t.colorSpot)),
            if (read) Text('READ', style: TextStyle(fontSize: 10, color: t.colorInk45)),
            if (narrated)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.headphones, size: 16),
              ),
            if (saved)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.check_box, size: 16),
              ),
          ],
        ),
      ),
    );
  }
}

/// N2: the contents sheet in search mode: the go-to field and its matches.
class _ContentsSearch extends StatefulWidget {
  const _ContentsSearch({required this.chapters});
  final List<SourceChapterSummary> chapters;

  @override
  State<_ContentsSearch> createState() => _ContentsSearchState();
}

class _ContentsSearchState extends State<_ContentsSearch> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final matches = goToChapterMatches(widget.chapters, _q);
    final n = goToChapterQuery(_q);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CONTENTS', style: kickerStyle(context)),
            TextField(
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Chapter number'),
              onChanged: (v) => setState(() => _q = v),
            ),
            const SizedBox(height: 8),
            if (n == null)
              const Text('Type a chapter number.')
            else if (matches.isEmpty)
              Text('No chapter ${formatChapterNumber(n)} in this book.')
            else ...[
              for (final c in matches.take(12))
                ListTile(
                  minVerticalPadding: 12,
                  title: Text(c.title),
                  subtitle: Text('row ${widget.chapters.indexWhere((x) => x.id == c.id) + 1}'),
                  onTap: () => Navigator.pop(context, c),
                ),
              if (matches.length > 12) Text('and ${matches.length - 12} more'),
            ],
          ],
        ),
      ),
    );
  }
}
