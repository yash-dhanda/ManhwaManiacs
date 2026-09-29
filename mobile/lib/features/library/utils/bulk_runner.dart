import 'dart:async';

import 'package:manhwamaniacs/core/utils/result.dart';

/// Stops a run from starting new items (`Stop` in the select-mode bar); running ones finish.
class BulkCancel {
  bool _stopped = false;
  bool get stopped => _stopped;
  void stop() => _stopped = true;
}

typedef BulkOutcome = ({int total, int done, int failed, bool stopped});

/// Runs [task] over [items] with at most [concurrency] in flight (cinematic 8.9 select mode).
Future<BulkOutcome> runBulk<T>(
  List<T> items,
  Future<Result<void>> Function(T) task, {
  int concurrency = 4,
  BulkCancel? cancel,
  void Function(int done, int failed)? onProgress,
}) async {
  var next = 0, done = 0, failed = 0, started = 0;
  Future<void> worker() async {
    while (next < items.length && !(cancel?.stopped ?? false)) {
      final item = items[next++];
      started++;
      Result<void> r;
      try {
        r = await task(item);
      } catch (_) {
        failed++;
        onProgress?.call(done, failed);
        continue;
      }
      if (r.isErr) {
        failed++;
      } else {
        done++;
      }
      onProgress?.call(done, failed);
    }
  }

  await Future.wait([for (var i = 0; i < concurrency.clamp(1, items.isEmpty ? 1 : items.length); i++) worker()]);
  return (total: items.length, done: done, failed: failed, stopped: started < items.length);
}

/// "Favourited 12 series.", "11 of 12 done, 1 failed.", "Stopped: 4 done.".
String summarizeBulkOutcome(BulkOutcome o, {required String verb}) {
  if (o.stopped) return 'Stopped: ${o.done} done.';
  if (o.failed > 0) return '${o.done} of ${o.total} done, ${o.failed} failed.';
  return '$verb ${o.done} series.';
}
