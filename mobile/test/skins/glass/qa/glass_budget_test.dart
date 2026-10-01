// ignore_for_file: directives_ordering, prefer_const_constructors
import 'dart:io';

import 'package:flutter/painting.dart' show Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/glass/registry.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';

import 'glass_qa_screens.dart';

/// mobile/45 K (15.7, 2.4.1): layers and shapes per moment, over the real shell. The manga reader moments (scrubbing, guided view,
/// Rain), the novel reader and the third-layer-forces-solid rule are asserted by `reader/glass_reader_budget_test.dart`,
/// `ambient/ambient_reader_test.dart`, `novel/novel_reader_test.dart` and `skin_glass_test.dart`; `qa.md` lists their counts.
void main() {
  Future<(int, int, String)> measure(WidgetTester t, ScreenId id, Size size, {String? location, bool toast = false, int ms = 800}) async {
    final base = kGlassQaScreens.firstWhere((e) => e.id == id);
    final s = GlassQaScreen(id, location ?? base.location, novels: base.novels, extra: base.extra, more: base.more, signedOut: base.signedOut);
    final rig = await pumpGlassQa(t, s, size: size);
    if (toast) {
      rig.shell.container.read(glassToastProvider.notifier).show(const GlassToastSpec('Removed from your library', actionLabel: 'Undo'));
    }
    await t.pump(Duration(milliseconds: ms));
    final r = rig.shell.container.read(glassRegistryProvider);
    final detail = [for (final e in r.entries) '${e.label}/${e.shapes}${e.exempt ? '/exempt' : ''}${e.scrim ? '/scrim' : ''}'].join(', ');
    // Never more than two stacked layers over one point: the registry forces the lowest of a third to solid1.
    expect(r.forcedSolid.length, lessThanOrEqualTo(r.layers));
    await disposeGlassQa(t, rig);
    return (r.layers, r.shapes, detail);
  }

  final moments = <(String, ScreenId, Size, String?, bool, int, int)>[
    ('Library root with the Filters sheet open and an Undo toast', ScreenId.library, Size(390, 844), '/library?sheet=filters', true, 4, 8),
    ('Library root with the Filters sheet open, no toast', ScreenId.library, Size(390, 844), '/library?sheet=filters', false, 4, 8),
    ('Search open with a toast', ScreenId.discover, Size(390, 844), '/search', true, 3, 3),
    ('Desktop frame Library with the sidebar, a toast and a window', ScreenId.library, Size(1180, 820), null, true, 6, 6),
    ('Profile picker', ScreenId.profiles, Size(390, 844), null, false, 2, 2),
    ('Onboarding', ScreenId.onboarding, Size(390, 844), null, false, 2, 2),
    ('Wrapped', ScreenId.annual, Size(390, 844), null, false, 2, 2),
    ('Home', ScreenId.tonight, Size(390, 844), null, false, 4, 8),
    ('Series detail (deep link, full page)', ScreenId.feature, Size(390, 844), null, false, 6, 8),
  ];
  for (final (name, id, size, loc, toast, layers, shapes) in moments) {
    glassQaWidgets('$name: at most $layers layers and $shapes shapes', (t) async {
      final (l, sh, detail) = await measure(t, id, size, location: loc, toast: toast);
      // ignore: avoid_print
      print('BUDGET $name -> $l layers, $sh shapes [$detail]');
      expect(l, lessThanOrEqualTo(layers), reason: detail);
      expect(sh, lessThanOrEqualTo(shapes), reason: detail);
    });
  }

  test('the ambient field is one CustomPaint with three RadialGradients and no ImageFilter.blur', () {
    final src = [for (final l in File('lib/skins/glass/glass/ambient_field.dart').readAsLinesSync()) if (!l.trimLeft().startsWith('//')) l].join('\n');
    expect(RegExp(r'ui\.Gradient\.radial').allMatches(src).length, 1, reason: 'one radial gradient built per anchor, in a loop of three');
    expect(src.contains('ImageFilter.blur'), isFalse);
    expect(src.contains('BackdropFilter'), isFalse);
    expect(RegExp(r'CustomPaint\(').allMatches(src).length, 1);
    expect(src, contains('for (var i = 0; i < 3; i++)'));
  });

  test('no file under lib/skins/glass decodes or prefetches reader pages itself', () {
    final hits = <String>[];
    for (final f in Directory('lib/skins/glass').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      final text = f.readAsStringSync();
      for (final m in RegExp(r'precacheImage|instantiateImageCodec|decodeImageFromList|ResizeImage').allMatches(text)) {
        final line = text.substring(0, m.start).split('\n').length;
        hits.add('${f.path}:$line');
      }
    }
    // Contract-assigned uses only: the cover palette's 64 px decode (palette.dart), the skin-preview loop's own assets, the share card's render.
    final allowed = {'lib/skins/glass/glass/palette.dart', 'lib/skins/glass/screens/onboarding/skin_preview_loop.dart', 'lib/skins/glass/wrapped/share_card.dart'};
    expect([for (final h in hits) if (!allowed.contains(h.split(':').first)) h], isEmpty);
  });

  test('snapshots are captured at pixelRatio 0.5', () {
    expect(File('lib/skins/glass/primitives/stack/route_snapshot.dart').readAsStringSync(), contains('pixelRatio: 0.5'));
  });
}
