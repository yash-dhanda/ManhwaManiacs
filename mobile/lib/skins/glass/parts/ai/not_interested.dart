import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/ai/providers/ai_providers.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/icons/glass_glyphs.g.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/swipe_row.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster_throw.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';

/// "Not interested" for one AI card (glass 9.1.1): a sideways throw (`decideThrow(allowAway)`, spin up to 12 degrees, `springDismiss`
/// with the release velocity), on phones a swipe row with a full swipe past 60 %, the menu, `Delete` / `Backspace` on the focused card
/// and a custom semantics action. Each sends `not_interested` and shows "We'll show fewer like this" with Undo (`undo`). "More like
/// this one" sends `liked_pick` and hands the item to [onMoreLikeThis].
class AiCardActions extends ConsumerStatefulWidget {
  const AiCardActions(
      {super.key,
      required this.child,
      required this.item,
      this.swipeRow = false,
      this.onRemoved,
      this.onMoreLikeThis,});
  final Widget child;
  final WorldItem item;

  /// Phones in a vertical list: a left swipe reveals "Not interested" instead of the throw gesture.
  final bool swipeRow;
  final VoidCallback? onRemoved;
  final void Function(WorldItem item)? onMoreLikeThis;

  @override
  ConsumerState<AiCardActions> createState() => AiCardActionsState();
}

class AiCardActionsState extends ConsumerState<AiCardActions>
    with SingleTickerProviderStateMixin {
  late final AnimationController _x =
      AnimationController.unbounded(vsync: this);
  final GlobalKey _box = GlobalKey();
  bool _removing = false;

  @override
  void dispose() {
    _x.dispose();
    super.dispose();
  }

  Rect _rect() {
    final ro = _box.currentContext?.findRenderObject();
    return ro is RenderBox && ro.attached
        ? ro.localToGlobal(Offset.zero) & ro.size
        : Rect.zero;
  }

  /// Sends the signal and hides the card for the session; the toast's Undo takes both back.
  Future<void> notInterested({double velocity = 0}) async {
    final w = widget.item;
    final fb = ref.read(aiFeedbackProvider);
    glassFire(ref, HapticEvent.throwCommit, velocity: velocity);
    unawaited(fb.notInterested(w));
    widget.onRemoved?.call();
    showGlassToast(
        ref,
        GlassToastSpec("We'll show fewer like this",
            undo: () => unawaited(fb.undoNotInterested(w)),),);
  }

  Future<void> moreLikeThis() async {
    await ref.read(aiFeedbackProvider).likedPick(widget.item);
    widget.onMoreLikeThis?.call(widget.item);
  }

  void openMenu() {
    unawaited(
      showGlassMenu(
        context,
        anchor: _rect(),
        title: widget.item.title,
        entries: [
          GlassMenuEntry(
              label: 'Not interested',
              onSelected: () => unawaited(notInterested()),),
          GlassMenuEntry(
              label: 'More like this one',
              onSelected: () => unawaited(moreLikeThis()),),
        ],
      ),
    );
  }

  KeyEventResult _key(FocusNode n, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    if (e.logicalKey == LogicalKeyboardKey.delete ||
        e.logicalKey == LogicalKeyboardKey.backspace) {
      unawaited(notInterested());
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _end(DragEndDetails d) {
    final box = _box.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final v =
        Offset(d.velocity.pixelsPerSecond.dx, d.velocity.pixelsPerSecond.dy);
    final centre = box.localToGlobal(box.size.center(Offset.zero));
    final view = MediaQuery.sizeOf(context);
    final decision = decideThrow(
        centre: centre, velocity: v, viewport: view, allowAway: true,);
    if (decision is ThrowAway) {
      _removing = true;
      final dir = (_x.value == 0 ? v.dx : _x.value).sign == 0
          ? 1.0
          : (_x.value == 0 ? v.dx : _x.value).sign;
      unawaited(notInterested(velocity: v.distance));
      unawaited(_x
          .springTo(dir * (view.width + 200), gt.springDismiss,
              velocityPxPerS: v.dx,)
          .whenComplete(() {
        if (mounted) setState(() => _removing = false);
      }),);
    } else {
      unawaited(_x.springTo(0, gt.springSnappy, velocityPxPerS: v.dx));
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget card = KeyedSubtree(key: _box, child: widget.child);
    if (widget.swipeRow) {
      card = GlassSwipeRow(
        name: widget.item.title,
        removedMessage: "We'll show fewer like this",
        trailing: [
          SwipeAction(
            id: 'not_interested',
            label: 'Not interested',
            glyph: GlassGlyphs.sparkleSlashRegular,
            run: () async {
              final fb = ref.read(aiFeedbackProvider);
              glassFire(ref, HapticEvent.throwCommit, velocity: 0);
              unawaited(fb.notInterested(widget.item));
              widget.onRemoved?.call();
            },
            undo: () async => unawaited(
                ref.read(aiFeedbackProvider).undoNotInterested(widget.item),),
          ),
        ],
        child: card,
      );
    } else {
      card = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: (d) => _x.value += d.delta.dx,
        onHorizontalDragEnd: _end,
        child: AnimatedBuilder(
          animation: _x,
          builder: (_, child) => Transform.translate(
            offset: Offset(_x.value, 0),
            child: Transform.rotate(
                angle: (_x.value / 400).clamp(-1.0, 1.0) * 12 * math.pi / 180,
                child: child,),
          ),
          child: card,
        ),
      );
    }
    return Focus(
      canRequestFocus: true,
      onKeyEvent: _key,
      child: Semantics(
        customSemanticsActions: {
          const CustomSemanticsAction(label: 'Not interested'): () =>
              unawaited(notInterested()),
          const CustomSemanticsAction(label: 'More like this one'): () =>
              unawaited(moreLikeThis()),
        },
        child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onLongPress: openMenu,
            child: Visibility(
                visible: !_removing || _x.value.abs() < 1e6, child: card,),),
      ),
    );
  }
}
