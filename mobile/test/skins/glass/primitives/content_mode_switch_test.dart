import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/novels/providers/novels_gate_provider.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/primitives/content_mode_switch.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/test_overrides.dart';
import 'support.dart';

class _Profile extends ActiveProfileNotifier {
  static const one = ActiveProfile(id: 1, name: 'One', avatarKey: null, mood: Mood.neutral);
  static const two = ActiveProfile(id: 2, name: 'Two', avatarKey: null, mood: Mood.neutral);
  @override
  ActiveProfile? build() => one;
  void to(ActiveProfile p) => state = p;
}

Future<List<Override>> _overrides({required bool novels, Map<String, Object> seeded = const {}}) async {
  SharedPreferences.setMockInitialValues(seeded);
  final prefs = await SharedPreferences.getInstance();
  return [
    sharedPrefsProvider.overrideWithValue(prefs),
    authenticatedAuthOverride(),
    novelsGateProvider.overrideWith((ref) async => novels),
    novelsEnabledProvider.overrideWithValue(novels),
    activeProfileProvider.overrideWith(_Profile.new),
  ];
}

void main() {
  setUp(GlassHaptics.debugLog.clear);

  testWidgets('absent when the server does not enable novels', (tester) async {
    await tester.pumpWidget(primHost(const GlassContentModeSwitch(), overrides: await _overrides(novels: false)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Manga'), findsNothing);
    expect(find.text('Novels'), findsNothing);
  });

  testWidgets('sidebar: two segments; switching fires select, persists per profile and records the origin', (tester) async {
    await tester.pumpWidget(primHost(const GlassContentModeSwitch(), overrides: await _overrides(novels: true)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Manga'), findsOneWidget);
    expect(find.text('Novels'), findsOneWidget);
    await tester.tap(find.text('Novels'));
    await tester.pump(const Duration(milliseconds: 100));
    final c = primContainer(tester);
    expect(c.read(contentModeControllerProvider), ContentMode.novel);
    expect(c.read(sharedPrefsProvider).getString('mm.content-mode.u1p1'), 'novel');
    expect(c.read(lastModeSwitchOriginProvider), isNotNull);
    expect(GlassHaptics.debugLog.map((e) => e.event), contains(HapticEvent.select));
    // A second persona does not inherit it.
    (c.read(activeProfileProvider.notifier) as _Profile).to(_Profile.two);
    expect(c.read(contentModeControllerProvider), ContentMode.manga);
  });

  testWidgets('navRow: a compact capsule expands on press into the two segments and the "One setting" line, then collapses on a choice', (tester) async {
    await tester.pumpWidget(primHost(const GlassContentModeSwitch(variant: GlassContentModeVariant.navRow), overrides: await _overrides(novels: true)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Manga'), findsOneWidget);
    expect(find.text('Novels'), findsNothing);
    await tester.tap(find.text('Manga'));
    await pumpFor(tester, 700);
    expect(find.text('Novels'), findsOneWidget);
    expect(find.text('One setting for the whole app'), findsOneWidget);
    await tester.tap(find.text('Novels'));
    await pumpFor(tester, 700);
    expect(find.text('One setting for the whole app'), findsNothing);
    expect(primContainer(tester).read(contentModeControllerProvider), ContentMode.novel);
  });

  testWidgets('menu: a mutually exclusive pair of rows', (tester) async {
    await tester.pumpWidget(primHost(const SizedBox(width: 300, child: GlassContentModeSwitch(variant: GlassContentModeVariant.menu)), overrides: await _overrides(novels: true)));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Novels'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(primContainer(tester).read(contentModeControllerProvider), ContentMode.novel);
  });
}
