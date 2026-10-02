import 'package:manhwamaniacs/core/time/server_instant.dart';

class FreshnessLabel {
  const FreshnessLabel({required this.text, required this.stale});

  final String text;
  final bool stale;
}

/// From the `cache` block of `GET /sources/{id}/series`:
/// `UPDATED 12 MIN AGO`, or `SAVED COPY · 3 H` when stale; null without a block.
FreshnessLabel? browseFreshness(Map<String, dynamic>? cache, DateTime now) {
  if (cache == null) return null;
  final stale = cache['stale'] == true || cache['status'] == 'stale';
  final at = serverInstant(cache['fetched_at']);
  final ago = at == null ? null : _bucket(now.difference(at));
  if (stale) {
    return FreshnessLabel(
      text: ago == null ? 'SAVED COPY' : 'SAVED COPY · ${ago.$2}',
      stale: true,
    );
  }
  return FreshnessLabel(
      text: ago == null ? 'UPDATED' : 'UPDATED ${ago.$1}', stale: false,);
}

/// (`12 MIN AGO`, `12 MIN`) style pair.
(String, String) _bucket(Duration d) {
  if (d.inMinutes < 1) return ('JUST NOW', 'JUST NOW');
  if (d.inMinutes < 60) return ('${d.inMinutes} MIN AGO', '${d.inMinutes} MIN');
  if (d.inHours < 48) return ('${d.inHours} H AGO', '${d.inHours} H');
  return ('${d.inDays} D AGO', '${d.inDays} D');
}
