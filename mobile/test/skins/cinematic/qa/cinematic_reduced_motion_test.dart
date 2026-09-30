// ignore_for_file: directives_ordering, require_trailing_commas, prefer_const_constructors, avoid_redundant_argument_values, unnecessary_lambdas, unnecessary_await_in_return
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/diagnostics/motion_recorder.dart';
import 'package:manhwamaniacs/features/settings/providers/a11y_prefs_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/set_heading.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/typed_headline.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

import '../library/library_test_support.dart' show pumpShelf;
import 'qa_screens.dart';

/// D1 (4.8, 14.1): the OS flag and the app's own switch each make `CineMotion.reduced` true.
/// On every screen in its ready state nothing loops (the frame queue empties within 2 s of fake
/// time); the three allowed loaders still animate; every move recorded by the motion recorder
/// during a scripted walk is 200 ms or less; a SetHeading builds no per-letter Transform and a
/// TypedHeadline shows its full text with no caret.
class _AppReduced extends A11yPrefsNotifier {
  @override
  A11yPrefs build() => const A11yPrefs(motion: 'reduced');
}

const _os = FakeAccessibilityFeatures(disableAnimations: true);

Future<void> _emptiesWithin2s(WidgetTester t, String what) async {
  try {
    await t.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 2));
  } catch (e) {
    fail('$what still schedules frames after 2 s of fake time: $e');
  }
}

void main() {
  for (final mode in const ['os flag', 'app switch']) {
    final os = mode == 'os flag';
    for (final s in kQaScreens) {
      testWidgets('reduced ($mode): ${s.id.id} settles', (t) async {
        if (os) t.platformDispatcher.accessibilityFeaturesTestValue = _os;
        try {
          final rig = await pumpQaScreen(t, s, reduced: os, extra: [if (!os) a11yPrefsProvider.overrideWith(_AppReduced.new)]);
          expect(CineMotion.reduced(t.element(find.byType(Navigator).first)), isTrue);
          await _emptiesWithin2s(t, s.id.id);
          await disposeQa(t, rig);
        } finally {
          t.platformDispatcher.clearAccessibilityFeaturesTestValue();
        }
      });
    }
  }

  testWidgets('reduced: the leader dial, the indeterminate rule and the button loading segment still animate', (t) async {
    t.platformDispatcher.accessibilityFeaturesTestValue = _os;
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await t.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [cinematicTokens]),
      home: Scaffold(
        body: Column(children: [
          const CineLeaderDial(showAfter: Duration.zero),
          const SizedBox(width: 200, child: CineIndeterminateRule()),
          CineButton(label: 'Save', loading: true, onPressed: () {}),
        ]),
      ),
    ),);
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(t.binding.hasScheduledFrame, isTrue);
  });

  testWidgets('reduced: every recorded move of a scripted walk is 200 ms or less', (t) async {
    MotionRecorder.instance.recording = true;
    addTearDown(() => MotionRecorder.instance.recording = false);
    t.platformDispatcher.accessibilityFeaturesTestValue = _os;
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final rig = await pumpShelf(t, start: '/', reduced: true);
    for (final path in ['/library', '/updates', '/library/collections', '/library/1', '/', '/settings', '/library']) {
      rig.router.go(path);
      for (var i = 0; i < 12; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
    }
    final over = [for (final e in MotionRecorder.instance.entries) if (e.plannedMs > 200) '${e.label} ${e.plannedMs} ms'];
    debugPrint('MOTION entries: ${MotionRecorder.instance.entries.length}');
    expect(over, isEmpty);
    await disposeQa(t, rig);
  });

  testWidgets('reduced: SetHeading has no per-letter Transform or blur; TypedHeadline shows everything with no caret', (t) async {
    await t.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [cinematicTokens]),
      builder: (context, app) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: app!),
      home: Scaffold(
        body: ProviderScope(
          child: Column(children: [
            SetHeading('Library', id: 'h', style: const TextStyle(fontSize: 40), cap: 1.3, level: 1, trigger: SetTrigger.mount),
            const TypedHeadline('Tonight, chapter 12.', style: TextStyle(fontSize: 32)),
          ]),
        ),
      ),
    ),);
    await t.pump();
    await t.pump(const Duration(milliseconds: 250));
    expect(find.descendant(of: find.byType(SetHeading), matching: find.byType(ImageFiltered)), findsNothing);
    expect(find.text('Library'), findsOneWidget);
    final rich = t.widget<RichText>(find.descendant(of: find.byType(TypedHeadline), matching: find.byType(RichText)).first);
    expect(rich.text.toPlainText(), 'Tonight, chapter 12.');
    await t.pump(const Duration(seconds: 1));
    expect(t.hasRunningAnimations, isFalse);
  });
}
