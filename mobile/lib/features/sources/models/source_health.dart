import 'package:manhwamaniacs/core/time/server_instant.dart';

/// Reachability of one source, as `GET /sources` and `GET /sources/health`
/// carry it in each row's `health` object.
enum SourceHealthStatus {
  ok,
  failing,
  dead,
  unknown;

  static SourceHealthStatus parse(String? raw) => switch (raw) {
        'ok' => SourceHealthStatus.ok,
        'failing' => SourceHealthStatus.failing,
        'dead' => SourceHealthStatus.dead,
        _ => SourceHealthStatus.unknown,
      };
}

DateTime? _date(Object? v) => serverInstant(v)?.toLocal();

class SourceHealth {
  const SourceHealth({
    this.status = SourceHealthStatus.unknown,
    this.consecutiveFailures = 0,
    this.demoted = false,
    this.lastOkAt,
    this.lastErrorAt,
    this.lastError,
    this.lastCheckedAt,
  });

  final SourceHealthStatus status;
  final int consecutiveFailures;
  final bool demoted;
  final DateTime? lastOkAt;
  final DateTime? lastErrorAt;
  final String? lastError;
  final DateTime? lastCheckedAt;

  factory SourceHealth.fromJson(Map<String, dynamic> json) => SourceHealth(
        status: SourceHealthStatus.parse(json['status'] as String?),
        consecutiveFailures:
            (json['consecutive_failures'] as num?)?.toInt() ?? 0,
        demoted: json['demoted'] as bool? ?? false,
        lastOkAt: _date(json['last_ok_at']),
        lastErrorAt: _date(json['last_error_at']),
        lastError: json['last_error'] as String?,
        lastCheckedAt: _date(json['last_checked_at']),
      );
}

/// `GET /system/source-health`.
class SourceHealthSummary {
  const SourceHealthSummary({
    this.total = 0,
    this.ok = 0,
    this.failing = 0,
    this.dead = 0,
    this.unknown = 0,
    this.demoted = 0,
  });

  final int total;
  final int ok;
  final int failing;
  final int dead;
  final int unknown;
  final int demoted;

  factory SourceHealthSummary.fromJson(Map<String, dynamic> json) {
    int n(String k) => (json[k] as num?)?.toInt() ?? 0;
    return SourceHealthSummary(
      total: n('total'),
      ok: n('ok'),
      failing: n('failing'),
      dead: n('dead'),
      unknown: n('unknown'),
      demoted: n('demoted'),
    );
  }
}
