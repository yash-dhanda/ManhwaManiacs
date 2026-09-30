// ignore_for_file: directives_ordering, require_trailing_commas, prefer_const_constructors, avoid_redundant_argument_values, unnecessary_lambdas, unnecessary_await_in_return
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/settings/providers/a11y_prefs_provider.dart';

import 'qa_accepted.dart';
import 'qa_screens.dart';

/// C6 (3.3, 14.7): every screen at phone and tablet, at text scale 1.0, 1.3 and 2.0, plain, with
/// OS Bold Text and with Hyperlegible text. Registered only with `MM_QA_MATRIX=1`.
/// No exception (no overflow); a paragraph that exceeds its lines must be one the contract ends
/// with an ellipsis (7 rows are single-line by rule). "Transmigration" in `type.cover` at 2.0 in
/// 358 px is `set_heading_test.dart`, and Bold Text adding 120 to `wght` is `type_test.dart`.
class _LegiblePrefs extends A11yPrefsNotifier {
  @override
  A11yPrefs build() => const A11yPrefs(legible: true);
}

void main() {
  if (Platform.environment['MM_QA_MATRIX'] != '1') return;
  const modes = ['plain', 'bold', 'legible'];
  for (final s in kQaScreens) {
    for (final size in const ['phone', 'tablet']) {
      for (final scale in const [1.0, 1.3, 2.0]) {
        for (final mode in modes) {
          testWidgets('scale ${s.id.id} $size x$scale $mode', (t) async {
            debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
            final prev = FlutterError.onError;
            FlutterError.onError = (d) {
              // Where each overflow comes from (`MM_QA_MATRIX=1` output).
              final where = d.toString().split('\n').where((l) => l.contains('.dart:') && l.contains('lib/')).take(1).join();
              debugPrint('FE ${s.id.id} $size x$scale $mode: ${d.exceptionAsString().split('\n').first} @ ${where.replaceAll(RegExp(r'.*mobile/'), '')}');
              prev?.call(d);
            };
            if (mode == 'bold') t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(boldText: true);
            try {
              final rig = await pumpQaScreen(t, s,
                  size: kQaSizes[size]!,
                  textScale: scale,
                  extra: [if (mode == 'legible') a11yPrefsProvider.overrideWith(_LegiblePrefs.new)]);
              final ex = t.takeException();
              expect(ex, isNull, reason: '${s.id.id} $size x$scale $mode: $ex');
              final bad = <String>[];
              for (final e in find.byType(RichText).evaluate()) {
                final ro = e.renderObject;
                final w = e.widget as RichText;
                if (ro is RenderParagraph && ro.hasSize && ro.didExceedMaxLines && w.overflow != TextOverflow.ellipsis) {
                  final txt = w.text.toPlainText().replaceAll('\n', ' ');
                  if (!kQaTruncations.any((a) => txt.contains(a.match))) bad.add(txt);
                }
              }
              expect(bad, isEmpty, reason: 'exceeds its lines without an ellipsis: $bad');
              await disposeQa(t, rig);
            } finally {
              debugDefaultTargetPlatformOverride = null;
              FlutterError.onError = prev;
              t.platformDispatcher.clearAccessibilityFeaturesTestValue();
            }
          });
        }
      }
    }
  }
}
