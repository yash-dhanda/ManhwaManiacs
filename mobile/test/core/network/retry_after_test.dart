import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/network/retry_after.dart';

void main() {
  final now = DateTime.utc(2026, 9, 29, 12);
  test('integer seconds', () => expect(parseRetryAfter('12', now: now), const Duration(seconds: 12)));
  test('http date', () => expect(parseRetryAfter('Tue, 29 Sep 2026 12:00:30 GMT', now: now), const Duration(seconds: 30)));
  test('past date is zero', () => expect(parseRetryAfter('Tue, 29 Sep 2026 11:00:00 GMT', now: now), Duration.zero));
  test('null and garbage', () {
    expect(parseRetryAfter(null, now: now), isNull);
    expect(parseRetryAfter('soon', now: now), isNull);
  });
}
