import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/icons/phosphor.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/spring_value.dart';

/// The selection check of lists and select mode (glass 7.22): a 24 px circle, `iris600` fill, white check, springing
/// in from scale 0 on `springTick`. Unselected it is a 1.5 px `g600` ring.
class GlassSelectionCheck extends StatelessWidget {
  const GlassSelectionCheck({super.key, required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: 24,
        child: Stack(
          alignment: Alignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: GlassColors.g600, width: 1.5)),
              child: const SizedBox.expand(),
            ),
            SpringValue(
              value: selected ? 1 : 0,
              spring: gt.springTick,
              builder: (context, v, _) => Transform.scale(
                scale: v.clamp(0.0, 1.3),
                child: DecoratedBox(
                  decoration: BoxDecoration(shape: BoxShape.circle, color: gt.colorIris600),
                  child: const Center(child: Icon(PhosphorBold.check, size: 14, color: Color(0xFFFFFFFF))),
                ),
              ),
            ),
          ],
        ),
      );
}
