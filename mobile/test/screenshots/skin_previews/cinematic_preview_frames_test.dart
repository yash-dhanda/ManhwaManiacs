// ignore_for_file: directives_ordering
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/home/providers/home_feed_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/tonight_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../skins/cinematic/feature/feature_test_support.dart' show featureTheme;
import '../../skins/cinematic/tonight/tonight_test_support.dart';
import '../support/shot_covers.dart';
import '../support/shot_harness.dart';
import '../support/shot_network.dart';
import '../support/skin_shots.dart';

/// The Cinematic edition preview (cinematic 8.30.3): 36 frames of Tonight scrolled 600 px down
/// and back, 360 x 640 px at device pixel ratio 1.0, captured at 6 fps.
///
///   MM_WRITE_PREVIEWS=1 flutter test test/screenshots/skin_previews/cinematic_preview_frames_test.dart
///
/// Without MM_WRITE_PREVIEWS the frames are rendered and discarded. The feed is the harness's
/// `test/fixtures/home/ready.json` (`design/previews/demo-feed.json` is not published yet); covers
/// are painted in-repo, there is no 18+ content and no profile data.
const _size = SkinShotSize('preview', Size(360, 640), 1.0, EdgeInsets.zero);
const _easeDrift = Cubic(0.37, 0, 0.63, 1);
const _frames = 36;

double previewOffset(int i) => i < 18 ? 600 * _easeDrift.transform(i / 17) : 600 * _easeDrift.transform((35 - i) / 17);

Map<String, String> _coverTitles() {
  final out = <String, String>{};
  void walk(Object? j) {
    if (j is Map<String, dynamic>) {
      final cover = j['cover_url'];
      if (cover is String && cover.startsWith('/sources/')) out[cover] = ((j['title'] as String?) ?? cover.split('/')[4]).replaceAll('-', ' ');
      j.values.forEach(walk);
    } else if (j is List<dynamic>) {
      j.forEach(walk);
    } else if (j is String && j.startsWith('/sources/') && j.endsWith('/cover')) {
      out.putIfAbsent(j, () => j.split('/')[4].replaceAll('-', ' '));
    }
  }

  walk(jsonDecode(File('test/fixtures/home/ready.json').readAsStringSync()));
  return out;
}

void main() {
  setUpAll(loadAppFonts);
  setUpAll(setUpShotCoverCache);

  testWidgets('render the 36 preview frames', (tester) async {
    final write = (Platform.environment['MM_WRITE_PREVIEWS'] ?? '') == '1';
    var seed = 0;
    final png = <String, Uint8List>{};
    for (final e in _coverTitles().entries) {
      final bytes = await tester.runAsync(() => ShotCoverArt(title: e.value, seed: seed++).toPng(width: 480, height: 720));
      png[e.key] = bytes!;
    }
    addShotCovers(png);
    SharedPreferences.setMockInitialValues({'mm.tonight.typed.u1p1': '{"date":"2026-09-30","variant":"normal"}'});
    final prefs = await SharedPreferences.getInstance();
    final dir = Directory('assets/skin_previews/cinematic');
    if (write) dir.createSync(recursive: true);
    await captureSkinWidget(
      tester,
      name: 'cinematic-preview',
      size: _size,
      overrides: [
        clockProvider.overrideWithValue(() => kTonightNow),
        homeFeedProvider.overrideWith(() => FakeHomeFeed(viewOf(loadFeed('ready')))),
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(debugShowCheckedModeBanner: false, theme: featureTheme(TargetPlatform.android), home: const TonightScreen()),
      proofDirOverride: Directory.systemTemp.createTempSync('preview').path,
      settle: (t) async {
        await settleTonight(t, by: const Duration(seconds: 4));
        await pumpUntilCoversLoad(t, rounds: 8);
        final position = t.state<ScrollableState>(find.descendant(of: find.byType(CustomScrollView), matching: find.byType(Scrollable)).first).position;
        for (var i = 0; i < _frames; i++) {
          position.jumpTo(previewOffset(i));
          await t.pump(const Duration(milliseconds: 167));
          final name = i.toString().padLeft(3, '0');
          if (write) {
            await writeShot(t, find.byKey(kSkinShotKey), '${dir.path}/$name.png', pixelRatio: 1.0);
          } else {
            final boundary = t.renderObject<RenderRepaintBoundary>(find.byKey(kSkinShotKey));
            await t.runAsync(() async => (await boundary.toImage()).dispose());
          }
        }
      },
    );
  });

  test('the scroll path is a 600 px there-and-back over 36 frames', () {
    expect(previewOffset(0), 0);
    expect(previewOffset(17), closeTo(600, 1e-9));
    expect(previewOffset(18), closeTo(600, 1e-9));
    expect(previewOffset(35), 0);
    expect(List.generate(_frames, previewOffset).every((v) => v >= 0 && v <= 600), isTrue);
  });
}
