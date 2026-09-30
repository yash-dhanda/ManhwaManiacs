import 'package:manhwamaniacs/features/sources/models/source_search_group.dart';

/// The on-screen order of result sections (glass 8.9). The first arrival orders tier 1: the Library first, then pinned sources in pin
/// order, then by result count (stable). Later arrivals (tier 2) are only ever appended in the order they answer, so nothing on screen
/// moves.
List<String> arrangeGroupKeys(List<String> current, List<SourceSearchGroup> groups, List<String> pinOrder) {
  if (current.isEmpty) {
    final indexed = [for (var i = 0; i < groups.length; i++) (i, groups[i])];
    int rank(SourceSearchGroup g) => g.isLocal ? 0 : (pinOrder.contains(g.source) ? 1 : 2);
    indexed.sort((a, b) {
      final ra = rank(a.$2), rb = rank(b.$2);
      if (ra != rb) return ra.compareTo(rb);
      if (ra == 1) return pinOrder.indexOf(a.$2.source!).compareTo(pinOrder.indexOf(b.$2.source!));
      final c = b.$2.items.length.compareTo(a.$2.items.length);
      return c != 0 ? c : a.$1.compareTo(b.$1);
    });
    return [for (final e in indexed) e.$2.key];
  }
  final have = current.toSet();
  return [...current, for (final g in groups) if (!have.contains(g.key)) g.key];
}

/// Initial letters for the jump bar, one per group.
String groupInitial(SourceSearchGroup g) => g.isLocal ? 'L' : (g.sourceName.isEmpty ? '?' : g.sourceName.substring(0, 1).toUpperCase());
