// ignore_for_file: directives_ordering, require_trailing_commas, prefer_const_constructors, avoid_redundant_argument_values, unnecessary_lambdas, unnecessary_await_in_return
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

import 'qa_accepted.dart';
import 'qa_audit.dart';
import 'qa_screens.dart';

/// B3: every `ScreenId` at the four proof sizes on iOS and Android, audited by `qa_audit.dart`.
/// `MM_WRITE_QA=1` writes each screen's violations to `docs/redesign/proof/mobile-24/audit/`.
void main() {
  final write = Platform.environment['MM_WRITE_QA'] == '1';
  final report = Platform.environment['MM_QA_REPORT'] == '1'; // list violations instead of failing
  final dir = Directory('../docs/redesign/proof/mobile-24/audit');

  for (final s in kQaScreens) {
    for (final entry in kQaSizes.entries) {
      for (final platform in const [TargetPlatform.iOS, TargetPlatform.android]) {
        final plat = platform == TargetPlatform.iOS ? 'ios' : 'android';
        final size = entry.value;
        final name = '${s.id.id}-${size.width.round()}x${size.height.round()}-$plat';
        testWidgets('qa $name', (t) async {
          debugDefaultTargetPlatformOverride = platform;
          try {
            final rig = await pumpQaScreen(t, s, size: size, platform: platform);
            final want = s.id == ScreenId.readerLanding ? '/library' : Uri.parse(s.location).path;
            expect(Uri.parse(rig.at).path, want, reason: '${s.id.id} was redirected');
            final all = await auditScreen(t, platform: platform);
            final open = [for (final v in all) if (!kQaAccepted.any((a) => a.covers(s.id.id, v))) v];
            if (write) {
              dir.createSync(recursive: true);
              File('${dir.path}/$name.json').writeAsStringSync(const JsonEncoder.withIndent('  ').convert({
                'screen': s.id.id,
                'size': '${size.width.round()}x${size.height.round()}',
                'platform': plat,
                'violations': [for (final v in open) v.toJson()],
                'accepted': all.length - open.length,
              }));
            }
            await disposeQa(t, rig);
            if (report) {
              for (final v in open) {
                debugPrint('QAV $name $v');
              }
            } else {
              expect(open, isEmpty, reason: open.join('\n'));
            }
          } finally {
            debugDefaultTargetPlatformOverride = null;
          }
        });
      }
    }
  }
}
