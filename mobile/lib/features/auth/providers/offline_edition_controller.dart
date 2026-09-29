import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/network/network_failures.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/auth/providers/session_offline_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/bookmark_outbox_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/progress_outbox_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';

/// Incremented when the server answers again after an outage; screens that care refetch.
final backOnlineEpochProvider = StateProvider<int>((ref) => 0, name: 'backOnlineEpoch');

/// What the outbox flush that follows a reconnection delivered.
class OutboxSyncResult {
  const OutboxSyncResult({required this.id, required this.reads, required this.bookmarks});
  final int id, reads, bookmarks;
}

/// Set once per reconnection, after both outboxes have been flushed.
final outboxSyncProvider = StateProvider<OutboxSyncResult?>((ref) => null, name: 'outboxSync');

/// The source of "the server did not answer" events. An override point for tests.
final networkFailureStreamProvider = Provider<Stream<AppError>>((ref) => networkFailures);

/// `GET /health`; true when the server answered. An override point for tests.
final serverProbeProvider = Provider<Future<bool> Function()>(
  (ref) => () async {
    try {
      await ref.read(dioProvider).get<Map<String, dynamic>>('/health');
      return true;
    } on DioException {
      return false;
    } catch (_) {
      return false;
    }
  },
);

/// 15, 30, 60, 60, ... seconds.
Duration offlinePollDelay(int attempt) =>
    Duration(seconds: [15, 30, 60][attempt < 2 ? attempt : 2]);

/// Backend unreachable mid-session (cinematic 8.32): the first failure while signed in marks the
/// session offline and polls `/health`; the first answer marks it online, bumps
/// [backOnlineEpochProvider] and flushes the outboxes. Only the Cinematic root reads this
/// provider, so legacy shows nothing new.
final offlineEditionControllerProvider = Provider<OfflineEditionController>(
  (ref) {
    final c = OfflineEditionController(ref);
    ref.onDispose(c.dispose);
    return c;
  },
  name: 'offlineEditionController',
);

class OfflineEditionController {
  OfflineEditionController(this._ref) {
    _sub = _ref.read(networkFailureStreamProvider).listen(_onFailure);
    _ref.listen<bool>(sessionOfflineProvider, (_, offline) {
      if (offline) _startPolling();
    });
    if (_ref.read(sessionOfflineProvider)) _startPolling();
  }

  final Ref _ref;
  StreamSubscription<AppError>? _sub;
  Timer? _timer;
  int _attempt = 0;
  int _syncs = 0;
  bool _disposed = false;

  bool get polling => _timer != null;

  void _onFailure(AppError _) {
    if (_ref.read(authControllerProvider) is! AuthAuthenticated) return;
    if (!_ref.read(sessionOfflineProvider)) _ref.read(sessionOfflineProvider.notifier).markOffline();
    _startPolling();
  }

  void _startPolling() {
    if (_timer != null || _disposed) return;
    _attempt = 0;
    _schedule();
  }

  void _schedule() {
    _timer = Timer(offlinePollDelay(_attempt++), () async {
      _timer = null;
      if (_disposed) return;
      final up = await _ref.read(serverProbeProvider)();
      if (_disposed) return;
      if (up) {
        await _backOnline();
      } else {
        _schedule();
      }
    });
  }

  Future<void> _backOnline() async {
    _ref.read(sessionOfflineProvider.notifier).markOnline();
    _ref.read(backOnlineEpochProvider.notifier).state++;
    final progress = _ref.read(progressOutboxControllerProvider);
    final bookmarks = _ref.read(bookmarkOutboxControllerProvider);
    final readsBefore = await progress.pendingCount();
    final marksBefore = await bookmarks.pendingCount();
    await progress.flush();
    await bookmarks.flush();
    if (_disposed) return;
    final reads = readsBefore - await progress.pendingCount();
    final marks = marksBefore - await bookmarks.pendingCount();
    _ref.read(outboxSyncProvider.notifier).state = OutboxSyncResult(
      id: ++_syncs,
      reads: reads < 0 ? 0 : reads,
      bookmarks: marks < 0 ? 0 : marks,
    );
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _sub?.cancel();
  }
}

/// "Synced 3 reads and 2 bookmarks." A zero part is dropped; null when both are zero.
String? syncedMessage(int reads, int bookmarks) {
  String part(int n, String one, String many) => '$n ${n == 1 ? one : many}';
  if (reads > 0 && bookmarks > 0) {
    return 'Synced ${part(reads, 'read', 'reads')} and ${part(bookmarks, 'bookmark', 'bookmarks')}.';
  }
  if (reads > 0) return 'Synced ${part(reads, 'read', 'reads')}.';
  if (bookmarks > 0) return 'Synced ${part(bookmarks, 'bookmark', 'bookmarks')}.';
  return null;
}
