import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/suggestion.dart';
import 'package:manhwamaniacs/features/library/providers/intelligence_providers.dart';
import 'package:manhwamaniacs/features/library/repositories/ask_repository.dart';
import 'package:manhwamaniacs/skins/glass/screens/picks/ask_controller.dart';

import 'ai_rig.dart';

ProviderContainer box(RoutedAdapter a) {
  final c = ProviderContainer(overrides: [askRepositoryProvider.overrideWithValue(AskRepository(dioOf(a))), suggestAvailabilityProvider.overrideWith((ref) async => const SuggestionAvailability(available: true, reason: 'ok', remainingToday: 5))]);
  addTearDown(c.dispose);
  c.listen(askControllerProvider, (_, __) {});
  return c;
}

void settle(FakeAsync fa) {
  for (var i = 0; i < 6; i++) {
    fa.flushMicrotasks();
    fa.elapse(const Duration(milliseconds: 5));
  }
}

void main() {
  test('Only my sources off asks the world with limit 12; on asks the library with limit 8', () async {
    final a = RoutedAdapter({'/library/world/suggest': (_) => suggestOk(12), '/library/suggest': (_) => suggestOk(8)});
    final c = box(a);
    final n = c.read(askControllerProvider.notifier);
    await n.ask((prompt: 'p', onlyMine: false, useTaste: true, novels: false));
    await n.ask((prompt: 'p', onlyMine: true, useTaste: false, novels: false));
    expect(a.calls[0].path, '/library/world/suggest');
    expect(a.calls[0].data, {'prompt': 'p', 'limit': 12, 'use_taste': true});
    expect(a.calls[1].path, '/library/suggest');
    expect(a.calls[1].data, {'prompt': 'p', 'limit': 8, 'use_taste': false});
    expect(c.read(askControllerProvider).items, hasLength(8));
    expect(c.read(askControllerProvider).remaining, 9);
  });

  test('Novels mode is always local with content_kind novel', () async {
    final a = RoutedAdapter({'/library/suggest': (_) => suggestOk(3)});
    final c = box(a);
    await c.read(askControllerProvider.notifier).ask((prompt: 'p', onlyMine: false, useTaste: true, novels: true));
    expect(a.calls.single.path, '/library/suggest');
    expect(a.calls.single.data, {'prompt': 'p', 'limit': 8, 'use_taste': true, 'content_kind': 'novel'});
  });

  test('no matches and the shelf-empty code read as failures, branching on code not status', () async {
    final a = RoutedAdapter({
      '/library/world/suggest': (_) => const Reply({'items': <Object>[], 'remaining_today': 4}),
      '/library/suggest': (_) => apiError(409, 'suggest_shelf_empty'),
    });
    final c = box(a);
    final n = c.read(askControllerProvider.notifier);
    await n.ask((prompt: 'p', onlyMine: false, useTaste: true, novels: false));
    expect(c.read(askControllerProvider).failure?.code, 'ai_no_matches');
    await n.ask((prompt: 'p', onlyMine: true, useTaste: true, novels: false));
    expect(c.read(askControllerProvider).failure?.code, 'suggest_shelf_empty');
  });

  test('a 429 is budget exhausted or rate limited by its code; only rate_limited retries by itself', () {
    fakeAsync((fa) {
      var n = 0;
      final a = RoutedAdapter({
        '/library/world/suggest': (_) {
          n++;
          return n == 1 ? apiError(429, 'rate_limited', headers: {'retry-after': '3'}) : suggestOk(2);
        },
        '/library/suggest': (_) => apiError(429, 'ai_budget_exhausted'),
      });
      final c = box(a);
      final ctl = c.read(askControllerProvider.notifier);
      ctl.ask((prompt: 'p', onlyMine: false, useTaste: true, novels: false));
      settle(fa);
      expect(c.read(askControllerProvider).failure?.code, 'rate_limited');
      expect(c.read(askControllerProvider).retryIn, 3);
      fa.elapse(const Duration(seconds: 3));
      settle(fa);
      expect(c.read(askControllerProvider).phase, AskPhase.results);
      expect(a.calls, hasLength(2));
      ctl.ask((prompt: 'p', onlyMine: true, useTaste: true, novels: false));
      settle(fa);
      fa.elapse(const Duration(seconds: 30));
      settle(fa);
      expect(c.read(askControllerProvider).failure?.code, 'ai_budget_exhausted');
      expect(a.calls, hasLength(3));
    });
  });

  test('Cancel cancels the request; 40 s abandons it with the timeout failure', () {
    fakeAsync((fa) {
      final a = RoutedAdapter({'/library/world/suggest': (_) => const Reply({}, hang: true)});
      final c = box(a);
      final ctl = c.read(askControllerProvider.notifier);
      ctl.ask((prompt: 'p', onlyMine: false, useTaste: true, novels: false));
      fa.elapse(const Duration(seconds: 5));
      expect(c.read(askControllerProvider).phase, AskPhase.asking);
      ctl.cancel();
      settle(fa);
      expect(c.read(askControllerProvider).phase, AskPhase.idle);
      ctl.ask((prompt: 'p', onlyMine: false, useTaste: true, novels: false));
      fa.elapse(const Duration(seconds: 39));
      expect(c.read(askControllerProvider).phase, AskPhase.asking);
      fa.elapse(const Duration(seconds: 2));
      settle(fa);
      expect(c.read(askControllerProvider).failure?.code, 'timeout');
    });
  });
}
