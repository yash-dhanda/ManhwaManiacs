import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_identity.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/novels/models/narration_save_state.dart';
import 'package:manhwamaniacs/features/novels/models/novel_cast.dart';
import 'package:manhwamaniacs/features/novels/providers/narration_jobs_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_audio_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_cast_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_chapter_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/series_audio_provider.dart';
import 'package:manhwamaniacs/features/novels/repositories/novels_repository.dart';
import 'package:manhwamaniacs/features/novels/utils/audiobook_labels.dart';
import 'package:manhwamaniacs/features/novels/utils/audiobook_plan.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_checkbox.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_segmented_control.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_slug_lines.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/listen_common.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_series.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Opens the owner's Audiobook sheet (cinematic 8.16.8): narrate chapters, or save narrated ones
/// to this device. It Rises. [initialQuickPick] `revoice` opens with RE-VOICE selected (from the
/// cast sheet's `Re-narrate 38 chapters`).
Future<void> showAudiobookSheet(
  BuildContext context, {
  required String sourceId,
  required String seriesKey,
  String? seriesTitle,
  String? currentChapterKey,
  String? initialQuickPick,
  List<SourceChapterSummary>? chapters,
  CineStockColors? stock,
}) =>
    showListenSheet<void>(
      context,
      kicker: 'AUDIOBOOK',
      title: 'Audiobook',
      stock: stock,
      builder: (_) => AudiobookBody(
        sourceId: sourceId,
        seriesKey: seriesKey,
        seriesTitle: seriesTitle,
        currentChapterKey: currentChapterKey,
        initialQuickPick: initialQuickPick,
        chapters: chapters,
      ),
    );

class AudiobookBody extends ConsumerStatefulWidget {
  const AudiobookBody({super.key, required this.sourceId, required this.seriesKey, this.seriesTitle, this.currentChapterKey, this.initialQuickPick, this.chapters});

  final String sourceId, seriesKey;
  final String? seriesTitle, currentChapterKey, initialQuickPick;

  /// The book's chapters when the caller already holds them; otherwise the series detail is read.
  final List<SourceChapterSummary>? chapters;

  @override
  ConsumerState<AudiobookBody> createState() => _AudiobookBodyState();
}

class _AudiobookBodyState extends ConsumerState<AudiobookBody> {
  late final StateController<bool> _open = ref.read(audiobookSheetOpenProvider.notifier);
  AudiobookMode _mode = AudiobookMode.narrate;
  final Set<String> _selected = {};
  String? _quick;
  bool _sending = false, _seeded = false;
  String? _unavailable;
  String? _sentLine;
  final Set<String> _cancelling = {};

  NovelSeriesKey get _series => (sourceId: widget.sourceId, seriesKey: widget.seriesKey);
  NovelChapterKey _key(String chapter) => (sourceId: widget.sourceId, seriesKey: widget.seriesKey, chapterKey: chapter);

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() => _open.state = true);
  }

  @override
  void dispose() {
    Future<void>.microtask(() {
      try {
        _open.state = false;
      } catch (_) {}
    });
    super.dispose();
  }

  AudiobookPlan _plan(List<SourceChapterSummary> chapters, NovelSeriesAudioDetail? detail) {
    final series = (sourceId: widget.sourceId, seriesKey: widget.seriesKey);
    final statuses = ref.watch(seriesNarrationStatusProvider(series)).valueOrNull ?? const <String, ChapterDownloadStatus>{};
    final unplayable = ref.watch(unplayableNarrationSavesProvider(series)).valueOrNull ?? const <String>{};
    return AudiobookPlan(
      chapters: [
        for (final c in readingOrder(chapters))
          AudiobookChapter(
            key: c.id,
            label: [if (c.number != null) 'Chapter ${chapterNumberText(c.number)}', if (c.title.isNotEmpty) c.title].join(' · '),
          ),
      ],
      rendered: detail?.renderedAt.keys.toSet() ?? const {},
      narratable: detail?.narratable ?? const {},
      saved: {for (final e in statuses.entries) e.key: narrationSaveState(e.value, unplayable: unplayable.contains(e.key))},
      revoice: detail == null ? const [] : chaptersToRevoice(detail),
      fromKey: widget.currentChapterKey,
    );
  }

  void _pick(AudiobookPlan plan, String id) {
    setState(() {
      _quick = id;
      _selected
        ..clear()
        ..addAll(switch (id) {
          'next' => plan.nextTen(_mode),
          'all' => plan.all(_mode),
          'revoice' => plan.revoice,
          _ => const <String>[],
        },);
    });
  }

  Future<void> _narrate(AudiobookPlan plan) async {
    setState(() {
      _sending = true;
      _unavailable = null;
      _sentLine = null;
    });
    final writer = ref.read(novelCastingWriterProvider);
    final groups = plan.groups(_selected);
    var queued = 0;
    final skipped = <String, String>{};
    AppError? failure;
    for (final (force, batches) in [(true, groups.force), (false, groups.fresh)]) {
      for (final keys in batches) {
        final r = await writer.requestRender(_key(keys.first), keys, force: force);
        if (r.isErr) {
          failure = r.error;
          break;
        }
        queued += r.value.queued.length;
        skipped.addAll(r.value.skipped);
      }
      if (failure != null) break;
    }
    if (!mounted) return;
    setState(() => _sending = false);
    if (failure != null) {
      if (failure is ApiError && failure.code == 'narration_unavailable') {
        setState(() => _unavailable = kNarrationUnavailableCaption);
      } else {
        ref.read(cineToastsProvider.notifier).error(failure.userMessage);
      }
      return;
    }
    cineFeedback(context, HapticEvent.tapPrimary);
    unawaited(rememberNarratingBook(ref, (sourceId: widget.sourceId, seriesKey: widget.seriesKey, title: widget.seriesTitle ?? 'Audiobook')));
    setState(() {
      _selected.clear();
      _quick = null;
      _sentLine = [
        queued == 0 ? 'Nothing was queued.' : 'Queued $queued ${queued == 1 ? 'chapter' : 'chapters'} for narration.',
        if (skipped.isNotEmpty) skippedNarrationLine(skipped),
      ].join(' ');
    });
  }

  Future<void> _save(AudiobookPlan plan, List<SourceChapterSummary> chapters) async {
    setState(() => _sending = true);
    final byKey = {for (final c in chapters) c.id: c};
    final queue = ref.read(downloadQueueControllerProvider.notifier);
    cineFeedback(context, HapticEvent.tapPrimary);
    for (final key in _selected) {
      final c = byKey[key];
      final ChapterIdentity id = _key(key);
      // A copy this phone cannot play is replaced, not kept.
      if (plan.saved[key] == NarrationSaveState.unplayable) await queue.cancelChapter(audioIdentity(id));
      await queue.enqueueChapters(narrationDownloadRequests(chapter: id, chapterNumber: c?.number, title: c?.title, seriesTitle: widget.seriesTitle));
    }
    if (!mounted) return;
    setState(() {
      _sending = false;
      _selected.clear();
      _quick = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final owner = ref.watch(isOwnerProvider);
    final given = widget.chapters;
    final chaptersAsync = given != null ? null : ref.watch(sourceSeriesDetailProvider((sourceId: widget.sourceId, seriesId: widget.seriesKey)));
    final detail = ref.watch(seriesAudioDetailProvider(_series)).valueOrNull;
    final hasScope = ref.watch(downloadsStoreProvider) != null;
    final jobs = ref.watch(novelAudioJobsProvider(_series)).valueOrNull ?? const <NovelAudioJob>[];
    final chapters = given ?? chaptersAsync?.valueOrNull?.chapters ?? const <SourceChapterSummary>[];
    final plan = _plan(chapters, detail);
    if (!_seeded && detail != null) {
      _seeded = true;
      if (widget.initialQuickPick == 'revoice' && plan.revoice.isNotEmpty) {
        _quick = 'revoice';
        _selected.addAll(plan.revoice);
      }
    }
    if (!owner) return Padding(padding: EdgeInsets.all(c.space6), child: CineRoleText('Only the owner can narrate this book.', c.typeUi, color: c.colorInk60));
    final canRender = (detail?.canRender ?? true);
    final narrate = _mode == AudiobookMode.narrate;
    final quickItems = narrate
        ? [
            const CineSlug('next', 'NEXT 10'),
            CineSlug('all', 'ALL UN-NARRATED', count: plan.all(_mode).length),
            if (plan.revoice.isNotEmpty) CineSlug('revoice', 'RE-VOICE', count: plan.revoice.length),
            const CineSlug('none', 'NONE'),
          ]
        : const [CineSlug('next', 'NEXT 10'), CineSlug('all', 'ALL NARRATED'), CineSlug('none', 'NONE')];
    final blocked = narrate && !canRender;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: c.space4, vertical: c.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasScope)
            CineSegmentedControl(
              labels: const ['NARRATE', 'SAVE TO THIS DEVICE'],
              index: narrate ? 0 : 1,
              onChanged: (i) => setState(() {
                _mode = i == 0 ? AudiobookMode.narrate : AudiobookMode.save;
                _selected.clear();
                _quick = null;
              }),
            ),
          SizedBox(height: c.space3),
          CineSlugLines(items: quickItems, selected: {if (_quick case final q?) q}, onChanged: (id) => _pick(plan, id)),
          SizedBox(height: c.space2),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: plan.chapters.isEmpty
                ? Padding(padding: EdgeInsets.all(c.space4), child: CineRoleText((chaptersAsync?.isLoading ?? false) ? 'LOADING' : 'No chapters yet.', c.typeKicker, color: c.colorInk60))
                : ListView.builder(
                    key: const Key('audiobook-chapters'),
                    itemCount: plan.chapters.length,
                    itemBuilder: (context, i) {
                      final ch = plan.chapters[i];
                      final sel = _selected.contains(ch.key);
                      final ok = plan.selectable(_mode, ch.key) && !(narrate && !canRender);
                      final caption = plan.caption(_mode, ch.key, selected: sel);
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: c.space1),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CineCheckbox(
                              value: sel,
                              label: ch.label,
                              onChanged: ok
                                  ? (v) => setState(() {
                                        v ? _selected.add(ch.key) : _selected.remove(ch.key);
                                        _quick = null;
                                      })
                                  : null,
                            ),
                            if (caption != null)
                              Padding(padding: const EdgeInsets.only(left: 32), child: CineRoleText(caption, c.typeMicro, color: c.colorInk60)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          SizedBox(height: c.space3),
          CineRoleText(audiobookEstimate(_mode), c.typeCaption, color: c.colorInk60),
          if (blocked || _unavailable != null) ...[
            SizedBox(height: c.space2),
            CineRoleText(_unavailable ?? kNarrationUnavailableCaption, c.typeCaption, color: c.colorProof, key: const Key('narration-unavailable')),
          ],
          if (_sentLine != null) ...[SizedBox(height: c.space2), CineRoleText(_sentLine!, c.typeCaption, color: c.colorInk80)],
          SizedBox(height: c.space3),
          CineButton(
            label: audiobookPrimaryLabel(_mode, _selected.length),
            loading: _sending,
            fullWidth: true,
            onPressed: _selected.isEmpty || blocked
                ? null
                : () => unawaited(narrate ? _narrate(plan) : _save(plan, chapters)),
          ),
          if (jobs.isNotEmpty) ...[
            SizedBox(height: c.space4),
            CineRoleText('IN THE QUEUE', c.typeKicker, color: c.colorInk60),
            SizedBox(height: c.space1),
            for (final j in jobs) _JobRow(job: j, cancelling: _cancelling.contains(j.jobId), onCancel: () => _cancelJob(j)),
          ],
          SizedBox(height: c.space4),
        ],
      ),
    );
  }

  Future<void> _cancelJob(NovelAudioJob job) async {
    setState(() => _cancelling.add(job.jobId));
    final err = await ref.read(novelCastingWriterProvider).cancelJob(_key(job.chapterKey), job.jobId);
    if (!mounted) return;
    if (err != null) {
      setState(() => _cancelling.remove(job.jobId));
      ref.read(cineToastsProvider.notifier).error(err.userMessage);
    }
  }
}

class _JobRow extends StatelessWidget {
  const _JobRow({required this.job, required this.cancelling, required this.onCancel});
  final NovelAudioJob job;
  final bool cancelling;
  final VoidCallback onCancel;

  String get _status {
    if (job.isFailed) return 'FAILED${job.errorDetail == null ? '' : ' · ${job.errorDetail}'}';
    if (job.isCancelled) return 'CANCELLED';
    if (job.isDone) return 'DONE';
    if (job.isWaiting) return 'QUEUED';
    if (job.status == 'planning') return 'PLANNING';
    return 'RENDERING ${(job.progress * 100).round()} %';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final active = job.isActive;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: c.space1),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CineRoleText(job.chapterNumber == null ? 'Chapter' : 'Chapter ${chapterNumberText(job.chapterNumber)}', c.typeUi),
                CineRoleText(cancelling ? 'It stops shortly.' : _status, c.typeMicro, color: job.isFailed ? c.colorProof : c.colorInk60),
                if (active) Padding(padding: EdgeInsets.only(top: c.space1), child: CineRuleProgress(value: job.isRunning ? job.progress : 0, semanticLabel: 'Narration of chapter ${chapterNumberText(job.chapterNumber)}')),
              ],
            ),
          ),
          if (active && !cancelling) CineButton(label: 'Cancel', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: onCancel),
        ],
      ),
    );
  }
}
