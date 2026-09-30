import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';

/// The jump bar (glass 8.9): a 28 px capsule on the trailing edge with the groups' initials stacked, in a 48 px hit strip. Dragging
/// along it moves between groups; each new group ticks. In semantics it is a list of buttons "Jump to {source} results".
class SearchJumpBar extends StatefulWidget {
  const SearchJumpBar({super.key, required this.names, required this.initials, required this.onJump, this.onTick});
  final List<String> names;
  final List<String> initials;
  final ValueChanged<int> onJump;
  final VoidCallback? onTick;

  @override
  State<SearchJumpBar> createState() => _SearchJumpBarState();
}

class _SearchJumpBarState extends State<SearchJumpBar> {
  int _last = -1;
  DateTime _lastTick = DateTime.fromMillisecondsSinceEpoch(0);

  void _at(double dy, double height) {
    final n = widget.initials.length;
    if (n == 0) return;
    final i = ((dy / height) * n).floor().clamp(0, n - 1);
    if (i == _last) return;
    _last = i;
    widget.onJump(i);
    final now = DateTime.now();
    if (now.difference(_lastTick).inMilliseconds >= 40) {
      _lastTick = now;
      widget.onTick?.call();
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, box) {
          final h = box.maxHeight;
          return Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragStart: (d) => _at(d.localPosition.dy, h),
                onVerticalDragUpdate: (d) => _at(d.localPosition.dy, h),
                onVerticalDragEnd: (_) => _last = -1,
                child: SizedBox(
                  width: 48,
                  height: h,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: gt.colorFill2, borderRadius: BorderRadius.circular(14)),
                      child: SizedBox(
                        width: 28,
                        child: Column(mainAxisSize: MainAxisSize.min, children: [for (final c in widget.initials) SizedBox(height: 16, child: Center(child: GlassLabel(c, role: gt.typeCaption2, color: gt.colorLabel2)))]),
                      ),
                    ),
                  ),
                ),
              ),
              // The semantics twin: one button per group.
              Semantics(
                container: true,
                child: Column(children: [
                  for (var i = 0; i < widget.names.length; i++)
                    Semantics(button: true, label: 'Jump to ${widget.names[i]} results', onTap: () => widget.onJump(i), child: const SizedBox(width: 1, height: 1)),
                ]),
              ),
            ],
          );
        },
      );
}
