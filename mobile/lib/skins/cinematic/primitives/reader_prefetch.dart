import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_chapter_provider.dart';

/// Warms a chapter manifest before the reader asks for it. `onPress` fires on
/// pointer-down (the reader opens next); `onDwell` fires for rows on load and
/// for a row a keyboard focuses for 150 ms. One request per chapter, ever
/// (P3, through the repository the sources limiter already guards).
/// TODO(mobile/06): replaced by the shared `ReaderPrefetch`.
class ReaderPrefetch {
  ReaderPrefetch(this._read);
  final T Function<T>(ProviderListenable<T>) _read;

  static final Set<String> _seen = {};

  @visibleForTesting
  static void reset() => _seen.clear();

  void warm(String sourceId, String seriesKey, String chapterKey) {
    if (!_seen.add('$sourceId|$seriesKey|$chapterKey')) return;
    try {
      final key = (sourceId: sourceId, seriesKey: seriesKey, chapterKey: chapterKey);
      unawaited(_read(chapterManifestProvider(key).future).then<void>((_) {}, onError: (_) {}));
    } catch (_) {}
  }

  void onPress(String s, String k, String c) => warm(s, k, c);
  void onDwell(String s, String k, String c) => warm(s, k, c);
}

ReaderPrefetch readerPrefetchOf(WidgetRef ref) => ReaderPrefetch(ref.read);
