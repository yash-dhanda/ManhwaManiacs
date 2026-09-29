import 'dart:math' as math;

import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

/// glass 7.33: the meniscus droplet of pull to refresh, as pure functions of the pulled extent in px.

/// The droplet grows 0 to 16 px over the first 60 px.
double dropletRadius(double pulled) => 16 * math.min(math.max(pulled, 0) / 60, 1);

/// The neck is `12 x (1 - progress)` px, progress = pulled / 100, thinning as the pull continues.
double neckWidth(double pulled) => 12 * (1 - math.min(math.max(pulled, 0) / glassTokens.thresholdPullTrigger, 1));

/// The `droplet` glyph turns 360 degrees per 100 px.
double glyphTurns(double pulled) => pulled / glassTokens.thresholdPullTrigger;

/// The neck snaps at exactly 100 px.
bool pullArmed(double pulled) => pulled >= glassTokens.thresholdPullTrigger;

/// Where the released droplet rests while `onRefresh()` runs.
double get pullRestLine => glassTokens.thresholdPullRest;
