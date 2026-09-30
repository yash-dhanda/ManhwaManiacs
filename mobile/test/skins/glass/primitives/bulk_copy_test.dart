import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/skins/glass/primitives/select/bulk_copy.dart';
import 'package:manhwamaniacs/skins/glass/primitives/select/bulk_toolbar.dart';

void main() {
  test('the result toast is one line with Retry failed only when something failed', () {
    expect(bulkToast('marked read', 12, 1), (message: '12 marked read · 1 failed', action: 'Retry failed'));
    expect(bulkToast('marked read', 12, 0), (message: '12 marked read', action: null));
    expect(bulkToast('removed', 0, 3), (message: '3 failed', action: 'Retry failed'));
  });

  test('a batch_too_large answer halves the batch for the next try', () async {
    final calls = <int>[];
    final a = BulkAction<int>(
      id: 'mark',
      label: 'Mark read',
      glyph: BulkGlyphs.markRead,
      run: (ids, cancel) async {
        calls.add(ids.length);
        if (ids.length > 5) throw const ApiError(statusCode: 400, code: 'batch_too_large', message: 'too many');
        return BulkResult(ok: ids.length);
      },
    );
    final sizer = BulkBatchSizer();
    final ids = {for (var i = 0; i < 12; i++) i};
    final first = await runBulkBatched(a, ids, CancelToken(), sizer);
    expect(first.ok, 0);
    expect(first.failed.length, 12);
    expect(sizer.size, 6);
    final second = await runBulkBatched(a, ids, CancelToken(), sizer);
    expect(second.ok, 0); // 6 is still too large for this server
    expect(sizer.size, 3);
    final third = await runBulkBatched(a, ids, CancelToken(), sizer);
    expect(third.ok, 12);
    expect(third.failed, isEmpty);
    expect(calls, [12, 6, 6, 3, 3, 3, 3]);
  });

  test('Stop cancels the remaining batches', () async {
    final cancel = CancelToken();
    var n = 0;
    final a = BulkAction<int>(
      id: 'x',
      label: 'X',
      glyph: BulkGlyphs.download,
      run: (ids, c) async {
        n++;
        cancel.cancel('stop');
        return BulkResult(ok: ids.length);
      },
    );
    final r = await runBulkBatched(a, {1, 2, 3, 4}, cancel, BulkBatchSizer()..size = 2);
    expect(n, 1);
    expect(r.ok, 2);
  });
}
