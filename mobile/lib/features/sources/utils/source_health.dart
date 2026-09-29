import 'package:manhwamaniacs/features/sources/models/source_health.dart';

enum HealthState { ok, failing, dead, unknown, demoted }

class HealthDescription {
  const HealthDescription(this.state, this.label);

  final HealthState state;
  final String label;
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _ago(DateTime at, DateTime now) {
  final d = now.difference(at);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 48) return '${d.inHours} h ago';
  return '${d.inDays} d ago';
}

/// `OK · last checked 4 min ago`, `FAILING · 3 errors`, `DEAD since 12 Sep`,
/// `DEMOTED` (wins over the status), `UNKNOWN` for a source never probed.
HealthDescription describeHealth(SourceHealth? health, DateTime now) {
  if (health == null) {
    return const HealthDescription(HealthState.unknown, 'UNKNOWN');
  }
  if (health.demoted) {
    return const HealthDescription(HealthState.demoted, 'DEMOTED');
  }
  switch (health.status) {
    case SourceHealthStatus.ok:
      final at = health.lastCheckedAt;
      return HealthDescription(
        HealthState.ok,
        at == null ? 'OK' : 'OK · last checked ${_ago(at, now)}',
      );
    case SourceHealthStatus.failing:
      final n = health.consecutiveFailures;
      return HealthDescription(
        HealthState.failing,
        'FAILING · $n ${n == 1 ? 'error' : 'errors'}',
      );
    case SourceHealthStatus.dead:
      final at = health.lastOkAt ?? health.lastErrorAt;
      return HealthDescription(
        HealthState.dead,
        at == null ? 'DEAD' : 'DEAD since ${at.day} ${_months[at.month - 1]}',
      );
    case SourceHealthStatus.unknown:
      return const HealthDescription(HealthState.unknown, 'UNKNOWN');
  }
}

int _rank(SourceHealth? h) {
  if (h == null) return 3;
  if (h.demoted && h.status != SourceHealthStatus.dead) {
    return h.status == SourceHealthStatus.failing ? 1 : 2;
  }
  return switch (h.status) {
    SourceHealthStatus.dead => 0,
    SourceHealthStatus.failing => 1,
    SourceHealthStatus.unknown => 3,
    SourceHealthStatus.ok => 4,
  };
}

/// Dead, failing, demoted, unknown, ok; then by name (case-insensitive).
List<T> sortWorstFirst<T>(
  Iterable<T> rows,
  SourceHealth? Function(T) health,
  String Function(T) name,
) {
  // Demoted sits between failing and unknown.
  int rank(T r) {
    final h = health(r);
    if (h != null &&
        h.demoted &&
        h.status != SourceHealthStatus.dead &&
        h.status != SourceHealthStatus.failing) {
      return 2;
    }
    return _rank(h) == 2 ? 2 : _rank(h);
  }

  return [...rows]..sort((a, b) {
      final c = rank(a).compareTo(rank(b));
      return c != 0
          ? c
          : name(a).toLowerCase().compareTo(name(b).toLowerCase());
    });
}
