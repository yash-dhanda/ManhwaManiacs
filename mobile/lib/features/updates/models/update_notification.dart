import 'package:manhwamaniacs/core/time/locked_until.dart';
import 'package:manhwamaniacs/core/time/server_instant.dart';

/// One new-chapter notification
/// (`backend/services/update_service.py`'s `serialize_notification`).
class UpdateNotification {
  const UpdateNotification({
    required this.id,
    required this.followedSeriesId,
    required this.sourceId,
    required this.seriesKey,
    required this.chapterKey,
    required this.chapterTitle,
    this.chapterNumber,
    required this.isRead,
    this.createdAt,
    this.lockedUntil,
  });

  final int id;
  final int? followedSeriesId;
  final String sourceId;
  final String seriesKey;
  final String chapterKey;
  final String chapterTitle;
  final double? chapterNumber;
  final bool isRead;
  final DateTime? createdAt;

  /// When an early-access chapter opens to everyone (UTC); null when open, unknown or from an older server. Whether it is
  /// still locked is [isLockedAt]'s question, asked at render time.
  final DateTime? lockedUntil;

  factory UpdateNotification.fromJson(Map<String, dynamic> json) =>
      UpdateNotification(
        id: json['id'] as int,
        followedSeriesId: json['followed_series_id'] as int?,
        sourceId: json['source_id'] as String,
        seriesKey: json['series_key'] as String,
        chapterKey: json['chapter_key'] as String,
        chapterTitle: json['chapter_title'] as String,
        chapterNumber: (json['chapter_number'] as num?)?.toDouble(),
        isRead: json['is_read'] as bool,
        createdAt: serverInstant(json['created_at']),
        lockedUntil: lockedUntilOf(json['locked_until']),
      );
}
