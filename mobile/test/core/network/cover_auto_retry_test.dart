import 'package:flutter_cache_manager/flutter_cache_manager.dart' show HttpExceptionWithStatus;
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/network/cover_auto_retry.dart';

void main() {
  const wait = Duration(milliseconds: 50);

  testWidgets('a failure reloads once after the delay, and only once per cover', (t) async {
    var reloads = 0;
    final r = CoverAutoRetry(() => reloads++, delay: wait);
    expect(r.pending, isFalse); // nothing runs until a load has failed
    r.failed('a', Exception('socket'));
    r.failed('a', Exception('socket')); // the error builder runs on every rebuild
    expect(r.pending, isTrue);
    await t.pump(wait);
    expect(reloads, 1);
    expect(r.pending, isFalse);
    r.failed('a', Exception('again')); // the retry failed too: no loop
    await t.pump(wait * 2);
    expect(reloads, 1);
    expect(r.pending, isFalse);
  });

  testWidgets('a cover the server says is gone is not retried', (t) async {
    var reloads = 0;
    final r = CoverAutoRetry(() => reloads++, delay: wait);
    r.failed('a', const HttpExceptionWithStatus(404, 'nope'));
    r.failed('b', const HttpExceptionWithStatus(410, 'gone'));
    expect(r.pending, isFalse);
    r.failed('c', const HttpExceptionWithStatus(502, 'bad gateway'));
    expect(r.pending, isTrue);
    await t.pump(wait);
    expect(reloads, 1);
  });

  testWidgets('reset drops the waiting reload and gives the next cover its own retry', (t) async {
    var reloads = 0;
    final r = CoverAutoRetry(() => reloads++, delay: wait);
    r.failed('a', Exception('x'));
    r.reset();
    expect(r.pending, isFalse);
    await t.pump(wait * 2);
    expect(reloads, 0);
    r.failed('b', Exception('x'));
    await t.pump(wait);
    expect(reloads, 1);
  });

  testWidgets('dispose leaves no timer behind', (t) async {
    var reloads = 0;
    final r = CoverAutoRetry(() => reloads++, delay: wait);
    r.failed('a', Exception('x'));
    r.dispose();
    expect(r.pending, isFalse);
    await t.pump(wait * 2);
    expect(reloads, 0);
  });
}
