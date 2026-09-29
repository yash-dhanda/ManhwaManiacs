import 'package:manhwamaniacs/features/sources/utils/chapter_label.dart';
import 'package:manhwamaniacs/features/updates/models/update_notification.dart';

/// Everything the Library card can say *truthfully* about a followed series
/// without firing a per-series network request.
///
/// [FollowedSeries.chapterCount] is only refreshed by the backend update
/// checker, so a freshly-followed series — or one whose connector is erroring
/// — reports 0 even though the series has hundreds of chapters. Rendering "0
/// chapters" is therefore a lie, and the only way to get a real count on this
/// screen would be one chapter-list request per followed series on every
/// Library open. Instead we surface what the already-loaded updates payload
/// knows: the newest chapter we have ever been notified about, and how many
/// of those notifications are still unread.
class FollowedSeriesMeta {
  const FollowedSeriesMeta({
    required this.unreadCount,
    required this.latestChapterLabel,
  });

  /// Unread new-chapter notifications for this series, counted from the same
  /// notification page the Updates tab renders — so the two always agree.
  final int unreadCount;

  /// Label of the newest chapter we have been notified about ("Chapter 120"),
  /// or null when the series has never produced a notification.
  final String? latestChapterLabel;

  static const FollowedSeriesMeta none =
      FollowedSeriesMeta(unreadCount: 0, latestChapterLabel: null);

  /// `followedSeriesId -> meta` for every series [notifications] mentions.
  ///
  /// Built once per notification list rather than per card. The grid's item
  /// builder runs for every tile entering the cache extent during a scroll, so
  /// deriving one card's meta by scanning the whole list there makes that
  /// builder O(notifications) — and `updatesProvider` fetches an unpaginated
  /// list. Series with no notification are simply absent; the card falls back
  /// to [none].
  static Map<int, FollowedSeriesMeta> indexBySeries(
    List<UpdateNotification> notifications,
  ) {
    final unread = <int, int>{};
    final latest = <int, UpdateNotification>{};
    for (final notification in notifications) {
      final seriesId = notification.followedSeriesId;
      if (seriesId == null) continue;
      if (!notification.isRead) unread[seriesId] = (unread[seriesId] ?? 0) + 1;
      final current = latest[seriesId];
      if (current == null || _isNewer(notification, current)) {
        latest[seriesId] = notification;
      }
    }
    return {
      for (final entry in latest.entries)
        entry.key: FollowedSeriesMeta(
          unreadCount: unread[entry.key] ?? 0,
          latestChapterLabel: chapterLabel(
            number: entry.value.chapterNumber,
            title: entry.value.chapterTitle,
          ).primary,
        ),
    };
  }

  /// Newest-first ordering: chapter number when both sides have one, else the
  /// creation timestamp, else insertion id.
  static bool _isNewer(UpdateNotification a, UpdateNotification b) {
    final an = a.chapterNumber;
    final bn = b.chapterNumber;
    if (an != null && bn != null && an != bn) return an > bn;
    final at = a.createdAt;
    final bt = b.createdAt;
    if (at != null && bt != null && at != bt) return at.isAfter(bt);
    return a.id > b.id;
  }
}
