// ignore_for_file: require_trailing_commas, avoid_redundant_argument_values, prefer_const_declarations, directives_ordering, prefer_function_declarations_over_variables
// ignore_for_file: prefer_const_constructors, unnecessary_lambdas
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Size;
import 'package:flutter/widgets.dart' show SizedBox;
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

import 'glass_audit.dart';
import 'glass_qa_accepted.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import '../../cinematic/feature/feature_test_support.dart' show Recorder;
import 'glass_qa_screens.dart';
import '../novel/novel_rig.dart' show pumpGlassNovel;
import '../reader/glass_reader_rig.dart' show GlassReaderOrigin, pumpGlassReader;

/// B2 + I1: every `ScreenId` audited at 390 x 844 on iOS and Android and at 834 x 1194 on iOS.
/// `MM_PROOF_DIR` writes `<dir>/../audit/<screen>-<frame>-<platform>.json`; `MM_QA_REPORT=1` lists violations instead of failing.
void main() {
  final proof = (Platform.environment['MM_PROOF_DIR'] ?? '').trim();
  final report = Platform.environment['MM_QA_REPORT'] == '1';
  final dir = proof.isEmpty ? null : Directory('$proof/../audit');
  const runs = [
    ('phone', Size(390, 844), TargetPlatform.iOS),
    ('phone', Size(390, 844), TargetPlatform.android),
    ('tablet', Size(834, 1194), TargetPlatform.iOS),
  ];
  for (final s in kGlassQaScreens) {
    for (final (frame, size, platform) in runs) {
      final plat = platform == TargetPlatform.iOS ? 'ios' : 'android';
      final name = '${s.id.id}-$frame-$plat';
      glassQaWidgets('qa $name', (t) async {
        final special = s.id == ScreenId.reader || s.id == ScreenId.readAll || s.id == ScreenId.novel;
        final rig = special ? null : await pumpGlassQa(t, s, size: size, platform: platform);
        if (s.id == ScreenId.reader) await pumpGlassReader(t, size: size, platform: platform);
        if (s.id == ScreenId.readAll) await pumpGlassReader(t, size: size, platform: platform, origin: GlassReaderOrigin.readAll, extra: [readerRepositoryProvider.overrideWithValue(GlassQaReader(Recorder()))]);
        if (s.id == ScreenId.novel) await pumpGlassNovel(t, size: size, android: platform == TargetPlatform.android);
        if (special) await t.pump(const Duration(milliseconds: 1500));
        final want = s.id == ScreenId.readerLanding ? '/library' : Uri.parse(s.location).path;
        if (rig != null) expect(Uri.parse(rig.at).path, want, reason: '${s.id.id} was redirected');
        final all = await auditGlass(t, platform: platform, screen: s.id);
        final open = [for (final v in all) if (!kGlassQaAccepted.any((a) => a.covers(s.id.id, v))) v];
        if (dir != null) {
          dir.createSync(recursive: true);
          File('${dir.path}/$name.json').writeAsStringSync(const JsonEncoder.withIndent('  ').convert({
            'screen': s.id.id,
            'frame': frame,
            'platform': plat,
            'violations': [for (final v in open) v.toJson()],
            'accepted': all.length - open.length,
          }));
        }
        if (rig != null) {
          await disposeGlassQa(t, rig);
        } else {
          await t.pumpWidget(const SizedBox());
          await t.pump(const Duration(seconds: 11));
        }
        if (report) {
          for (final v in open) {
            debugPrint('QAV $name $v');
          }
        } else {
          expect(open, isEmpty, reason: open.join('\n'));
        }
      });
    }
  }
}
