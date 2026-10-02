// ignore_for_file: require_trailing_commas
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/app/skin_app.dart';
import 'package:manhwamaniacs/app/skin_boot.dart';
import 'package:manhwamaniacs/core/platform/app_icon_switcher.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/profiles/providers/skin_outbox.dart';
import 'package:manhwamaniacs/skins/contract.g.dart' show Routes;
import 'package:manhwamaniacs/skins/glass/glass_motion_recorder.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/skin_card.dart';
import 'package:manhwamaniacs/skins/skins.dart';

import 'release_rig.dart';

/// release/01 F3 and the 4.0.1 release checks, through the real boot of both skins: see README.md.

Finder get _cine => find.byWidgetPredicate((w) => w.runtimeType.toString().startsWith('Cine'));
Finder get _glass => find.byWidgetPredicate((w) => RegExp(r'^_?Glass').hasMatch(w.runtimeType.toString()));

const _cineToast = 'Now in the Cinematic edition.';
const _glassToast = 'Switched to Glass';

/// Cinematic Settings, Edition: `Switch to Glass`, then the sheet's `Restart in Glass`, until the second boot has settled.
Future<void> _switchToGlass(WidgetTester t, ReleaseRig rig) async {
  final boots = rig.boots;
  await t.ensureVisible(find.text('Switch to Glass'));
  await t.pump();
  await t.tap(find.text('Switch to Glass'));
  await settle(t, ms: 800);
  await t.tap(find.text('Restart in Glass'));
  await pumpUntil(t, () => rig.boots == boots + 1);
  await settle(t, ms: 3000);
}

/// Glass Appearance and skin: the Cinematic card, then the alert's `Restart in Cinematic`.
Future<void> _switchToCinematic(WidgetTester t, ReleaseRig rig) async {
  final boots = rig.boots;
  final card = find.byWidgetPredicate((w) => w is GlassSkinCard && w.skin == SkinId.cinematic);
  await t.ensureVisible(card);
  await t.pump();
  await t.tap(card);
  await settle(t, ms: 800);
  expect(find.text('Stay in Glass'), findsOneWidget);
  await t.tap(find.text('Restart in Cinematic'));
  await pumpUntil(t, () => rig.boots == boots + 1);
  await settle(t, ms: 3000);
}

/// The arrival toast's Undo: a restart back with no confirm and no alert.
Future<void> _undo(WidgetTester t, ReleaseRig rig) async {
  final boots = rig.boots;
  await t.tap(find.text('Undo'));
  await t.pump(const Duration(milliseconds: 100));
  expect(find.text('Restart in Glass'), findsNothing);
  expect(find.text('Restart in Cinematic'), findsNothing);
  await pumpUntil(t, () => rig.boots == boots + 1);
  await settle(t, ms: 3000);
}

/// The app goes to the background and comes back (Android applies a queued icon alias at the pause).
Future<void> _background(WidgetTester t) async {
  for (final s in const [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused, AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
    t.binding.handleAppLifecycleStateChanged(s);
    await t.pump();
  }
  await t.runAsync(() async {});
  await t.pump();
}

void _expectLanded(ReleaseRig rig, SkinId skin, String route) {
  expect(rig.skins.last, skin);
  expect(rig.prefs.getString(kSkinActiveKey), skin.name);
  expect(rig.routes.last, route);
  expect(rig.at, route, reason: 'the same route, not the picker or sign-in');
  expect(rig.container.read(activeProfileProvider)?.id, 1, reason: 'the session is kept');
  expect(skin == SkinId.glass ? _cine : _glass, findsNothing, reason: 'nothing of the other skin is in the tree');
}

void main() {
  late GlassMotionRecorder recorder;
  setUp(() => GlassMotion.recorder = recorder = GlassMotionRecorder());
  tearDown(() => GlassMotion.recorder = GlassMotionRecorder.instance);

  for (final platform in const [TargetPlatform.iOS, TargetPlatform.android]) {
    for (final skin in const [SkinId.cinematic, SkinId.glass]) {
      releaseWidgets('boots into the stored ${skin.name} skin on its return route, with no restart', platform: platform, (t) async {
        final rig = await pumpRelease(t, skin: skin, route: '/library');
        expect(rig.skins, [skin]);
        expect(rig.at, '/library');
        expect(skin == SkinId.glass ? _glass : _cine, findsWidgets);
        expect(skin == SkinId.glass ? _cine : _glass, findsNothing);
        await disposeRelease(t);
      });
    }

    releaseWidgets('a stored legacy value boots Cinematic; a leftover mm.skin.debug is removed and ignored', platform: platform, (t) async {
      final rig = await pumpRelease(t, skin: SkinId.cinematic, skinName: 'legacy', profileSkins: {1: null, 2: null}, prefs: {kSkinDebugKey: 'glass'});
      expect(rig.skins, [SkinId.cinematic], reason: 'no restart: the profile has no skin and the default is Cinematic');
      expect(rig.prefs.containsKey(kSkinDebugKey), isFalse);
      expect(_cine, findsWidgets);
      expect(_glass, findsNothing);
      await disposeRelease(t);
    });

    releaseWidgets('Cinematic to Glass from Settings: same route, session, outbox PATCH, SKIN RESTART, downloads resume, icon, 10 s toast', platform: platform, (t) async {
      final rig = await pumpRelease(t, skin: SkinId.cinematic, route: '/settings/appearance', iconFollow: true);
      final resumes = rig.resumes;
      await _switchToGlass(t, rig);

      expect(rig.skins, [SkinId.cinematic, SkinId.glass]);
      _expectLanded(rig, SkinId.glass, '/settings/appearance');
      expect(rig.api.skinPatches, [(1, 'glass')], reason: 'the outbox PATCH reached the server after the restart');
      expect(rig.prefs.getString(kSkinOutboxKey), isNull);
      expect(rig.prefs.getInt(kSkinT0Key), isNull, reason: 'SKIN RESTART read mm.skin.t0 and cleared it');
      expect(rig.prefs.getInt(kSkinRestartLastKey), isNotNull);
      expect(rig.resumes, greaterThan(resumes), reason: 'DownloadsLifecycleGate re-queues pending downloads after the restart');
      if (platform == TargetPlatform.iOS) {
        expect(rig.icon.calls, ['ios:$kGlassIosIconName']);
      } else {
        expect(rig.icon.calls, isEmpty, reason: 'Android never toggles the alias inside the restart');
        expect(rig.prefs.getString(kIconPendingKey), kAndroidGlassIconAlias);
        await _background(t);
        expect(rig.icon.calls, ['android:$kAndroidGlassIconAlias']);
      }

      // The arrival notice: the skin's face, no underline, gone after its 10 s.
      expect(find.text(_glassToast), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      expectSkinText(find.byType(SkinApp));
      await settle(t, ms: 10500);
      expect(find.text(_glassToast), findsNothing);
      await disposeRelease(t);
    });

    releaseWidgets("Glass's Undo restarts back into Cinematic with no alert; the icon ends on the skin running at the pause", platform: platform, (t) async {
      final rig = await pumpRelease(t, skin: SkinId.cinematic, route: '/settings/appearance', iconFollow: true);
      await _switchToGlass(t, rig);
      await _undo(t, rig);
      expect(rig.skins, [SkinId.cinematic, SkinId.glass, SkinId.cinematic]);
      _expectLanded(rig, SkinId.cinematic, '/settings/appearance');
      expect(find.text(_cineToast), findsNothing, reason: 'an Undo is not undoable');
      expect(rig.api.skinPatches.last, (1, 'cinematic'));
      if (platform == TargetPlatform.iOS) {
        expect(rig.icon.calls, ['ios:$kGlassIosIconName', 'ios:null']);
      } else {
        expect(rig.icon.calls, isEmpty);
        await _background(t);
        expect(rig.icon.calls, ['android:$kAndroidCinematicIconAlias'], reason: 'one call, for the skin running at the pause');
      }
      await disposeRelease(t);
    });

    releaseWidgets('Glass to Cinematic through the alert and the 615 ms melt; Cinematic\'s Undo goes back to Glass', platform: platform, (t) async {
      final rig = await pumpRelease(t, skin: SkinId.glass, route: '/settings/appearance', iconFollow: true);
      await _switchToCinematic(t, rig);
      expect(recorder.entries.map((e) => (e.label, e.plannedMs)), contains(('SKIN MELT', 615)));
      expect(rig.skins, [SkinId.glass, SkinId.cinematic]);
      _expectLanded(rig, SkinId.cinematic, '/settings/appearance');
      expect(rig.api.skinPatches, [(1, 'cinematic')]);
      expect(find.text(_cineToast), findsOneWidget);
      expectSkinText(find.byType(SkinApp));

      await _undo(t, rig);
      expect(rig.skins, [SkinId.glass, SkinId.cinematic, SkinId.glass]);
      _expectLanded(rig, SkinId.glass, '/settings/appearance');
      expect(find.text(_glassToast), findsNothing, reason: 'an Undo is not undoable');
      if (platform == TargetPlatform.iOS) {
        expect(rig.icon.calls, ['ios:null', 'ios:$kGlassIosIconName'], reason: 'Undo is an explicit choice');
      } else {
        expect(rig.prefs.getString(kIconPendingKey), kAndroidGlassIconAlias);
      }
      await disposeRelease(t);
    });

    releaseWidgets("Glass profile form: the active profile's Skin row set to Cinematic restarts through the alert, same session", platform: platform, (t) async {
      final rig = await pumpRelease(t, skin: SkinId.glass, route: '/profiles/1/edit');
      final cine = find.text('Cinematic');
      await t.ensureVisible(cine.last);
      await t.pump();
      await t.tap(cine.last);
      await settle(t, ms: 400);
      await t.ensureVisible(find.text('Save changes'));
      await t.pump();
      await t.tap(find.text('Save changes'));
      await settle(t, ms: 1200);
      expect(find.text('Stay in Glass'), findsOneWidget);
      final boots = rig.boots;
      await t.tap(find.text('Restart in Cinematic'));
      await pumpUntil(t, () => rig.boots == boots + 1);
      await settle(t, ms: 3000);
      expect(rig.skins, [SkinId.glass, SkinId.cinematic]);
      expect(rig.prefs.getString(kSkinActiveKey), 'cinematic');
      expect(rig.container.read(activeProfileProvider)?.id, 1, reason: 'the session is kept');
      expect(rig.api.skinPatches.last, (1, 'cinematic'));
      expect(_glass, findsNothing);
      await disposeRelease(t);
    });

    releaseWidgets("Glass onboarding: picking Cinematic's look restarts into Cinematic's Formats step, same session", platform: platform, (t) async {
      final rig = await pumpRelease(t, skin: SkinId.glass, route: '/welcome?step=2', onboardingStep: '2');
      expect(find.text('Pick a look'), findsOneWidget);
      final boots = rig.boots;
      await t.tap(find.text('Cinematic'));
      await pumpUntil(t, () => rig.boots == boots + 1);
      await settle(t, ms: 3000);
      expect(rig.skins, [SkinId.glass, SkinId.cinematic]);
      expect(rig.routes.last, '/welcome?step=2');
      expect(rig.prefs.getString(kSkinActiveKey), 'cinematic');
      expect(rig.container.read(activeProfileProvider)?.id, 1, reason: 'the run neither signs out nor repeats the pick');
      expect(rig.api.skinPatches.last, (1, 'cinematic'));
      expect(rig.at, startsWith('/welcome'));
      expect(_glass, findsNothing);
      await disposeRelease(t);
    });

    releaseWidgets('Cinematic onboarding: Choose Glass restarts into Glass and carries on, same session', platform: platform, (t) async {
      final rig = await pumpRelease(t, skin: SkinId.cinematic, route: '/welcome?step=1', onboardingStep: '1');
      final boots = rig.boots;
      await t.ensureVisible(find.text('Choose Glass'));
      await t.pump();
      await t.tap(find.text('Choose Glass'));
      await pumpUntil(t, () => rig.boots == boots + 1, maxMs: 8000);
      await settle(t, ms: 3000);
      expect(rig.skins, [SkinId.cinematic, SkinId.glass]);
      expect(rig.prefs.getString(kSkinActiveKey), 'glass');
      expect(rig.container.read(activeProfileProvider)?.id, 1);
      expect(rig.api.skinPatches.last, (1, 'glass'));
      expect(rig.at, startsWith('/welcome'));
      expect(_cine, findsNothing);
      await disposeRelease(t);
    });

    releaseWidgets('icon follow off: a switch and its Undo never touch the icon', platform: platform, (t) async {
      final rig = await pumpRelease(t, skin: SkinId.cinematic, route: '/settings/appearance');
      await _switchToGlass(t, rig);
      await _undo(t, rig);
      await _background(t);
      expect(rig.icon.calls, isEmpty);
      expect(rig.prefs.getString(kIconPendingKey), isNull);
      await disposeRelease(t);
    });

    releaseWidgets('each profile boots its own skin: a mismatch and a profile switch restart with no toast and no icon', platform: platform, (t) async {
      final rig = await pumpRelease(t, skin: SkinId.cinematic, route: '/library', profileSkins: {1: 'glass', 2: 'cinematic'}, iconFollow: true);
      await pumpUntil(t, () => rig.boots == 2);
      await settle(t, ms: 3000);
      expect(rig.skins, [SkinId.cinematic, SkinId.glass], reason: "Riya's profile says Glass");
      _expectLanded(rig, SkinId.glass, '/library');
      expect(find.text(_glassToast), findsNothing);

      // A later profile switch restarts through the picker's own flow (the boot check judges only the boot profile).
      rig.router.go(Routes.profiles());
      await settle(t, ms: 1500);
      await t.tap(find.text('Aarav').first);
      await pumpUntil(t, () => rig.boots == 3);
      await settle(t, ms: 3000);
      expect(rig.skins.last, SkinId.cinematic, reason: "Aarav's profile says Cinematic");
      expect(rig.container.read(activeProfileProvider)?.id, 2);
      expect(rig.at, isNot(startsWith('/login')));
      expect(find.text(_cineToast), findsNothing);
      expect(find.text('Undo'), findsNothing);
      await _background(t);
      expect(rig.icon.calls, isEmpty, reason: 'never a profile switch or a boot restart');
      expect(rig.prefs.getString(kIconPendingKey), isNull);
      expect(rig.api.skinPatches, isEmpty, reason: 'a profile hand-off changes no profile');
      await disposeRelease(t);
    });

    releaseWidgets('the library and downloads survive the restart, in both skins', platform: platform, (t) async {
      final rig = await pumpRelease(t, skin: SkinId.cinematic, route: Routes.library());
      Future<void> visit(String route, String text) async {
        rig.router.go(route);
        await settle(t, ms: 1500);
        expect(find.textContaining(text, findRichText: true), findsWidgets, reason: '$route in ${rig.skins.last.name}');
      }

      await visit(Routes.library(), 'Series 2');
      await visit(Routes.downloads(), 'Series 1');
      rig.router.go('/settings/appearance');
      await settle(t, ms: 1500);
      await _switchToGlass(t, rig);
      await visit(Routes.library(), 'Series 2');
      await visit(Routes.downloads(), 'Series 1');
      rig.router.go('/settings/appearance');
      await settle(t, ms: 1500);
      await _switchToCinematic(t, rig);
      await visit(Routes.library(), 'Series 2');
      await disposeRelease(t);
    });
  }
}
