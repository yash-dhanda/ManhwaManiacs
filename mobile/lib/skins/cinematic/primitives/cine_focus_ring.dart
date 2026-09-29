import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// A 2 px `spot` ring drawn inset on [child] while it (or a descendant) holds
/// keyboard focus. Pointer and touch focus never show it (DESIGN §7.1).
/// TODO(mobile/04): replaced by the shared primitive when it lands.
class CineFocusRing extends StatefulWidget {
  const CineFocusRing({super.key, required this.child, this.inset = 2});

  final Widget child;
  final double inset;

  @override
  State<CineFocusRing> createState() => _CineFocusRingState();
}

class _CineFocusRingState extends State<CineFocusRing> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<CineTokens>()!;
    final keyboard = FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (f) => setState(() => _focused = f),
      child: Stack(
        children: [
          widget.child,
          if (_focused && keyboard)
            Positioned.fill(
              child: IgnorePointer(
                child: Padding(
                  padding: EdgeInsets.all(widget.inset),
                  child: DecoratedBox(
                    key: const Key('cine-focus-ring'),
                    decoration: BoxDecoration(border: Border.all(color: t.colorSpot, width: 2)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
