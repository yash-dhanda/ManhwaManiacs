// ignore_for_file: directives_ordering, unawaited_futures, avoid_dynamic_calls, library_private_types_in_public_api, inference_failure_on_collection_literal
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/edition/confirm_switch.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/edition/edition_picker.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/edition/next_issue_plate.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/edition/preview_loop.dart';

import '../downloads/downloads_rig.dart' show settle;
import 'settings_rig.dart';

String frame(WidgetTester t, {String skin = 'cinematic'}) {
  final img = t.widget<Image>(find.byKey(Key('preview-frame-$skin'), skipOffstage: false));
  return (img.image as AssetImage).assetName;
}

int indexOf(String path) => int.parse(RegExp(r'(\d{3})\.png$').firstMatch(path)![1]!);


Future<void> pumpPicker(WidgetTester t, {bool glass = false, bool dry = false, bool reduced = false, Size size = const Size(390, 844)}) =>
    pumpPage(t, EditionPicker(glassAvailable: glass, dryRun: dry), size: size, reduced: reduced);

void main() {
  group('the loop', () {
    testWidgets('plays the 36 frames at 6 fps and wraps after 6 s', (t) async {
      await pumpPicker(t);
      final f0 = indexOf(frame(t));
      await t.pump(const Duration(milliseconds: 500));
      expect(indexOf(frame(t)), (f0 + 3) % 36, reason: '6 fps: three frames in 500 ms');
      await t.pump(const Duration(milliseconds: 6000));
      expect(indexOf(frame(t)), (f0 + 3) % 36, reason: '36 frames at 6 fps is 6 s');
    });

    testWidgets('reduced motion shows frame 000 only', (t) async {
      await pumpPicker(t, reduced: true);
      await t.pump(const Duration(seconds: 2));
      expect(frame(t), previewFramePath('cinematic', 0));
    });

    testWidgets('the ticker stops while another route covers the page', (t) async {
      await pumpPicker(t);
      final nav = Navigator.of(t.element(find.byType(PreviewLoop)));
      nav.push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('on top'))));
      await settle(t, ms: 1200);
      final at = frame(t);
      await t.pump(const Duration(seconds: 2));
      expect(frame(t), at);
    });

    test('the 36 frames are bundled and declared', () {
      for (var i = 0; i < 36; i++) {
        expect(File(previewFramePath('cinematic', i)).existsSync(), isTrue, reason: '$i');
      }
      expect(File('pubspec.yaml').readAsStringSync(), contains('- assets/skin_previews/cinematic/'));
    });
  });

  group('flag off (glass_available false)', () {
    testWidgets('Cinematic carries THIS EDITION; Glass is the disabled NEXT ISSUE plate with no button and no caption', (t) async {
      await pumpPicker(t);
      expect(find.text('THIS EDITION'), findsOneWidget);
      expect(find.byType(NextIssuePlate), findsOneWidget);
      expect(find.byKey(const Key('preview-frame-glass')), findsNothing, reason: 'no frames, no loop');
      expect(find.byType(CineButton), findsNothing);
      expect(find.text(kEditionCaption), findsNothing);
      final semantics = t.widget<Semantics>(find.descendant(of: find.byType(NextIssuePlate), matching: find.byType(Semantics)).first);
      expect(semantics.properties.enabled, isFalse);
    });

    testWidgets('two cards side by side from 600 dp, stacked below', (t) async {
      await pumpPicker(t);
      final phoneGlass = t.getTopLeft(find.byType(NextIssuePlate));
      final phoneCine = t.getTopLeft(find.byKey(const Key('preview-frame-cinematic')));
      expect(phoneGlass.dy, greaterThan(phoneCine.dy));
      await t.pumpWidget(const SizedBox());
      await pumpPicker(t, size: const Size(834, 1194));
      expect(t.getTopLeft(find.byType(NextIssuePlate)).dy, lessThan(t.getBottomLeft(find.byKey(const Key('preview-frame-cinematic'))).dy));
    });
  });

  group('flag on', () {
    testWidgets('the Glass card set in its own face, with the button and the caption; missing frames say so', (t) async {
      await pumpPicker(t, glass: true, dry: true);
      expect(find.text('Switch to Glass'), findsOneWidget);
      expect(find.text('Glass: layered glass, springs and depth.'), findsOneWidget);
      expect(find.text(kEditionCaption), findsOneWidget);
      expect(find.text('Preview frames arrive with the Glass build.'), findsOneWidget);
      final name = t.widget<Text>(find.text('Glass'));
      expect(name.style?.fontFamily, 'GoogleSansFlexMM');
      expect(t.widget<Text>(find.text('Cinematic')).style?.fontFamily, 'BodoniModa');
    });

    testWidgets('below 600 dp the confirmation is a sheet: the copy, and Stay in Cinematic', (t) async {
      await pumpPicker(t, glass: true, dry: true);
      Scrollable.ensureVisible(t.element(find.text('Switch to Glass')), alignment: 0.5);
      await t.pump();
      await t.tap(find.text('Switch to Glass'));
      await settle(t, ms: 700);
      expect(find.text('Restart in Glass?'), findsOneWidget);
      expect(find.textContaining('The app closes and reopens in the Glass edition, on this page.'), findsOneWidget);
      expect(find.textContaining('The app icon changes after you next close the app from Recents.'), findsOneWidget);
      expect(find.text('Restart in Glass'), findsOneWidget);
      await t.tap(find.text('Stay in Cinematic'));
      await settle(t, ms: 500);
      expect(find.text('Restart in Glass?'), findsNothing);
    });

    testWidgets('from 600 dp it is a dialog; the dry run plays the press and writes nothing', (t) async {
      final c = await pumpPicker(t, glass: true, dry: true, size: const Size(834, 1194)).then((_) => null);
      expect(c, isNull);
      await t.tap(find.text('Switch to Glass'));
      await settle(t, ms: 700);
      expect(find.text('Restart in Glass?'), findsOneWidget);
      await t.tap(find.text('Restart in Glass'));
      var seen = false;
      for (var i = 0; i < 25; i++) {
        await t.pump(const Duration(milliseconds: 100));
        seen |= find.byKey(const Key('press-blade-0')).evaluate().isNotEmpty;
      }
      expect(seen, isTrue, reason: 'the press played');
      await settle(t, ms: 1000);
      expect(find.byKey(const Key('press-blade-0')), findsNothing, reason: 'reversed and gone');
    });
  });

  test('copy of the confirmation body', () {
    expect(restartInGlassBody(downloadsQueued: false, platform: TargetPlatform.iOS), 'The app closes and reopens in the Glass edition, on this page.');
    expect(restartInGlassBody(downloadsQueued: true, platform: TargetPlatform.iOS), contains('Downloads resume after the restart.'));
    expect(restartInGlassBody(downloadsQueued: false, platform: TargetPlatform.android), contains('Shortcuts on your home screen may need adding again.'));
  });

  test('no alternate icon is declared and the icon plugin is never called', () {
    expect(File('ios/Runner/Info.plist').readAsStringSync(), isNot(contains('CFBundleAlternateIcons')));
    expect(File('android/app/src/main/AndroidManifest.xml').readAsStringSync(), isNot(contains('activity-alias')));
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      final s = f.readAsStringSync();
      expect(s.contains('setAlternateIconName') || s.contains('FlutterDynamicIconPlus'), isFalse, reason: f.path);
    }
  });

}
