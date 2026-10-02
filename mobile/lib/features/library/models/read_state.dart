import 'package:manhwamaniacs/core/time/server_instant.dart';

/// Where this profile stands in one followed series —
/// `FollowedSeriesService._read_states` in the backend, computed for a whole
/// library page in one query and sent on each list item (and on the `follow`
/// and `patch` answers, which the library swaps straight into its list).
///
/// Render it through `utils/read_state_label.dart`, never inline.
class ReadState {
  const ReadState({
    required this.started,
    this.chapterKey,
    this.chapterNumber,
    this.position,
    required this.total,
    this.latestNumber,
    this.newCount,
    this.lastReadAt,
    this.continueKey,
    this.continueNumber,
  });

  /// Whether this profile has opened any chapter of the series.
  final bool started;

  /// The furthest chapter opened, by reading order; null when the known list
  /// no longer carries it.
  final String? chapterKey;

  /// That chapter's printed number, where the source numbers it.
  final double? chapterNumber;

  /// 1-based position of that chapter in reading order; null when unknown.
  final int? position;

  /// How many chapters the known list holds.
  final int total;

  /// The printed number of the last chapter in reading order, where known.
  final double? latestNumber;

  /// Chapters past the furthest one opened; null when the position is unknown.
  final int? newCount;

  /// When the furthest chapter was last read, where the server sends it (else the LIST column shows `—`).
  final DateTime? lastReadAt;

  /// The chapter after [chapterKey] once that one is finished (null while it is mid-read or last).
  final String? continueKey;
  final double? continueNumber;

  /// Where Continue goes: past a finished furthest chapter, else the furthest one.
  String? get resumeKey => continueKey ?? chapterKey;
  double? get resumeNumber => continueKey != null ? continueNumber : chapterNumber;

  factory ReadState.fromJson(Map<String, dynamic> json) => ReadState(
        started: json['started'] as bool? ?? false,
        chapterKey: json['chapter_key'] as String?,
        chapterNumber: (json['chapter_number'] as num?)?.toDouble(),
        position: (json['position'] as num?)?.toInt(),
        total: (json['total'] as num?)?.toInt() ?? 0,
        latestNumber: (json['latest_number'] as num?)?.toDouble(),
        newCount: (json['new_count'] as num?)?.toInt(),
        lastReadAt: serverInstant(json['last_read_at']),
        continueKey: json['continue_key'] as String?,
        continueNumber: (json['continue_number'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'started': started,
        'chapter_key': chapterKey,
        'chapter_number': chapterNumber,
        'position': position,
        'total': total,
        'latest_number': latestNumber,
        'new_count': newCount,
        if (lastReadAt != null) 'last_read_at': lastReadAt!.toIso8601String(),
        if (continueKey != null) 'continue_key': continueKey,
        if (continueNumber != null) 'continue_number': continueNumber,
      };
}
