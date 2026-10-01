import 'package:manhwamaniacs/features/updates/models/update_notification.dart';

/// `sourceId -> created_at` of the newest notification per source (from `GET /updates/notifications?limit=100`). The desktop-frame
/// pinned shelf reads "Updated 2 h ago" from it; a source with no entry reads "No updates yet".
Map<String, DateTime> latestUpdateBySource(Iterable<UpdateNotification> notifications) {
  final out = <String, DateTime>{};
  for (final n in notifications) {
    final at = n.createdAt;
    if (at == null) continue;
    final prev = out[n.sourceId];
    if (prev == null || at.isAfter(prev)) out[n.sourceId] = at;
  }
  return out;
}

/// "Updated 2 h ago" / "No updates yet".
String latestUpdateLine(DateTime? at, DateTime now) {
  if (at == null) return 'No updates yet';
  final d = now.difference(at);
  if (d.inMinutes < 1) return 'Updated just now';
  if (d.inMinutes < 60) return 'Updated ${d.inMinutes} min ago';
  if (d.inHours < 48) return 'Updated ${d.inHours} h ago';
  return 'Updated ${d.inDays} d ago';
}
