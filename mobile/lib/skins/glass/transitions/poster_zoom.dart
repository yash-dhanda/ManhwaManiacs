import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heroine/heroine.dart';
import 'package:manhwamaniacs/features/sources/utils/cover_tag.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

/// `springZoom` as the package's spring [Motion] (glass 4.2: 560 ms, bounce 0.06).
Motion glassZoomMotion() => SpringMotion(springOf(GlassSprings.zoom));

/// Poster zoom (glass 4.10, Zoom): wraps a cover so a tap flies it into the series sheet's cover slot on `springZoom`, and back.
/// The flight always runs to completion. A poster thrown by the user starts its flight at the release velocity, which the package
/// reads from a [HeroineVelocity] above the heroine; without one it starts at rest. Reduced motion: a 200 ms cross-fade.
class GlassCoverHero extends ConsumerWidget {
  const GlassCoverHero({super.key, required this.sourceId, required this.seriesKey, required this.child, this.releaseVelocity});
  final String sourceId;
  final String seriesKey;
  final Widget child;

  /// The throw's release velocity in px/s; null flies from rest.
  final Velocity? releaseVelocity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduced = ref.watch(glassMotionPrefsProvider.select((m) => m.reduced));
    Widget h = Heroine(
      tag: coverTag(sourceId, seriesKey),
      motion: reduced ? const CurvedMotion(Duration(milliseconds: 200)) : glassZoomMotion(),
      flightShuttleBuilder: reduced ? const FadeShuttleBuilder() : const SingleShuttleBuilder(),
      child: child,
    );
    if (releaseVelocity != null) h = HeroineVelocity(velocity: releaseVelocity!, child: h);
    return h;
  }
}
