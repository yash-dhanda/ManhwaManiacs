import 'dart:typed_data';

/// Lightness and saturation of an 8-bit colour, as Python `colorsys` HLS.
typedef Hls = ({double l, double s});

Hls hls(int r, int g, int b) {
  final rf = r / 255, gf = g / 255, bf = b / 255;
  final mx = [rf, gf, bf].reduce((a, c) => a > c ? a : c);
  final mn = [rf, gf, bf].reduce((a, c) => a < c ? a : c);
  final l = (mx + mn) / 2;
  if (mx == mn) return (l: l, s: 0.0);
  final s = l <= 0.5 ? (mx - mn) / (mx + mn) : (mx - mn) / (2 - mx - mn);
  return (l: l, s: s);
}

/// The page seed of cinematic 2.1.5 from 16 x 16 RGBA: the most saturated pixel with
/// 0.10 < L < 0.90 (ties to the first in row-major order), or null when greyscale (best S < 0.08).
String? pickPageSeed(Uint8List rgba) {
  var best = -1;
  var bestS = -1.0;
  for (var i = 0; i + 3 < rgba.length; i += 4) {
    final h = hls(rgba[i], rgba[i + 1], rgba[i + 2]);
    if (!(h.l > 0.10 && h.l < 0.90)) continue;
    if (h.s > bestS) {
      bestS = h.s;
      best = i;
    }
  }
  if (best < 0 || bestS < 0.08) return null;
  String two(int v) => v.toRadixString(16).padLeft(2, '0');
  return '#${two(rgba[best])}${two(rgba[best + 1])}${two(rgba[best + 2])}'.toUpperCase();
}

/// What the reader chrome takes its tint from.
sealed class PageTintSource {
  const PageTintSource();
  const factory PageTintSource.page(String seed) = PageTintPage;
  static const PageTintSource cover = PageTintCover();
}

final class PageTintPage extends PageTintSource {
  const PageTintPage(this.seed);
  final String seed;
  @override
  bool operator ==(Object other) => other is PageTintPage && other.seed == seed;
  @override
  int get hashCode => seed.hashCode;
}

final class PageTintCover extends PageTintSource {
  const PageTintCover();
  @override
  bool operator ==(Object other) => other is PageTintCover;
  @override
  int get hashCode => 1;
}

/// Turns a per-page seed (null for a greyscale page) into the chrome's tint source: a chromatic
/// page sets it, a greyscale page keeps the previous one, and [greyLimit] greyscale pages in a
/// row fall back to the cover until a chromatic page arrives.
class TintTracker {
  TintTracker({this.greyLimit = 6});
  final int greyLimit;
  PageTintSource? _current;
  int _grey = 0;

  PageTintSource? get current => _current;

  PageTintSource? feed(String? seed) {
    if (seed != null) {
      _grey = 0;
      return _current = PageTintSource.page(seed);
    }
    _grey++;
    if (_grey >= greyLimit) _current = PageTintSource.cover;
    return _current;
  }
}
