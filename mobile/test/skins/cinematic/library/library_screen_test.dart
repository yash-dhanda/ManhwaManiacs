// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/library/models/shelf_query.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/library/models/tag.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/book_list_row.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/library_poster.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_badge.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_confirm_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_galley.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_switch.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_reorderable_wall.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/typed_headline.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/library/shelf_wall.dart';

import 'library_test_support.dart';

const _tablet = Size(834, 1194);
const _storedKey = 'mm.shelf-query.u1p1';

Map<String, Object> _stored(ShelfQuery q) => {_storedKey: q.toStoredJson()};

/// How many distinct left edges the posters have (the columns of the wall).
int _columns(WidgetTester t) {
  final lefts = <double>{};
  for (final e in find.byType(LibraryPoster).evaluate()) {
    lefts.add(t.getTopLeft(find.byWidget(e.widget)).dx.roundToDouble());
  }
  return lefts.length;
}

Finder _headline(String s) => find.byWidgetPredicate((w) => w is TypedHeadline && w.text == s);

Future<void> _openFilters(WidgetTester t) async {
  await t.tap(find.text('Filters'));
  await settleShelf(t, by: const Duration(milliseconds: 600));
}

void main() {
  group('density', () {
    testWidgets('WALL shows 3 per row at 390 px and 5 at 834 px', (t) async {
      await pumpShelf(t);
      expect(find.byType(LibraryPoster), findsWidgets);
      expect(_columns(t), 3);
    });

    testWidgets('WALL 5 per row on a tablet', (t) async {
      await pumpShelf(t, size: _tablet);
      expect(_columns(t), 5);
    });

    testWidgets('COMPACT shows 4 per row on a phone and 7 on a tablet, no captions', (t) async {
      await pumpShelf(t, prefs: _stored(const ShelfQuery(density: ShelfDensity.compact)));
      expect(_columns(t), 4);
      expect(find.text('CH 12 OF 40'), findsNothing);
    });

    testWidgets('COMPACT 7 per row on a tablet', (t) async {
      await pumpShelf(t, size: _tablet, prefs: _stored(const ShelfQuery(density: ShelfDensity.compact)));
      expect(_columns(t), 7);
    });

    testWidgets('LIST rows are 72 px', (t) async {
      await pumpShelf(t, prefs: _stored(const ShelfQuery(density: ShelfDensity.list)));
      final row = find.byType(LibraryListRow).first;
      expect(t.getSize(row).height, 72);
    });

    testWidgets('the wall is lazy: 200 rows build fewer than 40 posters', (t) async {
      final lib = ShelfLibrary(all: [for (var i = 1; i <= 200; i++) shelfSeries(i)]);
      await pumpShelf(t, lib: lib);
      expect(find.byType(LibraryPoster).evaluate().length, lessThan(40));
    });
  });

  group('server-side sorts and filters', () {
    testWidgets('every sort sends its mapped parameter, filters send theirs', (t) async {
      final rig = await pumpShelf(t);
      expect(rig.lib.lastList['sort'], 'recently_updated');
      await _openFilters(t);
      await t.tap(find.text('Recently read'));
      await settleShelf(t);
      expect(rig.lib.lastList['sort'], '-last_read_at');
      await t.tap(find.text('Most unread'));
      await settleShelf(t);
      expect(rig.lib.lastList['sort'], '-new_count');
      await t.tap(find.text('Title A–Z'));
      await settleShelf(t);
      expect(rig.lib.lastList['sort'], 'title');
      await t.tap(find.text('Recently added'));
      await settleShelf(t);
      expect(rig.lib.lastList['sort'], 'recently_added');
      await t.tap(find.text('Manual order'));
      await settleShelf(t);
      expect(rig.lib.lastList['sort'], 'sort_order');
      await t.tap(find.byType(CineSwitch).at(1));
      await settleShelf(t);
      expect(rig.lib.lastList['new_only'], true);
      await t.tap(find.byType(CineSwitch).at(0));
      await settleShelf(t);
      expect(rig.lib.lastList['is_favorite'], true);
    });

    testWidgets('tags send tag_ids and show as removable tokens; Clear filters resets', (t) async {
      final lib = ShelfLibrary(
        all: [for (var i = 1; i <= 6; i++) shelfSeries(i, tags: [Tag(id: i % 2 == 0 ? 4 : 1, name: 'x', category: 'custom')])],
        tags: const [Tag(id: 1, name: 'slow burn', category: 'custom'), Tag(id: 4, name: 'dungeon', category: 'custom')],
      );
      await pumpShelf(t, lib: lib);
      final sem = t.ensureSemantics();
      await _openFilters(t);
      await t.ensureVisible(find.text('slow burn'));
      await t.tap(find.text('slow burn'));
      await settleShelf(t);
      await t.ensureVisible(find.text('dungeon'));
      await t.tap(find.text('dungeon'));
      await settleShelf(t);
      expect(lib.lastList['tag_ids'], [1, 4]);
      await t.tap(find.text('Done'));
      await settleShelf(t);
      expect(find.bySemanticsLabel('Remove slow burn'), findsOneWidget);
      expect(find.bySemanticsLabel('Remove dungeon'), findsOneWidget);
      await t.tap(find.bySemanticsLabel('Remove slow burn'));
      await settleShelf(t);
      expect(lib.lastList['tag_ids'], [4]);
      await t.tap(find.text('Clear filters'));
      await settleShelf(t);
      expect(lib.lastList['tag_ids'], isNull);
      expect(find.text('Clear filters'), findsNothing);
      sem.dispose();
    });

    testWidgets('the status slug line filters on the server and shows raised counts', (t) async {
      final lib = ShelfLibrary(all: [shelfSeries(1), shelfSeries(2, status: 'completed'), shelfSeries(3, status: 'completed')]);
      await pumpShelf(t, lib: lib);
      await t.ensureVisible(find.text('DONE').first);
      await t.pump();
      await t.tap(find.text('DONE').first);
      await settleShelf(t);
      expect(lib.lastList['reading_status'], 'completed');
      expect(find.byType(LibraryPoster), findsNWidgets(2));
    });
  });

  group('states', () {
    testWidgets('loading: the galley shows 12 flicker plates after 120 ms', (t) async {
      await pumpShelf(t, lib: ShelfLibrary(all: [shelfSeries(1)], listDelay: const Duration(seconds: 2)), settle: false);
      await t.pump(const Duration(milliseconds: 40));
      expect(find.byType(CineGalleyPlate), findsNothing);
      await t.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const Key('shelf-galley')), findsOneWidget);
      expect(find.byType(CineGalleyPlate), findsNWidgets(12));
      await t.pump(const Duration(seconds: 3));
    });

    testWidgets('empty shelf', (t) async {
      await pumpShelf(t, rows: const []);
      expect(find.text('EMPTY SHELF'), findsOneWidget);
      expect(find.text('Find something'), findsOneWidget);
    });

    testWidgets('filtered empty and search empty', (t) async {
      final rig = await pumpShelf(t, rows: [shelfSeries(1)], prefs: _stored(const ShelfQuery(fav: true)));
      expect(find.text('NOTHING MATCHES'), findsOneWidget);
      await settleShelf(t, by: const Duration(seconds: 3));
      expect(_headline('No series match these filters.'), findsOneWidget);
      await t.tap(find.text('Clear filters').last);
      await settleShelf(t);
      expect(find.byType(LibraryPoster), findsOneWidget);
      expect(rig.lib.lastList['is_favorite'], isNull);
    });

    testWidgets('search empty: typing a search that matches nothing', (t) async {
      final rig = await pumpShelf(t, rows: [shelfSeries(1)], start: '/library?q=zzz');
      await settleShelf(t, by: const Duration(seconds: 3));
      expect(_headline('Nothing on your shelf matches that.'), findsOneWidget);
      expect(find.text('Search every source'), findsOneWidget);
      expect(rig.lib.lastList['search'], 'zzz');
    });

    testWidgets('error: CORRECTION with Try again', (t) async {
      final lib = ShelfLibrary(all: [shelfSeries(1)], listError: const ApiError(statusCode: 500, code: 'boom', message: 'boom'));
      await pumpShelf(t, lib: lib);
      expect(find.text('CORRECTION'), findsOneWidget);
      await settleShelf(t, by: const Duration(seconds: 3));
      expect(_headline("Your shelf didn't load."), findsOneWidget);
      lib.listError = null;
      await t.tap(find.text('Try again'));
      await settleShelf(t);
      expect(find.byType(LibraryPoster), findsOneWidget);
    });

    testWidgets('page-load error after data keeps the wall and offers Retry', (t) async {
      final lib = ShelfLibrary(all: [shelfSeries(1), shelfSeries(2)]);
      await pumpShelf(t, lib: lib);
      lib.listError = const ApiError(statusCode: 500, code: 'boom', message: 'boom');
      await t.drag(find.byType(CustomScrollView).first, const Offset(0, 300));
      await settleShelf(t, by: const Duration(seconds: 2));
      expect(find.byType(LibraryPoster), findsNWidgets(2));
      expect(find.byKey(const Key('shelf-page-error')), findsOneWidget);
    });

    testWidgets('offline with nothing saved', (t) async {
      final lib = ShelfLibrary(all: [shelfSeries(1)], failList: true);
      await pumpShelf(t, lib: lib);
      await settleShelf(t, by: const Duration(seconds: 3));
      expect(_headline('Your shelf needs a connection.'), findsOneWidget);
      expect(find.text('Saved chapters still open from Downloads.'), findsOneWidget);
    });

    testWidgets('an 18+ series is absent with the gate closed; the certificate shows with it open', (t) async {
      final rows = [shelfSeries(1), shelfSeries(2, rating: 'mature')];
      await pumpShelf(t, rows: rows, gateOpen: true);
      expect(find.byWidgetPredicate((w) => w is CineBadge && w.variant == CineBadgeVariant.certificate), findsOneWidget);
    });
  });

  group('select mode and bulk actions', () {
    testWidgets('Select, tap toggles, the bar counts, Favourite runs at most 4 at once', (t) async {
      final lib = ShelfLibrary(all: [for (var i = 1; i <= 12; i++) shelfSeries(i)], patchDelay: const Duration(milliseconds: 50));
      final rig = await pumpShelf(t, lib: lib);
      await t.tap(find.text('Select'));
      await settleShelf(t, by: const Duration(milliseconds: 300));
      for (var i = 0; i < 3; i++) {
        await t.tap(find.byType(LibraryPoster).at(i));
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('3 SELECTED'), findsOneWidget);
      await t.tap(find.text('Select all 12'));
      await t.pump(const Duration(milliseconds: 50));
      expect(find.text('12 SELECTED'), findsOneWidget);
      await t.tap(find.text('Favourite'));
      await settleShelf(t, by: const Duration(seconds: 2));
      expect(rig.lib.peak, lessThanOrEqualTo(4));
      expect(rig.lib.peak, greaterThan(1));
      expect(rig.lib.patches.where((p) => p['is_favorite'] == true).length, 12);
      expect(find.text('Favourited 12 series.'), findsOneWidget);
    });

    testWidgets('Unfollow asks first; its confirm does nothing during the 1000 ms arm', (t) async {
      final rig = await pumpShelf(t);
      await t.tap(find.text('Select'));
      await settleShelf(t, by: const Duration(milliseconds: 300));
      await t.tap(find.byType(LibraryPoster).at(0));
      await t.tap(find.byType(LibraryPoster).at(1));
      await t.pump(const Duration(milliseconds: 50));
      await t.ensureVisible(find.text('Unfollow'));
      await t.tap(find.text('Unfollow'));
      await settleShelf(t, by: const Duration(milliseconds: 500));
      expect(find.byWidgetPredicate((w) => w is CineConfirmDialog && w.title == 'Unfollow 2 series?'), findsOneWidget);
      await t.tap(find.text('Unfollow 2'));
      await t.pump(const Duration(milliseconds: 100));
      expect(rig.lib.unfollowed, isEmpty);
      await t.pump(const Duration(milliseconds: 1200));
      await t.tap(find.text('Unfollow 2'));
      await settleShelf(t, by: const Duration(seconds: 1));
      expect(rig.lib.unfollowed, [1, 2]);
      expect(find.text('Unfollowed 2 series.'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
    });

    testWidgets('Undo re-follows and patches the saved status back', (t) async {
      final lib = ShelfLibrary(all: [shelfSeries(1, fav: true, status: 'on_hold'), shelfSeries(2)]);
      await pumpShelf(t, lib: lib);
      await t.tap(find.text('Select'));
      await settleShelf(t, by: const Duration(milliseconds: 300));
      await t.tap(find.byType(LibraryPoster).at(0));
      await t.pump(const Duration(milliseconds: 50));
      await t.ensureVisible(find.text('Unfollow'));
      await t.tap(find.text('Unfollow'));
      await settleShelf(t, by: const Duration(milliseconds: 1500));
      await t.tap(find.text('Unfollow 1'));
      await settleShelf(t, by: const Duration(seconds: 1));
      await t.tap(find.text('Undo'));
      await settleShelf(t, by: const Duration(seconds: 1));
      expect(lib.followedAgain, ['shelf/series-1']);
      final restore = lib.patches.last;
      expect(restore['is_favorite'], true);
      expect(restore['reading_status'], 'on_hold');
    });

    testWidgets('Android back leaves select mode first', (t) async {
      final rig = await pumpShelf(t);
      await t.tap(find.text('Select'));
      await settleShelf(t, by: const Duration(milliseconds: 300));
      expect(find.text('Done'), findsWidgets);
      await t.binding.handlePopRoute();
      await settleShelf(t, by: const Duration(milliseconds: 300));
      expect(find.textContaining('SELECTED'), findsNothing);
      expect(rig.at, '/library');
    });

    testWidgets('route ?select=1 opens select mode on mount', (t) async {
      await pumpShelf(t, start: '/library?select=1');
      expect(find.textContaining('SELECTED'), findsOneWidget);
    });
  });

  group('manual order', () {
    ShelfLibrary lib() => ShelfLibrary(all: [for (var i = 0; i < 6; i++) shelfSeries(i + 1, sortOrder: i)]);

    testWidgets('Move to top from Quick look writes only the changed sort_order values', (t) async {
      final l = lib();
      await pumpShelf(t, lib: l, prefs: _stored(const ShelfQuery(sort: ShelfSort.manual)));
      await t.longPress(find.byType(LibraryPoster).at(3));
      await settleShelf(t, by: const Duration(milliseconds: 800));
      await t.tap(find.text('Move to top'));
      await settleShelf(t, by: const Duration(milliseconds: 800));
      final written = {for (final p in l.patches) p['id']: p['sort_order']};
      expect(written, {4: 0, 1: 1, 2: 2, 3: 3});
    });

    testWidgets('handles show only over the whole, unfiltered shelf', (t) async {
      await pumpShelf(t, lib: lib(), prefs: _stored(const ShelfQuery(sort: ShelfSort.manual)));
      expect(find.byType(CineWallHandle), findsNWidgets(6));
    });

    testWidgets('a filter removes the handles', (t) async {
      final l = ShelfLibrary(all: [for (var i = 0; i < 6; i++) shelfSeries(i + 1, sortOrder: i, fav: true)]);
      await pumpShelf(t, lib: l, prefs: _stored(const ShelfQuery(sort: ShelfSort.manual, fav: true)));
      expect(find.byType(LibraryPoster), findsWidgets);
      expect(find.byType(CineWallHandle), findsNothing);
    });
  });

  group('novels', () {
    testWidgets('the book list is one column at 390 px, two at 834 px', (t) async {
      final rows = [for (var i = 1; i <= 4; i++) shelfSeries(i, title: 'Book $i', chapters: 412)];
      await pumpShelf(t, rows: rows, mode: ContentMode.novel, novelsEnabled: true, extra: _novelIndex);
      expect(find.byType(BookListRow), findsWidgets);
      final lefts = {for (final e in find.byType(BookListRow).evaluate()) t.getTopLeft(find.byWidget(e.widget)).dx.roundToDouble()};
      expect(lefts.length, 1);
      expect(find.text('412 CHAPTERS · SHELF'), findsWidgets);
    });

    testWidgets('two columns from 768 px', (t) async {
      final rows = [for (var i = 1; i <= 4; i++) shelfSeries(i, title: 'Book $i', chapters: 412)];
      await pumpShelf(t, rows: rows, size: _tablet, mode: ContentMode.novel, novelsEnabled: true, extra: _novelIndex);
      final lefts = {for (final e in find.byType(BookListRow).evaluate()) t.getTopLeft(find.byWidget(e.widget)).dx.roundToDouble()};
      expect(lefts.length, 2);
    });
  });
}

final _novelIndex = <Override>[sourceModeIndexProvider.overrideWithValue({'shelf': ContentMode.novel})];

