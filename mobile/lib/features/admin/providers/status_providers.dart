import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/admin/utils/status_summary.dart';
import 'package:manhwamaniacs/features/updates/models/update_settings.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

const Duration kBackendPollEvery = Duration(seconds: 15);
const Duration kSourcesPollEvery = Duration(seconds: 30);

/// One `GET /health` answer and the instant the next poll is due (for the `LIVE · 15 S` folio).
class BackendPoll {
  const BackendPoll({required this.health, required this.nextPollAt});
  final BackendHealth health;
  final DateTime nextPollAt;
}

/// `GET /health` every 15 s while listened to.
final backendHealthProvider = StreamProvider.autoDispose<BackendPoll>((ref) async* {
  final dio = ref.watch(dioProvider);
  var alive = true;
  ref.onDispose(() => alive = false);
  while (alive) {
    BackendHealth health;
    try {
      final r = await dio.get<Map<String, dynamic>>('/health');
      final d = r.data ?? const <String, dynamic>{};
      health = deriveBackendHealth(
        probe: BackendProbe(
          status: '${d['status'] ?? ''}',
          name: '${d['name'] ?? ''}',
          version: '${d['version'] ?? ''}',
        ),
      );
    } on DioException catch (e) {
      final err = e.error;
      health = deriveBackendHealth(
        failed: true,
        networkFailure: err is NetworkError || err is TimeoutError || err == null && e.response == null,
        errorMessage: err is ApiError ? err.message : null,
      );
    } catch (_) {
      health = deriveBackendHealth(failed: true);
    }
    if (!alive) return;
    yield BackendPoll(health: health, nextPollAt: DateTime.now().add(kBackendPollEvery));
    await Future<void>.delayed(kBackendPollEvery);
  }
});

/// One `GET /health` (public) for the backend's own version, as About shows it.
final serverVersionProvider = FutureProvider.autoDispose<String?>((ref) async {
  final r = await ref.watch(dioProvider).get<Map<String, dynamic>>('/health');
  final v = r.data?['version'];
  return v is String && v.isNotEmpty ? v : null;
});

/// `GET /updates/settings`.
final updateSettingsProvider = FutureProvider.autoDispose<UpdateSettings>((ref) async {
  final r = await ref.read(updatesRepositoryProvider).getSettings();
  if (r.isErr) throw r.error;
  return r.value;
});

/// `GET /updates/runs?limit=8`.
final updateRunsProvider = FutureProvider.autoDispose<List<UpdateRun>>((ref) async {
  final r = await ref.read(updatesRepositoryProvider).listRuns(limit: 8);
  if (r.isErr) throw r.error;
  return r.value;
});

/// The outcome of "Check now".
class ManualCheckResult {
  const ManualCheckResult({required this.ok, required this.message});
  final bool ok;
  final String message;
}

const String kCheckAlreadyRunning = 'A check is already running.';

/// `POST /updates/check`; `409 check_already_running` maps to [kCheckAlreadyRunning].
class ManualCheck extends AutoDisposeNotifier<bool> {
  @override
  bool build() => false;

  bool get running => state;

  Future<ManualCheckResult> run() async {
    if (state) return const ManualCheckResult(ok: false, message: kCheckAlreadyRunning);
    state = true;
    try {
      final r = await ref.read(updatesRepositoryProvider).triggerCheck();
      if (r.isErr) {
        final e = r.error;
        if (e is ApiError && (e.statusCode == 409 || e.code == 'check_already_running')) {
          return const ManualCheckResult(ok: false, message: kCheckAlreadyRunning);
        }
        return ManualCheckResult(ok: false, message: e is ApiError ? e.message : e.userMessage);
      }
      ref
        ..invalidate(updateRunsProvider)
        ..invalidate(updateSettingsProvider);
      final o = r.value;
      return ManualCheckResult(ok: true, message: o.queued ? 'Check queued.' : 'Check started.');
    } finally {
      state = false;
    }
  }
}

final manualCheckProvider = NotifierProvider.autoDispose<ManualCheck, bool>(ManualCheck.new, name: 'manualCheck');
