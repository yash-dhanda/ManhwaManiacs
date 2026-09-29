// ignore_for_file: require_trailing_commas, directives_ordering
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_badge.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';

import '../auth/auth_test_support.dart';

const _yash = ActiveProfile(id: 1, name: 'Yash', avatarKey: 'violet', mood: Mood.neutral);
FakeAuth _signedIn() => FakeAuth(initial: AuthAuthenticated(testUser));

Future<Rig> _open(WidgetTester t, {List<Profile>? profiles, List<String>? announcements}) async {
  if (announcements != null) {
    t.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (m) async {
      final data = (m as Map?)?['data'] as Map?;
      if (data?['message'] is String) announcements.add(data!['message'] as String);
      return null;
    });
    addTearDown(() => t.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, null));
  }
  final rig = await pumpAuth(t, start: '/', auth: _signedIn(), active: _yash, profiles: profiles ?? [profile(1, 'Yash', mature: true, mood: Mood.romantic), profile(2, 'Guest'), profile(3, 'Kid')]);
  unawaited(rig.router.push<void>('/profiles/manage'));
  await settle(t, 800);
  return rig;
}

double _y(WidgetTester t, String name) => t.getTopLeft(find.text(name)).dy;

void main() {
  testWidgets('rows: name, "{Mood} mood · 18+ on/off", CURRENT on the active one, Use on the others', (t) async {
    await _open(t);
    expect(find.text('YOUR ACCOUNT'), findsOneWidget);
    expect(find.text('Romantic mood · 18+ on'), findsOneWidget);
    expect(find.text('Default mood · 18+ off'), findsNWidgets(2));
    expect(find.byWidgetPredicate((w) => w is CineBadge && w.label == 'CURRENT'), findsOneWidget);
    expect(find.widgetWithText(CineButton, 'Use'), findsNWidgets(2));
    expect(find.bySemanticsLabel('Edit Guest'), findsOneWidget);
    expect(find.bySemanticsLabel('Delete Kid'), findsOneWidget);
  });

  testWidgets('Use switches at once with a toast and no Iris', (t) async {
    final rig = await _open(t);
    await t.ensureVisible(find.widgetWithText(CineButton, 'Use').first);
    await t.tap(find.widgetWithText(CineButton, 'Use').first);
    await settle(t, 400);
    expect(rig.container.read(activeProfileProvider)?.name, 'Guest');
    expect(find.text('Reading as Guest'), findsOneWidget);
  });

  testWidgets('Alt+Down moves the focused row, writes sort_order and announces the position', (t) async {
    final said = <String>[];
    final rig = await _open(t, announcements: said);
    expect(_y(t, 'Yash'), lessThan(_y(t, 'Guest')));
    // Focus the first row's Edit button, then Alt+Down.
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.pump();
    await t.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await t.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await settle(t, 600);
    expect(_y(t, 'Guest'), lessThan(_y(t, 'Yash')));
    expect(rig.profiles.calls.where((c) => c.startsWith('update:')), isNotEmpty);
    expect(said.any((s) => s.contains('moved to position 2 of 3')), isTrue, reason: said.join(' | '));
  });

  testWidgets('Delete opens the arming dialog and a double tap on the trigger does not delete', (t) async {
    final rig = await _open(t);
    final trigger = find.bySemanticsLabel('Delete Kid');
    await t.ensureVisible(trigger);
    await t.pump();
    await t.tap(trigger);
    await t.pump(const Duration(milliseconds: 50));
    await t.tap(trigger, warnIfMissed: false);
    await settle(t, 300);
    expect(rig.profiles.calls, isEmpty, reason: 'the second tap cannot commit: it lands on the barrier or on a dead armed button');
    if (find.text('Delete profile').evaluate().isEmpty) {
      await t.tap(trigger); // the barrier took the second tap; open it again
      await settle(t, 300);
    }
    expect(find.textContaining('Its library, progress, bookmarks and collections go with it.'), findsOneWidget);
    await t.tap(find.text('Delete profile').last);
    await t.pump();
    expect(rig.profiles.calls, isEmpty, reason: 'armed for a second');
    await settle(t, 1200);
    await t.tap(find.text('Delete profile').last);
    await settle(t, 600);
    expect(rig.profiles.calls, ['remove:3']);
    expect(find.text('Deleted Kid.'), findsOneWidget);
  });

  testWidgets('New profile is disabled at five, with the reason', (t) async {
    await _open(t, profiles: [for (var i = 1; i <= 5; i++) profile(i, 'P$i')]);
    final button = t.widget<CineButton>(find.widgetWithText(CineButton, 'New profile'));
    expect(button.onPressed, isNull);
    expect(button.disabledReason, '5 profiles is the limit.');
  });

  testWidgets('empty: NOTHING HERE YET with New profile', (t) async {
    await _open(t, profiles: const []);
    expect(find.text('NOTHING HERE YET'), findsOneWidget);
  });
}
