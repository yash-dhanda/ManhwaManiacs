import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/updates/models/update_notification.dart';
import 'package:manhwamaniacs/features/updates/models/update_settings.dart';

/// Update-check settings, the notifications a check produces, and the run
/// log (spec §4.5). Following a series lives at `POST /library/follow`
/// ([LibraryRepository.follow]) — there are no trackers here.
abstract interface class UpdatesRepository {
  Future<Result<UpdateSettings>> getSettings();

  Future<Result<UpdateSettings>> updateSettings({
    bool? enabled,
    int? checkIntervalMinutes,
    bool? notifyEnabled,
    bool? checkOnStartup,
  });

  Future<Result<List<UpdateNotification>>> listNotifications({
    bool unreadOnly = false,
    int limit = 100,
  });

  Future<Result<int>> getUnreadCount();

  Future<Result<void>> markRead(int notificationId);

  /// `POST /updates/notifications/read-all`. [contentKind] (`'manga'` /
  /// `'novel'`) clears only that content mode's rows; null clears every mode.
  Future<Result<void>> markAllRead({String? contentKind});

  Future<Result<List<UpdateRun>>> listRuns({int limit = 20});

  /// `POST /updates/check`. When a check is already running the backend
  /// queues this one instead of running it inline — `run` is null and
  /// [UpdateCheckOutcome.queued] is true in that case.
  Future<Result<UpdateCheckOutcome>> triggerCheck({List<int>? followedIds});

  Future<Result<UpdateRun>> checkFollowed(int followedId);

  /// `GET /updates/runs/{id}` (admin): one run, polled while a check runs.
  Future<Result<UpdateRun>> getRun(int runId);

  /// `GET /updates/sources`: the ids of the browsable sources, through the caller's 18+ gate.
  Future<Result<List<String>>> listUpdateSources();
}

class UpdateCheckOutcome {
  const UpdateCheckOutcome({required this.queued, this.run});

  final bool queued;
  final UpdateRun? run;
}

/// What "Check now" did (glass 8.21): ran inline, was queued behind a running check, or found one already running (`409`).
enum CheckOutcome { ran, queued, alreadyRunning }

extension UpdatesRepositoryGlass on UpdatesRepository {
  /// `POST /updates/check`, with `409 check_already_running` answered as [CheckOutcome.alreadyRunning] instead of an error.
  Future<Result<CheckOutcome>> checkNow() async {
    final r = await triggerCheck();
    if (r.isErr) {
      final e = r.error;
      if (e is ApiError && (e.statusCode == 409 || e.code == 'check_already_running')) return const Ok(CheckOutcome.alreadyRunning);
      return Err(e);
    }
    return Ok(r.value.queued ? CheckOutcome.queued : CheckOutcome.ran);
  }

  /// `POST /updates/followed/{id}/check`.
  Future<Result<UpdateRun>> checkSeries(int followedId) => checkFollowed(followedId);
}
