import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/suggestion.dart';
import 'package:manhwamaniacs/skins/glass/screens/picks/answer_list.dart';
import 'package:manhwamaniacs/skins/glass/screens/picks/ask_box.dart';
import 'package:manhwamaniacs/skins/glass/screens/picks/for_you_screen.dart';
import 'package:manhwamaniacs/skins/glass/screens/picks/genre_filter_chip.dart';

import '../../../screenshots/support/shot_harness.dart';
import '../primitives/support.dart' show pumpFor;
import '../shell/shell_rig.dart';
import 'ai_rig.dart';

Future<ShellRig> pumpPicks(WidgetTester t, RoutedAdapter a, {String start = '/library/recommendations', SuggestionAvailability? availability, Size size = const Size(390, 844), void Function(String?)? onGenre}) async {
  final rig = await pumpGlassShell(t, size: size, start: start, settle: false, extra: askOverrides(a, availability: availability, onGenre: onGenre));
  for (var i = 0; i < 8; i++) {
    await t.pump(const Duration(milliseconds: 300));
  }
  return rig;
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('idle: the title, the box with its counter, the examples and a disabled Ask', (t) async {
    final a = RoutedAdapter({});
    await pumpPicks(t, a);
    expect(find.byType(ForYouScreen), findsOneWidget);
    expect(find.text('0 / 600'), findsOneWidget);
    for (final e in kAskExamples) {
      expect(find.text(e), findsOneWidget);
    }
    expect(find.text('Only my sources'), findsOneWidget);
    expect(find.text('Use my taste'), findsOneWidget);
    await t.enterText(find.byType(EditableText).first, 'abc');
    await t.pump();
    expect(find.text('3 / 600'), findsOneWidget);
  });

  testWidgets('Enter asks the world with limit 12, deals the answers; the examples fill and ask', (t) async {
    final a = RoutedAdapter({'/library/world/suggest': (_) => suggestOk(3)});
    await pumpPicks(t, a);
    await t.tap(find.text(kAskExamples.first));
    await t.pump();
    await pumpFor(t, 1500);
    expect(a.calls.single.data, {'prompt': kAskExamples.first, 'limit': 12, 'use_taste': true});
    expect(find.byType(AnswerList), findsOneWidget);
    await pumpFor(t, 3000);
    expect(find.text('Ask again'), findsOneWidget);
  });

  testWidgets('alt+2 fills the second example and asks', (t) async {
    final a = RoutedAdapter({'/library/world/suggest': (_) => suggestOk(1)});
    await pumpPicks(t, a);
    await t.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.digit2);
    await t.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await pumpFor(t, 500);
    expect(a.calls.single.data, containsPair('prompt', kAskExamples[1]));
  });

  testWidgets('?genre=Fantasy shows the chip and requests that genre; clearing drops it', (t) async {
    final genres = <String?>[];
    final a = RoutedAdapter({});
    final h = t.ensureSemantics();
    final rig = await pumpPicks(t, a, start: '/library/recommendations?genre=Fantasy', onGenre: genres.add);
    expect(find.text('Fantasy'), findsWidgets);
    expect(genres, contains('Fantasy'));
    t.widget<GenreFilterChip>(find.byType(GenreFilterChip)).onClear();
    await pumpFor(t, 600);
    expect(rig.router.routerDelegate.currentConfiguration.uri.toString(), '/library/recommendations');
    expect(genres.last, isNull);
    h.dispose();
  });

  testWidgets('budget exhausted replaces the box with the notice and a countdown to 00:00 UTC', (t) async {
    final a = RoutedAdapter({});
    await pumpPicks(t, a, availability: const SuggestionAvailability(available: false, reason: 'budget_exhausted', remainingToday: 0));
    expect(find.textContaining("You've used today's AI asks"), findsOneWidget);
    expect(find.textContaining('Resets in '), findsOneWidget);
    expect(find.byType(AskBox), findsNothing);
    expect(find.text('Solo Picks'), findsWidgets);
  });

  testWidgets('not configured says the one long line', (t) async {
    await pumpPicks(t, RoutedAdapter({}), availability: const SuggestionAvailability(available: false, reason: 'not_configured', remainingToday: 0));
    expect(find.textContaining("AI isn't set up on this server"), findsOneWidget);
  });

  testWidgets('no matches keeps the prompt and says so', (t) async {
    final a = RoutedAdapter({'/library/world/suggest': (_) => const Reply({'items': <Object>[], 'remaining_today': 5})});
    await pumpPicks(t, a);
    await t.enterText(find.byType(EditableText).first, 'zzz nothing');
    await t.pump();
    await t.tap(find.text('Ask'));
    await pumpFor(t, 600);
    expect(find.text('Nothing matched that. Try describing it differently.'), findsOneWidget);
    expect(find.text('zzz nothing'), findsOneWidget);
  });

  testWidgets('the quota meter shows at 10 or fewer and stays out of the way above', (t) async {
    await pumpPicks(t, RoutedAdapter({}), availability: const SuggestionAvailability(available: true, reason: 'ok', remainingToday: 2));
    expect(find.text('2 of 10 asks left today'), findsOneWidget);
  });
}
