// ignore_for_file: require_trailing_commas
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

import '../../skins/cinematic/feature/feature_test_support.dart' show Recorder;
import '../../skins/glass/novel/novel_rig.dart' show pumpGlassNovel;
import '../../skins/glass/qa/glass_qa_screens.dart';
import '../../skins/glass/reader/glass_reader_rig.dart' show GlassReaderOrigin, pumpGlassReader;
import '../support/shot_harness.dart';
import '../support/skin_shots.dart';

/// The Glass alignment pass (as `cinematic/alignment_shots_test.dart`): every Glass screen and every Settings section at both
/// iPhone widths and two text scales, with the device's safe areas. A layout error (overflow) fails the test; writes PNGs only when
/// `MM_PROOF_DIR` is set, and with `MM_AUDIT_REPORT=1` prints each paragraph that sits closer than 12 px to a side edge:
///
///   MM_PROOF_DIR=/tmp/galign flutter test test/screenshots/glass/alignment_shots_test.dart
const _sizes = {'390': (Size(390, 844), EdgeInsets.only(top: 47, bottom: 34)), '430': (Size(430, 932), EdgeInsets.only(top: 59, bottom: 34))};
const _scales = [1.0, 1.3];
const _readers = {ScreenId.reader, ScreenId.readAll, ScreenId.novel};

/// Paragraphs on screen whose box comes within 12 px of the left or right edge (a hint for the visual pass, never a failure).
void _edges(WidgetTester t, String name, double width) {
  for (final e in find.byType(RichText).evaluate()) {
    final p = e.renderObject as RenderParagraph?;
    if (p == null || !p.attached || !p.hasSize) continue;
    final text = p.text.toPlainText().trim();
    if (text.isEmpty) continue;
    final box = MatrixUtils.transformRect(p.getTransformTo(null), Offset.zero & p.size);
    if (box.right <= 0 || box.left >= width || box.bottom <= 0) continue;
    if (box.left < 12 || box.right > width - 12) {
      debugPrint('EDGE $name "${text.length > 40 ? text.substring(0, 40) : text}" ${box.left.toStringAsFixed(1)}..${box.right.toStringAsFixed(1)} y${box.top.round()}');
    }
  }
}

Future<void> _shot(WidgetTester t, String name, double width) async {
  final dir = proofDir;
  if (dir != null) await writeShot(t, find.byKey(kSkinShotKey), '$dir/$name.png', pixelRatio: 1.5);
  if (Platform.environment['MM_AUDIT_REPORT'] == '1') _edges(t, name, width);
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    // A screen that listens for connectivity or the tilt sensor gets an answer while the PNG is written (real async).
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(const MethodChannel('dev.fluttercommunity.plus/connectivity_status'), (_) async => null);
    m.setMockMethodCallHandler(const MethodChannel('dev.fluttercommunity.plus/connectivity'), (_) async => <String>['wifi']);
    for (final c in ['dev.fluttercommunity.plus/sensors/method', 'dev.fluttercommunity.plus/sensors/accelerometer']) {
      m.setMockMethodCallHandler(MethodChannel(c), (_) async => null);
    }
  });

  group('screens', () {
    for (final s in kGlassQaScreens) {
      for (final size in _sizes.entries) {
        for (final scale in _scales) {
          final name = 'screens/${s.id.id}-${size.key}-x$scale';
          glassQaWidgets(name, (t) async {
            final (logical, padding) = size.value;
            GlassQaRig? rig;
            if (s.id == ScreenId.novel) {
              await pumpGlassNovel(t, size: logical, textScale: scale, padding: padding, boundaryKey: kSkinShotKey);
            } else if (_readers.contains(s.id)) {
              // The reader chrome clamps its own text scale (glass 3.3).
              await pumpGlassReader(t,
                  size: logical,
                  padding: padding,
                  origin: s.id == ScreenId.readAll ? GlassReaderOrigin.readAll : GlassReaderOrigin.manifest,
                  extra: [readerRepositoryProvider.overrideWithValue(GlassQaReader(Recorder()))]);
            } else {
              rig = await pumpGlassQa(t, s, size: logical, padding: padding, textScale: scale, boundaryKey: kSkinShotKey);
            }
            if (rig == null) await t.pump(const Duration(milliseconds: 1500));
            await _shot(t, name, logical.width);
            if (rig != null) {
              await disposeGlassQa(t, rig);
            } else {
              await t.pumpWidget(const SizedBox());
              await t.pump(const Duration(seconds: 11));
            }
          });
        }
      }
    }
  });

  // Each Settings section at full length: a tall window shows the whole section in one frame.
  group('settings', () {
    for (final section in SettingsSection.values) {
      for (final size in _sizes.entries) {
        for (final scale in _scales) {
          final name = 'settings/${section.slug}-${size.key}-x$scale';
          glassQaWidgets(name, (t) async {
            final (logical, padding) = size.value;
            final rig = await pumpGlassQa(t, GlassQaScreen(ScreenId.settings, Routes.settings(section)),
                size: Size(logical.width, 2400), padding: padding, textScale: scale, boundaryKey: kSkinShotKey);
            await _shot(t, name, logical.width);
            await disposeGlassQa(t, rig);
          });
        }
      }
    }
  });
}
