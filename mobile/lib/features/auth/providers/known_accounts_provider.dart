import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/auth/utils/known_accounts.dart' as store;
import 'package:manhwamaniacs/shared/providers/core_providers.dart';

/// The known usernames, most recent first. `remember` and `forgetAll` update the list.
class KnownAccountsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => store.knownAccounts(ref.read(sharedPrefsProvider));

  Future<void> remember(String username) async {
    await store.rememberAccount(ref.read(sharedPrefsProvider), username);
    state = store.knownAccounts(ref.read(sharedPrefsProvider));
  }

  Future<void> forgetAll() async {
    await store.forgetAll(ref.read(sharedPrefsProvider));
    state = const [];
  }
}

final knownAccountsProvider = NotifierProvider<KnownAccountsNotifier, List<String>>(KnownAccountsNotifier.new, name: 'knownAccounts');
