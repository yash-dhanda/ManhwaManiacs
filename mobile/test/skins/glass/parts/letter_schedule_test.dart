import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/circle/repositories/circle_repository.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/glass/parts/recommend/letter_schedule.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/test_overrides.dart';

class _Repo implements CircleRepository {
  _Repo(this.answer);
  Result<Object?> Function() answer;
  final sent = <List<int>>[];
  final from = <int?>[];

  @override
  // ignore: strict_raw_type
  Future<Result<dynamic>> sendLetter({required List<int> toProfileIds, required String sourceId, required String seriesKey, String? note, int? asProfileId}) async {
    sent.add(toProfileIds);
    from.add(asProfileId);
    return answer();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  // Undo fires the skin's haptics (the default skin is Cinematic since legacy went), so the
  // platform channel needs the test binding.
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ProviderContainer make(_Repo repo) {
    final c = ProviderContainer(overrides: [circleRepositoryProvider.overrideWithValue(repo), sharedPrefsProvider.overrideWithValue(prefs)]);
    addTearDown(c.dispose);
    return c;
  }

  test('the letter is sent as the profile that dropped it, even after a switch', () {
    fakeAsync((async) {
      final repo = _Repo(() => const Ok(null));
      final c = ProviderContainer(overrides: [circleRepositoryProvider.overrideWithValue(repo), sharedPrefsProvider.overrideWithValue(prefs), activeProfileOverride()]);
      addTearDown(c.dispose);
      scheduleLetter(c, toProfileId: 7, toName: 'Mira', sourceId: 's', seriesKey: 'k');
      async.elapse(const Duration(seconds: 11));
      expect(repo.from, [1]);
    });
  });

  test('the letter goes out when the toast leaves, not before', () {
    fakeAsync((async) {
      final repo = _Repo(() => const Ok(null));
      final c = make(repo);
      final h = scheduleLetter(c, toProfileId: 7, toName: 'Mira', sourceId: 's', seriesKey: 'k');
      async.flushMicrotasks();
      expect(repo.sent, isEmpty);
      final toasts = c.read(glassToastProvider);
      expect(toasts.single.spec.message, 'Recommended to Mira');
      expect(toasts.single.spec.undo, isNotNull);
      c.read(glassToastProvider.notifier).remove(toasts.single.id);
      async.flushMicrotasks();
      expect(repo.sent, [
        [7],
      ]);
      expect(h.sent, isTrue);
    });
  });

  test('Undo cancels the send', () {
    fakeAsync((async) {
      final repo = _Repo(() => const Ok(null));
      final c = make(repo);
      final h = scheduleLetter(c, toProfileId: 7, toName: 'Mira', sourceId: 's', seriesKey: 'k');
      expect(c.read(glassToastProvider.notifier).undoLast(), isTrue);
      final e = c.read(glassToastProvider).single;
      c.read(glassToastProvider.notifier).remove(e.id);
      async.flushMicrotasks();
      expect(repo.sent, isEmpty);
      expect(h.cancelled, isTrue);
    });
  });

  test('a failed send shows the error toast and calls onFailed; recipient_unavailable names the friend', () {
    fakeAsync((async) {
      final repo = _Repo(() => const Err(NetworkError(message: 'down')));
      final c = make(repo);
      var failed = 0;
      scheduleLetter(c, toProfileId: 7, toName: 'Mira', sourceId: 's', seriesKey: 'k', onFailed: () => failed++);
      c.read(glassToastProvider.notifier).remove(c.read(glassToastProvider).single.id);
      async.flushMicrotasks();
      expect(failed, 1);
      expect(c.read(glassToastProvider).single.spec.message, "Couldn't send that");

      repo.answer = () => const Err(ApiError(statusCode: 409, code: 'recipient_unavailable', message: 'x'));
      scheduleLetter(c, toProfileId: 8, toName: 'Noor', sourceId: 's', seriesKey: 'k2');
      final first = c.read(glassToastProvider).firstWhere((e) => e.spec.message.startsWith('Recommended'));
      c.read(glassToastProvider.notifier).remove(first.id);
      async.flushMicrotasks();
      expect(c.read(glassToastProvider).map((e) => e.spec.message), contains("Noor isn't taking recommendations any more."));
    });
  });

  test('Add a note only with a registered sheet and it hands the letter over', () {
    fakeAsync((async) {
      final repo = _Repo(() => const Ok(null));
      final c = make(repo);
      var noted = 0;
      scheduleLetter(c, toProfileId: 7, toName: 'Mira', sourceId: 's', seriesKey: 'k', onAddNote: () => noted++);
      final spec = c.read(glassToastProvider).single.spec;
      expect(spec.actionLabel, 'Add a note');
      spec.onAction!();
      c.read(glassToastProvider.notifier).remove(c.read(glassToastProvider).single.id);
      async.flushMicrotasks();
      expect(noted, 1);
      expect(repo.sent, isEmpty);
    });
  });
}
