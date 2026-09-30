import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/circle/utils/reaction_kinds.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/circle_guard.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_avatar.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/typed_text.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

const Map<String, int> _glyphs = {
  'heart': CineGlyph.heart,
  'lightning': CineGlyph.lightning,
  'smiley': CineGlyph.smiley,
  'drop': CineGlyph.drop,
  'sparkle': CineGlyph.sparkle,
};

/// The Phosphor glyph of a reaction (Regular, `ink.100` unless [color]); the two text stamps have
/// no glyph and fall back to a heart.
Widget reactionGlyph(ReactionKind kind, {double size = 20, Color? color}) =>
    CineGlyphIcon(_glyphs[reactionSpec(kind).glyph] ?? CineGlyph.heart, size: size, color: color);

/// `Loved`, `Chef's kiss` ... the spoken name.
String reactionName(ReactionKind kind) => reactionSpec(kind).label;

/// The colours of a stamp row: the skin's by default, a novel stock's on the end matter.
class ReactionStampColors {
  const ReactionStampColors({required this.outline, required this.ink, required this.muted, required this.fillText});
  final Color outline, ink, muted, fillText;
}

/// Reaction stamps (cinematic 9.3.3): a row of square stamps 8 px apart, each min 44 x 44 (48 on
/// Android) with a 1 px outline, the glyph and its count as a folio, the avatars of who pressed it
/// underneath. Pressing sets, moves or clears the viewer's reaction (drawn at once, queued offline).
/// Under the spoiler guard the counts and avatars give way to one line: the reactors and the total.
class ReactionStamps extends ConsumerWidget {
  const ReactionStamps({super.key, required this.sourceId, required this.seriesKey, required this.chapterKey, this.chapterNumber, this.colors, this.unsealIndex = 0});

  final String sourceId, seriesKey, chapterKey;
  final double? chapterNumber;
  final ReactionStampColors? colors;
  final int unsealIndex;

  static String chapterWords(double? n) => n == null ? 'this chapter' : 'chapter ${n == n.roundToDouble() ? n.toInt() : n}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (sourceId: sourceId, seriesKey: seriesKey);
    final chapters = ref.watch(chapterReactionsProvider(key)).valueOrNull ?? const <ChapterReactions>[];
    ChapterReactions? cr;
    for (final ch in chapters) {
      if (ch.chapterKey == chapterKey) cr = ch;
    }
    final mine = cr?.mine;
    final others = cr == null ? 0 : (cr.total - (mine == null ? 0 : 1)).clamp(0, 1 << 30);
    final guarded = others > 0 && circleGuarded(ref, sourceId: sourceId, seriesKey: seriesKey, chapterKey: chapterKey, sealed: cr?.sealed);
    return _StampRow(
      cr: cr,
      guarded: guarded,
      colors: colors,
      chapterNumber: chapterNumber ?? cr?.chapterNumber,
      unsealIndex: unsealIndex,
      onPress: (kind) {
        cineFeedback(context, HapticEvent.reactionSend, sound: SoundEvent.reactionSend);
        unawaited(ref.read(chapterReactionsProvider(key).notifier).press(chapterKey, kind, chapterNumber: chapterNumber));
      },
    );
  }
}

class _StampRow extends StatelessWidget {
  const _StampRow({required this.cr, required this.guarded, required this.colors, required this.chapterNumber, required this.unsealIndex, required this.onPress});
  final ChapterReactions? cr;
  final bool guarded;
  final ReactionStampColors? colors;
  final double? chapterNumber;
  final int unsealIndex;
  final ValueChanged<ReactionKind> onPress;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final mine = cr?.mine;
    final total = cr?.total ?? 0;
    final shown = [
      for (final s in reactionSpecs)
        if (s.offered || mine == s.kind || (!guarded && (cr?.countOf(s.kind) ?? 0) > 0)) s,
    ];
    final others = [for (final b in cr?.by ?? const <ReactionBy>[]) b];
    final label = guarded ? '$total ${total == 1 ? 'reaction' : 'reactions'}, hidden until you finish the chapter' : 'Reactions to ${ReactionStamps.chapterWords(chapterNumber)}';
    return Semantics(
      container: true,
      label: label,
      child: FocusTraversalGroup(
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.arrowRight): () => FocusScope.of(context).nextFocus(),
            const SingleActivator(LogicalKeyboardKey.arrowLeft): () => FocusScope.of(context).previousFocus(),
          },
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (guarded && total > 0)
              Padding(
                padding: EdgeInsets.only(bottom: c.space2),
                child: ExcludeSemantics(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    _Avatars(members: others, colors: colors),
                    SizedBox(width: c.space2),
                    CineRoleText('$total ${total == 1 ? 'reaction' : 'reactions'}', c.typeCaption, color: colors?.muted ?? c.colorInk45),
                  ],),
                ),
              ),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (var i = 0; i < shown.length; i++)
                _Stamp(
                  spec: shown[i],
                  mine: mine == shown[i].kind,
                  count: guarded ? null : cr?.countOf(shown[i].kind) ?? 0,
                  reactors: guarded ? const [] : [for (final b in others) if (b.kind == shown[i].kind) b],
                  guarded: guarded,
                  unsealIndex: unsealIndex + i,
                  colors: colors,
                  onPress: () => onPress(shown[i].kind),
                ),
            ],),
          ],),
        ),
      ),
    );
  }
}

/// Up to three 20 px avatars overlapping by 6 px, then a `+2` folio.
class _Avatars extends StatelessWidget {
  const _Avatars({required this.members, this.colors});
  final List<ProfileRef> members;
  final ReactionStampColors? colors;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final seen = <int>{};
    final unique = [for (final m in members) if (seen.add(m.profileId)) m];
    final shown = unique.take(3).toList();
    final extra = unique.length - shown.length;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: shown.isEmpty ? 0 : 20.0 + 14.0 * (shown.length - 1),
        height: 20,
        child: Stack(children: [
          for (var i = 0; i < shown.length; i++) Positioned(left: 14.0 * i, child: CineAvatar(avatarKey: shown[i].avatarKey, size: 20)),
        ],),
      ),
      if (extra > 0) ...[SizedBox(width: c.space1), CineRoleText('+$extra', c.typeFolio, color: colors?.muted ?? c.colorInk60)],
    ],);
  }
}

class _Stamp extends StatefulWidget {
  const _Stamp({required this.spec, required this.mine, required this.count, required this.reactors, required this.guarded, required this.unsealIndex, required this.colors, required this.onPress});
  final ReactionSpec spec;
  final bool mine, guarded;
  final int? count;
  final List<ProfileRef> reactors;
  final int unsealIndex;
  final ReactionStampColors? colors;
  final VoidCallback onPress;

  @override
  State<_Stamp> createState() => _StampState();
}

class _StampState extends State<_Stamp> {
  bool _down = false;
  bool _typed = false;

  @override
  void didUpdateWidget(_Stamp old) {
    super.didUpdateWidget(old);
    if (old.count != widget.count && !_typed) _typed = true;
  }

  void _press() {
    setState(() => _down = true);
    Timer(const Duration(milliseconds: 80), () {
      if (mounted) setState(() => _down = false);
    });
    widget.onPress();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final col = widget.colors;
    final reduced = CineMotion.reduced(context);
    final hit = cineHitMin(context);
    final ink = widget.mine ? (col?.fillText ?? const Color(0xFF000000)) : (col?.ink ?? c.colorInk100);
    final fill = widget.mine ? (col?.ink ?? c.colorInk100) : const Color(0x00000000);
    final outline = col?.outline ?? c.colorRule2;
    final spec = widget.spec;
    final count = widget.count;
    final spoken = '${spec.label}${count == null || count == 0 ? '' : ', $count ${count == 1 ? 'reaction' : 'reactions'}'}${widget.mine ? ', selected' : ''}';
    final press = AnimatedContainer(
      duration: reduced ? Duration.zero : (_down ? CineDur.tick : CineDur.beat),
      curve: _down ? CineCurves.easeSet : CineCurves.settle,
      transform: Matrix4.translationValues(0, _down ? 1 : 0, 0),
      constraints: BoxConstraints(minWidth: hit, minHeight: hit),
      padding: spec.stampText != null ? const EdgeInsets.symmetric(horizontal: 6) : EdgeInsets.zero,
      decoration: BoxDecoration(color: fill, border: Border.all(color: outline)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
        if (spec.stampText != null)
          CineRoleText(spec.stampText!, c.typeMicro, color: ink)
        else
          CineGlyphIcon(_glyphs[spec.glyph] ?? CineGlyph.heart, color: ink),
        if (count != null && count > 0)
          _typed && !reduced
              ? TypedText.plain('$count', key: ValueKey('${spec.kind.wire}-$count'), style: CineText.style(context, c.typeFolio).copyWith(color: widget.mine ? ink : (col?.muted ?? c.colorInk60)))
              : CineRoleText('$count', c.typeFolio, color: widget.mine ? ink : (col?.muted ?? c.colorInk60)),
      ],),
    );
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Semantics(
        inMutuallyExclusiveGroup: true,
        checked: widget.mine,
        button: true,
        label: spoken,
        excludeSemantics: true,
        onTap: _press,
        child: CinePressable(hit: false, onTap: _press, builder: (_, st) => Opacity(opacity: st.focused || st.hovered ? 1 : 0.94, child: press)),
      ),
      if (widget.reactors.isNotEmpty) Padding(padding: EdgeInsets.only(top: c.space1), child: ExcludeSemantics(child: _Avatars(members: widget.reactors, colors: col))),
    ],);
  }
}
