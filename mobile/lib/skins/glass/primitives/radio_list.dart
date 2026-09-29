import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/icons/phosphor.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/spring_value.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The 24 px radio visual (glass 7.22), for the gallery and `mobile/28`'s select-mode lists: off a 1.5 px `g600`
/// ring; on a 10 px white dot inside an `iris600` disc, the dot growing on `springTick`.
class GlassRadio extends StatelessWidget {
  const GlassRadio({super.key, required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: 24,
        child: SpringValue(
          value: selected ? 1 : 0,
          spring: gt.springTick,
          builder: (context, v, _) => DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? gt.colorIris600 : const Color(0x00000000),
              border: selected ? null : Border.all(color: GlassColors.g600, width: 1.5),
            ),
            child: Center(
              child: Transform.scale(
                scale: v.clamp(0.0, 1.3),
                child: const DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFFFFFF)), child: SizedBox.square(dimension: 10)),
              ),
            ),
          ),
        ),
      );
}

class GlassRadioOption<T> {
  const GlassRadioOption({required this.value, required this.label, this.enabled = true});
  final T value;
  final String label;
  final bool enabled;
}

/// Radios appear only in lists (glass 7.22): grouped rows with a trailing check for the selected row. Arrows move the
/// selection; each row is `Semantics(inMutuallyExclusiveGroup: true, checked:)`.
class GlassRadioList<T> extends ConsumerStatefulWidget {
  const GlassRadioList({super.key, required this.options, required this.value, required this.onChanged});
  final List<GlassRadioOption<T>> options;
  final T? value;
  final ValueChanged<T> onChanged;

  @override
  ConsumerState<GlassRadioList<T>> createState() => _GlassRadioListState<T>();
}

class _GlassRadioListState<T> extends ConsumerState<GlassRadioList<T>> {
  late final List<FocusNode> _nodes = List.generate(widget.options.length, (i) => FocusNode(debugLabel: 'radio$i'));

  @override
  void dispose() {
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _move(int from, int dir) {
    var i = from + dir;
    while (i >= 0 && i < widget.options.length && !widget.options[i].enabled) {
      i += dir;
    }
    if (i < 0 || i >= widget.options.length) return;
    widget.onChanged(widget.options[i].value);
    _nodes[i].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final hit = GlassFrame.hitMin(context);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < widget.options.length; i++)
            Focus(
              skipTraversal: true,
              onKeyEvent: (n, e) {
                if (e is! KeyDownEvent) return KeyEventResult.ignored;
                if (e.logicalKey == LogicalKeyboardKey.arrowDown || e.logicalKey == LogicalKeyboardKey.arrowRight) {
                  _move(i, 1);
                  return KeyEventResult.handled;
                }
                if (e.logicalKey == LogicalKeyboardKey.arrowUp || e.logicalKey == LogicalKeyboardKey.arrowLeft) {
                  _move(i, -1);
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: Builder(builder: (context) {
                final o = widget.options[i];
                final selected = widget.value == o.value;
                return Semantics(
                  inMutuallyExclusiveGroup: true,
                  checked: selected,
                  child: GlassPressable(
                    focusNode: _nodes[i],
                    material: GlassMaterial.content,
                    growth: GlassGrowth.light,
                    sink: 0.99,
                    shape: const GlassShape.superellipse(14),
                    enabled: o.enabled,
                    noSemantics: true,
                    haptic: HapticEvent.select,
                    onTap: () {
                      _nodes[i].requestFocus();
                      widget.onChanged(o.value);
                    },
                    builder: (context, info) => ConstrainedBox(
                      constraints: BoxConstraints(minHeight: hit),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: info.states.hovered ? gt.colorFill4 : const Color(0x00000000),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(child: GlassText(o.label, role: gt.typeBody, onGlass: true, color: o.enabled ? null : gt.colorLabel4)),
                              if (selected) Icon(PhosphorBold.check, size: 20, color: gt.colorIris400),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },),
            ),
        ],
      ),
    );
  }
}
