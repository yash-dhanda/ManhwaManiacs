/// The shared-element tag of a series cover: `cover-` + the 8-hex FNV-1a 32 of `sourceId`, NUL, `seriesKey`. The same series on any
/// screen gets the same tag, so the poster zoom finds its twin.
String coverTag(String sourceId, String seriesKey) {
  var h = 0x811C9DC5;
  for (final unit in '$sourceId\u0000$seriesKey'.codeUnits) {
    h ^= unit & 0xFF;
    h = (h * 0x01000193) & 0xFFFFFFFF;
    if (unit > 0xFF) {
      h ^= unit >> 8;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
  }
  return 'cover-${h.toRadixString(16).padLeft(8, '0')}';
}
