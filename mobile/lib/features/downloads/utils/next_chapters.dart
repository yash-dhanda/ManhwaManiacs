/// The chapter keys "Download next 5" queues: the [count] chapters of [readingOrder] (oldest to
/// newest) from the one being read on, skipping [saved] ones. A chapter read to its last page
/// ([currentFinished]) is not offered again.
List<String> nextUnreadKeys(
  List<String> readingOrder, {
  required String currentKey,
  bool currentFinished = false,
  Set<String> saved = const {},
  int count = 5,
}) {
  final at = readingOrder.indexOf(currentKey);
  final from = at < 0 ? 0 : (currentFinished ? at + 1 : at);
  return [
    for (final k in readingOrder.skip(from))
      if (!saved.contains(k)) k,
  ].take(count).toList();
}
