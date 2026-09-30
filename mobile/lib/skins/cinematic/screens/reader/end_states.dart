import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/providers/up_next_provider.dart';
import 'package:manhwamaniacs/features/library/utils/all_followed.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_notice.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_switch.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_series.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/up_next_rail.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The row this profile follows for a series, or null (`GET /library/series`, every page).
final readerFollowProvider = FutureProvider.autoDispose.family<FollowedSeries?, ReaderSeriesKey>((ref, k) async {
  final all = await listAllFollowed(ref.watch(libraryRepositoryProvider));
  if (all.isErr) return null;
  for (final f in all.value) {
    if (f.sourceId == k.sourceId && (f.seriesKey == k.seriesKey || f.identity == k.seriesKey)) return f;
  }
  return null;
}, name: 'readerFollow',);

/// "You finished {title}." for the end of a Completed series and "That's everything so far." for a
/// caught-up ongoing one (cinematic 8.14.6): a notice, a `Notify me` switch (caught up only), the
/// rail and the exits. Never `Notify me` for a Completed series.
class ReaderEndNotice extends ConsumerStatefulWidget {
  const ReaderEndNotice({
    super.key,
    required this.sourceId,
    required this.seriesKey,
    required this.title,
    required this.sourceName,
    required this.chapterCount,
    required this.completed,
    required this.latestChapter,
    required this.readHours,
    required this.onBackToSeries,
  });

  final String sourceId, seriesKey, title, sourceName;
  final int chapterCount;

  /// The series `status` is Completed.
  final bool completed;

  /// The newest chapter number ("142").
  final String latestChapter;

  /// Hours spent on the series, for "{n} chapters, {h} hours." (rounded up, at least 1).
  final int readHours;
  final VoidCallback onBackToSeries;

  @override
  ConsumerState<ReaderEndNotice> createState() => _ReaderEndNoticeState();
}

class _ReaderEndNoticeState extends ConsumerState<ReaderEndNotice> {
  bool? _notify;
  bool _done = false;

  ReaderSeriesKey get _key => (sourceId: widget.sourceId, seriesKey: widget.seriesKey);

  Future<FollowedSeries?> _ensureFollowed() async {
    final existing = await ref.read(readerFollowProvider(_key).future);
    if (existing != null) return existing;
    final r = await ref.read(libraryRepositoryProvider).follow(sourceId: widget.sourceId, seriesKey: widget.seriesKey);
    ref.invalidate(readerFollowProvider(_key));
    return r.isOk ? r.value : null;
  }

  Future<void> _setNotify(bool on) async {
    final f = await _ensureFollowed();
    if (f == null) {
      ref.read(cineToastsProvider.notifier).error("Couldn't turn that on.");
      return;
    }
    final r = await ref.read(libraryRepositoryProvider).patchSeries(f.id, notify: on);
    if (r.isOk) {
      setState(() => _notify = on);
    } else {
      ref.read(cineToastsProvider.notifier).error("Couldn't turn that on.");
    }
  }

  Future<void> _markDone() async {
    final f = await _ensureFollowed();
    if (f == null) return;
    final r = await ref.read(libraryRepositoryProvider).patchSeries(f.id, readingStatus: 'completed');
    if (r.isOk && mounted) setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final followed = ref.watch(readerFollowProvider(_key)).valueOrNull;
    final notify = _notify ?? followed?.notify ?? false;
    final completed = widget.completed;
    final alreadyDone = _done || followed?.readingStatus == 'completed';
    return Padding(
      padding: EdgeInsets.fromLTRB(c.space4, c.space6, c.space4, c.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CineNotice(
            tone: completed ? CineNoticeTone.empty : CineNoticeTone.caution,
            kicker: completed ? 'THE END' : 'CAUGHT UP',
            headline: completed ? 'You finished ${widget.title}.' : "That's everything so far.",
            deck: completed
                ? '${widget.chapterCount} chapters, ${widget.readHours} ${widget.readHours == 1 ? 'hour' : 'hours'}.'
                : "${widget.sourceName} has published ${widget.latestChapter} chapters. You'll get a notice when ${_next(widget.latestChapter)} lands.",
            primary: CineNoticeAction('Back to the series', widget.onBackToSeries),
            quiet: completed && !alreadyDone ? CineNoticeAction('Mark as done', _markDone) : null,
          ),
          if (!completed) ...[
            SizedBox(height: c.space4),
            Row(
              children: [
                Expanded(child: CineRoleText('Notify me', c.typeTitle)),
                CineSwitch(value: notify, label: 'Notify me', onChanged: _setNotify),
              ],
            ),
          ],
          SizedBox(height: c.space6),
          UpNextRail(sourceId: widget.sourceId, seriesKey: widget.seriesKey, mode: completed ? UpNextMode.theEnd : UpNextMode.caughtUp),
        ],
      ),
    );
  }

  static String _next(String latest) {
    final n = num.tryParse(latest);
    return n == null ? 'the next one' : '${n.floor() + 1}';
  }
}

/// `CORRECTION` for a next chapter that did not load (cinematic 8.14.11): "Chapter 143 didn't
/// load." with `Try again` and `Open it on its own →`; the engine retries by itself meanwhile.
class NextFailedNotice extends StatelessWidget {
  const NextFailedNotice({super.key, required this.label, required this.onRetry, required this.onOpen});

  final String label;
  final VoidCallback onRetry, onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Padding(
      padding: EdgeInsets.all(c.space4),
      child: CineNotice(
        tone: CineNoticeTone.error,
        headline: "$label didn't load.",
        primary: CineNoticeAction('Try again', onRetry),
        quiet: CineNoticeAction('Open it on its own →', onOpen),
      ),
    );
  }
}

/// "Next chapter isn't saved on this device" with `Back to Downloads` (offline edition).
class OfflineEndNotice extends StatelessWidget {
  const OfflineEndNotice({super.key, required this.onBackToDownloads});
  final VoidCallback onBackToDownloads;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Padding(
      padding: EdgeInsets.all(c.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CineRoleText("Next chapter isn't saved on this device", c.typeKicker, color: c.colorInk60, textAlign: TextAlign.center),
          SizedBox(height: c.space3),
          CineButton(label: 'Back to Downloads', variant: CineButtonVariant.quiet, onPressed: onBackToDownloads),
        ],
      ),
    );
  }
}
