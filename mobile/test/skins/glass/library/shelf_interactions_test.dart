import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/shelf_query.dart';
import 'package:manhwamaniacs/features/library/models/tag.dart';
import 'package:manhwamaniacs/features/library/providers/glass_density_provider.dart';
import 'package:manhwamaniacs/features/library/providers/library_selection_provider.dart';
import 'package:manhwamaniacs/features/library/providers/shelf_query_provider.dart';
import 'package:manhwamaniacs/features/library/utils/glass_density.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip.dart';
import 'package:manhwamaniacs/skins/glass/primitives/slider.dart';
import 'package:manhwamaniacs/skins/glass/primitives/stack/route_snapshot.dart' show GlassTab;
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart' show glassToastProvider;
import 'package:manhwamaniacs/skins/glass/screens/library/library_sheets.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/shelf_actions.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/shelf_grid.dart' show ShelfTile;

import '../../../features/library/shelf_fixtures.dart';
import '../../../screenshots/support/shot_harness.dart';
import '../shell/shell_rig.dart';
import 'library_rig.dart';

Future<void> _settle(WidgetTester t, [int steps = 6]) async {
  for (var i = 0; i < steps; i++) {
    await t.pump(const Duration(milliseconds: 150));
  }
}

FakeLib _three() => FakeLib(series: [shelfSeries(1, title: 'Alpha'), shelfSeries(2, title: 'Beta'), shelfSeries(3, title: 'Gamma'), shelfSeries(4, title: 'Delta')]);

/// Gives keyboard focus to the shelf tile titled [title] (the focusable node under its focus-tracking wrapper).
void focusTile(WidgetTester t, String title) {
  final tile = find.ancestor(of: find.text(title).first, matching: find.byType(ShelfTile)).first;
  final inner = find.descendant(of: tile, matching: find.byType(ListenableBuilder)).first;
  final node = Focus.of(t.element(inner));
  node.descendants.firstWhere((n) => n.canRequestFocus).requestFocus();
}

/// The centre of the poster of the shelf tile titled [title] (the caption under it is not part of the tap target).
Offset posterOf(WidgetTester t, String title) {
  final tile = find.ancestor(of: find.text(title).first, matching: find.byType(ShelfTile)).first;
  final r = t.getRect(tile);
  return Offset(r.center.dx, r.top + r.height * 0.35);
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('Android back from History goes Home (the hub is one tab root)', (t) async {
    final rig = await pumpLibrary(t, _three(), start: '/library/history', android: true);
    expect(rig.at, '/library/history');
    await t.binding.handlePopRoute();
    await _settle(t);
    expect(tabOfRig(rig), GlassTab.home);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('a two-pointer pinch of 1.3 at 3 columns commits 2; a one-finger drag of the same distance does not', (t) async {
    final rig = await pumpLibrary(t, _three());
    final density = rig.container.read(glassDensityProvider.notifier);
    expect(rig.container.read(glassDensityProvider).phone, GlassPhoneDensity.c3);

    final c = t.getCenter(find.text('Beta').first);
    final drag = await t.startGesture(c);
    await drag.moveBy(const Offset(30, 0));
    await drag.moveBy(const Offset(0, -30));
    await drag.up();
    await _settle(t);
    expect(rig.container.read(glassDensityProvider).phone, GlassPhoneDensity.c3, reason: 'one finger scrolls');

    final a = await t.startGesture(c - const Offset(50, 0), pointer: 7);
    final b = await t.startGesture(c + const Offset(50, 0), pointer: 8);
    await t.pump(const Duration(milliseconds: 16));
    for (var i = 0; i < 6; i++) {
      await a.moveBy(const Offset(-2.5, 0));
      await b.moveBy(const Offset(2.5, 0));
      await t.pump(const Duration(milliseconds: 16));
    }
    await a.up();
    await b.up();
    await _settle(t);
    expect(rig.container.read(glassDensityProvider).phone, GlassPhoneDensity.c2);
    expect(GlassMotion.recorder.entries.any((e) => e.label == 'DENSITY REFLOW'), isTrue, reason: 'the reflow goes through GlassMotion.play');
    density.setPhone(GlassPhoneDensity.c3);
  });

  testWidgets('mid-pinch the rows are clipped at the pinned toolbar, so no poster shows through it', (t) async {
    await pumpLibrary(t, _three());
    final c = t.getCenter(find.text('Beta').first);
    final a = await t.startGesture(c - const Offset(40, 0), pointer: 7);
    final b = await t.startGesture(c + const Offset(40, 0), pointer: 8);
    await t.pump(const Duration(milliseconds: 16));
    for (var i = 0; i < 6; i++) {
      await a.moveBy(const Offset(-6, 0));
      await b.moveBy(const Offset(6, 0));
      await t.pump(const Duration(milliseconds: 16));
    }
    final bar = t.getRect(find.byWidgetPredicate((w) => w is KeyedSubtree && w.key is GlobalKey && w.child.runtimeType.toString() == '_Toolbar'));
    final clips = find.ancestor(of: find.text('Beta').first, matching: find.byWidgetPredicate((w) => w is ClipRect && w.clipBehavior == Clip.hardEdge && w.clipper != null));
    expect(clips, findsWidgets);
    final clip = t.widget<ClipRect>(clips.first);
    final box = t.renderObject<RenderBox>(clips.first);
    final top = clip.clipper!.getClip(box.size).top + box.localToGlobal(Offset.zero).dy;
    expect(top, closeTo(bar.bottom, 0.5));
    await a.up();
    await b.up();
    await _settle(t);
    expect(find.ancestor(of: find.text('Beta').first, matching: find.byWidgetPredicate((w) => w is ClipRect && w.clipBehavior == Clip.hardEdge)), findsNothing);
  });

  testWidgets('the column slider writes the phone density', (t) async {
    final rig = await pumpLibrary(t, _three(), start: '/library?sheet=density');
    await _settle(t);
    expect(find.byType(GlassDensityBody), findsOneWidget);
    t.widget<GlassSlider>(find.byType(GlassSlider)).onChanged!(0);
    expect(rig.container.read(glassDensityProvider).phone, GlassPhoneDensity.list);
    t.widget<GlassSlider>(find.byType(GlassSlider)).onChanged!(1);
    expect(rig.container.read(glassDensityProvider).phone, GlassPhoneDensity.c5);
  });

  testWidgets('the tablet toolbar segmented control writes the wide density', (t) async {
    final rig = await pumpLibrary(t, _three(), size: const Size(834, 1194));
    expect(rig.container.read(glassDensityProvider).wide, GlassDensityWide.comfortable);
    await t.ensureVisible(find.text('Compact').first);
    await _settle(t, 2);
    await t.tap(find.text('Compact').first);
    await _settle(t);
    expect(rig.container.read(glassDensityProvider).wide, GlassDensityWide.compact);
  });

  testWidgets('a later visit with new query params applies them to the kept-alive shelf', (t) async {
    final rig = await pumpLibrary(t, _three());
    await _settle(t);
    rig.router.go('/');
    await _settle(t);
    rig.router.go('/library?reading_status=reading&sort=added');
    await _settle(t);
    final p = rig.container.read(shelfQueryProvider).toListParams();
    expect((p['reading_status'], p['sort']), ('reading', 'recently_added'));
  });

  testWidgets('the Filters sheet writes reading_status and tags', (t) async {
    final lib = _three()..tags = const [Tag(id: 5, name: 'Cosy', category: 'user', colorHex: '#7AA2F7')];
    final rig = await pumpLibrary(t, lib, start: '/library?sheet=filters');
    await _settle(t);
    await t.tap(find.text('On hold').last);
    await _settle(t);
    expect(rig.container.read(shelfQueryProvider).effectiveStatus, ShelfStatus.onHold);
    expect(rig.container.read(shelfQueryProvider).toListParams()['reading_status'], 'on_hold');
    t.widget<GlassChip>(find.widgetWithText(GlassChip, 'Cosy')).onPressed!();
    await _settle(t);
    expect(rig.container.read(shelfQueryProvider).tagIds, [5]);
    expect(lib.calls.any((c) => c.startsWith('listSeries:on_hold:5')), isTrue, reason: '${lib.calls}');
  });

  testWidgets('select mode: shift+x range, Ctrl+A, Esc clears then exits', (t) async {
    final rig = await pumpLibrary(t, _three());
    await t.tap(find.bySemanticsLabel(RegExp(r'^Select$')).first);
    await _settle(t);
    await t.tapAt(posterOf(t, 'Alpha'));
    await _settle(t, 2);
    expect(find.bySemanticsLabel('1 selected'), findsWidgets);

    // shift+x on Gamma selects the range from the last toggled item (the keyboard form of the touch paint).
    focusTile(t, 'Gamma');
    await _settle(t, 1);
    await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.keyX);
    await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await _settle(t, 2);
    expect(find.bySemanticsLabel('3 selected'), findsWidgets);

    await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.keyA);
    await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await _settle(t, 2);
    expect(find.bySemanticsLabel('4 selected'), findsWidgets);

    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await _settle(t, 2);
    expect(find.bySemanticsLabel('4 selected'), findsNothing);
    expect(rig.container.read(librarySelectionProvider).active, isTrue, reason: 'the first Esc only clears');
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await _settle(t, 2);
    expect(rig.container.read(librarySelectionProvider).active, isFalse);
  });

  testWidgets('Remove from library shows Undo and Undo restores favourite and status', (t) async {
    final s = shelfSeries(1, title: 'Alpha', fav: true, status: 'completed');
    final lib = FakeLib(series: [s]);
    final rig = await pumpLibrary(t, lib);
    await rig.container.read(glassShelfActionsProvider).remove(s);
    await _settle(t, 2);
    expect(lib.calls, contains('unfollow:1'));
    expect(find.text('Undo'), findsWidgets);
    expect(rig.container.read(glassToastProvider.notifier).undoLast(), isTrue);
    await _settle(t);
    expect(lib.calls, contains('follow:series-1'));
    expect(lib.calls.where((c) => c.startsWith('patch:99:true:completed')), isNotEmpty, reason: '${lib.calls}');
  });

  testWidgets('manual order: alt+down moves the focused series and announces its position assertively', (t) async {
    final announced = <String>[];
    t.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(SystemChannels.accessibility, (m) async {
      final data = (m as Map?)?['data'] as Map?;
      if (data?['message'] is String) announced.add(data!['message'] as String);
      return null;
    });
    addTearDown(() => t.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(SystemChannels.accessibility, null));
    final lib = FakeLib(series: [for (var i = 1; i <= 6; i++) shelfSeries(i, title: 'S$i', sortOrder: i)]);
    final rig = await pumpLibrary(t, lib);
    rig.container.read(shelfQueryProvider.notifier).patch((q) => q.copyWith(sort: ShelfSort.manual));
    await _settle(t);
    focusTile(t, 'S1');
    await _settle(t, 2);
    await t.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await t.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await _settle(t);
    expect(announced.any((a) => a.startsWith('S1 moved to position')), isTrue, reason: '$announced');
  });
}
