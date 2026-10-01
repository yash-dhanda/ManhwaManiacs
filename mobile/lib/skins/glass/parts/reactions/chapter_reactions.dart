import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/circle/utils/dispatch.dart' show chapterLabel;
import 'package:manhwamaniacs/features/circle/utils/spoiler_guard.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/copy/reactions.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/reactions/reaction_picker.dart';
import 'package:manhwamaniacs/skins/glass/primitives/reactions/reaction_strip.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart';
import 'package:manhwamaniacs/skins/glass/screens/profiles/avatar_map.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart' show glassOfflineProvider;
import 'package:manhwamaniacs/skins/glass/type.dart';

/// "Ch 212" for a chapter.
String chLabel(double? n) => n == null ? 'this chapter' : 'Ch ${chapterLabel(n)}';

/// One chapter's reactions bound to `chapterReactionsProvider` (glass 9.3.2): the reaction button (tap Love, hold to bloom,
/// mouse click opens the picker) and, with [strip], the strip the sent glyph flies into. Sending waits in the strip at 60 % in
/// a `bloom` ring; a refusal falls back with the error shake and "Couldn't send your reaction"; offline queues through the
/// outbox (with the series' [mature] flag) and draws at once; sharing or `reactions` off keeps it private with the helper.
class GlassChapterReactions extends ConsumerStatefulWidget {
  const GlassChapterReactions({super.key, required this.sourceId, required this.seriesKey, required this.chapterKey, this.chapterNumber, this.mature = false, this.strip = true, this.button = true, this.openRequest});
  final String sourceId, seriesKey, chapterKey;
  final double? chapterNumber;
  final bool mature;
  final bool strip;
  final bool button;

  /// Opens the picker from the keyboard (the activity list's `e`).
  final Listenable? openRequest;

  @override
  ConsumerState<GlassChapterReactions> createState() => _ChapterReactionsState();
}

class _ChapterReactionsState extends ConsumerState<GlassChapterReactions> {
  ReactionSendState _send = ReactionSendState.idle;
  int _fail = 0;

  CircleSeriesKey get _key => (sourceId: widget.sourceId, seriesKey: widget.seriesKey);

  Future<void> _press(ReactionKind kind) async {
    final n = ref.read(chapterReactionsProvider(_key).notifier);
    final before = n.reactionsOf(widget.chapterKey)?.mine;
    final want = before == kind ? null : kind;
    setState(() => _send = ReactionSendState.sending);
    await n.press(widget.chapterKey, kind, chapterNumber: widget.chapterNumber, mature: widget.mature);
    if (!mounted) return;
    final now = n.reactionsOf(widget.chapterKey)?.mine;
    if (now != want && !ref.read(glassOfflineProvider)) {
      glassFire(ref, HapticEvent.error);
      ref.read(glassToastProvider.notifier).show(const GlassToastSpec("Couldn't send your reaction", kind: GlassToastKind.error));
      setState(() {
        _send = ReactionSendState.failed;
        _fail++;
      });
      return;
    }
    setState(() => _send = ReactionSendState.idle);
  }

  void _clear() {
    final mine = ref.read(chapterReactionsProvider(_key).notifier).reactionsOf(widget.chapterKey)?.mine;
    if (mine != null) unawaited(_press(mine));
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(chapterReactionsProvider(_key)).valueOrNull ?? const [];
    final c = all.where((x) => x.chapterKey == widget.chapterKey).firstOrNull;
    final pid = ref.watch(activeProfileProvider)?.id;
    final sharing = pid == null ? null : ref.watch(sharingProvider(pid)).valueOrNull;
    final sharingOff = sharing != null && (!sharing.activity || !sharing.reactions);
    final finished = ref.watch(finishedChaptersProvider(_key)).contains(widget.chapterKey);
    final label = chLabel(widget.chapterNumber ?? c?.chapterNumber);
    final mine = c?.mine;
    final button = GlassReactionButton(mine: mine, chapterLabel: label, openRequest: widget.openRequest, onSend: (k) => unawaited(_press(k)), onClear: _clear);
    if (!widget.strip) return button;
    final reactors = [
      for (final b in c?.by ?? const <ReactionBy>[])
        if (b.kind != null && b.profileId != pid) StripReactor(kind: b.kind!, name: b.name, preset: glassPresetFor(b.avatarKey), sealed: c!.sealed),
    ];
    final guarded = c != null && guardedFor(finished ? {widget.chapterKey} : const {}, chapterKey: widget.chapterKey, isOwn: false, sealed: c.sealed);
    // Counts from people the server did not list; never shown per kind on a guarded chapter.
    final solo = <ReactionKind, int>{
      if (c != null && !guarded)
        for (final r in kGlassReactions) r.kind: (c.countOf(r.kind) - reactors.where((x) => x.kind == r.kind).length - (mine == r.kind ? 1 : 0)).clamp(0, 1 << 20),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.button) Padding(padding: const EdgeInsets.only(bottom: 8), child: button),
        GlassReactionStrip(
          reactors: reactors,
          onSend: (k) => unawaited(_press(k)),
          sourceId: widget.sourceId,
          seriesKey: widget.seriesKey,
          chapterKey: widget.chapterKey,
          chapterLabel: label,
          mine: mine,
          mineState: _send,
          failTrigger: _fail,
          completedLocally: finished,
          sharingOff: sharingOff,
          solo: solo,
        ),
      ],
    );
  }
}

/// A chapter row's summary (glass 9.3.2): a finished chapter shows the top kind's 16 px glyph and the total; a guarded one an
/// 8 px `bloom` dot and the count, "3 friends reacted". Nothing when no one reacted.
class ChapterReactionSummary extends ConsumerWidget {
  const ChapterReactionSummary({super.key, required this.sourceId, required this.seriesKey, required this.chapterKey});
  final String sourceId, seriesKey, chapterKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (sourceId: sourceId, seriesKey: seriesKey);
    final c = (ref.watch(chapterReactionsProvider(key)).valueOrNull ?? const []).where((x) => x.chapterKey == chapterKey).firstOrNull;
    if (c == null || c.total == 0) return const SizedBox.shrink();
    final finished = ref.watch(finishedChaptersProvider(key)).contains(chapterKey);
    final guarded = guardedFor(finished ? {chapterKey} : const {}, chapterKey: chapterKey, isOwn: false, sealed: c.sealed) && c.mine == null;
    final friends = c.total == 1 ? '1 friend reacted' : '${c.total} friends reacted';
    if (guarded) {
      return Semantics(
        label: friends,
        excludeSemantics: true,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: gt.colorBloom, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          GlassText('${c.total}', role: gt.typeCaption1, color: gt.colorLabel2),
        ],),
      );
    }
    var top = kGlassReactions.first;
    for (final r in kGlassReactions) {
      if (c.countOf(r.kind) > c.countOf(top.kind)) top = r;
    }
    return Semantics(
      label: '${c.total} ${c.total == 1 ? 'reaction' : 'reactions'}, most ${top.name}',
      excludeSemantics: true,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(top.fill, size: 16, color: c.mine == top.kind ? gt.colorBloom : gt.colorLabel2),
        const SizedBox(width: 4),
        GlassText('${c.total}', role: gt.typeCaption1, color: gt.colorLabel2),
      ],),
    );
  }
}

/// "React to this chapter" from a reader menu (glass 8.14, 9.3.2): the chapter's button and strip in a `medium` sheet.
Future<void> openChapterReactions(BuildContext context, {required String sourceId, required String seriesKey, required String chapterKey, double? chapterNumber, bool mature = false}) {
  final page = GlassSheetPage<void>(
    title: 'React to ${chLabel(chapterNumber)}',
    detents: const [GlassDetent.medium],
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Align(alignment: Alignment.topLeft, child: GlassChapterReactions(sourceId: sourceId, seriesKey: seriesKey, chapterKey: chapterKey, chapterNumber: chapterNumber, mature: mature)),
    ),
  );
  return Navigator.of(context, rootNavigator: true).push(page.createRoute(context));
}
