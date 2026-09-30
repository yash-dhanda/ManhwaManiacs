import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/novel_reader_screen.dart';

/// The `nonce` extra, when an entry asks for its own page (Contents, Jump): a different chapter
/// opened by Dip is a new route page, while the seamless next keeps the page it is on.
String _nonce(GoRouterState state) {
  final e = state.extra;
  return e is Map ? '${e['nonce'] ?? ''}' : '';
}

/// The page key of a novel route: the book plus the nonce, never the chapter, so the seamless
/// next chapter replaces the location without a new route page (cinematic 8.15.2); every other
/// route keeps go_router's own key.
LocalKey? novelPageKeyFor(GoRouterState state) {
  if (!state.uri.path.startsWith('/novels/')) return null;
  final p = state.pathParameters;
  return ValueKey<String>('novel:${p['sourceId']}:${p['seriesKey']}:${_nonce(state)}');
}

/// `/novels/:sourceId/:seriesKey/:chapterKey?page&para&at&listen` and its `/novels/read/...`
/// alias: each segment decoded once by go_router, the query read as the bucket, the bookmark
/// paragraph and its fraction. `listen=1` is read by `mobile/15`.
Widget novelScreenFor(GoRouterState state) {
  final p = state.pathParameters;
  final q = state.uri.queryParameters;
  final at = double.tryParse(q['at'] ?? '');
  return CineNovelReader(
    key: ValueKey<String>('novel:${p['sourceId']}:${p['seriesKey']}:${_nonce(state)}'),
    sourceId: p['sourceId']!,
    seriesKey: p['seriesKey']!,
    chapterKey: p['chapterKey']!,
    bucket: int.tryParse(q['page'] ?? '') ?? 1,
    paragraph: int.tryParse(q['para'] ?? ''),
    fraction: at == null || at.isNaN ? null : at.clamp(0.0, 1.0),
    nonce: _nonce(state),
  );
}
