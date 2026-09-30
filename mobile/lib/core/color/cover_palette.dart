import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

/// A cover's colours and luminances (glass 2.1.8): up to three ranked colours, the mean relative
/// luminance `l` and the 95th percentile `lMax`. The backend sends `palette: {a: [hex, hex, hex], l, lMax}`.
@immutable
class CoverPalette {
  const CoverPalette({required this.a, required this.l, required this.lMax});

  final List<Color> a;
  final double l;
  final double lMax;

  /// Null for null or a shape without numeric `l` and `lMax`; a malformed hex is skipped, never thrown.
  static CoverPalette? tryParse(Object? json) {
    if (json is! Map) return null;
    final l = json['l'], lMax = json['lMax'];
    if (l is! num || lMax is! num) return null;
    final raw = json['a'];
    return CoverPalette(
      a: [
        if (raw is List<dynamic>)
          for (final h in raw)
            if (_hex(h) case final c?) c,
      ].take(3).toList(),
      l: l.toDouble(),
      lMax: lMax.toDouble(),
    );
  }

  factory CoverPalette.fromServer(Map<String, dynamic> json) => tryParse(json) ?? (throw const FormatException('palette'));

  static Color? _hex(Object? v) {
    if (v is! String) return null;
    final s = v.startsWith('#') ? v.substring(1) : v;
    if (s.length != 6) return null;
    final n = int.tryParse(s, radix: 16);
    return n == null ? null : Color(0xFF000000 | n);
  }

  @override
  bool operator ==(Object other) => other is CoverPalette && other.l == l && other.lMax == lMax && listEquals(other.a, a);

  @override
  int get hashCode => Object.hash(l, lMax, Object.hashAll(a));
}
