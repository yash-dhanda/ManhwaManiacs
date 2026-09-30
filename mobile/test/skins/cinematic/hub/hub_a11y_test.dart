// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/utils/smart_shelf.dart';
import 'package:manhwamaniacs/features/library/providers/bookmarks_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/bookmark_outbox_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/typed_headline.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/updates/updates_new.dart';

import 'hub_test_support.dart';

const _phone = Size(390, 844);

HubLibrary _lib() => HubLibrary(
      all: [for (var i = 1; i <= 6; i++) shelfSeries(i, newCount: i == 1 ? 5 : 0)],
      collections: [shelfOf(1, 'Slow burns'), shelfOf(2, 'Smart', order: 1, rules: const ShelfRules(all: [ShelfRule(field: 'reading_status', op: 'eq', value: 'reading')]))],
      members: {1: [('shelf', 'series-1'), ('shelf', 'series-2')]},
      history: [logRow(1, 1), logRow(2, 2, done: true)],
    );

FakeUpdates _updates() => FakeUpdates(notes: [note(1, 1, 141), note(2, 1, 142), note(3, 2, 7)]);

Future<void> _meets(WidgetTester t, TargetPlatform platform) async {
  await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(t, meetsGuideline(platform == TargetPlatform.iOS ? iOSTapTargetGuideline : androidTapTargetGuideline));
}

Future<void> _screen(WidgetTester t, String start, TargetPlatform platform, {List<Override> extra = const [], HubLibrary? lib, Size size = _phone}) async {
  await pumpShelf(t, lib: lib ?? _lib(), start: start, size: size, platform: platform, extra: [...updatesOverrides(_updates()), ...extra]);
}

void main() {
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    final p = platform.name;
    testWidgets('Updates meets the $p tap target guidelines; each chapter folio has its own box, 8 px apart', (t) async {
      final h = t.ensureSemantics();
      await _screen(t, '/updates', platform);
      await _meets(t, platform);
      final folios = find.bySemanticsLabel(RegExp(r'^CH 14[12]$'));
      expect(folios, findsNWidgets(2));
      final a = t.getRect(folios.at(0)), b = t.getRect(folios.at(1));
      final min = platform == TargetPlatform.iOS ? 44.0 : 48.0;
      expect(a.height, greaterThanOrEqualTo(min));
      expect(a.width, greaterThanOrEqualTo(min));
      expect((b.left - a.right).abs() >= 8 || (a.left - b.right).abs() >= 8, isTrue);
      h.dispose();
    });

    testWidgets('Collections meets the $p guidelines, and so does the New shelf sheet', (t) async {
      final h = t.ensureSemantics();
      await _screen(t, '/library/collections', platform);
      await _meets(t, platform);
      await t.tap(find.text('New shelf'));
      await settleShelf(t, by: const Duration(milliseconds: 900));
      await _meets(t, platform);
      h.dispose();
    });

    testWidgets('a shelf page meets the $p guidelines, and so does Add series', (t) async {
      final h = t.ensureSemantics();
      await _screen(t, '/library/collections/1', platform);
      await _meets(t, platform);
      await t.tap(find.text('Add series'));
      await settleShelf(t, by: const Duration(milliseconds: 900));
      await _meets(t, platform);
      h.dispose();
    });

    testWidgets('History meets the $p guidelines', (t) async {
      final h = t.ensureSemantics();
      await _screen(t, '/library/history', platform);
      await _meets(t, platform);
      h.dispose();
    });

    testWidgets('Bookmarks meets the $p guidelines', (t) async {
      final h = t.ensureSemantics();
      final items = [mark('a', novel: true, snippet: 'A line.', note: 'n'), mark('b', series: 2)];
      await _screen(t, '/library/bookmarks', platform, extra: [
        bookmarksProvider.overrideWith(() => FakeBookmarks(items)),
        bookmarkOutboxControllerProvider.overrideWithValue(FakeOutbox(items)),
      ]);
      await _meets(t, platform);
      h.dispose();
    });
  }

  testWidgets('reduced motion: folios and headlines show at once with no typing', (t) async {
    await _screen(t, '/updates', TargetPlatform.android);
    // (a normal run types; see updates_test)
    await t.pumpWidget(const SizedBox());
    await pumpShelf(t, lib: _lib(), start: '/updates', reduced: true, extra: updatesOverrides(_updates()), settle: false);
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('CH 141'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is TypedHeadline && w.text.startsWith('CH ')), findsWidgets);
    await settleShelf(t);
  });

  testWidgets('text at 2.0 does not overflow any of the five screens', (t) async {
    for (final start in ['/updates', '/library/collections', '/library/collections/1', '/library/history', '/library/bookmarks']) {
      await pumpShelf(t, lib: _lib(), start: start, textScale: 2, extra: [
        ...updatesOverrides(_updates()),
        if (start.endsWith('bookmarks')) ...[
          bookmarksProvider.overrideWith(() => FakeBookmarks([mark('a', novel: true, snippet: 'A line of the book.', note: 'n')])),
          bookmarkOutboxControllerProvider.overrideWithValue(FakeOutbox([mark('a')])),
        ],
      ]);
      expect(tester(t), isNull, reason: start);
      await t.pumpWidget(const SizedBox());
    }
  });

  test('folio words', () {
    expect(updateFolio((notificationId: 1, chapterKey: 'c', chapterNumber: 141, title: '', read: false)), 'CH 141');
    expect(updateFolio((notificationId: 1, chapterKey: 'c', chapterNumber: 14.5, title: '', read: false)), 'CH 14.5');
    expect(updateFolio((notificationId: 1, chapterKey: 'c', chapterNumber: null, title: '', read: false)), 'NEW');
  });
}

/// A pumped frame with an overflow throws inside the test, so reaching here is the check.
Object? tester(WidgetTester t) => t.takeException();
