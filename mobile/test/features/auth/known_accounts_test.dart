import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/auth/utils/known_accounts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences p;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    p = await SharedPreferences.getInstance();
  });

  test('most recent first', () async {
    await rememberAccount(p, 'a');
    await rememberAccount(p, 'b');
    expect(knownAccounts(p), ['b', 'a']);
  });

  test('caps at five', () async {
    for (final n in ['a', 'b', 'c', 'd', 'e', 'f']) {
      await rememberAccount(p, n);
    }
    expect(knownAccounts(p), ['f', 'e', 'd', 'c', 'b']);
  });

  test('case-insensitive de-duplication, newest spelling wins', () async {
    await rememberAccount(p, 'Yash');
    await rememberAccount(p, 'other');
    await rememberAccount(p, 'yash');
    expect(knownAccounts(p), ['yash', 'other']);
  });

  test('a corrupt value reads as empty; forgetAll clears', () async {
    await p.setString(kKnownAccountsKey, '{not json');
    expect(knownAccounts(p), isEmpty);
    await rememberAccount(p, 'a');
    await forgetAll(p);
    expect(knownAccounts(p), isEmpty);
  });
}
