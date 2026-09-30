// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/auth/providers/offline_edition_controller.dart';
import 'package:manhwamaniacs/features/auth/providers/session_offline_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/bookmark_outbox_provider.dart';
import 'package:manhwamaniacs/features/library/providers/bookmarks_provider.dart';
import 'package:manhwamaniacs/features/reader/models/bookmark.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_text_field.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_swipe_row.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/typed_headline.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/bookmarks/marginal_note.dart';

import 'hub_test_support.dart';

Finder _headline(String s) => find.byWidgetPredicate((w) => w is TypedHeadline && w.text == s);

Future<({LibRig rig, FakeOutbox outbox})> _pump(WidgetTester t, List<Bookmark> items, {Size size = const Size(390, 2600), AppError? error, int pending = 0, bool offline = false}) async {
  final outbox = FakeOutbox(items)..pending = pending;
  final rig = await pumpShelf(
    t,
    lib: HubLibrary(all: [for (var i = 1; i <= 3; i++) shelfSeries(i)]),
    start: '/library/bookmarks',
    size: size,
    extra: [
      ...updatesOverrides(FakeUpdates()),
      bookmarksProvider.overrideWith(() => FakeBookmarks(items, error: error)),
      bookmarkOutboxControllerProvider.overrideWithValue(outbox),
      if (offline) sessionOfflineProvider.overrideWith(_Offline.new),
    ],
  );
  return (rig: rig, outbox: outbox);
}

class _Offline extends SessionOfflineNotifier {
  @override
  bool build() => true;
}

void main() {
  testWidgets('groups marginal notes by series: folios, pull quotes, notes, stale anchors', (t) async {
    final items = [
      mark('a', novel: true, snippet: 'The door was never locked.', fraction: 0.62, note: 'Reread this.'),
      mark('b', series: 2, index: 3, stale: true),
    ];
    final r = await _pump(t, items);
    expect(find.byType(MarginalNote), findsNWidgets(2));
    expect(find.text('CH 14 · 60% IN'), findsOneWidget);
    expect(find.text('CH 14 · PAGE 3'), findsOneWidget);
    expect(find.text('The door was never locked.'), findsOneWidget);
    expect(find.text('Reread this.'), findsOneWidget);
    expect(find.text('Add a note'), findsOneWidget);
    expect(find.text('The text here changed. This opens at the nearest spot.'), findsOneWidget);
    expect(find.text('Series 1'), findsWidgets);
    expect(find.text('Saved 28 September'), findsNWidgets(2));
    expect(r.rig.at, '/library/bookmarks');
    expect(find.byTooltip('Back'), findsNothing);
  });

  testWidgets('tapping a note opens the reader at the position by Dip', (t) async {
    final r = await _pump(t, [mark('a')]);
    await t.tap(find.text('CH 14 · PAGE 7'));
    await settleShelf(t, by: const Duration(milliseconds: 1400));
    expect(fullLocation(r.rig), '/reader/shelf/series-1/c14?page=7&at=0.500');
  });

  testWidgets('a novel bookmark opens at ?para=&at=', (t) async {
    final r = await _pump(t, [mark('a', novel: true, snippet: 'x', index: 9, fraction: 0.25)]);
    await t.tap(find.text('x'));
    await settleShelf(t, by: const Duration(milliseconds: 1400));
    expect(fullLocation(r.rig), '/novels/shelf/series-1/c14?para=9&at=0.250');
  });

  testWidgets('a note saves on focus loss through the outbox', (t) async {
    final r = await _pump(t, [mark('a'), mark('b', series: 2)]);
    await t.tap(find.text('Add a note').first);
    await settleShelf(t, by: const Duration(milliseconds: 500));
    await t.enterText(find.byType(EditableText).first, '  the reveal  ');
    // Tapping outside moves focus away.
    FocusManager.instance.primaryFocus?.unfocus();
    await settleShelf(t, by: const Duration(milliseconds: 600));
    expect(r.outbox.notes, [('a', 'the reveal')]);
    expect(find.text('the reveal'), findsOneWidget);
  });

  testWidgets('a note saves on the keyboard\'s done action and on Ctrl+Enter', (t) async {
    final r = await _pump(t, [mark('a'), mark('b', series: 2)]);
    await t.tap(find.text('Add a note').first);
    await settleShelf(t, by: const Duration(milliseconds: 500));
    await t.enterText(find.byType(EditableText).first, 'one');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await settleShelf(t, by: const Duration(milliseconds: 500));
    expect(r.outbox.notes.last, ('a', 'one'));
    await t.tap(find.text('Add a note').first);
    await settleShelf(t, by: const Duration(milliseconds: 500));
    await t.enterText(find.byType(EditableText).first, 'two');
    await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settleShelf(t, by: const Duration(milliseconds: 500));
    expect(r.outbox.notes.last, ('b', 'two'));
    expect(find.byType(CineTextField), findsNothing);
  });

  testWidgets('a bookmark removed on another device shows the toast and drops the note', (t) async {
    final r = await _pump(t, [mark('a'), mark('b', series: 2)]);
    r.outbox.deletedElsewhere = true;
    await t.tap(find.text('Add a note').first);
    await settleShelf(t, by: const Duration(milliseconds: 500));
    await t.enterText(find.byType(EditableText).first, 'x');
    FocusManager.instance.primaryFocus?.unfocus();
    await settleShelf(t, by: const Duration(milliseconds: 700));
    expect(find.text('That bookmark was removed on another device.'), findsOneWidget);
    expect(find.byType(MarginalNote), findsOneWidget);
  });

  testWidgets('Remove shows the 8 s Undo toast and Undo restores the bookmark', (t) async {
    final r = await _pump(t, [mark('a'), mark('b', series: 2)]);
    await t.tap(find.text('Remove').first);
    await settleShelf(t, by: const Duration(milliseconds: 700));
    expect(r.outbox.removed, ['a']);
    expect(find.text('Bookmark removed'), findsOneWidget);
    expect(find.byType(MarginalNote), findsOneWidget);
    await t.tap(find.text('Undo'));
    await settleShelf(t, by: const Duration(milliseconds: 700));
    expect(r.outbox.restored.single.clientId, 'a');
    expect(find.byType(MarginalNote), findsNWidgets(2));
    await settleShelf(t, by: const Duration(seconds: 9));
  });

  testWidgets('a swipe left on a phone removes a note', (t) async {
    final r = await _pump(t, [mark('a'), mark('b', series: 2)]);
    await t.drag(find.byType(CineSwipeRow).first, const Offset(-320, 0));
    await settleShelf(t, by: const Duration(milliseconds: 1000));
    expect(r.outbox.removed.length, 1);
    expect(find.text('Bookmark removed'), findsOneWidget);
    await settleShelf(t, by: const Duration(seconds: 9));
  });

  testWidgets('from 900 px the notes run in two columns with a rule between', (t) async {
    await _pump(t, [mark('a'), mark('b', series: 2), mark('c', series: 3)], size: const Size(1024, 1366));
    expect(find.byKey(const Key('bookmarks-two-columns')), findsOneWidget);
    final lefts = {for (final e in find.byType(MarginalNote).evaluate()) t.getTopLeft(find.byWidget(e.widget)).dx.round()};
    expect(lefts.length, 2);
  });

  testWidgets('the series filter narrows the list', (t) async {
    await _pump(t, [mark('a'), mark('b', series: 2)]);
    await t.tap(find.byKey(const Key('bookmarks-filter')));
    await settleShelf(t, by: const Duration(milliseconds: 800));
    await t.tap(find.text('Series 2').last);
    await settleShelf(t, by: const Duration(milliseconds: 600));
    expect(find.byType(MarginalNote), findsOneWidget);
  });

  testWidgets('the outbox flushes before the list and a caption says so', (t) async {
    final r = await _pump(t, [mark('a')], pending: 3);
    expect(r.outbox.flushes, 1);
    expect(find.text('Synced 3 bookmarks'), findsOneWidget);
  });

  testWidgets('the states: empty, error, offline caption', (t) async {
    await _pump(t, []);
    expect(find.text('NO MARKS YET'), findsOneWidget);
    expect(_headline('No bookmarks yet.'), findsOneWidget);
    expect(find.text('Go to library'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await _pump(t, [], error: const ApiError(statusCode: 500, code: 'x', message: 'x'));
    expect(find.text('CORRECTION'), findsOneWidget);
    expect(_headline("Bookmarks didn't load."), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    final off = await _pump(t, [mark('a')], offline: true);
    expect(find.text("Changes sync when you're back online"), findsOneWidget);
    expect(find.byType(MarginalNote), findsOneWidget);
    off.rig.container.read(offlineEditionControllerProvider).dispose();
  });

  testWidgets('J moves to a note, E edits its note', (t) async {
    await _pump(t, [mark('a'), mark('b', series: 2)]);
    await t.sendKeyEvent(LogicalKeyboardKey.keyJ);
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.keyE);
    await settleShelf(t, by: const Duration(milliseconds: 500));
    expect(find.byType(CineTextField), findsOneWidget);
  });

  testWidgets('Delete removes the focused note with no dialog and an Undo toast', (t) async {
    final r = await _pump(t, [mark('a'), mark('b', series: 2)]);
    await t.sendKeyEvent(LogicalKeyboardKey.keyJ);
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.delete);
    await settleShelf(t, by: const Duration(milliseconds: 600));
    expect(r.outbox.removed, isNotEmpty);
    expect(find.text('Bookmark removed'), findsOneWidget);
    await settleShelf(t, by: const Duration(seconds: 9));
  });

  test('folios', () {
    expect(bookmarkFolio(mark('a', novel: true)), 'CH 14 · 59% IN');
    expect(bookmarkFolio(mark('a', chapter: 14.5)), 'CH 14.5 · PAGE 7');
  });
}
