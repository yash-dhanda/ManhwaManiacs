import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// 48 dp on Android, 44 pt elsewhere (cinematic 7 intro, 14.6).
double cineHitMin(BuildContext c) =>
    Theme.of(c).platform == TargetPlatform.android ? c.cine.hitAndroid : c.cine.hitMin;

/// Grows the touch target, never the visual.
class CineHit extends StatelessWidget {
  const CineHit({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final hit = cineHitMin(context);
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: hit, minHeight: hit),
      child: Center(widthFactor: 1, heightFactor: 1, child: child),
    );
  }
}
