import 'package:manhwamaniacs/features/sources/utils/browse_freshness.dart' show FreshnessLabel;

/// The glass freshness sentences over the `cache` block of `GET /sources/{id}/series`: "Updated 12 min ago", or "Saved copy · 2 h"
/// when stale; null without a block. [offline] turns a saved copy into "Offline · saved copy from 2 h ago".
FreshnessLabel? glassFreshness(Map<String, dynamic>? cache, DateTime now, {bool offline = false}) {
  if (cache == null) return null;
  final stale = cache['stale'] == true || cache['status'] == 'stale';
  final at = cache['fetched_at'] is String ? DateTime.tryParse(cache['fetched_at'] as String) : null;
  final d = at == null ? null : now.difference(at);
  String? short, long;
  if (d != null) {
    if (d.inMinutes < 1) {
      short = 'just now';
      long = 'just now';
    } else if (d.inMinutes < 60) {
      short = '${d.inMinutes} min';
      long = '${d.inMinutes} min ago';
    } else if (d.inHours < 48) {
      short = '${d.inHours} h';
      long = '${d.inHours} h ago';
    } else {
      short = '${d.inDays} d';
      long = '${d.inDays} d ago';
    }
  }
  if (offline) return FreshnessLabel(text: long == null ? 'Offline · saved copy' : 'Offline · saved copy from $long', stale: true);
  if (stale) return FreshnessLabel(text: short == null ? 'Saved copy' : 'Saved copy · $short', stale: true);
  return FreshnessLabel(text: long == null ? 'Updated' : 'Updated $long', stale: false);
}
