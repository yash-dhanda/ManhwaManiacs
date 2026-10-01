/// The player's third title line (glass 8.16.2, B2): "Narrated by Aurora · Kade's voice voices 3 characters". The same rule as the web twin.
library;

/// [voicedCounts] lists, in the server's voice order, each voice that reads characters and how many; the one with the most characters
/// is named (ties go to the earlier voice).
String castLine({required String? narratorVoiceName, required List<({String voiceName, int characters})> voicedCounts}) {
  final narrator = narratorVoiceName == null || narratorVoiceName.isEmpty ? 'Narrated by the default voice' : 'Narrated by $narratorVoiceName';
  ({String voiceName, int characters})? best;
  for (final v in voicedCounts) {
    if (v.characters <= 0) continue;
    if (best == null || v.characters > best.characters) best = v;
  }
  if (best == null) return narrator;
  final n = best.characters;
  return '$narrator · ${best.voiceName} voices $n ${n == 1 ? 'character' : 'characters'}';
}
