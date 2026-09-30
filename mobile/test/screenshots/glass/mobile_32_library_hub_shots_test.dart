@Tags(['screenshots'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/library/shelf_fixtures.dart';
import '../../skins/glass/library/library_rig.dart';
import '../support/shot_harness.dart';
import '../support/skin_shots.dart';

/// mobile/32 proof: Glass Library hub routes on fixtures; written only when MM_PROOF_DIR is set.
void main() {
  setUpAll(loadAppFonts);
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('dev.fluttercommunity.plus/connectivity_status'), (_) async => null);
  });
  for (final r in ['/library', '/library/collections', '/library/history', '/library/bookmarks', '/updates', '/downloads']) {
    testWidgets('capture $r', (t) async {
      final s = kSkinShotSizes.first;
      await pumpLibrary(t, FakeLib(series: [shelfSeries(1), shelfSeries(2), shelfSeries(3)]), start: r, size: s.logical);
      final dir = Platform.environment['MM_PROOF_DIR'];
      if (dir != null && dir.isNotEmpty) {
        await writeShot(t, find.byType(RepaintBoundary).first, '$dir/glass${r.replaceAll('/', '-')}-${s.name}.png', pixelRatio: s.pixelRatio);
      }
    });
  }
}
