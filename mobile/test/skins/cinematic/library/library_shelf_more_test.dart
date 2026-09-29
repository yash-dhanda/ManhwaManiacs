// ignore_for_file: require_trailing_commas, directives_ordering
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/shelf_query.dart';
import 'package:manhwamaniacs/features/library/models/tag.dart';
import 'package:manhwamaniacs/features/library/utils/followed_series_cache.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/library_poster.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_badge.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_confirm_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/library/filters_sheet.dart';

import '../feature/feature_test_support.dart' show FakeUpdates;
import 'library_test_support.dart';

const _storedKey = 'mm.shelf-query.u1p1';

Map<String, Object> _stored(ShelfQuery q) => {_storedKey: q.toStoredJson()};

String? _focus() => FocusManager.instance.primaryFocus?.debugLabel;

Future<void> _key(WidgetTester t, LogicalKeyboardKey k) async {
  await t.sendKeyEvent(k);
  await t.pump(const Duration(milliseconds: 100));
}

Future<void> _settleKeys(WidgetTester t) => settleShelf(t, by: const Duration(milliseconds: 800));

Finder _tab(String label) => find.byWidgetPredicate(
      (w) => w is Semantics && (w.properties.button ?? false) && w.properties.selected != null && (w.properties.label ?? '').toLowerCase().startsWith(label.toLowerCase()),
    );

void main() {
  group('/library/browse', () {
    testWidgets('opens the Filters sheet once on a phone; returning to the tab does not reopen it', (t) async {
      final rig = await pumpShelf(t, start: '/library/browse');
      await settleShelf(t, by: const Duration(seconds: 1));
      expect(find.byType(FiltersSheetBody), findsOneWidget);
      await t.tap(find.text('Done'));
      await settleShelf(t, by: const Duration(seconds: 1));
      expect(find.byType(FiltersSheetBody), findsNothing);
      await t.tap(_tab('Downloads'));
      await settleShelf(t, by: const Duration(seconds: 1));
      await t.tap(_tab('Library'));
      await settleShelf(t, by: const Duration(seconds: 1));
      expect(rig.at, '/library/browse');
      expect(find.byType(FiltersSheetBody), findsNothing);
    });

    testWidgets('a tablet does not open it (its toolbar is open)', (t) async {
      await pumpShelf(t, start: '/library/browse', size: const Size(834, 1194));
      await settleShelf(t, by: const Duration(seconds: 1));
      expect(find.byType(FiltersSheetBody), findsNothing);
    });

    testWidgets('?status=reading is honoured for the visit', (t) async {
      final rig = await pumpShelf(t, start: '/library/browse?status=reading');
      expect(rig.lib.lastList['reading_status'], 'reading');
    });
  });

  group('hardware keyboard', () {
    testWidgets('H J K L and the arrows, Home and End move the focus around the wall', (t) async {
      await pumpShelf(t);
      await _key(t, LogicalKeyboardKey.keyJ);
      expect(_focus(), 'shelf-0');
      await _key(t, LogicalKeyboardKey.keyL);
      expect(_focus(), 'shelf-1');
      await _key(t, LogicalKeyboardKey.keyJ);
      expect(_focus(), 'shelf-4');
      await _key(t, LogicalKeyboardKey.keyK);
      expect(_focus(), 'shelf-1');
      await _key(t, LogicalKeyboardKey.keyH);
      expect(_focus(), 'shelf-0');
      await _key(t, LogicalKeyboardKey.arrowRight);
      expect(_focus(), 'shelf-1');
      await _key(t, LogicalKeyboardKey.arrowDown);
      expect(_focus(), 'shelf-4');
      await _key(t, LogicalKeyboardKey.arrowLeft);
      expect(_focus(), 'shelf-3');
      await _key(t, LogicalKeyboardKey.arrowUp);
      expect(_focus(), 'shelf-0');
      await _key(t, LogicalKeyboardKey.end);
      await _settleKeys(t);
      expect(_focus(), 'shelf-11');
      await _key(t, LogicalKeyboardKey.home);
      await _settleKeys(t);
      expect(_focus(), 'shelf-0');
    });

    testWidgets('Enter opens the focused series', (t) async {
      final rig = await pumpShelf(t, extra: [updatesProvider.overrideWith(() => FakeUpdates(Recorder(), const []))]);
      await _key(t, LogicalKeyboardKey.keyJ);
      await _key(t, LogicalKeyboardKey.enter);
      await settleShelf(t, by: const Duration(seconds: 1));
      expect(rig.at, '/library/1');
    });

    testWidgets('X enters select mode, Space toggles the focused poster, Ctrl+A selects all, X leaves', (t) async {
      await pumpShelf(t);
      await _key(t, LogicalKeyboardKey.keyX);
      expect(find.text('0 SELECTED'), findsOneWidget);
      await _key(t, LogicalKeyboardKey.keyJ);
      await _key(t, LogicalKeyboardKey.space);
      expect(find.text('1 SELECTED'), findsOneWidget);
      await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.keyA);
      await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('12 SELECTED'), findsOneWidget);
      await _key(t, LogicalKeyboardKey.keyX);
      expect(find.textContaining('SELECTED'), findsNothing);
    });

    testWidgets('F favourites the focused series', (t) async {
      final rig = await pumpShelf(t);
      await _key(t, LogicalKeyboardKey.keyJ);
      await _key(t, LogicalKeyboardKey.keyF);
      await _settleKeys(t);
      expect(rig.lib.patches.single, {'id': 1, 'is_favorite': true});
    });

    testWidgets('1 to 7 pick the status filters in slug-line order', (t) async {
      final rig = await pumpShelf(t);
      const keys = [LogicalKeyboardKey.digit1, LogicalKeyboardKey.digit2, LogicalKeyboardKey.digit3, LogicalKeyboardKey.digit4, LogicalKeyboardKey.digit5, LogicalKeyboardKey.digit6, LogicalKeyboardKey.digit7];
      const wire = [null, 'reading', 'unread', 'completed', 'on_hold', 'plan_to_read', 'dropped'];
      for (var i = 0; i < 7; i++) {
        await _key(t, keys[i]);
        await _settleKeys(t);
        expect(rig.lib.lastList['reading_status'], wire[i], reason: 'key ${i + 1}');
      }
    });

    testWidgets('S cycles the sort, V the density, R reprints', (t) async {
      final rig = await pumpShelf(t);
      await _key(t, LogicalKeyboardKey.keyS);
      await _settleKeys(t);
      expect(rig.lib.lastList['sort'], 'recently_added');
      await _key(t, LogicalKeyboardKey.keyV);
      await _settleKeys(t);
      final lefts = {for (final e in find.byType(LibraryPoster).evaluate()) t.getTopLeft(find.byWidget(e.widget)).dx.roundToDouble()};
      expect(lefts.length, 4, reason: 'COMPACT is 4 per row');
      final calls = rig.lib.shelfCalls.length;
      await _key(t, LogicalKeyboardKey.keyR);
      await _settleKeys(t);
      expect(rig.lib.shelfCalls.length, greaterThan(calls));
    });

    testWidgets('/ opens and focuses the search; typing letters does not run the wall keys', (t) async {
      final rig = await pumpShelf(t);
      await _key(t, LogicalKeyboardKey.slash);
      await settleShelf(t, by: const Duration(milliseconds: 400));
      expect(find.byType(EditableText), findsOneWidget);
      await t.enterText(find.byType(EditableText), 'jkx');
      await t.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('SELECTED'), findsNothing);
      await settleShelf(t, by: const Duration(seconds: 1));
      expect(rig.lib.lastList['search'], 'jkx');
    });

    testWidgets('Alt+Right moves the focused poster in Manual order and announces it', (t) async {
      final l = ShelfLibrary(all: [for (var i = 0; i < 6; i++) shelfSeries(i + 1, sortOrder: i)]);
      await pumpShelf(t, lib: l, prefs: _stored(const ShelfQuery(sort: ShelfSort.manual)));
      await _key(t, LogicalKeyboardKey.keyJ);
      await t.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await t.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await settleShelf(t, by: const Duration(seconds: 1));
      expect({for (final p in l.patches) p['id']: p['sort_order']}, {1: 1, 2: 0});
    });
  });

  group('Quick look', () {
    testWidgets('long press offers the actions; Favourite, Status, Notify and Remove write through', (t) async {
      final rig = await pumpShelf(t, extra: [updatesProvider.overrideWith(() => FakeUpdates(Recorder(), const []))]);
      Future<void> open() async {
        await t.longPress(find.byType(LibraryPoster).first);
        await settleShelf(t, by: const Duration(milliseconds: 800));
      }

      await open();
      for (final a in ['Open', 'Favourite', 'Status', 'Notify', 'Add to collection', 'Download next 5', 'Remove from library']) {
        expect(find.text(a), findsOneWidget, reason: a);
      }
      await t.tap(find.text('Favourite'));
      await settleShelf(t, by: const Duration(milliseconds: 800));
      expect(rig.lib.patches.last, {'id': 1, 'is_favorite': true});
      await open();
      await t.tap(find.text('Notify'));
      await settleShelf(t, by: const Duration(milliseconds: 800));
      expect(rig.lib.patches.last, {'id': 1, 'notify': true});
      await open();
      await t.tap(find.text('Status'));
      await settleShelf(t, by: const Duration(milliseconds: 800));
      await t.tap(find.text('DONE').last);
      await settleShelf(t, by: const Duration(milliseconds: 800));
      expect(rig.lib.patches.last, {'id': 1, 'reading_status': 'completed'});
    });

    testWidgets('Remove from library commits at once with an Undo that restores the series', (t) async {
      final lib = ShelfLibrary(all: [shelfSeries(1, fav: true, status: 'on_hold'), shelfSeries(2)]);
      final rig = await pumpShelf(t, lib: lib);
      await t.longPress(find.byType(LibraryPoster).first);
      await settleShelf(t, by: const Duration(milliseconds: 800));
      await t.tap(find.text('Remove from library'));
      await settleShelf(t, by: const Duration(milliseconds: 800));
      expect(lib.unfollowed, [1]);
      final toast = rig.container.read(cineToastsProvider).last;
      expect(toast.text, 'Removed Series 1. Your reading progress is kept.');
      expect(toast.actionLabel, 'Undo');
      expect(toast.hold, const Duration(milliseconds: 8000));
      toast.onAction!();
      await settleShelf(t, by: const Duration(seconds: 1));
      expect(lib.followedAgain, ['shelf/series-1']);
      expect(lib.patches.last['is_favorite'], true);
      expect(lib.patches.last['reading_status'], 'on_hold');
    });

    testWidgets('offline keeps only Open and Continue', (t) async {
      final lib = ShelfLibrary(all: [shelfSeries(1)], failList: true);
      final rows = [shelfSeries(1)];
      await pumpShelf(t, lib: lib, saved: [savedGroup(1)], prefs: {followedSeriesCacheKeyFor('u1p1'): jsonEncode([for (final r in rows) r.toJson()])});
      await t.longPress(find.byType(LibraryPoster).first);
      await settleShelf(t, by: const Duration(milliseconds: 800));
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Favourite'), findsNothing);
      expect(find.text('Remove from library'), findsNothing);
    });
  });

  group('offline edition and the 18+ gate', () {
    final rows = [shelfSeries(1), shelfSeries(2, rating: 'mature')];
    final cache = {followedSeriesCacheKeyFor('u1p1'): jsonEncode([for (final r in rows) r.toJson()])};

    testWidgets('gate closed: a saved mature series is absent and nothing mentions it', (t) async {
      await pumpShelf(t, lib: ShelfLibrary(all: rows, failList: true), saved: [savedGroup(1), savedGroup(2)], prefs: cache);
      expect(find.byKey(const Key('shelf-offline-banner')), findsOneWidget);
      expect(find.byType(LibraryPoster), findsOneWidget);
      expect(find.text('Series 2'), findsNothing);
      expect(find.byWidgetPredicate((w) => w is CineBadge && w.variant == CineBadgeVariant.certificate), findsNothing);
    });

    testWidgets('gate open: it appears with the 18 certificate', (t) async {
      await pumpShelf(t, lib: ShelfLibrary(all: rows, failList: true), saved: [savedGroup(1), savedGroup(2)], prefs: cache, gateOpen: true);
      expect(find.byType(LibraryPoster), findsNWidgets(2));
      expect(find.byWidgetPredicate((w) => w is CineBadge && w.variant == CineBadgeVariant.certificate), findsOneWidget);
    });

    testWidgets('offline disables the toolbar: taps on Select do nothing', (t) async {
      await pumpShelf(t, lib: ShelfLibrary(all: rows, failList: true), saved: [savedGroup(1)], prefs: cache);
      await t.tap(find.text('Select'), warnIfMissed: false);
      await settleShelf(t, by: const Duration(milliseconds: 400));
      expect(find.textContaining('SELECTED'), findsNothing);
    });
  });

  group('tags', () {
    ShelfLibrary lib() => ShelfLibrary(
          all: [shelfSeries(1)],
          tags: const [Tag(id: 1, name: 'slow burn', category: 'custom'), Tag(id: 4, name: 'dungeon', category: 'custom')],
        );

    Future<ShelfLibrary> open(WidgetTester t) async {
      final l = lib();
      await pumpShelf(t, lib: l);
      await t.tap(find.text('Filters'));
      await settleShelf(t, by: const Duration(milliseconds: 600));
      await t.ensureVisible(find.text('Manage tags…'));
      await t.tap(find.text('Manage tags…'));
      await settleShelf(t, by: const Duration(milliseconds: 800));
      return l;
    }

    testWidgets('rename saves through the keyboard done action', (t) async {
      final l = await open(t);
      await t.enterText(find.byType(TextField).first, 'renamed');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await settleShelf(t, by: const Duration(milliseconds: 800));
      expect(l.tagCalls, ['rename:1:renamed']);
    });

    testWidgets('New tag adds a row whose field creates the tag', (t) async {
      final l = await open(t);
      await t.tap(find.text('New tag'));
      await settleShelf(t, by: const Duration(milliseconds: 500));
      await t.enterText(find.byType(TextField).last, 'fresh');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await settleShelf(t, by: const Duration(milliseconds: 800));
      expect(l.tagCalls, ['create:fresh']);
    });

    testWidgets('delete asks first and its confirm is dead for the 1000 ms arm', (t) async {
      final l = await open(t);
      await t.tap(find.byTooltip('Delete tag').first);
      await settleShelf(t, by: const Duration(milliseconds: 500));
      expect(find.byWidgetPredicate((w) => w is CineConfirmDialog && w.title == 'Delete the tag slow burn? It comes off every series.'), findsOneWidget);
      await t.tap(find.text('Delete tag'));
      await t.pump(const Duration(milliseconds: 100));
      expect(l.tagCalls, isEmpty);
      await t.pump(const Duration(milliseconds: 1200));
      await t.tap(find.text('Delete tag'));
      await settleShelf(t, by: const Duration(milliseconds: 800));
      expect(l.tagCalls, ['delete:1']);
    });

    testWidgets('an empty profile says so', (t) async {
      final l = ShelfLibrary(all: [shelfSeries(1)]);
      await pumpShelf(t, lib: l);
      // No tags: the Filters sheet has no TAGS section, so open the sheet directly.
      await t.tap(find.text('Filters'));
      await settleShelf(t, by: const Duration(milliseconds: 600));
      expect(find.text('TAGS'), findsNothing);
    });
  });

  group('reflow', () {
    for (final scale in [1.3, 1.5, 2.0]) {
      testWidgets('text scale $scale lays out the shelf without overflow', (t) async {
        await pumpShelf(t, textScale: scale);
        expect(t.takeException(), isNull);
        expect(find.byType(LibraryPoster), findsWidgets);
      });
    }

    testWidgets('reduced motion shows the wall at once', (t) async {
      await pumpShelf(t, reduced: true);
      expect(find.byType(LibraryPoster), findsWidgets);
      expect(t.takeException(), isNull);
    });
  });
}
