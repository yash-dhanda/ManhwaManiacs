import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/network/request_limiter.dart';
import 'package:manhwamaniacs/features/reader/engine/paged_prefetch.dart';

void main() {
  test('visible view and the next are P0, pages +2 and +3 are P3', () {
    expect([for (var i = 0; i < 4; i++) pagedPrefetchPriority(i)], [RequestPriority.p0, RequestPriority.p0, RequestPriority.p3, RequestPriority.p3]);
  });

  test('warmThroughLimiter takes a slot at that priority and releases it', () async {
    final l = RequestLimiter();
    await warmThroughLimiter(l, RequestPriority.p3, () async {});
    expect(l.free(), l.capacity - 1);
    await expectLater(warmThroughLimiter(l, RequestPriority.p0, () async => throw StateError('x')), throwsStateError);
    expect(l.free(), l.capacity - 2);
  });
}
