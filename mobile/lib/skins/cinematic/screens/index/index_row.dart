import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/a11y/folio.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_dot_leader.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The leader draw (cinematic 4.5): a clip reveal left to right, 320 ms per row, rows 24 ms
/// apart, `easeSettle`. Reduced motion, and every visit after the first of the session, show the
/// leader at rest.
class LeaderDraw extends StatefulWidget {
  const LeaderDraw({super.key, required this.index, required this.play, required this.child});
  final int index;
  final bool play;
  final Widget child;

  @override
  State<LeaderDraw> createState() => _LeaderDrawState();
}

class _LeaderDrawState extends State<LeaderDraw> with SingleTickerProviderStateMixin {
  // One controller spans the row's stagger delay and its 320 ms draw, so no timer is needed.
  late final int _delay = 24 * widget.index;
  late final AnimationController _c = AnimationController(vsync: this, duration: Duration(milliseconds: _delay + 320));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!widget.play || CineMotion.reduced(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (context, child) {
          final total = _delay + 320;
          final t = ((_c.value * total - _delay) / 320).clamp(0.0, 1.0);
          return ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: context.cine.easeSettle.transform(t),
              child: child,
            ),
          );
        },
      );
}

/// One row of the Index (48 dp): label, dot leader, folio value, caret. [value] null hides the
/// value only (a failed count); [loading] shows `–`.
class IndexRow extends StatelessWidget {
  const IndexRow({
    super.key,
    required this.label,
    this.value,
    this.loading = false,
    this.onTap,
    this.leading,
    this.index = 0,
    this.playLeaders = false,
    this.focusNode,
  });

  final String label;
  final String? value;
  final bool loading;
  final VoidCallback? onTap;
  final Widget? leading;
  final int index;
  final bool playLeaders;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final shown = loading ? '–' : value;
    final spoken = shown == null ? label : (loading ? '$label, loading' : '$label, ${folioLabel(shown)}');
    return Semantics(
      button: true,
      container: true,
      label: spoken,
      excludeSemantics: true,
      onTap: onTap,
      child: CinePressable(
        focusNode: focusNode,
        onTap: onTap,
        hit: false,
        builder: (context, st) => Container(
          constraints: BoxConstraints(minHeight: cineHitMin(context) > 48 ? cineHitMin(context) : 48),
          decoration: BoxDecoration(border: Border(bottom: c.ruleHair), color: st.pressed ? c.colorPaper3 : null),
          child: Row(
            children: [
              if (leading != null) ...[leading!, SizedBox(width: c.space2)],
              Expanded(
                child: CineLeaderRow(
                  label: CineRoleText(label, c.typeUi),
                  leader: LeaderDraw(index: index, play: playLeaders, child: const CineDotLeader()),
                  value: shown == null ? null : CineRoleText(shown, c.typeFolio, color: c.colorInk45, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
              SizedBox(width: c.space2),
              CineGlyphIcon(CineGlyph.caretRight, size: 16, color: c.colorInk45),
            ],
          ),
        ),
      ),
    );
  }
}
