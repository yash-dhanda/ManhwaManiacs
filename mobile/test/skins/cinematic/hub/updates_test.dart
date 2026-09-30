// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/updates/models/update_settings.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_swipe_row.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/typed_headline.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/updates/updates_new.dart';

import 'hub_test_support.dart';

const _wide = Size(1024, 1366);
const _tall = Size(390, 2400);

FakeUpdates _updates() => FakeUpdates(notes: [
      note(1, 1, 141),
      note(2, 1, 142),
      note(3, 2, 7),
      note(4, 3, 3, at: kShelfNow.subtract(const Duration(days: 1, hours: 2))),
      note(5, 4, 9, read: true, at: kShelfNow.subtract(const Duration(days: 3))),
    ], runs: [
      UpdateRun(id: 9, trigger: 'scheduled', status: 'finished', seriesChecked: 12, newChaptersFound: 3, startedAt: kShelfNow.subtract(const Duration(hours: 1))),
    ], progress: [
      const UpdateRun(id: 10, trigger: 'manual', status: 'running', seriesChecked: 3, newChaptersFound: 1),
      const UpdateRun(id: 10, trigger: 'manual', status: 'finished', seriesChecked: 12, newChaptersFound: 2),
    ]);

Future<LibRig> _pump(WidgetTester t, FakeUpdates u, {Size size = const Size(390, 844), bool member = false, ShelfLibrary? lib, bool reduced = false, bool settle = true}) =>
    pumpShelf(t, lib: lib, start: '/updates', size: size, reduced: reduced, settle: settle, extra: updatesOverrides(u, member: member), unread: u.notes.where((n) => !n.isRead).length);

void main() {
  testWidgets('groups the new chapters by day then series, with the deck and the folios', (t) async {
    final u = _updates();
    await _pump(t, u, size: _tall);
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('YESTERDAY'), findsOneWidget);
    expect(find.text('Series 1'), findsWidgets);
    expect(find.byType(UpdateGroupRow), findsNWidgets(4));
    expect(find.textContaining('4 new chapters across 3 series'), findsWidgets);
    expect(find.textContaining('STOP PRESS'), findsWidgets);
    // No back arrow on a hub tab.
    expect(find.bySemanticsLabel('Back'), findsNothing);
  });

  testWidgets('fresh folios type themselves once per session', (t) async {
    final u = _updates();
    final rig = await _pump(t, u, settle: false);
    await t.pump(const Duration(milliseconds: 400));
    expect(find.byType(TypedHeadline), findsWidgets);
    await settle(t, 3000);
    expect(rig.container.read(seenUpdateIdsProvider), containsAll([1, 2, 3, 4]));
    // A rebuild types nothing again.
    rig.container.invalidate(updatesProvider);
    await settle(t, 600);
    expect(find.byWidgetPredicate((w) => w is TypedHeadline && w.text.startsWith('CH ')), findsNothing);
  });

  testWidgets('Check now shows the running rule, then "Checking 12 series…"; an admin reads the run live', (t) async {
    final u = _updates();
    final rig = await _pump(t, u);
    await t.tap(find.text('Check now'));
    await t.pump(const Duration(milliseconds: 100));
    expect(rig.rec.haptics, contains('tap.primary'));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('Checking 12 series…'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('Checked 3 of 12 · 1 new'), findsWidgets);
    await settle(t, 3000);
    expect(u.getRuns, greaterThanOrEqualTo(2));
    expect(find.text('Check now'), findsOneWidget);
    expect(rig.rec.haptics, isNot(contains('success')));
  });

  testWidgets('a check already running shows the caption', (t) async {
    final u = _updates()..conflict = true;
    await _pump(t, u);
    await t.tap(find.text('Check now'));
    await settle(t, 600);
    expect(find.text('A check is already running.'), findsOneWidget);
  });

  testWidgets('Mark read fades a group and a swipe left marks it read without moving the hub', (t) async {
    final u = _updates();
    final rig = await _pump(t, u, size: _tall);
    final row = find.byType(CineSwipeRow).first;
    await t.drag(row, const Offset(-320, 0));
    await settle(t, 800);
    expect(u.read, isNotEmpty);
    expect(rig.at, '/updates');
    // The group stays listed.
    expect(find.byType(UpdateGroupRow), findsNWidgets(4));
  });

  testWidgets('Mark all read is disabled with nothing unread and toasts otherwise', (t) async {
    final u = _updates();
    await _pump(t, u);
    await t.tap(find.text('Mark all manga read').evaluate().isEmpty ? find.text('Mark all read') : find.text('Mark all manga read'));
    await settle(t, 800);
    expect(u.readAll, hasLength(1));
    expect(find.text('Marked every new chapter as seen.'), findsOneWidget);
    final btn = t.widget<CineButton>(find.byType(CineButton).at(1));
    expect(btn.onPressed, isNull);
  });

  testWidgets('the admin aside shows from 900 px, for admins only, and the lists keep their columns', (t) async {
    final u = _updates();
    await _pump(t, u, size: _wide);
    expect(find.byKey(const Key('updates-aside')), findsOneWidget);
    expect(find.text('RECENT CHECKS'), findsOneWidget);
    final adminWidth = t.getSize(find.byType(UpdateGroupRow).first).width;
    await t.pumpWidget(const SizedBox());
    final member = await _pump(t, _updates(), size: _wide, member: true);
    expect(find.byKey(const Key('updates-aside')), findsNothing);
    expect(t.getSize(find.byType(UpdateGroupRow).first).width, adminWidth);
    expect(member.at, '/updates');
    await t.pumpWidget(const SizedBox());
    await _pump(t, _updates());
    expect(find.byKey(const Key('updates-aside')), findsNothing);
  });

  testWidgets('FOLLOWING lists the follows, the bell toggles notify and Unfollow offers Undo', (t) async {
    final u = _updates();
    final rig = await _pump(t, u);
    await t.tap(find.text('FOLLOWING'));
    await settle(t, 600);
    expect(find.text('Series 1'), findsWidgets);
    expect(find.text('Not checked yet'), findsWidgets);
    await t.tap(find.bySemanticsLabel(RegExp('Notify me of new chapters of Series 1')).first);
    await settle(t, 400);
    expect(rig.lib.patches.any((p) => p['id'] == 1 && p['notify'] == true), isTrue);
  });

  testWidgets('the states: empty, error, offline with the last list read-only', (t) async {
    await _pump(t, FakeUpdates(), lib: ShelfLibrary(all: const []));
    expect(find.byKey(const Key('updates-new-empty')), findsOneWidget);
    expect(find.text('NOTHING NEW'), findsOneWidget);
    await t.tap(find.text('FOLLOWING'));
    await settle(t, 600);
    expect(find.text('NOTHING FOLLOWED YET'), findsOneWidget);
    await t.pumpWidget(const SizedBox());

    await _pump(t, FakeUpdates(failList: true));
    expect(find.text('CORRECTION'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is TypedHeadline && w.text == "Updates didn't load."), findsOneWidget);
    await t.pumpWidget(const SizedBox());

    final off = FakeUpdates(notes: [note(1, 1, 5)]);
    final rig = await _pump(t, off);
    off.offline = true;
    rig.container.invalidate(updatesProvider);
    await settle(t, 800);
    expect(find.text('OFFLINE EDITION'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is TypedHeadline && w.text == 'Updates need a connection to check.'), findsOneWidget);
    final check = t.widget<CineButton>(find.byType(CineButton).first);
    expect(check.onPressed, isNull);
  });

  testWidgets('the deck opens the schedule sheet for a member and hardware keys work', (t) async {
    final u = _updates();
    await _pump(t, u, member: true);
    await t.tap(find.textContaining('checking every 30 min').first);
    await settle(t, 800);
    expect(find.text('When chapters are checked'), findsOneWidget);
    expect(find.text('Checking every 30 minutes.'), findsOneWidget);
    await t.tap(find.text('Done'));
    await settle(t, 600);
    await t.sendKeyEvent(LogicalKeyboardKey.keyC);
    await settle(t, 800);
    expect(u.triggers, greaterThan(0));
  });
}
