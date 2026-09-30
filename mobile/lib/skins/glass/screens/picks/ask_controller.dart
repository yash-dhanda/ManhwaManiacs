import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/library/providers/intelligence_providers.dart';
import 'package:manhwamaniacs/skins/glass/primitives/thinking_phases.dart';

enum AskPhase { idle, asking, results, failed }

/// Why an ask ended without answers (the server's `code` with the client's own `timeout` and `offline`).
class AskFailure {
  const AskFailure(this.code, {this.retryAfter});
  final String code;
  final int? retryAfter;
}

class AskState {
  const AskState(
      {this.phase = AskPhase.idle,
      this.prompt = '',
      this.items = const [],
      this.partial = false,
      this.remaining,
      this.failure,
      this.elapsed = Duration.zero,
      this.retryIn,
      this.serial = 0,});
  final AskPhase phase;
  final String prompt;
  final List<WorldItem> items;
  final bool partial;

  /// `remaining_today` of the last answer.
  final int? remaining;
  final AskFailure? failure;
  final Duration elapsed;

  /// Seconds until an automatic `rate_limited` retry.
  final int? retryIn;

  /// Increases with every answer, so the Deal plays once per answer.
  final int serial;

  AskState copy(
          {AskPhase? phase,
          String? prompt,
          List<WorldItem>? items,
          bool? partial,
          int? remaining,
          AskFailure? failure,
          bool clearFailure = false,
          Duration? elapsed,
          int? retryIn,
          bool clearRetry = false,
          int? serial,}) =>
      AskState(
        phase: phase ?? this.phase,
        prompt: prompt ?? this.prompt,
        items: items ?? this.items,
        partial: partial ?? this.partial,
        remaining: remaining ?? this.remaining,
        failure: clearFailure ? null : failure ?? this.failure,
        elapsed: elapsed ?? this.elapsed,
        retryIn: clearRetry ? null : retryIn ?? this.retryIn,
        serial: serial ?? this.serial,
      );
}

typedef AskArgs = ({String prompt, bool onlyMine, bool useTaste, bool novels});

/// The Ask box's request (glass 9.1.2): `POST /library/suggest` (8, local) or `POST /library/world/suggest` (12), cancellable, abandoned
/// at 40 s, with the automatic `Retry-After` retry for `rate_limited` only.
final askControllerProvider =
    NotifierProvider.autoDispose<AskController, AskState>(AskController.new,
        name: 'askController',);

class AskController extends AutoDisposeNotifier<AskState> {
  CancelToken? _token;
  Timer? _tick, _retry;
  AskArgs? _last;
  int _id = 0;

  @override
  AskState build() {
    ref.onDispose(() {
      _token?.cancel();
      _tick?.cancel();
      _retry?.cancel();
    });
    return const AskState();
  }

  AskArgs? get lastArgs => _last;

  Future<void> ask(AskArgs a) async {
    _retry?.cancel();
    _token?.cancel();
    _last = a;
    final id = ++_id;
    final token = _token = CancelToken();
    final clock = Stopwatch()..start();
    state = state.copy(
        phase: AskPhase.asking,
        prompt: a.prompt,
        clearFailure: true,
        elapsed: Duration.zero,
        clearRetry: true,);
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (id != _id) return;
      state = state.copy(elapsed: clock.elapsed);
      if (abandoned(clock.elapsed)) {
        token.cancel();
        _finish(id, failure: const AskFailure('timeout'));
      }
    });
    final repo = ref.read(askRepositoryProvider);
    try {
      final r = a.onlyMine || a.novels
          ? await repo.librarySuggest(
              prompt: a.prompt,
              limit: 8,
              useTaste: a.useTaste,
              contentKind: a.novels ? 'novel' : null,
              cancel: token,)
          : await repo.worldSuggest(
              prompt: a.prompt, limit: 12, useTaste: a.useTaste, cancel: token,);
      if (id != _id) return;
      if (r.isErr) {
        _finish(id, failure: _failureOf(r.error));
        return;
      }
      final v = r.value;
      _tick?.cancel();
      if (v.items.isEmpty) {
        state = state.copy(
            phase: AskPhase.failed,
            failure: const AskFailure('ai_no_matches'),
            remaining: v.remainingToday,
            items: const [],);
      } else {
        state = state.copy(
            phase: AskPhase.results,
            items: v.items,
            partial: v.dropped > 0,
            remaining: v.remainingToday,
            clearFailure: true,
            serial: state.serial + 1,);
      }
      ref.invalidate(suggestAvailabilityProvider);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel &&
          id == _id &&
          state.phase == AskPhase.asking) {
        cancelQuietly(id);
      }
    }
  }

  void cancelQuietly(int id) {
    if (id != _id) return;
    _tick?.cancel();
    state = state.copy(phase: AskPhase.idle, clearFailure: true);
  }

  /// The plain Cancel (and Esc): cancels the Dio request and returns to idle with the prompt kept.
  void cancel() {
    if (state.phase != AskPhase.asking) return;
    _token?.cancel();
    _id++;
    _tick?.cancel();
    state = state.copy(phase: AskPhase.idle, clearFailure: true);
  }

  void _finish(int id, {required AskFailure failure}) {
    if (id != _id) return;
    _tick?.cancel();
    state = state.copy(phase: AskPhase.failed, failure: failure);
    if (failure.code == 'rate_limited') _startRetry(failure.retryAfter ?? 10);
  }

  void _startRetry(int seconds) {
    var left = seconds;
    state = state.copy(retryIn: left);
    _retry?.cancel();
    _retry = Timer.periodic(const Duration(seconds: 1), (t) {
      left--;
      if (left <= 0) {
        t.cancel();
        final a = _last;
        if (a != null) unawaited(ask(a));
      } else {
        state = state.copy(retryIn: left);
      }
    });
  }

  AskFailure _failureOf(AppError e) => switch (e) {
        ApiError(:final code, :final retryAfter) =>
          AskFailure(_normal(code), retryAfter: retryAfter?.inSeconds),
        NetworkError() => const AskFailure('offline'),
        TimeoutError() => const AskFailure('timeout'),
        _ => const AskFailure('ai_failed'),
      };

  static String _normal(String code) => switch (code) {
        'ai_no_matches' ||
        'suggest_shelf_empty' ||
        'ai_budget_exhausted' ||
        'ai_not_configured' ||
        'rate_limited' ||
        'ai_failed' =>
          code,
        _ => 'ai_failed',
      };
}
