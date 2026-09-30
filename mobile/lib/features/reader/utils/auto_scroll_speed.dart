/// Auto-scroll speed in engine units (cinematic 8.14.8 AMBIENT, 9.4.1): [speed] is the ×
/// multiplier (0.50-3.00), the result pixels per second for a viewport [viewportHeight] tall.
/// 60 px/s at 1.00× on a 1080 px viewport, scaled with the viewport.
double autoScrollPxPerSecondX(double speed, double viewportHeight) => 60 * speed * viewportHeight / 1080;

/// Steps [speed] by [delta] (0.25 for the `<` / `>` keys) inside 0.50-3.00.
double stepAutoScrollSpeed(double speed, double delta) => (speed + delta).clamp(0.5, 3.0);
