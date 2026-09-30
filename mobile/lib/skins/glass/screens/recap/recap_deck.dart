import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/recap/recap_deck.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/screens/recap/deck_card.dart';

/// Depth of the card at [pos] (0 = front, 1 = next, 2 = the one behind): scale 1 / 0.94 / 0.89 (glass 9.1.3).
double deckScale(double pos) {
  if (pos <= 0) return 1;
  if (pos <= 1) return 1 - 0.06 * pos;
  return 0.94 - 0.05 * (pos - 1);
}

/// The black overlay of the card at [pos]: 0 / 40 % / 60 % (brightness 100 / 60 / 40 %).
double deckDim(double pos) {
  if (pos <= 0) return 0;
  if (pos <= 1) return 0.4 * pos;
  return 0.4 + 0.2 * (pos - 1);
}

/// A swipe up past 80 px (projected) or at `vy <= -800` lifts the front card.
bool swipeUpAdvances(double dy, double vy) => dy + vy * 0.1 <= -80 || vy <= -800;

/// Four cards stacked in depth (glass 9.1.3, Deck lift-off): the front one lifts toward the viewer (scale 1 to 1.06, up 40 px) and
/// away on `springSmooth`, the next one rising from 0.94. Swipe up, a tap on the right half, `Right` or `Space` advance; swipe down,
/// the left half or `Left` go back. A finger during the lift catches it. Reduced motion: 150 ms cross-fades.
class RecapDeckView extends ConsumerStatefulWidget {
  const RecapDeckView({super.key, required this.deck, this.onIndexChanged, this.width});
  final DeckState deck;
  final ValueChanged<int>? onIndexChanged;
  final double? width;

  @override
  ConsumerState<RecapDeckView> createState() => RecapDeckViewState();
}

class RecapDeckViewState extends ConsumerState<RecapDeckView> with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController.unbounded(vsync: this);
  int index = 0;
  bool _busy = false;

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  int get count => kDeckKinds.length;

  Future<void> next() async {
    if (index >= count - 1) return;
    _busy = true;
    unawaited(ref.read(glassHapticsProvider).fire(HapticEvent.select));
    await GlassMotion.play(MotionName.deckLiftOff, controller: _t, target: 1);
    if (!mounted) return;
    setState(() {
      index++;
      _t.value = 0;
      _busy = false;
    });
    widget.onIndexChanged?.call(index);
  }

  Future<void> previous() async {
    if (index <= 0) return;
    _busy = true;
    setState(() {
      index--;
      _t.value = 1;
    });
    widget.onIndexChanged?.call(index);
    await GlassMotion.play(MotionName.deckLiftOff, controller: _t, target: 0);
    if (mounted) _busy = false;
  }

  void _catch() {
    if (_t.isAnimating) _t.stop();
  }

  /// Space and Right advance, Left goes back; true when the key was the deck's.
  bool handleKey(LogicalKeyboardKey k) {
    if (k == LogicalKeyboardKey.arrowRight || k == LogicalKeyboardKey.space) {
      unawaited(next());
      return true;
    }
    if (k == LogicalKeyboardKey.arrowLeft) {
      unawaited(previous());
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final reduced = ref.watch(glassMotionPrefsProvider.select((m) => m.reduced));
    final assistive = ref.watch(glassAssistiveProvider);
    if (assistive) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final k in kDeckKinds)
            Padding(padding: const EdgeInsets.only(bottom: 16), child: DeckCardFrame(title: deckTitleOf(k.$1, widget.deck), child: deckBodyFor(k.$1, widget.deck))),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, c) {
        final w = (widget.width ?? c.maxWidth) * 0.88;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Progress(index: index, count: count),
            const SizedBox(height: 12),
            RawGestureDetector(
              behavior: HitTestBehavior.opaque,
              gestures: {
                VerticalDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(
                  VerticalDragGestureRecognizer.new,
                  (r) => r
                    ..onDown = ((_) => _catch())
                    ..onEnd = (d) {
                      final vy = d.velocity.pixelsPerSecond.dy;
                      if (swipeUpAdvances(0, vy) || vy <= -800) {
                        unawaited(next());
                      } else if (vy >= 800) {
                        unawaited(previous());
                      }
                    }
                    ..onUpdate = (d) {
                      if (d.delta.dy < -24) unawaited(next());
                      if (d.delta.dy > 24) unawaited(previous());
                    },
                ),
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) {
                  if (_busy && !reduced) return;
                  if (d.localPosition.dx > w / 2) {
                    unawaited(next());
                  } else {
                    unawaited(previous());
                  }
                },
                child: SizedBox(
                  width: w,
                  child: AnimatedBuilder(
                    animation: _t,
                    builder: (context, _) => Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (var i = (index + 2).clamp(0, count - 1); i >= index; i--) _card(i, reduced),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _card(int i, bool reduced) {
    final d = i - index;
    final t = _t.value.clamp(0.0, 1.0);
    final (kind, _) = kDeckKinds[i];
    final card = DeckCardFrame(
      key: ValueKey('deck-card-$kind'),
      title: deckTitleOf(kind, widget.deck),
      overlay: deckDim(d - (d >= 1 ? t : 0)),
      child: deckBodyFor(kind, widget.deck),
    );
    if (reduced) {
      final o = d == 0 ? 1 - t : (d == 1 ? t : 0.0);
      final faded = Opacity(opacity: o.clamp(0.0, 1.0), child: card);
      return d == 0 ? faded : Positioned(left: 0, right: 0, top: 0, child: faded);
    }
    if (d == 0) {
      return Opacity(opacity: (1 - t).clamp(0.0, 1.0), child: Transform.translate(offset: Offset(0, -40 * t), child: Transform.scale(scale: 1 + 0.06 * t, child: card)));
    }
    final pos = d - t;
    return Positioned(left: 0, right: 0, top: -8.0 * pos, child: Transform.scale(scale: deckScale(pos), alignment: Alignment.topCenter, child: card));
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.index, required this.count});
  final int index, count;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Card ${index + 1} of $count',
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++)
              Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: AnimatedContainer(duration: const Duration(milliseconds: 180), width: 28, height: 4, decoration: BoxDecoration(color: i <= index ? gt.colorMachine : gt.colorLabel4, borderRadius: BorderRadius.circular(2)))),
          ],
        ),
      );
}
