@Tags(['screenshots'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/primitives/reveal_slots.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/spotlight.dart';

import '../../skins/glass/home/home_rig.dart';
import '../glass_shell_shots_support.dart';
import '../support/shot_covers.dart';
import '../support/shot_harness.dart';
import '../support/shot_network.dart';
import '../support/skin_shots.dart';

/// The Glass edition preview (glass 8.25.1, 12.7): 36 frames, 166 ms apart, 216 x 468 px (the 360 x 780 preview ratio at 0.6: 270 x 585 came to 4.3 MB and 240 x 520 to 3.6 MB, both over the 3 MB cap).
///
///   MM_WRITE_PREVIEWS=1 flutter test test/screenshots/glass/skin_preview_capture_test.dart
///
/// Without MM_WRITE_PREVIEWS the frames are rendered and discarded. Real today: 000-011 Home with the spotlight paging once (the
/// demo feed is `test/fixtures/home`; covers are painted in-repo; nothing mature). The poster Zoom, the Dive into the reader and the
/// dock droplet belong to screens other lanes build; until they merge, 012-035 scroll Home down and back (the same render path),
/// and the owner recaptures once the series sheet and the reader are in (open issue in the report).
const _size = SkinShotSize('preview', Size(360, 780), 0.6, EdgeInsets.only(top: 40, bottom: 28));
const _frames = 36;
const _ease = Cubic(0.37, 0, 0.63, 1);

/// 0 for the spotlight frames, then a there-and-back scroll over 600 px.
double previewScroll(int i) {
  if (i < 12) return 0;
  final k = i - 12;
  return k < 12 ? 600 * _ease.transform(k / 11) : 600 * _ease.transform((23 - k) / 11);
}

Set<String> _coverPaths() {
  final paths = <String>{};
  void walk(Object? v) {
    if (v is Map) {
      for (final e in v.entries) {
        if (e.key == 'cover_url' && e.value is String) paths.add(Uri.parse(e.value as String).path);
        walk(e.value);
      }
    } else if (v is List) {
      v.forEach(walk);
    }
  }

  for (final f in Directory('test/fixtures/home').listSync().whereType<File>().where((f) => f.path.endsWith('.json'))) {
    walk(jsonDecode(f.readAsStringSync()));
  }
  return paths;
}

void main() {
  setUpAll(loadAppFonts);
  setUp(glassRevealSlots.reset);
  setUpAll(setUpShotCoverCache);

  test('the scroll path is a 600 px there-and-back after the spotlight frames', () {
    expect(previewScroll(0), 0);
    expect(previewScroll(11), 0);
    expect(previewScroll(23), closeTo(600, 1e-9));
    expect(previewScroll(35), 0);
    expect(List.generate(_frames, previewScroll).every((v) => v >= 0 && v <= 600), isTrue);
  });

  testWidgets('render the 36 preview frames', (t) async {
    final write = (Platform.environment['MM_WRITE_PREVIEWS'] ?? '') == '1';
    final out = <String, Uint8List>{};
    await t.runAsync(() async {
      var i = 0;
      for (final p in _coverPaths()) {
        out[p] = await ShotCoverArt(title: p.split('/').reversed.skip(1).first.replaceAll('-', ' '), seed: i++).toPng(width: 240, height: 360);
      }
    });
    addShotCovers(out);
    final s = await openShell(t, _size, settle: false, extra: [...homeOverrides(homeRepoOf('ready'))]);
    for (var i = 0; i < 6; i++) {
      await s.settle(600);
    }
    await pumpUntilCoversLoad(t, rounds: 25);
    final dir = Directory('assets/skin_previews/glass');
    if (write) dir.createSync(recursive: true);
    final scrollable = find.descendant(of: find.byType(CustomScrollView), matching: find.byType(Scrollable)).first;
    final position = t.state<ScrollableState>(scrollable).position;
    for (var i = 0; i < _frames; i++) {
      if (i == 4 && find.byType(Spotlight).evaluate().isNotEmpty) t.state<SpotlightState>(find.byType(Spotlight)).go(1);
      position.jumpTo(previewScroll(i));
      await t.pump(const Duration(milliseconds: 166));
      final name = i.toString().padLeft(3, '0');
      if (write) {
        await writeShot(t, find.byKey(kSkinShotKey), '${dir.path}/$name.png', pixelRatio: _size.pixelRatio);
      } else {
        await s.snap('unused', _size);
      }
    }
    await t.pumpWidget(const SizedBox.shrink());
    await t.pump(const Duration(minutes: 11));
  });
}
