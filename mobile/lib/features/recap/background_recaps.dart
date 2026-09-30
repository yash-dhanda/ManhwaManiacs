import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/recap/recap_cache.dart';
import 'package:manhwamaniacs/features/recap/recap_deck.dart';
import 'package:manhwamaniacs/features/recap/sse.dart';

const Duration kRecapKeepAlive = Duration(seconds: 60);

class RecapReady {
  const RecapReady(this.key, this.title, {this.sourceId = '', this.seriesKey = '', this.to = '', this.scope = 'series'});
  final String key, title, sourceId, seriesKey, to, scope;
}

class BackgroundRecapEntry {
  BackgroundRecapEntry._(this.key, this.title, this.sourceId, this.seriesKey, this.mature, this.startedAt);
  final String key, title, sourceId, seriesKey;
  final bool mature;
  final DateTime startedAt;
  StreamSubscription<SseEvent>? _sub;
  Timer? _timer;
  CancelToken? _cancel;
  DeckState deck = const DeckState();
}

/// Streams of closed recap sheets, kept running until 60 s after their request started (glass 9.1.3). When `done` arrives the deck is
/// saved through [RecapCache] and a [RecapReady] is emitted on [readyStream]; past 60 s, or on a profile switch or the 18+ purge, the
/// request is cancelled and nothing is emitted.
final backgroundRecapsProvider = Provider<BackgroundRecaps>((ref) {
  final b = BackgroundRecaps(ref);
  ref.onDispose(b.dispose);
  return b;
}, name: 'backgroundRecaps');

class BackgroundRecaps {
  BackgroundRecaps(this._ref);
  final Ref _ref;
  final Map<String, BackgroundRecapEntry> _entries = {};
  final StreamController<RecapReady> _ready = StreamController<RecapReady>.broadcast();

  Stream<RecapReady> get readyStream => _ready.stream;
  int get length => _entries.length;
  bool contains(String key) => _entries.containsKey(key);

  /// [key] is the cache key (`recapCacheKey`). [events] must be listenable by this call (hand over the sheet's stream as a broadcast
  /// stream); [deckSoFar] is what the sheet had already folded.
  void keepAlive(
    String key, {
    required Stream<SseEvent> events,
    required CancelToken cancel,
    required String title,
    required String sourceId,
    required String seriesKey,
    String to = '',
    String scope = 'series',
    required bool mature,
    required DateTime startedAt,
    DeckState deckSoFar = const DeckState(),
  }) {
    _drop(key);
    final e = BackgroundRecapEntry._(key, title, sourceId, seriesKey, mature, startedAt).._cancel = cancel;
    e.deck = deckSoFar;
    _entries[key] = e;
    final left = kRecapKeepAlive - _ref.read(clockProvider)().difference(startedAt);
    if (left <= Duration.zero) {
      _drop(key);
      return;
    }
    e._timer = Timer(left, () => _drop(key));
    e._sub = events.listen(
      (ev) {
        e.deck = deckReducer(e.deck, ev);
        if (e.deck.done != null) {
          final deck = e.deck;
          _entries.remove(key);
          e._timer?.cancel();
          unawaited(e._sub?.cancel());
          unawaited(_ref.read(recapCacheProvider).save(key, deck));
          if (!_ready.isClosed) _ready.add(RecapReady(key, title, sourceId: sourceId, seriesKey: seriesKey, to: to, scope: scope));
        } else if (e.deck.error != null) {
          _drop(key);
        }
      },
      onError: (Object _) => _drop(key),
      onDone: () => _entries.remove(key),
    );
  }

  void _drop(String key) {
    final e = _entries.remove(key);
    if (e == null) return;
    e._timer?.cancel();
    unawaited(e._sub?.cancel());
    e._cancel?.cancel();
  }

  void cancelWhere(bool Function(BackgroundRecapEntry entry) test) {
    for (final k in [for (final e in _entries.values) if (test(e)) e.key]) {
      _drop(k);
    }
  }

  void cancelAll() => cancelWhere((_) => true);

  void dispose() {
    cancelAll();
    unawaited(_ready.close());
  }
}
