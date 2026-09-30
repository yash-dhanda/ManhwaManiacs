import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/dev/auth_fixtures.dart';
import 'package:manhwamaniacs/skins/glass/routes/redirect_hold.dart';

import '../auth/auth_rig.dart';
import '../shell/shell_rig.dart';

void main() {
  testWidgets('with the hold on, a signed-in state stays on /login; with it off the guard redirects', (t) async {
    final rig = await pumpGlassShell(t, start: '/login', extra: [...glassAuthFixtureOverrides(const GlassAuthFixture(signedIn: true)), glassRedirectHoldProvider.overrideWith((ref) => true)]);
    expect(rig.at, '/login');
    rig.container.read(glassRedirectHoldProvider.notifier).state = false;
    await settleFor(t, 600);
    expect(rig.at, isNot('/login'));
  });

  testWidgets('with no hold the guard redirects from the start', (t) async {
    final rig = await pumpGlassShell(t, start: '/login', extra: glassAuthFixtureOverrides(const GlassAuthFixture(signedIn: true)));
    expect(rig.at, isNot('/login'));
  });
}
