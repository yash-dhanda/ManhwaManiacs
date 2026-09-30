import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/skins/glass/dev/auth_fixtures.dart';
import 'package:manhwamaniacs/skins/glass/screens/profiles/profiles_manage_screen.dart';

import '../../../screenshots/support/shot_harness.dart';
import '../auth/auth_rig.dart';

GlassAuthFixture _fx({int n = 4, List<Profile>? profiles}) => GlassAuthFixture(signedIn: true, profiles: profiles ?? fixtureProfiles(n), active: const ActiveProfile(id: 1, name: 'Yash', avatarKey: 'violet', mood: Mood.fantasy));

/// Tabs until a profile row has focus.
Future<void> _focusRow(WidgetTester t) async {
  for (var i = 0; i < 10; i++) {
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.pump();
    if (FocusManager.instance.primaryFocus?.debugLabel?.startsWith('manage-') ?? false) return;
  }
}

void main() {
  setUpAll(loadAppFonts);

  test('the move announcement', () => expect(moveAnnouncement('Late-night reads', 2, 4), 'Late-night reads moved to position 2 of 4'));

  testWidgets('rows show the name, the mood line and the Active badge', (t) async {
    await pumpAuth(t, '/profiles/manage', _fx());
    await settleFor(t, 2500);
    expect(find.text('Profiles'), findsWidgets);
    expect(find.text('Fantasy mood'), findsOneWidget);
    expect(find.text('Horror mood'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Use'), findsNWidgets(3));
  });

  testWidgets('Alt+Down reorders and sends only the moved sort_orders', (t) async {
    await pumpAuth(t, '/profiles/manage', _fx());
    await settleFor(t, 2500);
    await _focusRow(t);
    await t.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await t.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await settleFor(t, 800);
    expect(FakeProfiles.calls.where((c) => c.startsWith('reorder')), isNotEmpty);
    expect(FakeProfiles.calls.last, 'reorder:2,1,3,4');
  });

  testWidgets('at five profiles Add is disabled and the limit shows', (t) async {
    await pumpAuth(t, '/profiles/manage', _fx(n: 5));
    await settleFor(t, 2500);
    expect(find.text('Up to 5 profiles'), findsOneWidget);
  });

  testWidgets('an empty account shows the dashed card and its Add button', (t) async {
    await pumpAuth(t, '/profiles/manage', _fx(n: 0));
    await settleFor(t, 2500);
    expect(find.text('No profiles yet'), findsOneWidget);
    expect(find.text('Add profile'), findsWidgets);
  });

  testWidgets('offline: reordering does nothing and Add is disabled', (t) async {
    await pumpAuth(t, '/profiles/manage', _fx(), online: false);
    await settleFor(t, 2500);
    await _focusRow(t);
    await t.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await t.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await settleFor(t, 600);
    expect(FakeProfiles.calls.where((c) => c.startsWith('reorder')), isEmpty);
  });

  testWidgets('Use switches to that profile', (t) async {
    final rig = await pumpAuth(t, '/profiles/manage', _fx());
    await settleFor(t, 2500);
    await t.tap(find.text('Use').first);
    await t.pump();
    await settleFor(t);
    expect(rig.at, '/');
  });
}
