import 'dart:ui' show Color;

/// A series' three issue colours as the backend sends them (`{duo, tint, ink}` hex strings).
class Ambient {
  const Ambient({required this.duo, required this.tint, required this.ink});
  final Color duo, tint, ink;

  /// Null for null, a missing key or a malformed hex.
  static Ambient? tryParse(Object? json) {
    if (json is! Map) return null;
    final duo = _hex(json['duo']), tint = _hex(json['tint']), ink = _hex(json['ink']);
    if (duo == null || tint == null || ink == null) return null;
    return Ambient(duo: duo, tint: tint, ink: ink);
  }

  static Color? _hex(Object? v) {
    if (v is! String) return null;
    final s = v.startsWith('#') ? v.substring(1) : v;
    if (s.length != 6) return null;
    final n = int.tryParse(s, radix: 16);
    return n == null ? null : Color(0xFF000000 | n);
  }

  Map<String, String> toJson() => {'duo': _str(duo), 'tint': _str(tint), 'ink': _str(ink)};

  static String _str(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  @override
  bool operator ==(Object other) => other is Ambient && other.duo == duo && other.tint == tint && other.ink == ink;

  @override
  int get hashCode => Object.hash(duo, tint, ink);
}
