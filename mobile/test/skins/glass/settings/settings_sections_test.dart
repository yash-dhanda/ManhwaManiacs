import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/feedback_section.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_common.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoProfile extends ActiveProfileNotifier {
  @override
  ActiveProfile? build() => null;
}

Future<ProviderContainer> _pump(WidgetTester t, Widget child, {List<Override> extra = const []}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [sharedPrefsProvider.overrideWithValue(prefs), ...extra]);
  addTearDown(c.dispose);
  await t.pumpWidget(UncontrolledProviderScope(container: c, child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)))));
  return c;
}

void main() {
  testWidgets('ProfileGate: no profile shows the notice and the link, never the body', (t) async {
    await _pump(t, ProfileGate(builder: (_) => const Text('body')), extra: [activeProfileProvider.overrideWith(_NoProfile.new)]);
    expect(find.text('Choose a profile first'), findsOneWidget);
    expect(find.text('Choose a profile'), findsOneWidget);
    expect(find.text('body'), findsNothing);
  });

  testWidgets('Feel it plays five feels 400 ms apart and Hear it seven cues 300 ms apart', (t) async {
    final feels = <(int, int)>[];
    final hears = <(int, int, double)>[];
    await _pump(
      t,
      FeedbackSection(
        showHaptics: true,
        feelPlayer: (i) async => feels.add((i, t.binding.clock.now().millisecondsSinceEpoch)),
        hearPlayer: (i, db) async => hears.add((i, t.binding.clock.now().millisecondsSinceEpoch, db)),
      ),
    );
    await t.tap(find.text('Feel it'));
    await t.pump();
    await t.pump(const Duration(seconds: 3));
    expect([for (final f in feels) f.$1], [0, 1, 2, 3, 4]);
    expect(feels.last.$2 - feels.first.$2, 1600);
    await t.tap(find.text('Hear it'));
    await t.pump();
    await t.pump(const Duration(seconds: 3));
    expect(hears.length, 7);
    expect(hears.last.$2 - hears.first.$2, 1800);
    expect(hears.first.$3, -6, reason: 'the slider default, even while UI sounds are off');
  });

  testWidgets('Feel it is disabled with its caption while haptics are off', (t) async {
    final c = await _pump(t, const FeedbackSection(showHaptics: true));
    expect(find.text('Turn haptics on to feel them.'), findsNothing);
    await c.read(hapticFeedbackProvider.notifier).setEnabled(false);
    await t.pump();
    expect(find.text('Turn haptics on to feel them.'), findsOneWidget);
  });
}
