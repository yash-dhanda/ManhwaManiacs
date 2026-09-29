import 'dart:ui' show Color;

import 'package:flutter/painting.dart' show HSLColor;
import 'package:manhwamaniacs/core/utils/fnv1a.dart';

int sourceWashHue(String sourceId) => fnv1a32(sourceId) % 360;

/// The dark hue-tinted ground behind a catalogue's opening state.
Color sourceWash(String id) =>
    HSLColor.fromAHSL(1, sourceWashHue(id).toDouble(), 0.35, 0.06).toColor();
