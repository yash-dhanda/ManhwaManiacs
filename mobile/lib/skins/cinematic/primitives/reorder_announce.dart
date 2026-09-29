/// The four "Move" actions every reorderable row and poster gains (cinematic 7.16), and the
/// announcement a screen reader hears after one.
enum CineMove {
  up('Move up'),
  down('Move down'),
  top('Move to top'),
  bottom('Move to bottom');

  const CineMove(this.label);
  final String label;

  /// Where an item at [from] of [count] lands, or null when the move is disabled at that end.
  int? target(int from, int count) {
    final to = switch (this) {
      CineMove.up => from - 1,
      CineMove.down => from + 1,
      CineMove.top => 0,
      CineMove.bottom => count - 1,
    };
    return to < 0 || to >= count || to == from ? null : to;
  }
}

/// "Solo Leveling moved to position 3 of 12"; [position] is 1-based.
String moveAnnouncement(String title, int position, int total) => '$title moved to position $position of $total';
