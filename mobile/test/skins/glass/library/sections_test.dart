import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/collection.dart';
import 'package:manhwamaniacs/features/library/models/reading_history_item.dart';
import 'package:manhwamaniacs/features/library/providers/bookmarks_provider.dart';
import 'package:manhwamaniacs/features/reader/models/bookmark.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/row_shell.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/add_series_sheet.dart';

import '../../../features/library/shelf_fixtures.dart';
import '../../../screenshots/support/shot_harness.dart';
import 'library_rig.dart';

Future<void> _settle(WidgetTester t, [int steps = 6]) async {
  for (var i = 0; i < steps; i++) {
    await t.pump(const Duration(milliseconds: 150));
  }
}

ReadingHistoryItem historyItem(int i) => ReadingHistoryItem(
      id: i,
      sourceId: 'shelf',
      seriesKey: 'series-$i',
      chapterKey: 'c$i',
      chapterNumber: i.toDouble(),
      lastPage: 3,
      pageCount: 20,
      isCompleted: false,
      lastReadAt: DateTime.now().subtract(Duration(minutes: i)),
      seriesTitle: 'Read $i',
    );

Bookmark bookmark(String id, {String series = 'series-1', String? title}) => Bookmark(
      clientId: id,
      id: id.hashCode,
      sourceId: 'shelf',
      seriesKey: series,
      chapterKey: 'c12',
      chapterNumber: 12,
      anchorIndex: 7,
      seriesTitle: title ?? 'Series of $id',
      createdAt: DateTime(2026, 9, 28, 21, 41),
      updatedAt: DateTime(2026, 9, 28, 21, 41),
    );

/// The bookmarks list from memory; [next] replaces it on the next build (a sync that dropped a row).
class FakeBookmarks extends BookmarksNotifier {
  FakeBookmarks(this.rows);
  List<Bookmark> rows;

  @override
  Future<BookmarksState> build() async => BookmarksState(bookmarks: rows);

  void drop(String clientId) {
    rows = [for (final b in rows) if (b.clientId != clientId) b];
    state = AsyncData(BookmarksState(bookmarks: rows));
  }
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('a collection card opens its detail', (t) async {
    final lib = FakeLib(
      series: [shelfSeries(1, title: 'Alpha'), shelfSeries(2, title: 'Beta')],
      collections: const [Collection(id: 3, name: 'Weekend reads', seriesCount: 0, sortOrder: 0)],
    );
    final rig = await pumpLibrary(t, lib, start: '/library/collections');
    await t.tap(find.text('Weekend reads').first);
    await _settle(t, 10);
    expect(rig.at, '/library/collections/3');
    expect(lib.calls, contains('getCollection:3'));
  });

  testWidgets('Add series keeps the sheet open', (t) async {
    final lib = FakeLib(
      series: [shelfSeries(1, title: 'Alpha'), shelfSeries(2, title: 'Beta')],
      collections: const [Collection(id: 3, name: 'Weekend reads', seriesCount: 0, sortOrder: 0)],
    );
    final rig = await pumpLibrary(t, lib, start: '/library/collections/3');
    rig.router.go('/library/collections/3?sheet=add-series&collection=3');
    await _settle(t, 10);
    expect(find.byType(GlassAddSeriesBody), findsOneWidget);
    final rows = find.descendant(of: find.byType(GlassAddSeriesBody), matching: find.byType(GlassRowShell));
    expect(rows, findsNWidgets(2), reason: 'Alpha and Beta are not in the collection yet');
    t.widget<GlassRowShell>(rows.first).onTap!();
    await _settle(t, 10);
    expect(lib.calls, contains('addToCollection:3:series-1'));
    expect(find.byType(GlassAddSeriesBody), findsOneWidget, reason: 'the sheet stays open');
  });

  testWidgets('History "Load more" fetches the next page', (t) async {
    final lib = FakeLib(history: [for (var i = 1; i <= 60; i++) historyItem(i)]);
    await pumpLibrary(t, lib, start: '/library/history');
    expect(lib.calls, contains('history:0:true'));
    await t.scrollUntilVisible(find.text('Load more'), 400, scrollable: find.byType(Scrollable).last);
    await t.tap(find.text('Load more'));
    await _settle(t);
    expect(lib.calls, contains('history:50:true'));
  });

  testWidgets('the bookmark filter chip shows one series and its × clears both parameters', (t) async {
    final bms = FakeBookmarks([bookmark('a', title: 'Solo Leveling'), bookmark('b', series: 'series-2', title: 'Other one')]);
    final rig = await pumpLibrary(t, FakeLib(), start: '/library/bookmarks?source=shelf&series=series-1', extra: [bookmarksProvider.overrideWith(() => bms)]);
    expect(find.text('Other one'), findsNothing);
    expect(find.text('Solo Leveling'), findsWidgets);
    t.widget<GlassChip>(find.widgetWithText(GlassChip, 'Solo Leveling')).onRemove!();
    await _settle(t);
    final loc = rig.router.routerDelegate.currentConfiguration.uri;
    expect(loc.queryParameters.containsKey('source'), isFalse);
    expect(loc.queryParameters.containsKey('series'), isFalse);
    expect(find.text('Other one'), findsWidgets);
  });

  testWidgets('a bookmark removed on another device drops with its toast', (t) async {
    final bms = FakeBookmarks([bookmark('a', title: 'Alpha mark'), bookmark('b', title: 'Beta mark')]);
    await pumpLibrary(t, FakeLib(), start: '/library/bookmarks', extra: [bookmarksProvider.overrideWith(() => bms)]);
    expect(find.text('Alpha mark'), findsWidgets);
    bms.drop('a');
    await _settle(t);
    expect(find.text('Alpha mark'), findsNothing);
    expect(find.text('That bookmark was removed on another device'), findsOneWidget);
  });
}
