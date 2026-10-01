/// What is wrong with a password-change form, per field (skin copy maps each to its line).
enum PasswordIssue { currentEmpty, newEmpty, tooShort, tooLong, mismatch, same }

/// The first issue of each field: Current, New and Confirm (null when the field is fine). At least 8 and at most 4,096
/// characters, different from the current one, and the confirmation must match.
({PasswordIssue? current, PasswordIssue? next, PasswordIssue? confirm}) checkPasswordChange({required String current, required String next, required String confirm}) {
  final c = current.isEmpty ? PasswordIssue.currentEmpty : null;
  final n = next.isEmpty
      ? PasswordIssue.newEmpty
      : next.length < 8
          ? PasswordIssue.tooShort
          : next.length > 4096
              ? PasswordIssue.tooLong
              : current.isNotEmpty && next == current
                  ? PasswordIssue.same
                  : null;
  final f = n == null && confirm != next ? PasswordIssue.mismatch : null;
  return (current: c, next: n, confirm: f);
}
