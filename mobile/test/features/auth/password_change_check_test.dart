import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/auth/utils/password_change_check.dart';

void main() {
  test('each field reports its first issue', () {
    expect(checkPasswordChange(current: '', next: '', confirm: ''), (current: PasswordIssue.currentEmpty, next: PasswordIssue.newEmpty, confirm: null));
    expect(checkPasswordChange(current: 'a', next: 'short', confirm: 'short').next, PasswordIssue.tooShort);
    expect(checkPasswordChange(current: 'a', next: 'x' * 4097, confirm: 'x' * 4097).next, PasswordIssue.tooLong);
    expect(checkPasswordChange(current: 'samesame', next: 'samesame', confirm: 'samesame').next, PasswordIssue.same);
    expect(checkPasswordChange(current: 'old-pass', next: 'new-pass1', confirm: 'new-pass2').confirm, PasswordIssue.mismatch);
    expect(checkPasswordChange(current: 'old-pass', next: 'new-pass1', confirm: 'new-pass1'), (current: null, next: null, confirm: null));
  });
}
