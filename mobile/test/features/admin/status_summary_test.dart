import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/admin/utils/status_summary.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/models/source_health.dart';
import 'package:manhwamaniacs/features/updates/models/update_settings.dart';

UpdateRun run({int id = 1, String status = 'completed', String? error}) => UpdateRun(
      id: id,
      trigger: 'scheduled',
      status: status,
      seriesChecked: 4,
      newChaptersFound: 0,
      error: error,
      startedAt: DateTime.utc(2026, 7, 28, 11),
      finishedAt: status == 'running' ? null : DateTime.utc(2026, 7, 28, 11, 0, 10),
    );

UpdateSettings settings({bool enabled = true, int interval = 60, DateTime? last, bool noLast = false}) => UpdateSettings(
      enabled: enabled,
      checkIntervalMinutes: interval,
      notifyEnabled: true,
      checkOnStartup: true,
      lastRunAt: noLast ? null : (last ?? DateTime.utc(2026, 7, 28, 11, 30)),
    );

SourceSummary src(String id, {SourceHealthStatus status = SourceHealthStatus.ok, int failures = 0, bool demoted = false, String? err, String? name}) =>
    SourceSummary(
      id: id,
      name: name ?? id,
      description: '',
      browsable: true,
      supportsImport: false,
      health: SourceHealth(status: status, consecutiveFailures: failures, demoted: demoted, lastError: err),
    );

final noon = DateTime.utc(2026, 7, 28, 12);
const okProbe = BackendProbe(status: 'online', name: 'ManhwaManiacs', version: '1.0.0');

void main() {
  group('worstState', () {
    test('healthy for an empty list', () => expect(worstState(const []), StatusState.healthy));
    test('ranks down over warning over unknown over healthy', () {
      expect(worstState([StatusState.healthy, StatusState.unknown]), StatusState.unknown);
      expect(worstState([StatusState.unknown, StatusState.warning]), StatusState.warning);
      expect(worstState([StatusState.warning, StatusState.down]), StatusState.down);
    });
  });

  group('deriveBackendHealth', () {
    test('unknown while in flight', () {
      final h = deriveBackendHealth(loading: true);
      expect(h.state, StatusState.unknown);
      expect(h.reachable, isFalse);
    });
    test('a transport failure is unreachable, not an error response', () {
      final h = deriveBackendHealth(failed: true, networkFailure: true);
      expect(h.state, StatusState.down);
      expect(h.message, contains('did not answer'));
    });
    test("the server's own message when it answered with an error", () {
      final h = deriveBackendHealth(failed: true, errorMessage: 'database is locked');
      expect(h.state, StatusState.down);
      expect(h.message, contains('database is locked'));
    });
    test('name and version when the probe succeeds', () {
      final h = deriveBackendHealth(probe: okProbe);
      expect(h.state, StatusState.healthy);
      expect(h.version, '1.0.0');
    });
    test('warns on a status other than online', () {
      final h = deriveBackendHealth(probe: const BackendProbe(status: 'degraded', name: 'M', version: '1'));
      expect(h.state, StatusState.warning);
      expect(h.message, contains('degraded'));
    });
  });

  group('deriveCheckerHealth', () {
    test('unknown before settings arrive', () {
      final h = deriveCheckerHealth(now: noon, loading: true);
      expect(h.state, StatusState.unknown);
      expect(h.lastRun, isNull);
    });
    test('warns when automatic checks are off', () {
      final h = deriveCheckerHealth(settings: settings(enabled: false), runs: [run()], now: noon);
      expect(h.state, StatusState.warning);
      expect(h.message, contains('switched off'));
    });
    test('down while the newest runs failed, and counts the streak', () {
      final h = deriveCheckerHealth(
        settings: settings(),
        runs: [run(id: 3, status: 'failed'), run(id: 2, status: 'failed'), run()],
        now: noon,
      );
      expect(h.state, StatusState.down);
      expect(h.consecutiveFailures, 2);
      expect(h.failedRuns, hasLength(2));
      expect(h.message, contains('last 2 update checks failed'));
    });
    test('older failures do not count once a newer run succeeded', () {
      final h = deriveCheckerHealth(settings: settings(), runs: [run(id: 3), run(id: 2, status: 'failed')], now: noon);
      expect(h.consecutiveFailures, 0);
      expect(h.state, StatusState.healthy);
      expect(h.failedRuns, hasLength(1));
    });
    test('an in-progress run is ignored when measuring the streak', () {
      final h = deriveCheckerHealth(settings: settings(), runs: [run(id: 4, status: 'running'), run(id: 3)], now: noon);
      expect(h.consecutiveFailures, 0);
      expect(h.runningRun?.id, 4);
    });
    test('warns when no check ever finished', () {
      final h = deriveCheckerHealth(settings: settings(noLast: true), runs: const [], now: noon);
      expect(h.state, StatusState.warning);
      expect(h.message, contains('No update check has finished'));
    });
    test('warns when the next check is more than a whole interval late', () {
      final h = deriveCheckerHealth(settings: settings(last: DateTime.utc(2026, 7, 28, 8)), runs: [run()], now: noon);
      expect(h.state, StatusState.warning);
      expect(h.message, contains('180 minutes ago'));
    });
    test('healthy on schedule', () {
      final h = deriveCheckerHealth(settings: settings(), runs: [run()], now: noon);
      expect(h.state, StatusState.healthy);
      expect(h.schedule!.estimatedNextRunAt, DateTime.utc(2026, 7, 28, 12, 30));
    });
  });

  group('deriveSourceHealth', () {
    test('empty', () {
      expect(deriveSourceHealth(null), isEmpty);
      expect(deriveSourceHealth(const []), isEmpty);
    });
    test('failing maps to warning with streak and error', () {
      final r = deriveSourceHealth([src('flaky', status: SourceHealthStatus.failing, failures: 2, err: 'HTTP 522')]).single;
      expect(r.state, StatusState.warning);
      expect(r.lastError, 'HTTP 522');
      expect(r.message, contains('last 2 probes'));
    });
    test('dead maps to down, demoted kept', () {
      final r = deriveSourceHealth([src('gone', status: SourceHealthStatus.dead, failures: 10, demoted: true)]).single;
      expect(r.state, StatusState.down);
      expect(r.demoted, isTrue);
      expect(r.message, contains('dead'));
    });
    test('never probed is unknown, never healthy', () {
      expect(deriveSourceHealth([src('fresh', status: SourceHealthStatus.unknown)]).single.state, StatusState.unknown);
    });
    test('worst first', () {
      final rows = deriveSourceHealth([
        src('healthy'),
        src('dead', status: SourceHealthStatus.dead, failures: 10),
        src('failing', status: SourceHealthStatus.failing, failures: 3),
        src('fresh', status: SourceHealthStatus.unknown),
      ]);
      expect(rows.map((r) => r.id), ['dead', 'failing', 'fresh', 'healthy']);
    });
  });

  group('summarise', () {
    StatusSummary make(List<SourceSummary> sources) => summarise(
          backend: deriveBackendHealth(probe: okProbe),
          checkerSettings: settings(),
          runs: [run()],
          sourceHealth: sources,
          now: noon,
        );

    test('everything running when every part is healthy', () {
      final s = make([src('a')]);
      expect(s.worst, StatusState.healthy);
      expect(s.problems, isEmpty);
      expect(s.headline, 'Everything is running.');
    });
    test('counts problems in digits and lists them', () {
      final s = make([src('a', status: SourceHealthStatus.dead, failures: 10, name: 'A'), src('b', status: SourceHealthStatus.failing, failures: 1, name: 'B')]);
      expect(s.worst, StatusState.down);
      expect(s.headline, '2 things need attention.');
      expect(s.problems.first, contains('A'));
    });
    test('one problem uses the singular', () {
      expect(make([src('a', status: SourceHealthStatus.dead, failures: 3)]).headline, '1 thing needs attention.');
    });
    test('unknown while data is still arriving', () {
      final s = summarise(backend: deriveBackendHealth(loading: true), checkerLoading: true, now: noon);
      expect(s.worst, StatusState.unknown);
      expect(s.problems, isEmpty);
    });
  });
}
