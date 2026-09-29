import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/settings/services/server_switch.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('the first server read becomes home and keeps the plain scope', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    expect(downloadsServerPrefix(prefs, 'https://manhwamaniacs.xyz/'), '');
    expect(prefs.getString(kDownloadsHomeServerKey), 'https://manhwamaniacs.xyz');
    expect(downloadsScopeId(userId: 1, profileId: 2, serverPrefix: ''), 'u1p2');
  });

  test('another server gets an h{8 hex} prefix that never matches the home ids', () async {
    SharedPreferences.setMockInitialValues({kDownloadsHomeServerKey: 'https://a.example'});
    final prefs = await SharedPreferences.getInstance();
    final p = downloadsServerPrefix(prefs, 'https://B.example/');
    expect(p, matches(RegExp(r'^h[0-9a-f]{8}$')));
    expect(p, downloadsServerPrefix(prefs, 'https://b.example'));
    final other = downloadsScopeId(userId: 1, profileId: 2, serverPrefix: p)!;
    expect(other, isNot('u1p2'));
    expect(other, '${p}u1p2');
    // Back on the old server, the old rows are addressable again.
    expect(downloadsServerPrefix(prefs, 'https://a.example/'), '');
  });

  test('a missing half of the session has no scope', () {
    expect(downloadsScopeId(userId: null, profileId: 2, serverPrefix: 'h00000000'), isNull);
  });

  test('address comparison ignores case and a trailing slash', () {
    expect(normaliseAddress('HTTPS://X.example/'), 'https://x.example');
  });
}
