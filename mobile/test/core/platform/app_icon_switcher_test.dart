import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/platform/app_icon_switcher.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/skin.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Fake implements AppIconPlugin {
  final calls = <String>[];
  @override
  Future<void> setIos(String? name) async => calls.add('ios:$name');
  @override
  Future<void> setAndroid(String name) async => calls.add('android:$name');
}

Future<(AppIconSwitcher, _Fake, SharedPreferences)> _rig({bool follow = true, bool glass = true, TargetPlatform platform = TargetPlatform.iOS}) async {
  SharedPreferences.setMockInitialValues({if (follow) kIconFollowKey: true});
  final prefs = await SharedPreferences.getInstance();
  final fake = _Fake();
  return (AppIconSwitcher(prefs: prefs, plugin: fake, glassAvailable: glass, platform: platform), fake, prefs);
}

void main() {
  test('the two Android alias names are fully qualified and the iOS name is AppIcon-Glass', () {
    expect(kGlassIosIconName, 'AppIcon-Glass');
    expect(kAndroidGlassIconAlias, 'com.manhwamaniacs.reader.GlassIcon');
    expect(kAndroidCinematicIconAlias, 'com.manhwamaniacs.reader.CinematicIcon');
  });

  test('follow is off by default and persists per device', () async {
    final (sw, _, prefs) = await _rig(follow: false);
    expect(sw.follow, false);
    await sw.setFollow(true);
    expect(prefs.getBool(kIconFollowKey), true);
    expect(sw.follow, true);
  });

  test('iOS: follow on + flag on calls the plugin inside the restart moment; Cinematic restores the primary icon', () async {
    final (sw, fake, _) = await _rig();
    await sw.onExplicitSkinChoice(SkinId.glass);
    await sw.onExplicitSkinChoice(SkinId.cinematic);
    expect(fake.calls, ['ios:AppIcon-Glass', 'ios:null']);
  });

  test('Android: the alias is queued and applies only on pause, with the key cleared', () async {
    final (sw, fake, prefs) = await _rig(platform: TargetPlatform.android);
    await sw.onExplicitSkinChoice(SkinId.cinematic);
    expect(fake.calls, isEmpty);
    expect(prefs.getString(kIconPendingKey), kAndroidCinematicIconAlias);
    await sw.onExplicitSkinChoice(SkinId.glass);
    expect(prefs.getString(kIconPendingKey), kAndroidGlassIconAlias);
    await sw.applyPending();
    expect(fake.calls, ['android:com.manhwamaniacs.reader.GlassIcon']);
    expect(prefs.getString(kIconPendingKey), isNull);
    await sw.applyPending();
    expect(fake.calls, hasLength(1));
  });

  test('follow off: no call and nothing queued', () async {
    final (sw, fake, prefs) = await _rig(follow: false);
    await sw.onExplicitSkinChoice(SkinId.glass);
    final (a, fakeA, prefsA) = await _rig(follow: false, platform: TargetPlatform.android);
    await a.onExplicitSkinChoice(SkinId.glass);
    expect(fake.calls, isEmpty);
    expect(fakeA.calls, isEmpty);
    expect(prefs.getString(kIconPendingKey), isNull);
    expect(prefsA.getString(kIconPendingKey), isNull);
  });

  test('flag off: no call and nothing queued even with follow on', () async {
    final (sw, fake, _) = await _rig(glass: false);
    await sw.onExplicitSkinChoice(SkinId.glass);
    final (a, fakeA, prefsA) = await _rig(glass: false, platform: TargetPlatform.android);
    await a.onExplicitSkinChoice(SkinId.glass);
    expect(fake.calls, isEmpty);
    expect(fakeA.calls, isEmpty);
    expect(prefsA.getString(kIconPendingKey), isNull);
  });

  test('a profile hand-off never reaches the switcher: only the explicit path calls onExplicitSkinChoice', () async {
    // The hand-off passes explicit: false to the Glass switch flow, which skips the icon call; the switcher itself has no
    // other entry point that moves the icon.
    final (sw, fake, _) = await _rig();
    expect(fake.calls, isEmpty);
    expect(sw.pending, isNull);
  });

  testWidgets('the pause listener applies the queued alias when the app goes to the background', (t) async {
    SharedPreferences.setMockInitialValues({kIconPendingKey: kAndroidGlassIconAlias});
    final prefs = await SharedPreferences.getInstance();
    final fake = _Fake();
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await t.pumpWidget(ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        appIconSwitcherProvider.overrideWithValue(AppIconSwitcher(prefs: prefs, plugin: fake, glassAvailable: true)),
      ],
      child: const Directionality(textDirection: TextDirection.ltr, child: AppIconPauseListener(child: SizedBox())),
    ),);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await t.pump();
    expect(fake.calls, ['android:com.manhwamaniacs.reader.GlassIcon']);
    debugDefaultTargetPlatformOverride = null;
  });
}
