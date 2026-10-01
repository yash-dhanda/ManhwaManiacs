// ignore_for_file: directives_ordering, prefer_const_constructors
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show SizedBox;
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

import '../novel/novel_rig.dart' show pumpGlassNovel;
import '../reader/glass_reader_rig.dart' show GlassReaderOrigin, pumpGlassReader;
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import '../../cinematic/feature/feature_test_support.dart' show Recorder;
import 'glass_audit.dart';
import 'glass_qa_screens.dart';

/// mobile/45 I5 (3.3, 14.7): every screen at text scale 1.0, 1.3 and 2.0 with no overflow, no text under 11 px (G9), and the 3.3
/// rules that are visible in the tree: dock labels hide from 1.6, Bold Text and Legible text clip nothing.
/// `MM_QA_REPORT=1` (a `--dart-define`) lists findings instead of failing.
void main() {
  final report = const bool.fromEnvironment('MM_QA_REPORT');
  const special = {ScreenId.reader, ScreenId.readAll, ScreenId.novel};
  for (final scale in const [1.0, 1.3, 2.0]) {
    for (final s in kGlassQaScreens) {
      glassQaWidgets('${s.id.id} at text scale $scale: no overflow, nothing under 11 px', (t) async {
        GlassQaRig? rig;
        final old = FlutterError.onError;
        final errors = <String>[];
        FlutterError.onError = (d) {
          final text = d.toString();
          final w = RegExp(r'relevant error-causing widget was:\n\s+(.*)\n\s+(.*)').firstMatch(text);
          errors.add('${d.exception.toString().split('\n').first} <- ${w?.group(2) ?? w?.group(1) ?? ''}');
        };
        addTearDown(() => FlutterError.onError = old);
        if (special.contains(s.id)) {
          if (s.id == ScreenId.novel) {
            await pumpGlassNovel(t, textScale: scale);
          } else {
            await pumpGlassReader(t,
                origin: s.id == ScreenId.readAll ? GlassReaderOrigin.readAll : GlassReaderOrigin.manifest,
                extra: [readerRepositoryProvider.overrideWithValue(GlassQaReader(Recorder()))]); // the reader chrome clamps at 1.3 by itself
          }
          await t.pump(const Duration(milliseconds: 1500));
        } else {
          rig = await pumpGlassQa(t, s, textScale: scale);
        }
        final found = await auditGlass(t, platform: TargetPlatform.iOS, screen: s.id);
        final bad = [for (final v in found) if (v.rule == GlassRule.g9TextSize) v];
        if (report) {
          for (final v in bad) {
            debugPrint('TS ${s.id.id} $scale $v');
          }
          for (final e in errors) {
            debugPrint('TS ${s.id.id} $scale ERR $e');
          }
        } else {
          expect([...bad.map((v) => v.toString()), ...errors], isEmpty, reason: [...bad, ...errors].join('\n'));
        }
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
