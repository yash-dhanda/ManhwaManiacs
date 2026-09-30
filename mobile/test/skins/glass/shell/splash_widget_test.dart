import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/splash/glass_splash.dart';

import '../../../screenshots/support/shot_harness.dart';
import 'shell_rig.dart';

bool _splashUp(WidgetTester t) => find.bySemanticsLabel('Loading ManhwaManiacs').evaluate().isNotEmpty;

/// Pumps [ms] of fake time in 50 ms frames.
Future<void> _run(WidgetTester t, int ms) async {
  for (var i = 0; i < ms ~/ 50; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUpAll(loadAppFonts);
  tearDown(() => GlassSplash.pending = false);

  testWidgets('cold: the Droplet is up at first, hands off, and is gone within 1,400 ms', (t) async {
    final handle = t.ensureSemantics();
    GlassSplash.pending = true;
    await pumpGlassShell(t, settle: false);
    expect(_splashUp(t), isTrue);
    await _run(t, 600);
    expect(_splashUp(t), isTrue);
    await _run(t, 800);
    expect(_splashUp(t), isFalse);
    handle.dispose();
  });

  testWidgets('warm (seen an hour ago): gone within 500 ms', (t) async {
    final handle = t.ensureSemantics();
    GlassSplash.pending = true;
    await pumpGlassShell(t, settle: false, prefsExtra: {kGlassLastSeenKey: DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch});
    expect(_splashUp(t), isTrue);
    await _run(t, 500);
    expect(_splashUp(t), isFalse);
    handle.dispose();
  });

  testWidgets('reduced motion: a 200 ms cross-fade, gone within 300 ms', (t) async {
    final handle = t.ensureSemantics();
    GlassSplash.pending = true;
    await pumpGlassShell(t, settle: false, extra: [glassMotionPrefsProvider.overrideWith((ref) => const GlassMotionPrefs(reduced: true))]);
    expect(_splashUp(t), isTrue);
    await _run(t, 300);
    expect(_splashUp(t), isFalse);
    handle.dispose();
  });

  testWidgets('a tap at 300 ms skips to the hand-off', (t) async {
    final handle = t.ensureSemantics();
    GlassSplash.pending = true;
    await pumpGlassShell(t, settle: false);
    await _run(t, 300);
    expect(_splashUp(t), isTrue);
    await t.tapAt(const Offset(200, 400));
    await _run(t, 300);
    expect(_splashUp(t), isFalse);
    handle.dispose();
  });

  testWidgets('with no boot pending nothing plays (a widget test that pumps the root sees no splash)', (t) async {
    final handle = t.ensureSemantics();
    await pumpGlassShell(t, settle: false);
    expect(_splashUp(t), isFalse);
    handle.dispose();
  });

  testWidgets('it plays once per boot: the flag is consumed', (t) async {
    GlassSplash.pending = true;
    await pumpGlassShell(t, settle: false);
    expect(GlassSplash.pending, isFalse);
    await _run(t, 1400);
  });
}
