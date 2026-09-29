import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/network/api_image.dart';
import 'package:manhwamaniacs/core/network/request_limiter.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

/// `ref.read` of a `WidgetRef`, a `Ref` or a `ProviderContainer`.
typedef ReadProvider = T Function<T>(ProviderListenable<T> provider);

final Set<String> _started = {};

/// Forgets which chapters were warmed (tests).
void resetChapterStartPrefetch() => _started.clear();

/// Warms the start of a chapter before the reader asks for it: the manifest (the existing
/// repository fetch) and its first two pages, whose proxied `/sources/...` URLs go through the
/// sources limiter at [priority] (P1 on press, P3 after a dwell). Skin-neutral: plain ids, never a
/// skin's route target. One request set per chapter, ever; every failure is swallowed, because a
/// warm-up must never surface.
Future<void> prefetchChapterStart(
  ReadProvider read, {
  required String sourceId,
  required String seriesKey,
  required String chapterKey,
  required RequestPriority priority,
}) async {
  if (!_started.add('$sourceId|$seriesKey|$chapterKey')) return;
  try {
    final r = await read(readerRepositoryProvider).manifest(sourceId: sourceId, seriesKey: seriesKey, chapterKey: chapterKey);
    if (r.isErr) return;
    final dio = read(dioProvider);
    final base = read(apiBaseUrlProvider);
    for (final page in r.value.pages.take(2)) {
      unawaited(
        dio
            .get<List<int>>(
              resolveApiResourceUrl(base, page.url),
              options: Options(responseType: ResponseType.bytes, extra: {'mm.priority': priority}),
            )
            .then<void>((_) {}, onError: (_) {}),
      );
    }
  } catch (_) {
    // Warm-up only.
  }
}
