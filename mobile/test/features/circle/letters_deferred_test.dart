import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/circle/utils/letters_deferred.dart';

void main() {
  late List<LetterDraft> sent;
  Future<void> send(LetterDraft d) async => sent.add(d);
  setUp(() => sent = []);

  PendingLetter schedule({bool mature = false}) => scheduleLetter(toProfileIds: const [7], sourceId: 's', seriesKey: 'k', mature: mature, send: send);

  test('undo cancels', () => fakeAsync((a) {
        final p = schedule();
        a.elapse(const Duration(seconds: 3));
        p.undo();
        a.elapse(const Duration(seconds: 20));
        expect(sent, isEmpty);
        expect(p.cancelled, isTrue);
      }),);

  test('the window ending sends once', () => fakeAsync((a) {
        final p = schedule();
        a.elapse(const Duration(milliseconds: 9999));
        expect(sent, isEmpty);
        a.elapse(const Duration(milliseconds: 1));
        expect(sent, hasLength(1));
        p.undo();
        unawaitedFlush(p);
        a.elapse(const Duration(seconds: 20));
        expect(sent, hasLength(1));
        expect(sent.single.note, isNull);
      }),);

  test('a note sends at once with the note', () => fakeAsync((a) {
        final p = schedule();
        p.sendWithNote('  The tower arc is unreal  ');
        a.flushMicrotasks();
        expect(sent.single.note, 'The tower arc is unreal');
        a.elapse(const Duration(seconds: 20));
        expect(sent, hasLength(1));
      }),);

  test('the provider flushes on pause and drops only mature letters', () => fakeAsync((a) {
        TestWidgetsFlutterBinding.ensureInitialized();
        final c = ProviderContainer();
        final n = c.read(pendingLettersProvider.notifier);
        n.schedule(toProfileIds: const [1], sourceId: 's', seriesKey: 'a', mature: true, send: send);
        n.schedule(toProfileIds: const [2], sourceId: 's', seriesKey: 'b', mature: false, send: send);
        n.schedule(toProfileIds: const [3], sourceId: 's', seriesKey: 'c', mature: false, send: send);
        expect(c.read(pendingLettersProvider), hasLength(3));
        n.dropMature();
        expect(c.read(pendingLettersProvider), hasLength(2));
        n.didChangeAppLifecycleState(AppLifecycleState.paused);
        a.flushMicrotasks();
        expect(sent.map((d) => d.seriesKey), ['b', 'c']);
        expect(c.read(pendingLettersProvider), isEmpty);
        a.elapse(const Duration(seconds: 20));
        expect(sent, hasLength(2));
        c.dispose();
      }),);

  test('flush sends every pending letter', () => fakeAsync((a) {
        final c = ProviderContainer();
        final n = c.read(pendingLettersProvider.notifier);
        n.schedule(toProfileIds: const [1], sourceId: 's', seriesKey: 'a', mature: false, send: send);
        n.schedule(toProfileIds: const [2], sourceId: 's', seriesKey: 'b', mature: true, send: send);
        n.flushPendingLetters();
        a.flushMicrotasks();
        expect(sent, hasLength(2));
        c.dispose();
      }),);
}

void unawaitedFlush(PendingLetter p) => p.flush();
