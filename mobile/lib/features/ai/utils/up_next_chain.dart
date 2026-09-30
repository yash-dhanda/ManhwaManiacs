/// Where a finished series' `Up next` rail draws from, in order (cinematic 8.14.6): Similar (with
/// the same-genre fallback), then the Because you read world section, then the reader's own shelf
/// (plan-to-read and favourites). The first source with anything to show wins; one request each,
/// `similarProvider` is the only place Similar is fetched.
enum UpNextSource { similar, because, shelf }

List<T> upNextChain<T>({required List<T> similar, required List<T> because, required List<T> shelf, void Function(UpNextSource)? onPicked}) {
  final picks = [(UpNextSource.similar, similar), (UpNextSource.because, because), (UpNextSource.shelf, shelf)];
  for (final (source, items) in picks) {
    if (items.isNotEmpty) {
      onPicked?.call(source);
      return items;
    }
  }
  return const [];
}
