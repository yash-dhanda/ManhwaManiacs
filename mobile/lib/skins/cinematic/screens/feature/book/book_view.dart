import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/network/api_image.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_selection.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_summary_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/library/providers/library_series_actions.dart';
import 'package:manhwamaniacs/features/library/utils/cover_url.dart';
import 'package:manhwamaniacs/features/library/utils/mark_read.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_series_providers.dart';
import 'package:manhwamaniacs/features/novels/providers/series_audio_provider.dart';
import 'package:manhwamaniacs/features/novels/utils/novel_book.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/reader/models/bookmark.dart';
import 'package:manhwamaniacs/features/recap/models/recap_origin.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';
import 'package:manhwamaniacs/features/sources/utils/chapter_sort_store.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/phosphor.g.dart';
import 'package:manhwamaniacs/skins/cinematic/navigation.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/chapter_reaction_folio.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/pass_it_on_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/recap/continue_to.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/book/book_contents.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/book/book_front_matter.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/book/book_states.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/book/contents_row.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/book/contents_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/circle_panel.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/downloads/run_feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/downloads/run_summary_line.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/downloads/selection_bar.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/downloads/series_download_card.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_data.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_lightbox.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_shortcuts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_states.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/chapters_panel.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/feature_actions.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/feature_overflow.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/previously_on_button.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/series_ambient.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/audiobook_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/listen_common.dart' show isOwnerProvider;
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The novel Book page: typographic front matter, actions, windowed contents.
class BookView extends ConsumerStatefulWidget {
  const BookView({
    super.key,
    required this.data,
    this.focusChapter,
    this.sourceIsDown = false,
    this.contentsNotice,
    this.openAudiobook = false,
  });
  final FeatureData data;

  /// `?sheet=audiobook`: the owner's Audiobook sheet opens with the page.
  final bool openAudiobook;

  /// `?chapter=`: the row to centre with the current band.
  final String? focusChapter;
  final bool sourceIsDown;

  /// Overrides the derived contents state (loading, offline, error ...).
  final ContentsNoticeKind? contentsNotice;

  @override
  ConsumerState<BookView> createState() => _BookViewState();
}

class _BookViewState extends ConsumerState<BookView> {
  final _selection = ChapterSelectionController();
  final _commands = FeatureCommands();
  final _scroll = ScrollController();
  final _startKey = GlobalKey();
  final _goToCtl = TextEditingController();
  final _goToFocus = FocusNode();
  bool _narratedOnly = false;
  String? _order;
  Set<String> _run = {};
  int _runAlreadySaved = 0;
  final _runFeedback = RunFeedback();
  ({int start, int end})? _window;
  String? _focus;
  List<SourceChapterSummary> _goToMatches = const [];
  String? _goToCaption;

  FeatureData get d => widget.data;
  ChapterMarks get _marks => ChapterMarks(ref, d);

  @override
  void initState() {
    super.initState();
    _focus = widget.focusChapter;
    _commands.viewCover = _cover;
    _commands.goTo = _goTo;
    _commands.toggleOrder = () => _setOrder(order == 'oldest' ? 'newest' : 'oldest');
    _commands.toggleFollow = _toggleLibrary;
    _commands.download = _downloadBook;
    // The first three chapters warm their manifests silently (P3).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pf = readerPrefetchOf(ref);
      for (final c in d.readingOrder.take(3)) {
        pf.onDwell(ReaderTarget.manifest(d.sourceId, d.seriesKey, c.id));
      }
      if (_focus != null) _centerFocus();
      if (widget.openAudiobook && ref.read(isOwnerProvider)) _openAudiobook();
    });
  }

  /// The owner's Audiobook sheet, Rising over the page (cinematic 8.18).
  void _openAudiobook() {
    final progress = ref.read(sourceSeriesProgressProvider((sourceId: d.sourceId, seriesId: d.seriesKey)));
    String? lastKey;
    DateTime? at;
    for (final e in progress.entries) {
      if (at == null || e.value.updatedAt.isAfter(at)) {
        lastKey = e.key;
        at = e.value.updatedAt;
      }
    }
    unawaited(showAudiobookSheet(context, sourceId: d.sourceId, seriesKey: d.seriesKey, seriesTitle: d.title, currentChapterKey: lastKey, chapters: d.chapters));
  }

  @override
  void dispose() {
    _selection.dispose();
    _scroll.dispose();
    _goToCtl.dispose();
    _goToFocus.dispose();
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

  List<SourceChapterSummary> _shown(Set<String> narrated) {
    final reading = d.readingOrder;
    var shown = order == 'oldest' ? reading : reading.reversed.toList();
    if (_narratedOnly) shown = [for (final c in shown) if (narrated.contains(c.id)) c];
    return shown;
  }

  void _centerFocus() {
    final ctx = _startKey.currentContext;
    if (ctx == null || !_scroll.hasClients || _focus == null) return;
    final box = ctx.findRenderObject();
    if (box is! RenderBox) return;
    final narrated = ref.read(seriesAudioProvider((sourceId: d.sourceId, seriesKey: d.seriesKey))).valueOrNull?.rendered ?? const <String>{};
    final shown = _shown(narrated);
    final i = shown.indexWhere((c) => c.id == _focus);
    if (i < 0) return;
    final win = _window ?? tocWindowAround(shown.length, i);
    final viewport = RenderAbstractViewport.of(box);
    final top = viewport.getOffsetToReveal(box, 0).offset;
    final view = _scroll.position.viewportDimension;
    final target = top + (i - win.start) * kContentsRowExtent - view / 2 + kContentsRowExtent / 2;
    unawaited(_scroll.animateTo(
      target.clamp(0.0, _scroll.position.maxScrollExtent),
      duration: MediaQuery.disableAnimationsOf(context)
          ? const Duration(milliseconds: 150)
          : CineDur.column,
      curve: CineCurves.settle,
    ),);
  }

  void _focusOn(SourceChapterSummary c, List<SourceChapterSummary> shown) {
    final i = shown.indexWhere((x) => x.id == c.id);
    setState(() {
      _focus = c.id;
      _window = tocWindowAround(shown.length, i < 0 ? 0 : i);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerFocus());
  }

  Future<void> _goTo() async {
    final wide = MediaQuery.sizeOf(context).width >= 600;
    if (wide) {
      _goToFocus.requestFocus();
      return;
    }
    final narrated = ref.read(seriesAudioProvider((sourceId: d.sourceId, seriesKey: d.seriesKey))).valueOrNull?.rendered ?? const <String>{};
    final shown = _shown(narrated);
    final picked = await showContentsSheet(
      context,
      chapters: shown,
      currentKey: _focus,
      online: isOnline(ref),
    );
    if (picked != null && mounted) _focusOn(picked, shown);
  }

  void _inlineGoTo(String q, List<SourceChapterSummary> shown) {
    final m = goToChapterMatches(d.chapters, q);
    final n = goToChapterQuery(q);
    setState(() {
      _goToMatches = m;
      _goToCaption = n == null
          ? 'Type a chapter number.'
          : m.isEmpty
              ? 'No chapter ${formatChapterNumber(n)} in this book.'
              : null;
    });
  }

  void _cover() => showCoverLightbox(
        context,
        imageUrl: sourceSeriesCoverUrl(ref.read(apiBaseUrlProvider), d.sourceId, d.seriesKey),
        title: d.title,
        heroTag: d.followed != null
            ? seriesCoverHeroTag(d.followed!.id)
            : 'cover-${d.sourceId}-${d.seriesKey}',
        headers: apiImageHttpHeaders(ref.read(authTokenStoreProvider).token, profileId: ref.read(activeProfileProvider)?.id),
      );

  /// The split button: a recap first when `mm.recap` asks (novels read their text, `sourced_from: text`).
  void _continue(SourceChapterSummary c) => unawaited(continueTo(context, ref,
      sourceId: d.sourceId, seriesKey: d.seriesKey, chapterKey: c.id, title: d.title, lastReadAt: d.followed?.readState?.lastReadAt, origin: RecapEntry.wipe,),);

  void _open(SourceChapterSummary c, {bool listen = false}) {
    final target = ReaderTarget.novel(d.sourceId, d.seriesKey, c.id, listen: listen);
    readerPrefetchOf(ref).onPress(target);
    enterReader(context, target, entry: ReaderEntry.wipe);
  }

  Future<void> _downloadSelected() async {
    final keys = _selection.selected;
    final chapters = d.chapters.where((c) => keys.contains(c.id)).toList();
    _selection.end();
    _startRun(chapters);
    feedback(ref, HapticEvent.downloadStart);
    await ref
        .read(downloadQueueControllerProvider.notifier)
        .enqueueChapters(queueRequests(d, chapters, kind: DownloadKind.novel));
  }

  void _startRun(List<SourceChapterSummary> chapters) {
    final statuses =
        ref.read(seriesChapterDownloadStatusProvider(d.identity)).valueOrNull ?? const {};
    _runFeedback.reset();
    setState(() {
      _run = {for (final c in chapters) c.id};
      _runAlreadySaved =
          chapters.where((c) => statuses[c.id]?.state == DownloadChapterState.complete).length;
    });
  }

  void _downloadBook() {
    if (ref.read(activeProfileProvider) == null) return;
    final statuses = ref.read(seriesChapterDownloadStatusProvider(d.identity)).valueOrNull ?? const {};
    _selection
      ..begin()
      ..replaceWith([
        for (final c in d.chapters)
          if (statuses[c.id]?.state != DownloadChapterState.complete) c.id,
      ]);
  }

  Future<void> _toggleLibrary() async {
    if (!isOnline(ref)) return;
    final f = d.followed;
    if (f == null) {
      final err = await ref
          .read(updatesProvider.notifier)
          .followSeries(sourceId: d.sourceId, seriesKey: d.seriesKey);
      if (!mounted) return;
      if (err == null) feedback(ref, HapticEvent.followAdd, SoundEvent.followAdd);
      featureToast(context, err?.userMessage ?? 'Added ${d.title}. New chapters will notify you.');
    } else {
      final actions = ref.read(librarySeriesActionsProvider);
      final r = await actions.remove(f);
      if (!mounted) return;
      featureToast(
        context,
        r.error?.userMessage ?? 'Removed ${d.title}.',
        onUndo: r.error != null ? null : () => unawaited(actions.restore(f, slots: r.slots)),
      );
    }
  }

  Set<String> _completed() {
    final p = ref.read(sourceSeriesProgressProvider((sourceId: d.sourceId, seriesId: d.seriesKey)));
    return {for (final e in p.entries) if (e.value.completed) e.key};
  }

  String _num(SourceChapterSummary c) =>
      c.number == null ? '' : ' ${formatChapterNumber(c.number!)}';

  Future<void> _markRead(List<SourceChapterSummary> chapters, String message) async {
    final before = _completed();
    final marked = await _marks.markRead(chapters, previouslyCompleted: before);
    if (!mounted) return;
    feedback(ref, HapticEvent.select);
    featureToast(context, message, onUndo: () => unawaited(_marks.undoMarkRead(before, marked)));
  }

  Future<void> _rowMenu(SourceChapterSummary c) async {
    feedback(ref, HapticEvent.longpressOpen);
    final choice = await showChapterMenu(context, online: isOnline(ref));
    if (choice == null || !mounted) return;
    switch (choice) {
      case 'read':
        await _markRead([c], 'Marked chapter${_num(c)} read.');
      case 'upto':
        final progress = ref.read(sourceSeriesProgressProvider((sourceId: d.sourceId, seriesId: d.seriesKey)));
        final refs = [
          for (final x in d.chapters)
            (key: x.id, number: x.number, completed: progress[x.id]?.completed ?? false),
        ];
        final keys = chaptersUpTo(refs, c.number ?? double.infinity).map((r) => r.key).toSet();
        final chapters = d.chapters.where((x) => keys.contains(x.id)).toList();
        await _markRead(chapters, 'Marked ${chapters.length} chapters read.');
      case 'unread':
        final deleted = await _marks.markUnread([c.id]);
        if (!mounted) return;
        feedback(ref, HapticEvent.select);
        featureToast(
          context,
          'Marked chapter${_num(c)} unread.',
          onUndo: () => unawaited(_marks.undoMarkUnread(deleted, {c.id: c.number})),
        );
      case 'download':
        _startRun([c]);
        feedback(ref, HapticEvent.downloadStart);
        await ref
            .read(downloadQueueControllerProvider.notifier)
            .enqueueChapters(queueRequests(d, [c], kind: DownloadKind.novel));
      case 'bookmark':
        final ok = await _marks.bookmarkStart(c, media: BookmarkMedia.novel);
        if (!mounted) return;
        if (ok) feedback(ref, HapticEvent.bookmarkAdd, SoundEvent.bookmarkAdd);
        featureToast(context, ok ? 'Bookmarked chapter${_num(c)}.' : "Couldn't bookmark it.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = cineOf(context);
    final s = d.series;
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final online = isOnline(ref);
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
    final summary = ref.watch(seriesDownloadSummaryProvider((series: d.identity, listed: d.chapters.length)));
    final running = summary != null && (summary.downloadingPage != null || summary.waiting > 0);

    final reading = d.readingOrder;
    final shown = _shown(narrated);
    final focusIndex = _focus == null ? 0 : shown.indexWhere((c) => c.id == _focus).clamp(0, shown.length);
    final win = _window ?? tocWindowAround(shown.length, focusIndex);

    final blurb = shelfBlurb(s.description);
    final facts = [
      formatChapterCount(d.chapters.length)?.toUpperCase(),
      if (formatEstimatedWords(estimate) != null) formatEstimatedWords(estimate)!.toUpperCase(),
      if (formatEstimatedTotal(estimate) != null) formatEstimatedTotal(estimate)!.toUpperCase(),
      formatStatus(s.status)?.toUpperCase(),
    ].whereType<String>().join(' · ');

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
    _commands.continueReading =
        resumeChapter == null || caughtUp ? null : () => _continue(resumeChapter);
    _commands.listen = audio != null && narrated.isNotEmpty && resumeChapter != null
        ? () => _open(resumeChapter, listen: true)
        : null;

    ref.listen(seriesChapterDownloadStatusProvider(d.identity), (prev, next) {
      _runFeedback.check(ref, _run, next.valueOrNull ?? const {});
    });
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
    final base = ref.watch(apiBaseUrlProvider);
    final cover = f != null
        ? followedSeriesCoverUrl(base, f)
        : sourceSeriesCoverUrl(base, d.sourceId, d.seriesKey);
    final heroTag = f != null ? seriesCoverHeroTag(f.id) : 'cover-${d.sourceId}-${d.seriesKey}';

    final contentsNotice = widget.contentsNotice ??
        (d.chapters.isEmpty
            ? (!online
                ? ContentsNoticeKind.offline
                : (s.chapterCount > 0 ? ContentsNoticeKind.unavailable : ContentsNoticeKind.empty))
            : (shown.isEmpty && _narratedOnly ? ContentsNoticeKind.empty : null));

    return SeriesAmbient(
      seriesKey: '${d.sourceId}/${d.seriesKey}',
      builder: (context, amb) => ListenableBuilder(
        listenable: _selection,
        builder: (context, _) => PopScope(
          canPop: !_selection.isActive,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && _selection.isActive && defaultTargetPlatform != TargetPlatform.iOS) {
              _selection.end();
            }
          },
          child: FeatureShortcuts(
            book: true,
            commands: _commands,
            child: Scaffold(
              backgroundColor: t.colorPaper0,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  tooltip: 'Back',
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  icon: const Icon(PhosphorRegular.arrowLeft),
                  onPressed: () => featureBack(context),
                ),
                actions: [
                  if (ref.watch(isOwnerProvider))
                    IconButton(
                      key: const Key('audiobook-button'),
                      tooltip: "Narrate or save this book's audio",
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      icon: const Icon(PhosphorRegular.headphones, semanticLabel: 'Audiobook'),
                      onPressed: _openAudiobook,
                    ),
                  if ((ref.watch(circleMembersProvider).valueOrNull ?? const []).isNotEmpty)
                    IconButton(
                      tooltip: 'Recommend to…',
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      icon: const Icon(PhosphorRegular.paperPlaneTilt),
                      onPressed: () => unawaited(showPassItOnSheet(context, sourceId: d.sourceId, seriesKey: d.seriesKey, title: d.series.title, coverUrl: d.series.coverUrl)),
                    ),
                  IconButton(
                    tooltip: 'More',
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    icon: const Icon(PhosphorRegular.dotsThree),
                    onPressed: () => showFeatureOverflow(
                      context,
                      ref,
                      d,
                      onCover: _cover,
                      sourceIsDown: widget.sourceIsDown,
                      book: true,
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: _selection.isActive
                  ? SelectionBar(
                      controller: _selection,
                      chapters: selectable,
                      onDownload: _downloadSelected,
                      showWholeBook: true,
                    )
                  : null,
              body: CustomScrollView(
                controller: _scroll,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                  BookFrontMatter(
                    kicker:
                        'NOVEL · ${(formatStatus(s.status) ?? '').toUpperCase()} · ${d.sourceId.toUpperCase()}',
                    title: s.title,
                    byline: byline(s.author),
                    facts: facts,
                    estimateNote: estimate.sampleSize > 0
                        ? 'Length estimated from ${estimate.sampleSize} chapters read so far.'
                        : null,
                    blurb: blurb,
                    genres: shelfGenres(s.genres),
                    sourceId: d.sourceId,
                    coverUrl: cover,
                    heroTag: heroTag,
                    onCover: _cover,
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    key: const Key('primary-action'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      disabledBackgroundColor: t.colorPaper3,
                      disabledForegroundColor: t.colorInk30,
                    ),
                    onPressed: resumeChapter == null || caughtUp ? null : () => _continue(resumeChapter),
                    child: caughtUp
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [Icon(PhosphorRegular.check, size: 18), SizedBox(width: 8), Text('All caught up')],
                          )
                        : Text(
                            lastKey == null || p == null
                                ? 'Start reading  │  CH ${reading.isEmpty ? '' : formatChapterNumber(reading.first.number ?? 1)}'
                                : 'Continue  │  CH ${formatChapterNumber(resumeChapter?.number ?? 0)}'
                                    '${p.pageCount > 0 ? ' · ${(p.page * 100 / p.pageCount).round()}%' : ''}',
                          ),
                  ),
                  const SizedBox(height: 8),
                  PreviouslyOnButton(sourceId: d.sourceId, seriesKey: d.seriesKey, chapterKey: caughtUp ? null : resumeChapter?.id, commands: _commands),
                  if (audio != null && narrated.isNotEmpty && resumeChapter != null)
                    OutlinedButton(
                      key: const Key('listen'),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                      onPressed: () => _open(resumeChapter, listen: true),
                      child: const Text('Listen'),
                    )
                  else if (audio != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        "Narration isn't available for this book.",
                        key: const Key('narration-unavailable'),
                        style: TextStyle(fontSize: 13, color: t.colorInk60),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: Tooltip(
                          message: online ? (f == null ? 'Add to library' : 'In your library') : kNeedsConnection,
                          child: TextButton.icon(
                            key: const Key('library-toggle'),
                            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                            icon: Icon(f == null ? PhosphorRegular.plus : PhosphorRegular.check),
                            label: const Text('LIBRARY'),
                            onPressed: online ? _toggleLibrary : null,
                          ),
                        ),
                      ),
                      if (unsaved > 0 && !running)
                        Expanded(
                          child: Tooltip(
                            message: ref.watch(activeProfileProvider) == null
                                ? 'Downloads belong to a reading profile.'
                                : 'Download book',
                            child: TextButton.icon(
                              key: const Key('download-book'),
                              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                              icon: const Icon(PhosphorRegular.cloudArrowDown),
                              label: Text('DOWNLOAD $unsaved'),
                              onPressed: ref.watch(activeProfileProvider) == null ? null : _downloadBook,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SeriesDownloadCard(
                    series: d.identity,
                    listed: d.chapters.length,
                    onStorage: () => context.go(ScreenId.downloads.path),
                  ),
                  DownloadRunLine(
                    series: d.identity,
                    runKeys: _run,
                    alreadySaved: _runAlreadySaved,
                    onDismiss: () => setState(() => _run = {}),
                    onManage: () => context.go(ScreenId.downloads.path),
                  ),
                  BookContentsToolbar(
                    order: order,
                    onOrder: _setOrder,
                    selecting: _selection.isActive,
                    onPick: _selection.isActive ? _selection.end : _selection.begin,
                    narratedOnly: _narratedOnly,
                    onNarrated: (v) => setState(() => _narratedOnly = v),
                    onGoTo: _goTo,
                    wide: wide,
                    goToController: _goToCtl,
                    goToFocus: _goToFocus,
                    onGoToSubmitted: (q) => _inlineGoTo(q, shown),
                    goToMatches: _goToMatches,
                    goToCaption: _goToCaption,
                    onPickMatch: (c) => _focusOn(c, shown),
                    showNarrated: audio != null,
                  ),
                      ]),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverMainAxisGroup(
                      slivers: bookContentsSlivers(
                        shown: shown,
                        window: win,
                        onWindow: (w) => setState(() => _window = w),
                        notice: contentsNotice,
                        startKey: _startKey,
                        rowBuilder: (c) {
                          final pr = progress[c.id];
                          final done = pr?.completed ?? false;
                          final st = statuses[c.id];
                          return ContentsRow(
                            key: ValueKey('row-${c.id}'),
                            chapter: c,
                            read: done,
                            percent: (pr?.pageCount ?? 0) > 0 && !done
                                ? (pr!.page * 100 / pr.pageCount).round()
                                : null,
                            narrated: narrated.contains(c.id),
                            reactionSlot: ChapterReactionFolio(sourceId: d.sourceId, seriesKey: d.seriesKey, chapterKey: c.id, chapterNumber: c.number),
                            downloadState: st?.state,
                            current: c.id == _focus,
                            selecting: _selection.isActive,
                            selected: _selection.isSelected(c.id),
                            onSwipeRead: online && !_selection.isActive
                                ? () => unawaited(_markRead([c], 'Marked chapter${_num(c)} read.'))
                                : null,
                            onMenu: () => unawaited(_rowMenu(c)),
                            onLongPress: () => unawaited(_rowMenu(c)),
                            onTap: () {
                              if (_selection.isActive) {
                                if (st?.state != DownloadChapterState.complete) {
                                  _selection.toggle(c.id);
                                }
                              } else {
                                _open(c);
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: BookCircleSection(sourceId: d.sourceId, seriesKey: d.seriesKey, title: d.series.title, coverUrl: d.series.coverUrl),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 96)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
