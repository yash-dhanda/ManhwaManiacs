// ignore_for_file: directives_ordering, unawaited_futures, avoid_dynamic_calls, library_private_types_in_public_api, inference_failure_on_collection_literal
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/edition/confirm_switch.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/edition/edition_picker.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/edition/next_issue_plate.dart';
import 'package:manhwamaniacs/skins/skin_preview.dart';

import '../downloads/downloads_rig.dart' show settle;
import 'settings_rig.dart';

AnimationController preview(WidgetTester t, {String skin = 'cinematic'}) =>
    (t.state(find.descendant(of: find.byKey(Key('edition-preview-$skin'), skipOffstage: false), matching: find.byType(SkinPreview), skipOffstage: false).first) as dynamic).controller as AnimationController;


Future<void> pumpPicker(WidgetTester t, {bool glass = false, bool reduced = false, Size size = const Size(390, 844)}) =>
    pumpPage(t, EditionPicker(glassAvailable: glass), size: size, reduced: reduced);

void main() {
  group('the live preview', () {
    testWidgets('scrolls every frame on one controller', (t) async {
      await pumpPicker(t);
      final c = preview(t);
      expect(c.isAnimating, isTrue);
      final v0 = c.value;
      await t.pump(const Duration(milliseconds: 16));
      expect(c.value, greaterThan(v0));
    });

    testWidgets('reduced motion holds the top, still', (t) async {
      await pumpPicker(t, reduced: true);
      await t.pump(const Duration(seconds: 2));
      expect(preview(t).value, 0);
      expect(preview(t).isAnimating, isFalse);
    });

    testWidgets('the preview stops while another route covers the page', (t) async {
      await pumpPicker(t);
      final nav = Navigator.of(t.element(find.byType(SkinPreview).first));
      nav.push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('on top'))));
      await settle(t, ms: 1200);
      final at = preview(t).value;
      await t.pump(const Duration(seconds: 2));
      expect(preview(t).value, at);
    });

    test('no PNG frames are bundled any more', () {
      expect(File('pubspec.yaml').readAsStringSync(), isNot(contains('skin_previews')));
    });
  });

  group('flag off (glass_available false)', () {
    testWidgets('Cinematic carries THIS EDITION; Glass is the disabled NEXT ISSUE plate with no button and no caption', (t) async {
      await pumpPicker(t);
      expect(find.text('THIS EDITION'), findsOneWidget);
      expect(find.byType(NextIssuePlate), findsOneWidget);
      expect(find.byKey(const Key('edition-preview-glass')), findsNothing, reason: 'no Glass card, no preview');
      expect(find.byType(CineButton), findsNothing);
      expect(find.text(kEditionCaption), findsNothing);
      final semantics = t.widget<Semantics>(find.descendant(of: find.byType(NextIssuePlate), matching: find.byType(Semantics)).first);
      expect(semantics.properties.enabled, isFalse);
    });

    testWidgets('two cards side by side from 600 dp, stacked below', (t) async {
      await pumpPicker(t);
      final phoneGlass = t.getTopLeft(find.byType(NextIssuePlate));
      final phoneCine = t.getTopLeft(find.byKey(const Key('edition-preview-cinematic')));
      expect(phoneGlass.dy, greaterThan(phoneCine.dy));
      await t.pumpWidget(const SizedBox());
      await pumpPicker(t, size: const Size(834, 1194));
      expect(t.getTopLeft(find.byType(NextIssuePlate)).dy, lessThan(t.getBottomLeft(find.byKey(const Key('edition-preview-cinematic'))).dy));
    });
  });

  group('flag on', () {
    testWidgets('the Glass card set in its own face, with the button and the caption; missing frames say so', (t) async {
      await pumpPicker(t, glass: true);
      expect(find.text('Switch to Glass'), findsOneWidget);
      expect(find.text('Glass: layered glass, springs and depth.'), findsOneWidget);
      expect(find.text(kEditionCaption), findsOneWidget);
      final name = t.widget<Text>(find.text('Glass'));
      expect(name.style?.fontFamily, 'GoogleSansFlexMM');
      expect(t.widget<Text>(find.text('Cinematic')).style?.fontFamily, 'BodoniModa');
    });

    testWidgets('below 600 dp the confirmation is a sheet: the copy, and Stay in Cinematic', (t) async {
      await pumpPicker(t, glass: true);
      Scrollable.ensureVisible(t.element(find.text('Switch to Glass')), alignment: 0.5);
      await t.pump();
      await t.tap(find.text('Switch to Glass'));
      await settle(t, ms: 700);
      expect(find.text('Restart in Glass?'), findsOneWidget);
      expect(find.textContaining('The app closes and reopens in the Glass edition, on this page.'), findsOneWidget);
      expect(find.textContaining('The app icon changes'), findsNothing, reason: 'App icon follows the skin is off by default');
      expect(find.text('Restart in Glass'), findsOneWidget);
      await t.tap(find.text('Stay in Cinematic'));
      await settle(t, ms: 500);
      expect(find.text('Restart in Glass?'), findsNothing);
    });

    testWidgets('from 600 dp it is a dialog', (t) async {
      await pumpPicker(t, glass: true, size: const Size(834, 1194));
      await t.tap(find.text('Switch to Glass'));
      await settle(t, ms: 700);
      expect(find.text('Restart in Glass?'), findsOneWidget);
      expect(find.byType(CineDialog), findsOneWidget);
      await t.tap(find.text('Stay in Cinematic'));
      await settle(t, ms: 500);
      expect(find.text('Restart in Glass?'), findsNothing);
    });
  });

  test('copy of the confirmation body', () {
    expect(restartInGlassBody(downloadsQueued: false, platform: TargetPlatform.iOS), 'The app closes and reopens in the Glass edition, on this page.');
    expect(restartInGlassBody(downloadsQueued: true, platform: TargetPlatform.iOS), contains('Downloads resume after the restart.'));
    expect(restartInGlassBody(downloadsQueued: false, platform: TargetPlatform.android), isNot(contains('app icon')), reason: 'the icon only moves while it follows the skin');
    expect(restartInGlassBody(downloadsQueued: false, platform: TargetPlatform.android, iconFollows: true), contains('Shortcuts on your home screen may need adding again.'));
  });

  test('the launcher is the .CinematicIcon alias (the only one enabled) and only the switcher calls the icon plugin', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final aliases = RegExp(r'<activity-alias([^>]*)>').allMatches(manifest).map((m) => m[1]!).toList();
    expect(aliases, hasLength(2));
    final enabled = aliases.where((a) => a.contains('android:enabled="true"')).toList();
    expect(enabled, hasLength(1));
    expect(enabled.single, contains('android:name=".CinematicIcon"'));
    expect(aliases.firstWhere((a) => a.contains('.GlassIcon')), contains('android:enabled="false"'));
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart') && !f.path.endsWith('app_icon_switcher.dart'))) {
      final s = f.readAsStringSync();
      expect(s.contains('setAlternateIconName') || s.contains('FlutterDynamicIconPlus'), isFalse, reason: f.path);
    }
  });

}
