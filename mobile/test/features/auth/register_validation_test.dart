import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/auth/utils/register_validation.dart';

void main() {
  test('username rules', () {
    expect(usernameValid('ab'), isFalse);
    expect(usernameValid('a.b'), isTrue);
    expect(usernameValid('a' * 64), isTrue);
    expect(usernameValid('a' * 65), isFalse);
    expect(usernameValid('_ab'), isFalse);
    expect(usernameValid('a b'), isFalse);
  });

  test('password, confirmation and email', () {
    expect(passwordLongEnough('1234567'), isFalse);
    expect(passwordLongEnough('12345678'), isTrue);
    expect(confirmationMatches('a', 'a'), isTrue);
    expect(confirmationMatches('a', 'b'), isFalse);
    expect(emailValidOrBlank(''), isTrue);
    expect(emailValidOrBlank('a@b.co'), isTrue);
    expect(emailValidOrBlank('a@b'), isFalse);
  });

  test('canSubmitRegister', () {
    const ok = RegisterDraft(username: 'abc', password: 'password1', confirm: 'password1');
    expect(canSubmitRegister(ok, inviteRequired: false), isTrue);
    expect(canSubmitRegister(ok, inviteRequired: true), isFalse);
    expect(canSubmitRegister(const RegisterDraft(username: 'abc', password: 'password1', confirm: 'password1', invite: 'x'), inviteRequired: true), isTrue);
    expect(canSubmitRegister(const RegisterDraft(username: 'abc', password: 'password1', confirm: 'nope'), inviteRequired: false), isFalse);
    expect(canSubmitRegister(const RegisterDraft(username: 'abc', password: 'password1', confirm: 'password1', email: 'bad'), inviteRequired: false), isFalse);
    expect(canSubmitRegister(const RegisterDraft(username: 'ab', password: 'password1', confirm: 'password1'), inviteRequired: false), isFalse);
  });
}
