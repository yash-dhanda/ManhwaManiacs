// ignore_for_file: directives_ordering, require_trailing_commas, prefer_const_constructors, avoid_redundant_argument_values, unnecessary_lambdas, unnecessary_await_in_return
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/set_heading.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/typed_headline.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// C5 (14.5). The timer rules are proved where the timers live, and `qa.md` names each test:
/// toasts (`primitives/toast_host_test.dart`), reader chrome (`reader/reader_chrome_behaviour_test.dart`,
/// `reader/reader_motion_a11y_test.dart`), the recap countdown (`recap/recap_screen_test.dart`), The Annual
/// and guided view (`annual/annual_screen_test.dart`, `reader/reader_motion_a11y_test.dart`), the Listen
/// post-play countdown (`listen/post_play_test.dart`), the lightbox label (`primitives/lightbox_test.dart`),
/// folios (`folio_test.dart`). This file adds the one rule with no home: reveals expose their full
/// text 100 ms after navigation, while the animation still runs.
void main() {
  Widget host(Widget child) => ProviderScope(
        child: MaterialApp(
          theme: ThemeData(extensions: const [cinematicTokens]),
          home: Scaffold(body: child),
        ),
      );

  testWidgets('SetHeading and TypedHeadline expose their full text 100 ms in, mid-animation', (t) async {
    final h = t.ensureSemantics();
    await t.pumpWidget(host(Column(children: [
      SetHeading('Recently read', id: 'sr-1', style: const TextStyle(fontSize: 40), cap: 1.3, level: 1, trigger: SetTrigger.mount),
      const TypedHeadline('Tonight, chapter 143 of The Return.', style: TextStyle(fontSize: 28), level: 2),
    ],),),);
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(t.hasRunningAnimations, isTrue, reason: 'the reveal is still playing');
    final set = t.getSemantics(find.byType(SetHeading));
    expect(set.label, 'Recently read');
    expect(set.flagsCollection.isHeader, isTrue);
    expect(set.headingLevel, 1);
    final typed = t.getSemantics(find.byType(TypedHeadline));
    expect(typed.label, 'Tonight, chapter 143 of The Return.');
    expect(typed.headingLevel, 2);
    await t.pump(const Duration(seconds: 6));
    h.dispose();
  });
}
