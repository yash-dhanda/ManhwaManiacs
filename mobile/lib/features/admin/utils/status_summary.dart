import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/models/source_health.dart';
import 'package:manhwamaniacs/features/updates/models/update_settings.dart';

/// A port of `frontend/src/app/(app)/admin/status/status.ts`: everything is derived from
/// responses that already exist, nothing is invented, and an unknown stays unknown.
enum StatusState { healthy, warning, down, unknown }

const _severity = {
  StatusState.healthy: 0,
  StatusState.unknown: 1,
  StatusState.warning: 2,
  StatusState.down: 3,
};

/// The most severe state; healthy for an empty list.
StatusState worstState(Iterable<StatusState> states) => states.fold(
      StatusState.healthy,
      (worst, s) => _severity[s]! > _severity[worst]! ? s : worst,
    );

// ---- backend ----------------------------------------------------------------

class BackendProbe {
  const BackendProbe({required this.status, required this.name, required this.version});
  final String status;
  final String name;
  final String version;
}

class BackendHealth {
  const BackendHealth({
    required this.state,
    required this.reachable,
    required this.name,
    required this.version,
    required this.message,
  });
  final StatusState state;
  final bool reachable;
  final String? name;
  final String? version;
  final String message;
}

/// [networkFailure] is a transport failure (the server is not there), which reads differently
/// from the server answering with an error ([errorMessage]).
BackendHealth deriveBackendHealth({
  BackendProbe? probe,
  bool failed = false,
  bool networkFailure = false,
  String? errorMessage,
  bool loading = false,
}) {
  if (failed) {
    return BackendHealth(
      state: StatusState.down,
      reachable: false,
      name: null,
      version: null,
      message: networkFailure
          ? 'The backend did not answer. It may be stopped, restarting, or unreachable from this phone.'
          : errorMessage != null
              ? 'The health probe failed: $errorMessage'
              : 'The health probe failed.',
    );
  }
  if (loading || probe == null) {
    return const BackendHealth(
      state: StatusState.unknown,
      reachable: false,
      name: null,
      version: null,
      message: 'Contacting the backend…',
    );
  }
  final online = probe.status == 'online';
  return BackendHealth(
    state: online ? StatusState.healthy : StatusState.warning,
    reachable: true,
    name: probe.name,
    version: probe.version,
    message: online ? 'The API is answering health probes.' : 'The API reported status "${probe.status}".',
  );
}

// ---- update checker ---------------------------------------------------------

class CheckSchedule {
  const CheckSchedule({
    required this.enabled,
    required this.intervalMinutes,
    required this.lastRunAt,
    required this.estimatedNextRunAt,
    required this.overdueByMinutes,
    required this.overdue,
    required this.neverRun,
  });
  final bool enabled;
  final int intervalMinutes;
  final DateTime? lastRunAt;

  /// An estimate: the last finished run plus the interval. Null until a run has finished.
  final DateTime? estimatedNextRunAt;
  final int? overdueByMinutes;

  /// Past the estimate by a whole extra interval: a run was probably missed.
  final bool overdue;
  final bool neverRun;
}

CheckSchedule? describeCheckSchedule(UpdateSettings? s, DateTime now) {
  if (s == null) return null;
  final last = s.lastRunAt;
  if (last == null) {
    return CheckSchedule(
      enabled: s.enabled,
      intervalMinutes: s.checkIntervalMinutes,
      lastRunAt: null,
      estimatedNextRunAt: null,
      overdueByMinutes: null,
      overdue: false,
      neverRun: true,
    );
  }
  final interval = Duration(minutes: s.checkIntervalMinutes);
  final next = last.add(interval);
  final late = now.difference(next);
  return CheckSchedule(
    enabled: s.enabled,
    intervalMinutes: s.checkIntervalMinutes,
    lastRunAt: last,
    estimatedNextRunAt: next,
    overdueByMinutes: late > Duration.zero ? late.inMinutes : null,
    // One interval late is normal jitter; two is a missed cycle.
    overdue: s.enabled && late > interval,
    neverRun: false,
  );
}

class CheckerHealth {
  const CheckerHealth({
    required this.state,
    required this.schedule,
    required this.lastRun,
    required this.runningRun,
    required this.failedRuns,
    required this.consecutiveFailures,
    required this.message,
  });
  final StatusState state;
  final CheckSchedule? schedule;
  final UpdateRun? lastRun;
  final UpdateRun? runningRun;
  final List<UpdateRun> failedRuns;
  final int consecutiveFailures;
  final String message;
}

CheckerHealth deriveCheckerHealth({
  UpdateSettings? settings,
  List<UpdateRun>? runs,
  required DateTime now,
  bool loading = false,
}) {
  final list = runs ?? const <UpdateRun>[];
  final schedule = describeCheckSchedule(settings, now);
  final failed = [for (final r in list) if (r.status == 'failed') r];
  var streak = 0;
  for (final r in list) {
    if (r.status == 'running') continue;
    if (r.status != 'failed') break;
    streak++;
  }
  CheckerHealth make(StatusState s, String m) => CheckerHealth(
        state: s,
        schedule: schedule,
        lastRun: list.isEmpty ? null : list.first,
        runningRun: list.where((r) => r.status == 'running').firstOrNull,
        failedRuns: failed,
        consecutiveFailures: streak,
        message: m,
      );
  if (loading || settings == null) return make(StatusState.unknown, "Loading the update checker's history…");
  if (!settings.enabled) {
    return make(StatusState.warning, 'Automatic update checks are switched off, so no series is being checked.');
  }
  if (streak > 0) {
    return make(StatusState.down, streak == 1 ? 'The last update check failed.' : 'The last $streak update checks failed.');
  }
  if (schedule != null && schedule.neverRun) {
    return make(StatusState.warning, 'No update check has finished yet, so there is nothing to schedule from.');
  }
  if (schedule != null && schedule.overdue) {
    return make(
      StatusState.warning,
      'The next check was expected ${schedule.overdueByMinutes} minutes ago. The scheduler may not be running.',
    );
  }
  return make(StatusState.healthy, 'The update checker is running on schedule.');
}

// ---- per-source health ------------------------------------------------------

class SourceHealthRow {
  const SourceHealthRow({
    required this.id,
    required this.name,
    required this.consecutiveFailures,
    required this.demoted,
    required this.lastError,
    required this.lastCheckedAt,
    required this.lastOkAt,
    required this.state,
    required this.message,
  });
  final String id;
  final String name;
  final int consecutiveFailures;
  final bool demoted;
  final String? lastError;
  final DateTime? lastCheckedAt;
  final DateTime? lastOkAt;
  final StatusState state;
  final String message;
}

/// `GET /sources/health` rows, worst first (unknown is a real state, never a synonym for ok).
List<SourceHealthRow> deriveSourceHealth(Iterable<SourceSummary>? rows) {
  final out = <SourceHealthRow>[];
  for (final r in rows ?? const <SourceSummary>[]) {
    final h = r.health ?? const SourceHealth();
    final n = h.consecutiveFailures;
    final (state, message) = switch (h.status) {
      SourceHealthStatus.dead => (StatusState.down, 'Unreachable on the last $n searches: treat as dead.'),
      SourceHealthStatus.failing => (
          StatusState.warning,
          n == 1 ? 'Failed its most recent probe.' : 'Failed its last $n probes${h.demoted ? ' (demoted in search)' : ''}.'
        ),
      SourceHealthStatus.unknown => (StatusState.unknown, 'Never probed yet, so there is nothing to report.'),
      SourceHealthStatus.ok => (StatusState.healthy, 'Answered its last probe.'),
    };
    out.add(SourceHealthRow(
      id: r.id,
      name: r.name.isEmpty ? r.id : r.name,
      consecutiveFailures: n,
      demoted: h.demoted,
      lastError: h.lastError,
      lastCheckedAt: h.lastCheckedAt,
      lastOkAt: h.lastOkAt,
      state: state,
      message: message,
    ),);
  }
  out.sort((a, b) {
    final c = _severity[b.state]!.compareTo(_severity[a.state]!);
    if (c != 0) return c;
    final f = b.consecutiveFailures.compareTo(a.consecutiveFailures);
    return f != 0 ? f : a.id.compareTo(b.id);
  });
  return out;
}

// ---- overall ----------------------------------------------------------------

class StatusSummary {
  const StatusSummary({
    required this.worst,
    required this.headline,
    required this.problems,
    required this.backend,
    required this.checker,
    required this.sources,
  });
  final StatusState worst;

  /// "Everything is running." or "2 things need attention." ("1 thing needs attention.").
  final String headline;
  final List<String> problems;
  final BackendHealth backend;
  final CheckerHealth checker;
  final List<SourceHealthRow> sources;
}

String statusHeadline(StatusState worst, int problems) {
  if (problems > 0) return problems == 1 ? '1 thing needs attention.' : '$problems things need attention.';
  return worst == StatusState.unknown ? 'Checking the system…' : 'Everything is running.';
}

StatusSummary summarise({
  required BackendHealth backend,
  UpdateSettings? checkerSettings,
  bool checkerLoading = false,
  List<UpdateRun>? runs,
  Iterable<SourceSummary>? sourceHealth,
  required DateTime now,
}) {
  final checker = deriveCheckerHealth(settings: checkerSettings, runs: runs, now: now, loading: checkerLoading);
  final sources = deriveSourceHealth(sourceHealth);
  final worst = worstState([backend.state, checker.state, worstState(sources.map((s) => s.state))]);
  final problems = <String>[];
  void push(StatusState s, String m) {
    if (s == StatusState.warning || s == StatusState.down) problems.add(m);
  }

  push(backend.state, backend.message);
  push(checker.state, checker.message);
  for (final s in sources) {
    push(s.state, '${s.name}: ${s.message}');
  }
  return StatusSummary(
    worst: worst,
    headline: statusHeadline(worst, problems.length),
    problems: problems,
    backend: backend,
    checker: checker,
    sources: sources,
  );
}
