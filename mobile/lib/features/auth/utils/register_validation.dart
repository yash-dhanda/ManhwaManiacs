/// Register rules shared by both skins (mobile S04, glass 8.4).
final RegExp kUsernamePattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9_.\-]{2,63}$');
final RegExp kEmailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

bool usernameValid(String v) => kUsernamePattern.hasMatch(v);
bool passwordLongEnough(String v) => v.length >= 8;
bool confirmationMatches(String password, String confirm) => password == confirm;
bool emailValidOrBlank(String v) => v.trim().isEmpty || kEmailPattern.hasMatch(v.trim());

class RegisterDraft {
  const RegisterDraft({this.username = '', this.password = '', this.confirm = '', this.invite = '', this.email = ''});
  final String username, password, confirm, invite, email;
}

bool canSubmitRegister(RegisterDraft d, {required bool inviteRequired}) =>
    usernameValid(d.username) &&
    passwordLongEnough(d.password) &&
    confirmationMatches(d.password, d.confirm) &&
    emailValidOrBlank(d.email) &&
    (!inviteRequired || d.invite.trim().isNotEmpty);
