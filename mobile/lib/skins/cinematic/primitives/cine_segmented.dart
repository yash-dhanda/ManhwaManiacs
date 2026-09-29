import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// The segmented control (DESIGN §7.5): a 40 px `rule.2` frame, a `spot`
/// underline that slides under the chosen segment (320 ms `settle`, 150 ms
/// under reduced motion) and a 48 px hit box per segment. TODO(mobile/05):
/// replaced by the shared primitive.
class CineSegmented<T> extends StatelessWidget {
  const CineSegmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<(T value, String label)> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<CineTokens>()!;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final index = options.indexWhere((o) => o.$1 == value).clamp(0, options.length - 1);
    return SizedBox(
      height: 48,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth.isFinite ? box.maxWidth : options.length * 132.0;
          final seg = w / options.length;
          return SizedBox(
            width: w,
            child: Stack(
              children: [
                Positioned.fill(
                  top: 4,
                  bottom: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(border: Border.all(color: t.colorRule2)),
                  ),
                ),
                AnimatedPositioned(
                  duration: reduced ? CineDur.reduced : CineDur.column,
                  curve: CineCurves.settle,
                  left: seg * index,
                  width: seg,
                  bottom: 4,
                  height: 2,
                  child: ColoredBox(key: const Key('segmented-underline'), color: t.colorSpot),
                ),
                Row(
                  children: [
                    for (final (v, label) in options)
                      Expanded(
                        child: Semantics(
                          button: true,
                          selected: v == value,
                          inMutuallyExclusiveGroup: true,
                          label: label,
                          excludeSemantics: true,
                          child: InkWell(
                            onTap: () => onChanged(v),
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  label,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 12,
                                    letterSpacing: 1.2,
                                    fontWeight: v == value ? FontWeight.w700 : FontWeight.w500,
                                    color: v == value ? t.colorInk100 : t.colorInk60,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
