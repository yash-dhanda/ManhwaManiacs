import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';

void main() {
  test('a skin restart keeps the server changed in Settings', () {
    final memo = ApiUrlMemo('https://old.example');
    final first = ProviderContainer(overrides: [memo.scopeOverride], observers: [memo]);
    expect(first.read(apiBaseUrlProvider), 'https://old.example');
    first.read(apiBaseUrlProvider.notifier).state = 'https://new.example';
    first.dispose();
    // The restart builds a new scope from the same memo.
    final second = ProviderContainer(overrides: [memo.scopeOverride], observers: [memo]);
    addTearDown(second.dispose);
    expect(second.read(apiBaseUrlProvider), 'https://new.example');
  });
}
