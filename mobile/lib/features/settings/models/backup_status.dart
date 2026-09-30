/// What the nightly backup job last reported. A missing one means UNKNOWN, never healthy.
class NightlyBackup {
  const NightlyBackup({required this.ok, this.finishedAt, this.phase, this.bytes});

  final bool ok;
  final DateTime? finishedAt;
  final String? phase;
  final int? bytes;

  factory NightlyBackup.fromJson(Map<String, dynamic> json) => NightlyBackup(
        ok: json['ok'] as bool? ?? false,
        finishedAt: DateTime.tryParse(json['finished_at'] as String? ?? '')?.toLocal(),
        phase: json['phase'] as String?,
        bytes: (json['bytes'] as num?)?.toInt(),
      );
}

/// Whether a database restore is staged, waiting for the backend to restart.
///
/// Mirrors the backend's `GET/DELETE /backup/*` payload shape exactly.
class BackupStatus {
  const BackupStatus({required this.restorePending, this.nightly});

  final bool restorePending;
  final NightlyBackup? nightly;

  factory BackupStatus.fromJson(Map<String, dynamic> json) {
    final n = json['nightly'];
    return BackupStatus(
      restorePending: json['restore_pending'] as bool? ?? false,
      nightly: n is Map<String, dynamic> ? NightlyBackup.fromJson(n) : null,
    );
  }
}
