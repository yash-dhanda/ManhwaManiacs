@Tags(['screenshots'])
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/models/auth_user.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/glass/dev/auth_fixtures.dart' show FakeAuth;
import 'package:manhwamaniacs/skins/glass/prefs.dart';

import '../glass_shell_shots_support.dart';
import '../support/shot_harness.dart';
import '../support/skin_shots.dart';

/// The mobile/39 proof captures (glass 8.25): Glass Settings and the skin switch. Written only when `MM_PROOF_DIR` is set; otherwise
/// rasterised and discarded.
class _Auth extends FakeAuth {
  _Auth(bool admin) : super(AuthAuthenticated(AuthUser(id: 1, username: 'demo', isAdmin: admin, createdAt: DateTime.utc(2026))));
}

class _NoProfile extends ActiveProfileNotifier {
  @override
  ActiveProfile? build() => null;
}

const _phone = SkinShotSize('phone', Size(390, 844), 3.0, EdgeInsets.only(top: 47, bottom: 34));

Future<ShotSession> _open(WidgetTester t, SkinShotSize size, String route, {bool admin = true, List<Override> extra = const [], bool reduced = false}) async {
  final s = await openShell(t, size, start: route, settle: false, extra: [authControllerProvider.overrideWith(() => _Auth(admin)), ...extra]);
  if (reduced) s.container.read(glassInAppPrefsProvider.notifier).setReduceMotion(true);
  for (var i = 0; i < 4; i++) {
    await s.settle(600);
  }
  return s;
}

Future<void> _end(WidgetTester t) async {
  await t.pumpWidget(const SizedBox.shrink());
  await t.pump(const Duration(minutes: 11));
}

void main() {
  setUpAll(loadAppFonts);
  const wide = kSkinShotTabletWide;
  final tablet = kSkinShotSizes[1];

  testWidgets('root: phone, tablet, desktop frame, non-admin, solid, contrast', (t) async {
    var s = await _open(t, _phone, '/settings');
    await s.snap('root', _phone);
    s = await _open(t, tablet, '/settings');
    await s.snap('root', tablet);
    s = await _open(t, wide, '/settings/appearance');
    await s.snap('root', wide);
    await s.snap('appearance', wide);
    s = await _open(t, _phone, '/settings', admin: false);
    await s.snap('root-non-admin', _phone);
    s = await _open(t, _phone, '/settings');
    s.container.read(glassInAppPrefsProvider.notifier).setSolidGlass(true);
    await s.settle(800);
    await s.snap('root-solid', _phone);
    s.container.read(glassInAppPrefsProvider.notifier)
      ..setSolidGlass(false)
      ..setIncreaseContrast(true);
    await s.settle(800);
    await s.snap('root-contrast', _phone);
    await _end(t);
  });

  testWidgets('search overlay, no match, hit pulse', (t) async {
    final s = await _open(t, _phone, '/settings');
    await t.tap(find.text('Search settings'));
    await s.settle(600);
    await t.enterText(find.byType(EditableText), 'solid');
    await s.settle(600);
    await s.snap('search-overlay', _phone);
    await t.enterText(find.byType(EditableText), 'zzzqq');
    await s.settle(600);
    await s.snap('search-no-match', _phone);
    await t.enterText(find.byType(EditableText), 'contrast');
    await s.settle(600);
    await t.tap(find.text('Increase contrast').first);
    await s.settle(300);
    await s.snap('search-hit-pulse', _phone);
    await _end(t);
  });

  testWidgets('appearance, skin cards under reduced motion, the switch alert', (t) async {
    var s = await _open(t, _phone, '/settings/appearance');
    await s.snap('appearance', _phone);
    await _end(t);
    s = await _open(t, _phone, '/settings/appearance', reduced: true);
    await s.snap('skin-cards-reduced-motion', _phone);
    await t.tap(find.text('Cinematic'));
    await s.settle(800);
    await s.snap('switch-alert', _phone);
    await t.tap(find.text('Stay in Glass'));
    await s.settle(600);
    await _end(t);
  });

  testWidgets('reader defaults, content, feedback, account, about, circle, ai', (t) async {
    for (final (route, name) in [
      ('/settings/reading-manga', 'reader-defaults-manga'),
      ('/settings/reading-novels', 'reader-defaults-novels'),
      ('/settings/listen', 'reader-defaults-listen'),
      ('/settings/ambient', 'reader-defaults-ambient'),
      ('/settings/content', 'content-gate'),
      ('/settings/feedback', 'feedback'),
      ('/settings/profile', 'account'),
      ('/settings/about', 'about-android'),
      ('/settings/circle', 'circle-privacy'),
      ('/settings/ai', 'ai-recaps'),
    ]) {
      final s = await _open(t, _phone, route);
      await s.snap(name, _phone);
      await _end(t);
    }
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final s = await _open(t, _phone, '/settings/about');
    await s.snap('about-ios', _phone);
    debugDefaultTargetPlatformOverride = null;
    await _end(t);
  });

  testWidgets('shortcuts on the tablet, no profile', (t) async {
    var s = await _open(t, tablet, '/settings/keyboard');
    await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await s.settle(800);
    await s.snap('shortcuts', tablet);
    s = await _open(t, _phone, '/settings/ai', extra: [activeProfileProvider.overrideWith(_NoProfile.new)]);
    await s.snap('no-profile', _phone);
    await _end(t);
  });
}
