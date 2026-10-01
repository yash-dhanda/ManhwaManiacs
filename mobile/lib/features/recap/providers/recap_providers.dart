import 'dart:async';
import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/recap/models/recap_models.dart';
import 'package:manhwamaniacs/features/recap/repositories/recap_repository.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';

final recapRepositoryProvider = Provider<RecapRepository>((ref) => RecapRepository(ref.watch(dioProvider)), name: 'recapRepository');

/// Kept alive for 60 s after the last listener so a screen that asks again is served at once.
final recapAvailabilityProvider = FutureProvider.autoDispose.family<RecapAvailability, RecapKey>((ref, key) async {
  final link = ref.keepAlive();
  Timer? t;
  ref
    ..onCancel(() => t = Timer(const Duration(seconds: 60), link.close))
    ..onResume(() => t?.cancel())
    ..onDispose(() => t?.cancel());
  try {
    return await ref.watch(recapRepositoryProvider).availability(key);
  } catch (e) {
    // A failed check is "no recap here", never an error the reader sees; do not cache it.
    link.close();
    return const RecapAvailability(available: false, reason: 'unknown');
  }
});

enum RecapPhase { loading, streaming, done, none, error }

/// Recap prose tokens: whole words, with `\n\n` as its own token between paragraphs.
final _token = RegExp(r'\n{2,}|[^\s]+');
const kRecapParagraphToken = '\n\n';

/// Reasons that read as "no recap for this one" rather than an unavailable desk.
String _reasonOf(String code) => switch (code) {
      'ai_not_configured' => 'not_configured',
      'ai_budget_exhausted' => 'budget_exhausted',
      _ => code,
    };

class RecapStreamState {
  const RecapStreamState({
    this.phase = RecapPhase.loading,
    this.reason,
    this.retryAfter,
    this.meta,
    this.words = const [],
    this.generatedAt,
  });
  final RecapPhase phase;
  final String? reason;
  final int? retryAfter;
  final RecapMeta? meta;

  /// The words revealed so far, one every 30 ms (paragraph breaks are [kRecapParagraphToken]).
  final List<String> words;
  final DateTime? generatedAt;

  RecapStreamState copy({RecapPhase? phase, String? reason, int? retryAfter, RecapMeta? meta, List<String>? words, DateTime? generatedAt}) =>
      RecapStreamState(
        phase: phase ?? this.phase,
        reason: reason ?? this.reason,
        retryAfter: retryAfter ?? this.retryAfter,
        meta: meta ?? this.meta,
        words: words ?? this.words,
        generatedAt: generatedAt ?? this.generatedAt,
      );
}

final recapStreamProvider = NotifierProvider.autoDispose.family<RecapStreamNotifier, RecapStreamState, RecapKey>(RecapStreamNotifier.new, name: 'recapStream');

class RecapStreamNotifier extends AutoDisposeFamilyNotifier<RecapStreamState, RecapKey> {
  CancelToken? _cancel;
  StreamSubscription<RecapEvent>? _sub;
  Timer? _pace;
  final Queue<String> _queue = Queue();
  bool _flush = false, _streamDone = false, _disposed = false;
  int _run = 0;

  /// One word every 30 ms (the fade of each is the screen's).
  static const wordGap = Duration(milliseconds: 30);

  @override
  RecapStreamState build(RecapKey arg) {
    ref.onDispose(() {
      _disposed = true;
      _teardown();
    });
    unawaited(Future<void>.microtask(_start));
    return const RecapStreamState();
  }

  void _teardown() {
    _cancel?.cancel();
    _cancel = null;
    unawaited(_sub?.cancel());
    _sub = null;
    _pace?.cancel();
    _pace = null;
  }

  Future<void> retry() async {
    _teardown();
    _queue.clear();
    _flush = false;
    _streamDone = false;
    state = const RecapStreamState();
    await _start();
  }

  /// Reveals every word received and every word still to come the moment it arrives.
  void completeNow() {
    _flush = true;
    _drain();
  }

  Future<void> _start() async {
    final id = ++_run;
    final token = _cancel = CancelToken();
    final RecapOpen open;
    try {
      open = await ref.read(recapRepositoryProvider).open(arg, cancel: token);
    } catch (_) {
      if (_disposed || id != _run) return;
      state = state.copy(phase: RecapPhase.error);
      return;
    }
    if (_disposed || id != _run) return;
    switch (open) {
      case RecapNone(:final reason, :final retryAfter):
        _finishNone(reason, retryAfter);
      case DeckStream():
        _finishNone('error', null);
      case RecapStream(:final events):
        _sub = events.listen(
          (e) => _onEvent(e, id),
          onError: (Object _) {
            if (!_disposed && id == _run) state = state.copy(phase: RecapPhase.error);
          },
          onDone: () {
            if (_disposed || id != _run) return;
            if (!_streamDone) {
              // The connection closed without `done`: what arrived stands; an empty one is an error.
              if (state.words.isEmpty && _queue.isEmpty) {
                state = state.copy(phase: RecapPhase.error);
              } else {
                _streamDone = true;
                _drain();
              }
            }
          },
        );
    }
  }

  void _finishNone(String reason, int? retryAfter) {
    final r = _reasonOf(reason);
    if (r == 'error' || r == 'ai_failed') {
      state = state.copy(phase: RecapPhase.error, reason: r);
    } else {
      state = state.copy(phase: RecapPhase.none, reason: r, retryAfter: retryAfter);
    }
  }

  void _onEvent(RecapEvent e, int id) {
    if (_disposed || id != _run) return;
    switch (e) {
      case RecapMeta():
        state = state.copy(meta: e, phase: RecapPhase.streaming);
      case RecapDelta(:final text):
        _queue.addAll(_token.allMatches(text).map((m) => m[0]!.startsWith('\n') ? kRecapParagraphToken : m[0]!));
        if (state.phase == RecapPhase.loading) state = state.copy(phase: RecapPhase.streaming);
        _drain();
      case RecapDone(:final generatedAt):
        _streamDone = true;
        state = state.copy(generatedAt: generatedAt);
        _drain();
      case RecapError(:final code, :final retryAfter):
        _teardown();
        _queue.clear();
        _finishNone(code == 'ai_failed' ? 'error' : code, retryAfter);
    }
  }

  void _drain() {
    if (_flush && _queue.isNotEmpty) {
      state = state.copy(words: [...state.words, ..._queue]);
      _queue.clear();
    }
    if (_queue.isEmpty) {
      _pace?.cancel();
      _pace = null;
      if (_streamDone && state.phase != RecapPhase.done && state.phase != RecapPhase.none) state = state.copy(phase: RecapPhase.done);
      return;
    }
    _pace ??= Timer.periodic(wordGap, (_) {
      if (_disposed || _queue.isEmpty) return _drain();
      state = state.copy(words: [...state.words, _queue.removeFirst()]);
    });
  }
}
