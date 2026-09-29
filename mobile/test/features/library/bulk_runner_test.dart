import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/library/utils/bulk_runner.dart';

void main() {
  test('never more than 4 in flight, and every item runs', () async {
    final gates = <Completer<void>>[];
    var inflight = 0, peak = 0, ran = 0;
    final run = runBulk<int>(List.generate(12, (i) => i), (i) async {
      inflight++;
      peak = peak < inflight ? inflight : peak;
      final c = Completer<void>();
      gates.add(c);
      await c.future;
      inflight--;
      ran++;
      return const Ok(null);
    });
    for (var spin = 0; ran < 12; spin++) {
      await Future<void>.delayed(Duration.zero);
      if (gates.isNotEmpty) gates.removeAt(0).complete();
      expect(spin, lessThan(200));
    }
    final o = await run;
    expect(peak, 4);
    expect(o, (total: 12, done: 12, failed: 0, stopped: false));
  });

  test('progress counts failures and a thrown task is a failure', () async {
    final seen = <(int, int)>[];
    final o = await runBulk<int>([1, 2, 3], (i) async {
      if (i == 2) return Err(const UnknownError(message: 'x'));
      if (i == 3) throw StateError('boom');
      return const Ok(null);
    }, concurrency: 1, onProgress: (d, f) => seen.add((d, f)));
    expect(o, (total: 3, done: 1, failed: 2, stopped: false));
    expect(seen.last, (1, 2));
  });

  test('cancel stops new starts; running ones finish', () async {
    final cancel = BulkCancel();
    final o = await runBulk<int>(List.generate(10, (i) => i), (i) async {
      if (i == 3) cancel.stop();
      return const Ok(null);
    }, concurrency: 1, cancel: cancel);
    expect(o.stopped, isTrue);
    expect(o.done, 4);
  });

  test('summaries', () {
    expect(summarizeBulkOutcome((total: 12, done: 12, failed: 0, stopped: false), verb: 'Favourited'), 'Favourited 12 series.');
    expect(summarizeBulkOutcome((total: 12, done: 11, failed: 1, stopped: false), verb: 'Favourited'), '11 of 12 done, 1 failed.');
    expect(summarizeBulkOutcome((total: 12, done: 4, failed: 0, stopped: true), verb: 'Favourited'), 'Stopped: 4 done.');
  });
}
