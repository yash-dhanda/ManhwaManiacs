import 'dart:convert';

/// FNV-1a 32 over the UTF-8 bytes (the same hash the web uses for washes).
int fnv1a32(String s) {
  var h = 0x811C9DC5;
  for (final b in utf8.encode(s)) {
    h ^= b;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h;
}
