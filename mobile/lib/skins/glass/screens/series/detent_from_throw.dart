import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';

enum SeriesDetent { medium, large }

/// The detent a thrown poster opens the series sheet at (glass 8.12 "The cover lands"): `large` when the throw's projected landing
/// is nearer `largeTop` than `mediumTop`. [vy] in px/s, negative upward; tops are screen y of the sheet's top edge.
///
/// The sheet enters from the bottom edge, so the projection starts at [viewportHeight] (where the sheet's top is when the throw
/// hands over), capped at one viewport. On an 844 px phone this makes −1200 px/s settle at `medium` and −2400 px/s at `large`, the
/// vectors of the step (projecting from `mediumTop` would send any throw above ~350 px/s to `large`).
SeriesDetent openingDetent({required double vy, required double mediumTop, required double largeTop, required double viewportHeight}) {
  final landing = projectCapped(viewportHeight, vy, viewportHeight);
  return (landing - largeTop).abs() < (landing - mediumTop).abs() ? SeriesDetent.large : SeriesDetent.medium;
}
