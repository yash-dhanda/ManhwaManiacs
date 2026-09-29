import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/pull_math.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Pull to reprint (cinematic 7.29) on `custom_refresh_indicator` 4.0.2, trigger at 96 px. The pull
/// reveals a 2 px `spot` rule growing from the centre outwards and the caption `PULL TO REPRINT`,
/// which becomes `RELEASE TO REPRINT` at the trigger (`refresh.arm` once when crossing); on
/// release (`refresh.fire`) the rule runs as an indeterminate rule until [onRefresh] completes.
/// Never used on Downloads.
class CinePullToReprint extends StatelessWidget {
  const CinePullToReprint({super.key, required this.onRefresh, required this.child});

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return CustomRefreshIndicator(
      offsetToArmed: kPullTrigger,
      onRefresh: onRefresh,
      onStateChanged: (change) {
        if (change.didChange(to: IndicatorState.armed)) cineFeedback(context, HapticEvent.refreshArm, sound: SoundEvent.refreshArm);
        if (change.didChange(to: IndicatorState.loading)) cineFeedback(context, HapticEvent.refreshFire);
      },
      builder: (context, child, controller) => AnimatedBuilder(
        animation: controller,
        child: child,
        builder: (context, child) {
          final pull = controller.value * kPullTrigger;
          final loading = controller.isLoading || controller.isFinalizing;
          final offset = loading ? 48.0 : pullContentOffset(pull, max: 48);
          return Stack(children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 48,
              child: Opacity(
                opacity: loading || pull > 0 ? 1 : 0,
                child: Semantics(
                  liveRegion: true,
                  label: loading ? 'Refreshing' : null,
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    if (!loading) CineRoleText(controller.isArmed ? 'RELEASE TO REPRINT' : 'PULL TO REPRINT', c.typeKicker, color: c.colorInk60),
                    SizedBox(height: c.space2),
                    if (loading)
                      const CineIndeterminateRule(track: false)
                    else
                      FractionallySizedBox(widthFactor: pullRuleFraction(pull), child: SizedBox(height: 2, child: ColoredBox(key: const Key('cine-pull-rule'), color: c.colorSpot))),
                  ],),
                ),
              ),
            ),
            Transform.translate(offset: Offset(0, offset), child: child),
          ],);
        },
      ),
      child: child,
    );
  }
}
