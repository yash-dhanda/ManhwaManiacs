import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Genres of the series opened from a Tonight rail this app session (unique, newest last).
final rerankNotesProvider = NotifierProvider<RerankNotes, List<String>>(RerankNotes.new, name: 'rerankNotes');

class RerankNotes extends Notifier<List<String>> {
  @override
  List<String> build() => const [];

  /// Called when the reader opens a series from a Tonight rail; a repeat moves to the end.
  void noteOpenedFromRail(String topGenre) {
    final g = topGenre.trim();
    if (g.isEmpty) return;
    state = [...state.where((e) => e.toLowerCase() != g.toLowerCase()), g];
  }
}

/// In-session re-ranking (cinematic 9.1.4): every rail whose top genre matches a noted genre moves
/// up one position, the newest noted genre applied last. Rails at index `< floor` (the cover story
/// and `Continue`) never move and nothing moves above them.
List<R> rerankRails<R>(List<R> rails, List<String> noted, String? Function(R) topGenre, {int floor = 0}) {
  final out = [...rails];
  for (final g in noted) {
    final want = g.toLowerCase();
    // Walk top to bottom so two matching rails keep their order.
    for (var i = floor + 1; i < out.length; i++) {
      if (topGenre(out[i])?.toLowerCase() == want) {
        final r = out.removeAt(i);
        out.insert(i - 1, r);
      }
    }
  }
  return out;
}
