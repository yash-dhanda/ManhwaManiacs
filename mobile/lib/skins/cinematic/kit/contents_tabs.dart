import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/cine_text.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// Contents tabs (§7.12) in pager mode: labels in `type.nav`, a 2 px `spot`
/// rule that follows [animation] (a `TabController.animation`, so it tracks
/// the finger). Each tab is 44 / 48 tall.
///
/// TODO(mobile/05): the contents-tab primitive owns this.
class ContentsTabs extends StatelessWidget {
  const ContentsTabs({super.key, required this.labels, required this.index, required this.animation, required this.onTap});

  final List<String> labels;
  final int index;
  final Animation<double> animation;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final hit = minHit(context);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: SizedBox(
        height: hit + 2,
        child: LayoutBuilder(builder: (context, box) {
          final w = box.maxWidth / labels.length;
          return Stack(children: [
            const Positioned(left: 0, right: 0, bottom: 0, child: SizedBox(height: 1, child: ColoredBox(color: CineColors.rule1))),
            Row(children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == index,
                    label: labels[i],
                    excludeSemantics: true,
                    onTap: () => onTap(i),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(i),
                      child: Center(child: CineText(labels[i], context.cine.typeNav, color: i == index ? CineColors.ink100 : CineColors.ink60, maxLines: 1, excludeSemantics: true)),
                    ),
                  ),
                ),
            ],),
            AnimatedBuilder(
              animation: animation,
              builder: (context, _) => Positioned(
                left: animation.value * w,
                width: w,
                bottom: 0,
                child: const SizedBox(height: 2, child: ColoredBox(color: CineColors.spot)),
              ),
            ),
          ],);
        },),
      ),
    );
  }
}
