import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/settings/models/app_changelog.dart';
import 'package:manhwamaniacs/features/settings/utils/whats_new_policy.dart';

void main() {
  test('opens only when a stored build exists and is lower', () {
    expect(shouldAutoOpenWhatsNew(currentBuild: 58, lastSeenBuild: 57), isTrue);
    expect(shouldAutoOpenWhatsNew(currentBuild: 57, lastSeenBuild: 57), isFalse);
    expect(shouldAutoOpenWhatsNew(currentBuild: 56, lastSeenBuild: 57), isFalse);
    expect(shouldAutoOpenWhatsNew(currentBuild: 57, lastSeenBuild: null), isFalse);
    expect(shouldAutoOpenWhatsNew(currentBuild: 0, lastSeenBuild: 3), isFalse);
  });

  test('folio reads version, build and date', () {
    const e = ChangelogRelease(version: '3.5.0', build: 57, date: '2026-09-28', highlights: []);
    expect(formatReleaseFolio(e), '3.5.0 · BUILD 57 · 28 SEP 2026');
  });

  test('folio drops what the server left out', () {
    const e = ChangelogRelease(version: '3.5.0', build: 0, date: '', highlights: []);
    expect(formatReleaseFolio(e), '3.5.0');
  });
}
