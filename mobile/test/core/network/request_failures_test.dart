import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/network/network_failures.dart';
import 'package:manhwamaniacs/core/network/request_failures.dart';

void main() {
  final t0 = DateTime(2026, 9, 30, 12);

  test('three failures within 10 s make the server unreachable; a success clears it', () {
    final t = RequestFailureTracker();
    expect(t.failure(t0), isFalse);
    expect(t.failure(t0.add(const Duration(seconds: 4))), isFalse);
    expect(t.failure(t0.add(const Duration(seconds: 9))), isTrue);
    expect(t.success(), isFalse);
    expect(t.unreachable, isFalse);
  });

  test('failures older than the window do not count', () {
    final t = RequestFailureTracker();
    t.failure(t0);
    t.failure(t0.add(const Duration(seconds: 5)));
    expect(t.failure(t0.add(const Duration(seconds: 12))), isFalse);
  });

  test('the provider follows the failure and success streams', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.listen(requestFailuresProvider, (_, __) {});
    for (var i = 0; i < 3; i++) {
      reportNetworkFailure(const TimeoutError());
    }
    expect(c.read(requestFailuresProvider), isTrue);
    reportNetworkSuccess();
    expect(c.read(requestFailuresProvider), isFalse);
  });
}
