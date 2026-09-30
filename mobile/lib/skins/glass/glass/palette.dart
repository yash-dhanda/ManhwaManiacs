import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:manhwamaniacs/core/color/cover_palette.dart';
import 'package:manhwamaniacs/core/color/oklch.dart';
import 'package:material_color_utilities/material_color_utilities.dart' show QuantizerCelebi;

export 'package:manhwamaniacs/core/color/cover_palette.dart' show CoverPalette;

/// One ranked candidate colour with its OKLCH and population.
class _Candidate {
  _Candidate(this.color, this.count) : lch = oklchFromColor(color);
  final Color color;
  final int count;
  final Oklch lch;
}

/// The discard-and-rank rule of glass 2.1.8 step 1, never `Score.score`: discard OKLCH `L < 0.12`,
/// `L > 0.94` or `C < 0.025` unless all would go (then keep the two most populous); rank by
/// `population x (0.5 + C)`; top three.
List<Color> rankPalette(Map<int, int> colorToCount) {
  final all = [for (final e in colorToCount.entries) _Candidate(Color(e.key | 0xFF000000), e.value)]
    ..sort((x, y) => y.count.compareTo(x.count));
  var kept = [for (final c in all) if (c.lch.l >= 0.12 && c.lch.l <= 0.94 && c.lch.c >= 0.025) c];
  if (kept.isEmpty) kept = all.take(2).toList();
  kept.sort((x, y) => (y.count * (0.5 + y.lch.c)).compareTo(x.count * (0.5 + x.lch.c)));
  return [for (final c in kept.take(3)) c.color];
}

/// `l` (mean) and `lMax` (95th percentile) relative luminance from opaque-enough ARGB pixels.
({double l, double lMax}) luminanceStats(Iterable<int> argbPixels) {
  final ys = <double>[];
  var sum = 0.0;
  for (final p in argbPixels) {
    if ((p >>> 24) < 16) continue;
    final y = relativeLuminance(Color(p));
    ys.add(y);
    sum += y;
  }
  if (ys.isEmpty) return (l: 1.0, lMax: 1.0);
  ys.sort();
  final idx = ((ys.length - 1) * 0.95).round();
  return (l: sum / ys.length, lMax: ys[idx]);
}

/// Pure core of the client fallback; runs in `compute()` on a decoded 64 px image.
Future<CoverPalette> paletteFromPixels(List<int> argbPixels) async {
  final opaque = [for (final p in argbPixels) if ((p >>> 24) >= 16) p | 0xFF000000];
  final stats = luminanceStats(argbPixels);
  if (opaque.isEmpty) return CoverPalette(a: const [], l: stats.l, lMax: stats.lMax);
  final result = await QuantizerCelebi().quantize(opaque, 16);
  return CoverPalette(a: rankPalette(result.colorToCount), l: stats.l, lMax: stats.lMax);
}

Future<CoverPalette> _isolatePalette(Uint32List pixels) => paletteFromPixels(pixels);

final Map<String, Future<CoverPalette>> _cache = {};

@visibleForTesting
void clearCoverPaletteCache() => _cache.clear();

/// The server `palette {a, l, lMax}` when present; otherwise decodes a 64 px `ResizeImage`, quantises it
/// in `compute()` and applies the rank rule. Cached per image URL for the session.
Future<CoverPalette> coverPalette({
  required String cacheKey,
  Map<String, dynamic>? server,
  CoverPalette? known,
  ImageProvider Function()? image,
}) {
  if (known != null) return Future.value(known);
  if (server != null) return Future.value(CoverPalette.fromServer(server));
  return _cache[cacheKey] ??= _decode(image!());
}

Future<CoverPalette> _decode(ImageProvider provider) async {
  final completer = Completer<ui.Image>();
  final stream = ResizeImage(provider, width: 64).resolve(ImageConfiguration.empty);
  late ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, _) {
      if (!completer.isCompleted) completer.complete(info.image.clone());
      stream.removeListener(listener);
    },
    onError: (e, s) {
      if (!completer.isCompleted) completer.completeError(e, s);
      stream.removeListener(listener);
    },
  );
  stream.addListener(listener);
  final img = await completer.future;
  final bytes = await img.toByteData();
  img.dispose();
  final rgba = bytes!.buffer.asUint8List();
  final px = Uint32List(rgba.length ~/ 4);
  for (var i = 0; i < px.length; i++) {
    final r = rgba[i * 4], g = rgba[i * 4 + 1], b = rgba[i * 4 + 2], a = rgba[i * 4 + 3];
    px[i] = (a << 24) | (r << 16) | (g << 8) | b;
  }
  return compute(_isolatePalette, px);
}

/// The three blob colours and the size each blob draws at (1.0, or 0.6 for a reused first colour).
class FieldColours {
  const FieldColours(this.colors, this.scales);
  final List<Color> colors;
  final List<double> scales;
}

/// glass 2.1.8 step 4: OKLCH clamp L 0.55 to 0.78, C 0.06 to 0.16, hue kept; a colour with C < 0.03 before
/// clamping becomes [mood]; fewer than three colours reuse the first at 60 % size.
FieldColours fieldColours(CoverPalette? palette, Color mood) {
  Color clamp(Color c) {
    final o = oklchFromColor(c);
    if (o.c < 0.03) return mood;
    return colorFromOklch(Oklch(o.l.clamp(0.55, 0.78), o.c.clamp(0.06, 0.16), o.h));
  }

  final src = palette?.a ?? const <Color>[];
  if (src.isEmpty) return FieldColours([mood, mood, mood], const [1.0, 0.6, 0.6]);
  final colors = <Color>[];
  final scales = <double>[];
  for (var i = 0; i < 3; i++) {
    if (i < src.length) {
      colors.add(clamp(src[i]));
      scales.add(1.0);
    } else {
      colors.add(colors.first);
      scales.add(0.6);
    }
  }
  return FieldColours(colors, scales);
}

/// The palette's first colour at OKLCH L 0.86 with C at most 0.08 (the rim tint, glass 2.1.8).
Color rimTint(CoverPalette? palette, {Color fallback = const Color(0xFFBCB0FF)}) {
  if (palette == null || palette.a.isEmpty) return fallback;
  final o = oklchFromColor(palette.a.first);
  return colorFromOklch(Oklch(0.86, o.c.clamp(0.0, 0.08), o.h));
}

