/// `?sheet=audiobook` (glass 8.16.5, H): narrate chapters (the owner) or save narrated ones to this device. A `large` sheet; on the
/// desktop frame the 440 px right panel. A live header, Narrate / Save to device, assist chips, one row per chapter with its status,
/// the estimate, the primary button, and the Jobs section (liquid bar per job, owner-only cancel and "Render again").
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_identity.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
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
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/icons/phosphor.g.dart';
import 'package:manhwamaniacs/skins/glass/listen/glass_narration_host.dart';
import 'package:manhwamaniacs/skins/glass/listen/job_rows.dart';
import 'package:manhwamaniacs/skins/glass/listen/skip_toast.dart';
import 'package:manhwamaniacs/skins/glass/primitives/checkbox.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/liquid_progress.dart';
import 'package:manhwamaniacs/skins/glass/primitives/progress.dart' show GlassSpinner;
import 'package:manhwamaniacs/skins/glass/primitives/segmented.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// 9 minutes of rendering per chapter on the narration PC.
const int kMinutesPerChapter = 9;

String estimateLine(AudiobookMode mode, int chapters) => mode == AudiobookMode.narrate
    ? 'About ${chapters * kMinutesPerChapter} minutes of rendering on the narration PC'
    : 'Saves while the app is open. The text is saved too, so the chapter plays and follows along offline.';

String primaryLabel(AudiobookMode mode, int n) => mode == AudiobookMode.narrate ? 'Make audiobook of $n ${n == 1 ? 'chapter' : 'chapters'}' : 'Save audio of $n ${n == 1 ? 'chapter' : 'chapters'}';

/// The status under a chapter's name.
String rowStatus(AudiobookPlan plan, AudiobookMode mode, String key) {
  final saved = plan.saved[key] ?? NarrationSaveState.none;
  if (mode == AudiobookMode.narrate) {
    if (plan.isRendered(key)) return saved == NarrationSaveState.saved ? 'Narrated · saved on this device' : 'Narrated';
    return plan.narratable.contains(key) ? 'Not narrated yet' : 'Download the text first';
  }
  return switch (saved) {
    NarrationSaveState.saved => 'Saved on this device',
    NarrationSaveState.unplayable => "Saved copy can't play here · select to save again",
    NarrationSaveState.saving => 'Saving…',
    NarrationSaveState.failed => "Couldn't be saved · select to retry",
    NarrationSaveState.none => plan.isRendered(key) ? 'Narrated' : 'Not narrated yet',
  };
}

String _chapterLabel(SourceChapterSummary c) {
  final n = c.number == null ? null : (c.number! % 1 == 0 ? c.number!.toInt().toString() : c.number.toString());
  return [if (n != null) 'Chapter $n', if (c.title.isNotEmpty) c.title].join(' · ');
}

List<SourceChapterSummary> _readingOrder(List<SourceChapterSummary> chapters) {
  final numbered = chapters.where((c) => c.number != null).toList()..sort((a, b) => a.number!.compareTo(b.number!));
  return [...numbered, ...chapters.where((c) => c.number == null)];
}

class GlassAudiobookBody extends ConsumerStatefulWidget {
  const GlassAudiobookBody({super.key, required this.sourceId, required this.seriesKey, this.seriesTitle, this.currentChapterKey, this.initialMode, this.onGlass = true});
  final String sourceId, seriesKey;
  final String? seriesTitle, currentChapterKey;

  /// Opened from the reader's listen button on an un-narrated chapter: Narrate with that chapter selected.
  final AudiobookMode? initialMode;
  final bool onGlass;

  @override
  ConsumerState<GlassAudiobookBody> createState() => _GlassAudiobookBodyState();
}

class _GlassAudiobookBodyState extends ConsumerState<GlassAudiobookBody> {
  late final StateController<bool> _open = ref.read(audiobookSheetOpenProvider.notifier);
  late AudiobookMode _mode = widget.initialMode ?? AudiobookMode.narrate;
  final Set<String> _selected = {};
  final Set<String> _removed = {};
  final Set<String> _cancelling = {};
  bool _sending = false, _seeded = false;
  bool _unavailable = false;
  String? _quick;

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
    final statuses = ref.watch(seriesNarrationStatusProvider(_series)).valueOrNull ?? const <String, ChapterDownloadStatus>{};
    final unplayable = ref.watch(unplayableNarrationSavesProvider(_series)).valueOrNull ?? const <String>{};
    return AudiobookPlan(
      chapters: [for (final c in _readingOrder(chapters)) AudiobookChapter(key: c.id, label: _chapterLabel(c))],
      rendered: detail?.renderedAt.keys.toSet() ?? const {},
      narratable: detail?.narratable ?? const {},
      saved: {for (final e in statuses.entries) e.key: narrationSaveState(e.value, unplayable: unplayable.contains(e.key))},
      revoice: detail == null ? const [] : chaptersToRevoice(detail),
      fromKey: widget.currentChapterKey,
    );
  }

  void _pick(AudiobookPlan plan, String id) {
    glassFire(ref, HapticEvent.select);
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

  void _toast(String text, {bool error = false}) => ref.read(glassToastProvider.notifier).show(GlassToastSpec(text, kind: error ? GlassToastKind.error : GlassToastKind.info));

  Future<void> _narrate(AudiobookPlan plan) async {
    setState(() {
      _sending = true;
      _unavailable = false;
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
      glassFire(ref, HapticEvent.error);
      if (failure is ApiError && failure.code == 'narration_unavailable') {
        setState(() => _unavailable = true);
      } else {
        _toast(listenErrorText(failure), error: true);
      }
      return;
    }
    glassFire(ref, HapticEvent.tapPrimary);
    unawaited(rememberNarratingBook(ref, (sourceId: widget.sourceId, seriesKey: widget.seriesKey, title: widget.seriesTitle ?? 'Audiobook')));
    ref.invalidate(activeAudioJobsProvider);
    setState(() {
      _selected.clear();
      _quick = null;
    });
    _toast(queuedToast(queued: queued, skipped: skipped));
  }

  Future<void> _save(AudiobookPlan plan, List<SourceChapterSummary> chapters) async {
    setState(() => _sending = true);
    final byKey = {for (final c in chapters) c.id: c};
    final queue = ref.read(downloadQueueControllerProvider.notifier);
    glassFire(ref, HapticEvent.tapPrimary);
    final n = _selected.length;
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
    _toast(savingToast(n));
  }

  Future<void> _cancelJob(NovelAudioJob job) async {
    setState(() => _cancelling.add(job.jobId));
    final err = await ref.read(novelCastingWriterProvider).cancelJob(_key(job.chapterKey), job.jobId);
    if (!mounted) return;
    if (err != null) {
      setState(() => _cancelling.remove(job.jobId));
      _toast(listenErrorText(err), error: true);
    }
  }

  Future<void> _renderAgain(NovelAudioJob job) async {
    final r = await ref.read(novelCastingWriterProvider).requestRender(_key(job.chapterKey), [job.chapterKey], force: true);
    if (!mounted) return;
    if (r.isErr) {
      _toast(listenErrorText(r.error), error: true);
    } else {
      _toast(queuedToast(queued: r.value.queued.length, skipped: r.value.skipped));
    }
  }

  @override
  Widget build(BuildContext context) {
    final onGlass = widget.onGlass;
    final owner = ref.watch(glassIsOwnerProvider);
    final online = ref.watch(deviceOnlineProvider).valueOrNull ?? true;
    final hasScope = ref.watch(downloadsStoreProvider) != null && GlassFrame.of(context) == GlassFrameKind.phone;
    final detailAsync = ref.watch(seriesAudioDetailProvider(_series));
    final detail = detailAsync.valueOrNull;
    final chaptersAsync = ref.watch(sourceSeriesDetailProvider((sourceId: widget.sourceId, seriesId: widget.seriesKey)));
    final chapters = chaptersAsync.valueOrNull?.chapters ?? const <SourceChapterSummary>[];
    final jobsAsync = ref.watch(novelAudioJobsProvider(_series));
    final jobs = [for (final j in jobsAsync.valueOrNull ?? const <NovelAudioJob>[]) if (!_removed.contains(j.jobId)) j];
    final plan = _plan(chapters, detail);
    final canNarrate = owner && online;
    // Non-owners and offline phones get Save only (where Save exists).
    final modes = [if (canNarrate) AudiobookMode.narrate, if (hasScope) AudiobookMode.save];
    if (modes.isNotEmpty && !modes.contains(_mode)) _mode = modes.first;
    if (!_seeded && detail != null) {
      _seeded = true;
      final k = widget.currentChapterKey;
      if (widget.initialMode == AudiobookMode.narrate && k != null && plan.selectable(_mode, k)) _selected.add(k);
    }
    final loading = detailAsync.isLoading && !detailAsync.hasValue || chaptersAsync.isLoading && !chaptersAsync.hasValue;
    final failed = !loading && detail == null && online;
    final running = jobs.where((j) => j.isRunning).length, waiting = jobs.where((j) => j.isWaiting).length;
    final header = audiobookButtonLabel(canRender: detail?.canRender ?? false, running: running, waiting: waiting, rendered: plan.rendered.length);
    final narrate = _mode == AudiobookMode.narrate;
    final blocked = narrate && detail?.canRender == false;
    final textColor = onGlass ? gt.colorOnGlass : gt.colorLabel1;
    final dim = gt.colorLabel2;

    Widget body;
    if (!online && modes.isEmpty) {
      body = Center(child: Padding(padding: const EdgeInsets.all(24), child: GlassText('The audiobook needs a connection. Saved audio still plays.', role: gt.typeCallout, onGlass: onGlass, textAlign: TextAlign.center)));
    } else if (loading) {
      body = GlassSkeletonGroup(label: 'Loading the audiobook', child: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: Column(children: [for (var i = 0; i < 4; i++) Padding(padding: const EdgeInsets.only(bottom: 12), child: GlassSkeleton(height: 48, radius: 16, index: i))])));
    } else if (failed) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            GlassText("Couldn't load the audiobook status", role: gt.typeCallout, onGlass: onGlass, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            GlassButton(label: 'Try again', size: GlassButtonSize.small, onPressed: () {
              ref.invalidate(seriesAudioDetailProvider(_series));
              ref.invalidate(sourceSeriesDetailProvider((sourceId: widget.sourceId, seriesId: widget.seriesKey)));
            },),
          ],),
        ),
      );
    } else {
      final offlineSave = !online;
      final shown = [
        for (final c in plan.chapters)
          if (!(offlineSave && !plan.narratable.contains(c.key) && _mode == AudiobookMode.save)) c,
      ];
      body = Column(
        children: [
          if (modes.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: GlassSegmented<AudiobookMode>(
                segments: const [GlassSegment(value: AudiobookMode.narrate, label: 'Narrate'), GlassSegment(value: AudiobookMode.save, label: 'Save to device')],
                selected: _mode,
                onSelected: (m) => setState(() {
                  _mode = m;
                  _selected.clear();
                  _quick = null;
                }),
              ),
            ),
          if (blocked || _unavailable)
            Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 8), child: GlassText(kNarrationUnavailableCaption, role: gt.typeFootnote, onGlass: onGlass, color: gt.colorWarning, maxScale: 1.5, maxLines: 4)),
          if (modes.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _chip('Next 10', 'next', plan),
                  _chip(narrate ? 'All un-narrated (${plan.all(_mode).length})' : 'All narrated (${plan.all(_mode).length})', 'all', plan),
                  if (narrate && plan.revoice.isNotEmpty) _chip('Re-voice (${plan.revoice.length})', 'revoice', plan),
                  _chip('None', 'none', plan),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: CustomScrollView(
              slivers: [
                if (jobsAsync.hasError)
                  SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), child: Row(children: [Expanded(child: GlassText("Couldn't load narration jobs", role: gt.typeFootnote, onGlass: onGlass, color: gt.colorWarning)), GlassButton(label: 'Try again', size: GlassButtonSize.small, onPressed: () => ref.invalidate(novelAudioJobsProvider(_series)))]))),
                if (jobs.isNotEmpty) SliverToBoxAdapter(child: _JobsSection(jobs: jobs, owner: owner, cancelling: _cancelling, onGlass: onGlass, onCancel: _cancelJob, onRerender: _renderAgain, onRemove: (j) => setState(() => _removed.add(j.jobId)))),
                SliverList.builder(
                  itemCount: shown.length,
                  itemBuilder: (context, i) {
                    final ch = shown[i];
                    final sel = _selected.contains(ch.key);
                    final ok = plan.selectable(_mode, ch.key) && !blocked;
                    final status = rowStatus(plan, _mode, ch.key);
                    return _ChapterRow(
                      key: ValueKey('chapter-${ch.key}'),
                      label: ch.label,
                      status: status,
                      selected: sel,
                      enabled: ok,
                      onGlass: onGlass,
                      color: textColor,
                      dim: dim,
                      onChanged: (v) => setState(() {
                        v ? _selected.add(ch.key) : _selected.remove(ch.key);
                        _quick = null;
                      }),
                    );
                  },
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
              ],
            ),
          ),
          if (modes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GlassText(estimateLine(_mode, _selected.length), role: gt.typeCaption1, onGlass: onGlass, color: dim, maxLines: 3, maxScale: 1.5),
                  const SizedBox(height: 8),
                  GlassButton(
                    label: primaryLabel(_mode, _selected.length),
                    variant: GlassButtonVariant.primary,
                    fullWidth: true,
                    loading: _sending,
                    onPressed: _selected.isEmpty || blocked ? null : () => unawaited(narrate ? _narrate(plan) : _save(plan, chapters)),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    return Column(
      children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 8), child: Align(alignment: Alignment.centerLeft, child: Semantics(liveRegion: true, child: GlassText(header, role: gt.typeSubhead, onGlass: onGlass, color: dim, maxLines: 2, maxScale: 1.5)))),
        Expanded(child: body),
      ],
    );
  }

  Widget _chip(String label, String id, AudiobookPlan plan) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GlassChip(label: label, kind: GlassChipKind.assist, selected: _quick == id, onPressed: () => _pick(plan, id)),
      );
}

class _ChapterRow extends StatelessWidget {
  const _ChapterRow({super.key, required this.label, required this.status, required this.selected, required this.enabled, required this.onGlass, required this.color, required this.dim, required this.onChanged});
  final String label, status;
  final bool selected, enabled, onGlass;
  final Color color, dim;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: enabled ? 1 : 0.55,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                GlassCheckbox(value: selected, onChanged: enabled ? onChanged : null, label: '$label, $status'),
                const SizedBox(width: 8),
                Expanded(
                  child: ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GlassText(label, role: gt.typeBody, onGlass: onGlass, maxLines: 1, overflow: TextOverflow.ellipsis, maxScale: 1.5),
                        GlassText(status, role: gt.typeCaption1, onGlass: onGlass, color: dim, maxLines: 2, maxScale: 1.5),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _JobsSection extends StatelessWidget {
  const _JobsSection({required this.jobs, required this.owner, required this.cancelling, required this.onGlass, required this.onCancel, required this.onRerender, required this.onRemove});
  final List<NovelAudioJob> jobs;
  final bool owner, onGlass;
  final Set<String> cancelling;
  final void Function(NovelAudioJob) onCancel, onRerender, onRemove;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(header: true, child: GlassText('Jobs', role: gt.typeHeadline, onGlass: onGlass)),
            const SizedBox(height: 6),
            for (final j in jobs) _JobTile(job: j, row: jobRowFor(j, owner: owner), cancelling: cancelling.contains(j.jobId), onGlass: onGlass, onCancel: () => onCancel(j), onRerender: () => onRerender(j), onRemove: () => onRemove(j)),
          ],
        ),
      );
}

class _JobTile extends StatelessWidget {
  const _JobTile({required this.job, required this.row, required this.cancelling, required this.onGlass, required this.onCancel, required this.onRerender, required this.onRemove});
  final NovelAudioJob job;
  final JobRow row;
  final bool cancelling, onGlass;
  final VoidCallback onCancel, onRerender, onRemove;

  Color get _tone => switch (row.tone) {
        JobTone.waiting => gt.colorG700,
        JobTone.working => gt.colorIris400,
        JobTone.success => gt.colorSuccess,
        JobTone.danger => gt.colorDanger,
        JobTone.muted => gt.colorLabel3,
      };

  @override
  Widget build(BuildContext context) {
    final chapter = job.chapterNumber == null ? 'Chapter' : 'Chapter ${job.chapterNumber! % 1 == 0 ? job.chapterNumber!.toInt() : job.chapterNumber}';
    final glyph = switch (row.tone) {
      JobTone.success => Icon(PhosphorFill.checkCircle, size: 18, color: _tone),
      JobTone.danger => Icon(PhosphorRegular.x, size: 18, color: _tone),
      JobTone.waiting => Icon(PhosphorRegular.pulse, size: 18, color: _tone),
      JobTone.muted => Icon(PhosphorRegular.x, size: 18, color: _tone),
      JobTone.working => row.spinner ? GlassSpinner(size: 18, color: _tone) : Icon(PhosphorRegular.waveform, size: 18, color: _tone),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 24, child: glyph),
          const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              container: true,
              label: '$chapter, ${row.title}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassText(chapter, role: gt.typeSubhead, wght: 600, onGlass: onGlass, maxLines: 1),
                  GlassText(cancelling ? 'Stops shortly' : row.title, role: gt.typeCaption1, onGlass: onGlass, color: row.tone == JobTone.danger ? gt.colorDanger : gt.colorLabel2, maxLines: 2, maxScale: 1.5),
                  if (row.progress != null) Padding(padding: const EdgeInsets.only(top: 6), child: LiquidProgress(value: row.progress!, height: 12, color: gt.colorIris500)),
                ],
              ),
            ),
          ),
          if (row.canCancel && !cancelling) GlassButton(label: 'Cancel', size: GlassButtonSize.small, onPressed: onCancel),
          if (row.canRerender) GlassButton(label: 'Render again', size: GlassButtonSize.small, onPressed: onRerender),
          if (row.removable) GlassButton(label: 'Remove', size: GlassButtonSize.small, onPressed: onRemove),
        ],
      ),
    );
  }
}
