import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

enum CineSwipeKind { markRead, remove }

/// A row with one swipe action (cinematic 7.16): `Dismissible` end-to-start with a 50 % threshold
/// and one flat 72 px slab behind it: `Mark read` (`ink.100`, `#000` label; the row springs back
/// and dims) or `Remove` (`proof`; the row leaves and its siblings close up in 240 ms). The same
/// action must also be in the row menu. Rows win horizontal drags over pagers by the gesture arena.
class CineSwipeRow extends StatefulWidget {
  const CineSwipeRow({
    super.key,
    required this.id,
    required this.kind,
    required this.onCommit,
    required this.child,
    this.dimmed,
  });

  /// A stable identity for the `Dismissible`.
  final Object id;
  final CineSwipeKind kind;
  final VoidCallback onCommit;
  final Widget child;

  /// Forces the dim; by default a committed `Mark read` dims the row itself.
  final bool? dimmed;

  @override
  State<CineSwipeRow> createState() => _CineSwipeRowState();
}

class _CineSwipeRowState extends State<CineSwipeRow> {
  bool _dim = false;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final remove = widget.kind == CineSwipeKind.remove;
    final label = remove ? 'Remove' : 'Mark read';
    final slab = Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 72,
        child: ColoredBox(
          color: remove ? c.colorProof : c.colorInk100,
          child: Center(child: CineRoleText(label, c.typeLabel, color: const Color(0xFF000000), textAlign: TextAlign.center)),
        ),
      ),
    );
    final dim = widget.dimmed ?? _dim;
    return Dismissible(
      key: ValueKey(widget.id),
      direction: DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.5},
      movementDuration: const Duration(milliseconds: 504),
      resizeDuration: const Duration(milliseconds: 240),
      background: ExcludeSemantics(child: slab),
      secondaryBackground: ExcludeSemantics(child: slab),
      confirmDismiss: remove
          ? null
          : (_) async {
              cineFeedback(context, HapticEvent.select);
              widget.onCommit();
              if (mounted) setState(() => _dim = true);
              return false;
            },
      onDismissed: remove
          ? (_) {
              cineFeedback(context, HapticEvent.deleteConfirm);
              widget.onCommit();
            }
          : null,
      child: AnimatedOpacity(
        duration: c.durSnap,
        opacity: dim ? 0.55 : 1,
        child: widget.child,
      ),
    );
  }
}
