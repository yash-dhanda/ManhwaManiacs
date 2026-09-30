import 'package:manhwamaniacs/features/library/models/ambient.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/updates/models/update_notification.dart';

/// One new chapter inside a [SeriesUpdate].
typedef UpdateChapter = ({int notificationId, String chapterKey, double? chapterNumber, String title, bool read});

/// The new chapters of one series on one day.
class SeriesUpdate {
  const SeriesUpdate({
    required this.sourceId,
    required this.seriesKey,
    required this.title,
    required this.coverUrl,
    required this.ambient,
    required this.chapters,
    required this.newestAt,
    this.followedId,
  });

  final String sourceId, seriesKey, title;
  final String? coverUrl;
  final Ambient? ambient;
  final int? followedId;

  /// In ascending chapter number.
  final List<UpdateChapter> chapters;
  final DateTime? newestAt;

  int get unread => chapters.where((c) => !c.read).length;
  bool get allRead => unread == 0;

  /// The first chapter not yet read, or null when the group is fully read.
  UpdateChapter? get firstUnread => firstUnreadOf(this);
}

UpdateChapter? firstUnreadOf(SeriesUpdate g) {
  for (final c in g.chapters) {
    if (!c.read) return c;
  }
  return null;
}

/// `firstUnread(group)` as the prompt names it.
UpdateChapter? firstUnread(SeriesUpdate group) => firstUnreadOf(group);

class UpdateDay {
  const UpdateDay({required this.label, required this.groups});

  /// `TODAY`, `YESTERDAY` or `MONDAY 28 SEPTEMBER`.
  final String label;

  /// Newest first.
  final List<SeriesUpdate> groups;
}

const _days = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];
const _months = [
  'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE', 'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER',
];

/// The date rule's words for [at] seen from [now] (both read in local time).
String dayLabel(DateTime at, DateTime now) {
  final a = at.toLocal(), n = now.toLocal();
  final d = DateTime(a.year, a.month, a.day);
  final today = DateTime(n.year, n.month, n.day);
  final gap = DateTime.utc(today.year, today.month, today.day).difference(DateTime.utc(d.year, d.month, d.day)).inDays;
  if (gap == 0) return 'TODAY';
  if (gap == 1) return 'YESTERDAY';
  return '${_days[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';
}

/// Groups [items] by day, then by series (newest first at both levels); a notification with no
/// date lands on the oldest day, labelled `EARLIER`. [sourceId] keeps one source only.
/// [followed] supplies each series' title, cover and issue colours.
List<UpdateDay> groupNotifications(
  List<UpdateNotification> items,
  DateTime now, {
  String? sourceId,
  List<FollowedSeries> followed = const [],
}) {
  final by = {for (final f in followed) '${f.sourceId}\u0000${f.seriesKey}': f};
  final days = <String, Map<String, List<UpdateNotification>>>{};
  final order = <String>[];
  final sorted = [...items.where((n) => sourceId == null || n.sourceId == sourceId)]
    ..sort((a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
  for (final n in sorted) {
    final label = n.createdAt == null ? 'EARLIER' : dayLabel(n.createdAt!, now);
    final day = days.putIfAbsent(label, () {
      order.add(label);
      return {};
    });
    day.putIfAbsent('${n.sourceId}\u0000${n.seriesKey}', () => []).add(n);
  }
  return [
    for (final label in order)
      UpdateDay(label: label, groups: [
        for (final e in days[label]!.entries)
          () {
            final rows = e.value;
            final f = by[e.key];
            final chapters = [
              for (final n in rows)
                (notificationId: n.id, chapterKey: n.chapterKey, chapterNumber: n.chapterNumber, title: n.chapterTitle, read: n.isRead),
            ]..sort((a, b) {
                final x = a.chapterNumber, y = b.chapterNumber;
                if (x != null && y != null && x != y) return x.compareTo(y);
                return a.notificationId.compareTo(b.notificationId);
              });
            return SeriesUpdate(
              sourceId: rows.first.sourceId,
              seriesKey: rows.first.seriesKey,
              title: f?.title ?? rows.first.seriesKey,
              coverUrl: f?.coverUrl,
              ambient: f?.ambient,
              followedId: f?.id ?? rows.first.followedSeriesId,
              chapters: chapters,
              newestAt: rows.first.createdAt,
            );
          }(),
      ],),
  ];
}
