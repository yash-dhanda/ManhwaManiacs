import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/logging/app_logger.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/novels/utils/listen_sessions.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

/// At most this many sessions per `POST /novels/listen-sessions`.
const int kListenBatchMax = 200;

/// Queues closed listening sessions in the device's sqlite outbox and sends them oldest first as
/// one array of at most [kListenBatchMax] (the progress outbox's pattern: write locally, flush
/// when something changes).
///
/// A 2xx deletes the sent rows. A 4xx other than 429 deletes them too (the server judged the bytes
/// and the same rows will draw the same refusal; keeping them would wedge every later flush).
/// 429, 503 and network errors keep them for the next trigger.
class ListenSessionOutboxController {
  ListenSessionOutboxController(this.ref);

  final Ref ref;

  Future<void>? _draining;
  Future<void>? _queued;

  /// Queue [session] for the active profile and try to send it. A no-op with no active scope:
  /// there is nowhere to persist it.
  Future<void> save(ClosedListenSession session) async {
    final store = ref.read(downloadsStoreProvider);
    if (store == null) return;
    await store.enqueueListenSession(session.toJson());
    return flush();
  }

  /// Sends every queued row of the active profile. Never throws. Overlapping calls join one
  /// follow-up pass, so a row is never read (and posted) by two drains at once.
  Future<void> flush() {
    final draining = _draining;
    if (draining != null) {
      return _queued ??= draining.then((_) {
        _queued = null;
        return flush();
      });
    }
    return _draining = _drain().whenComplete(() => _draining = null);
  }

  Future<int> pendingCount() async {
    try {
      return (await ref.read(downloadsStoreProvider)?.pendingListenSessions())?.length ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _drain() async {
    try {
      final store = ref.read(downloadsStoreProvider);
      if (store == null) return;
      final repository = ref.read(novelsRepositoryProvider);
      while (true) {
        final pending = await store.pendingListenSessions();
        if (pending.isEmpty) return;
        final result = await repository.saveListenSessions([for (final p in pending) p.$2]);
        final ids = [for (final p in pending) p.$1];
        if (result.isOk) {
          await store.clearListenSessions(ids);
          if (pending.length < kListenBatchMax) return;
          continue;
        }
        final error = result.error;
        if (error is ApiError && error.statusCode >= 400 && error.statusCode < 500 && error.statusCode != 429) {
          appLogger.w('listen sessions: dropped ${ids.length} row(s) the server refused (${error.message})');
          await store.clearListenSessions(ids);
          continue;
        }
        return;
      }
    } catch (_) {
      // Offline or a transient error: the rows stay queued for the next trigger.
    }
  }
}

final listenSessionOutboxControllerProvider = Provider<ListenSessionOutboxController>(ListenSessionOutboxController.new, name: 'listenSessionOutbox');
