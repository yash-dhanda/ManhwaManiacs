import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/utils/spoiler_guard.dart';
import 'package:manhwamaniacs/skins/glass/primitives/badge.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/profile_orb.dart';
import 'package:manhwamaniacs/skins/glass/primitives/reactions/glass_reactions.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// Whether the viewer's own reaction is confirmed, on its way, or failed (glass 9.3.2 states).
enum ReactionSendState { idle, sending, failed }

/// One friend's reaction on the chapter.
class StripReactor {
  const StripReactor({required this.kind, required this.name, required this.preset, this.isOwn = false, this.sealed});
  final ReactionKind kind;
  final String name;
  final GlassAvatarPreset preset;
  final bool isOwn;

  /// The server's `sealed`; null when unknown (offline included), which hides.
  final bool? sealed;
}

/// The reaction strip under a chapter (glass 9.3.2): the six glyphs (24 px) with counts, up to three friend orbs beside each (then
/// "+2"), a long-press (or `.`) on a glyph opens who reacted, `1` to `6` send directly. Your own is `bloom` on a `bloomWash` disc;
/// the rest are `label2`. A guarded reaction (through [isGuarded] and `completedThisSession`) shows only the reactor's orb and
/// "reacted to Ch {n}", never the glyph or a per-kind count; when the chapter completes the glyphs unseal, each fading in over
/// 160 ms, 40 ms apart. Sharing off: "Only you see this. Turn on Circle sharing to show others."
class GlassReactionStrip extends ConsumerStatefulWidget {
  const GlassReactionStrip({
    super.key,
    required this.reactors,
    required this.onSend,
    required this.sourceId,
    required this.seriesKey,
    required this.chapterKey,
    required this.chapterLabel,
    this.mine,
    this.mineState = ReactionSendState.idle,
    this.failTrigger = 0,
    this.completedLocally = false,
    this.sharingOff = false,
    this.solo = const {},
  });

  /// Everyone else's reactions (and the viewer's own with `isOwn`).
  final List<StripReactor> reactors;
  final ValueChanged<ReactionKind> onSend;
  final String sourceId, seriesKey, chapterKey;

  /// "Ch 212".
  final String chapterLabel;
  final ReactionKind? mine;
  final ReactionSendState mineState;
  final int failTrigger;
  final bool completedLocally;
  final bool sharingOff;

  /// Counts of reactions from people not listed as [reactors] (an aggregate), by kind.
  final Map<ReactionKind, int> solo;

  @override
  ConsumerState<GlassReactionStrip> createState() => _GlassReactionStripState();
}

class _GlassReactionStripState extends ConsumerState<GlassReactionStrip> {
  final Map<ReactionKind, GlobalKey> _keys = {for (final r in kGlassReactions) r.kind: GlobalKey()};
  late final ReactionTargets _targets = ref.read(glassReactionTargetsProvider);
  bool _wasGuarded = true;
  bool _unsealing = false;

  @override
  void initState() {
    super.initState();
    _keys.forEach(_targets.register);
  }

  @override
  void dispose() {
    _keys.forEach(_targets.unregister);
    super.dispose();
  }

  bool _guarded(StripReactor r, bool completedSession) => isGuarded(isOwn: r.isOwn, sealed: r.sealed, completedLocally: widget.completedLocally, completedThisSession: completedSession);

  Future<void> _who(BuildContext c, GlassReaction r, List<StripReactor> list) async {
    final box = c.findRenderObject();
    if (box is! RenderBox) return;
    if (list.isEmpty) return;
    await showGlassMenu(c, anchor: box.localToGlobal(Offset.zero) & box.size, title: '${r.name} reactions', entries: [for (final x in list) GlassMenuEntry(label: x.isOwn ? 'You' : x.name)]);
  }

  KeyEventResult _key(FocusNode n, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    const digits = [LogicalKeyboardKey.digit1, LogicalKeyboardKey.digit2, LogicalKeyboardKey.digit3, LogicalKeyboardKey.digit4, LogicalKeyboardKey.digit5, LogicalKeyboardKey.digit6];
    final i = digits.indexOf(e.logicalKey);
    if (i < 0) return KeyEventResult.ignored;
    widget.onSend(kGlassReactions[i].kind);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final completed = ref.watch(completedThisSessionProvider).contains(chapterId(widget.sourceId, widget.seriesKey, widget.chapterKey));
    final guarded = [for (final r in widget.reactors) if (_guarded(r, completed)) r];
    final open = [for (final r in widget.reactors) if (!_guarded(r, completed)) r];
    final anyGuarded = guarded.isNotEmpty;
    if (_wasGuarded && !anyGuarded && widget.reactors.isNotEmpty) _unsealing = true;
    if (anyGuarded) _unsealing = false;
    _wasGuarded = anyGuarded || widget.reactors.isEmpty;
    final host = GlassHost.of(context);
    final helper = host ? gt.colorOnGlass : gt.colorLabel3;
    return Focus(
      onKeyEvent: _key,
      child: Semantics(
        container: true,
        label: 'Reactions',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < kGlassReactions.length; i++)
                  _Slot(
                    key: ValueKey('glass-reaction-slot-${kGlassReactions[i].kind.name}'),
                    reaction: kGlassReactions[i],
                    slotKey: _keys[kGlassReactions[i].kind]!,
                    index: i,
                    reactors: [for (final r in open) if (r.kind == kGlassReactions[i].kind) r],
                    extra: widget.solo[kGlassReactions[i].kind] ?? 0,
                    mine: widget.mine == kGlassReactions[i].kind,
                    mineState: widget.mineState,
                    failTrigger: widget.failTrigger,
                    unseal: _unsealing,
                    onSend: () => widget.onSend(kGlassReactions[i].kind),
                    onWho: (c, list) => _who(c, kGlassReactions[i], list),
                  ),
              ],
            ),
            if (anyGuarded)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  for (final g in guarded.take(3)) GlassFriendBadge(g.preset, name: g.name),
                  if (guarded.length > 3) GlassText('+${guarded.length - 3}', role: gt.typeCaption1, color: gt.colorLabel2),
                  GlassText('reacted to ${widget.chapterLabel}', role: gt.typeFootnote, color: gt.colorLabel2),
                ],),
              ),
            if (widget.sharingOff)
              Padding(padding: const EdgeInsets.only(top: 8), child: GlassText('Only you see this. Turn on Circle sharing to show others.', role: gt.typeFootnote, color: helper, onGlass: host)),
          ],
        ),
      ),
    );
  }
}

class _Slot extends ConsumerWidget {
  const _Slot({super.key, required this.reaction, required this.slotKey, required this.index, required this.reactors, required this.extra, required this.mine, required this.mineState, required this.failTrigger, required this.unseal, required this.onSend, required this.onWho});
  final GlassReaction reaction;
  final GlobalKey slotKey;
  final int index;
  final List<StripReactor> reactors;
  final int extra;
  final bool mine;
  final ReactionSendState mineState;
  final int failTrigger;
  final bool unseal;
  final VoidCallback onSend;
  final void Function(BuildContext context, List<StripReactor> who) onWho;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = reactors.length + extra + (mine && !reactors.any((r) => r.isOwn) ? 1 : 0);
    final sending = mine && mineState == ReactionSendState.sending;
    final color = mine ? gt.colorBloom : gt.colorLabel2;
    Widget glyph = SizedBox.square(
      dimension: 32,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: mine ? gt.colorBloomWash : const Color(0x00000000),
          border: sending ? Border.all(color: gt.colorBloom.withValues(alpha: 0.4), width: 1.5) : null,
        ),
        child: Center(child: Opacity(opacity: sending ? 0.6 : 1, child: Icon(reaction.fill, size: 24, color: color))),
      ),
    );
    glyph = GlassShake(trigger: mine ? failTrigger : 0, child: glyph);
    // Unsealing: each glyph fades in over 160 ms, 40 ms apart.
    Widget body = Column(mainAxisSize: MainAxisSize.min, children: [
      KeyedSubtree(key: slotKey, child: glyph),
      GlassPop(trigger: count, child: GlassText('$count', role: gt.typeMono, size: 12, height: 16, color: color)),
      if (reactors.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            for (final r in reactors.take(3)) Padding(padding: const EdgeInsets.only(right: 2), child: GlassFriendBadge(r.preset, name: r.name)),
            if (reactors.length > 3) GlassText('+${reactors.length - 3}', role: gt.typeCaption2, color: gt.colorLabel2),
          ],),
        ),
    ],);
    if (unseal) {
      body = _Unseal(delayMs: 40 * index, child: body);
    }
    return SizedBox(
      width: 56,
      child: GlassPressable(
        material: GlassMaterial.content,
        sink: 0.94,
        shape: const GlassShape.superellipse(16),
        onTap: onSend,
        onLongPress: () => onWho(context, reactors),
        semanticsLabel: '${reaction.name}, $count',
        semanticsHint: 'Long press to see who reacted',
        toggled: mine,
        builder: (context, info) => Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onKeyEvent: (n, e) {
            if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.period) {
              onWho(context, reactors);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: ConstrainedBox(constraints: const BoxConstraints(minHeight: 48), child: Center(child: body)),
        ),
      ),
    );
  }
}

class _Unseal extends StatefulWidget {
  const _Unseal({required this.delayMs, required this.child});
  final int delayMs;
  final Widget child;

  @override
  State<_Unseal> createState() => _UnsealState();
}

class _UnsealState extends State<_Unseal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 160));
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(Duration(milliseconds: widget.delayMs), () {
      if (mounted) unawaited(_c.forward());
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _c, child: widget.child);
}

