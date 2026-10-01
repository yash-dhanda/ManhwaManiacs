// ignore_for_file: require_trailing_commas, directives_ordering, avoid_redundant_argument_values
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/ai/providers/ai_providers.dart';
import 'package:manhwamaniacs/features/ai/providers/suggested_tags_provider.dart';
import 'package:manhwamaniacs/features/ai/repositories/ai_repository.dart';
import 'package:manhwamaniacs/features/home/utils/continue_hidden.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/tonight_screen.dart';

import 'tonight_test_support.dart';

const _stamp = {'mm.tonight.typed.u1p1': '{"date":"2026-09-30","variant":"normal"}'};
const _tall = Size(390, 6200);

ProviderContainer _container(WidgetTester t) => ProviderScope.containerOf(t.element(find.byType(TonightScreen)));

Future<void> _pump(WidgetTester t, String feed, {Size size = _tall, double textScale = 1, bool wide = false}) async {
  await pumpTonight(t, feed: feed, size: size, textScale: textScale, wide: wide, prefs: _stamp);
  await settleTonight(t, by: const Duration(seconds: 3));
}

void main() {
  testWidgets('Continue reading cuttings: folio captions, nudges, and a tap continues by the wipe', (t) async {
    final rig = await (() async {
      final r = await pumpTonight(t, feed: 'ready', size: _tall, prefs: _stamp);
      await settleTonight(t, by: const Duration(seconds: 3));
      return r;
    })();
    expect(find.text('CH 142 · 70%'), findsOneWidget);
    expect(find.text('2 NEW'), findsWidgets);
    expect(find.text('ALMOST DONE'), findsOneWidget);
    await t.drag(find.text('CH 142 · 70%'), const Offset(-2000, 0));
    await settleTonight(t, by: const Duration(seconds: 1));
    expect(find.text('NEXT · CH 77'), findsOneWidget, reason: 'a row with no page count');
    expect(find.text('PAUSED 9 D'), findsOneWidget);
    await t.drag(find.text('NEXT · CH 77'), const Offset(2000, 0));
    await settleTonight(t, by: const Duration(seconds: 1));
    await t.tap(find.text('CH 142 · 70%'));
    await settleTonight(t, by: const Duration(seconds: 1));
    expect(rig.visited, contains('/reader/shelf/the-lantern-courier/c142'));
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('poster captions: NEW badges, N LEFT, information-only credit', (t) async {
    await _pump(t, 'ready');
    expect(find.text('3 NEW'), findsWidgets);
    expect(find.text('2 LEFT'), findsWidgets);
    expect(find.text('NOT ON YOUR SOURCES'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('long-press a cutting: Quick look with Open, Continue, Previously on, Mark read, Remove from row', (t) async {
    await _pump(t, 'ready');
    await t.longPress(find.text('CH 142 · 70%'));
    await settleTonight(t, by: const Duration(seconds: 1));
    for (final id in ['open', 'continue', 'previously-on', 'mark-read', 'remove-from-row']) {
      expect(find.byKey(Key('quick-look-$id')), findsOneWidget, reason: id);
    }
    expect(find.text('Add to collection'), findsNothing);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('Remove from row hides the cutting, toasts with Undo, and Undo brings it back', (t) async {
    await _pump(t, 'ready');
    await t.longPress(find.text('CH 142 · 70%'));
    await settleTonight(t, by: const Duration(seconds: 1));
    await t.tap(find.text('Remove from row'));
    await settleTonight(t, by: const Duration(seconds: 1));
    final c = _container(t);
    expect(find.text('CH 142 · 70%'), findsNothing);
    expect(c.read(continueHiddenProvider), hasLength(1));
    final toast = c.read(cineToastsProvider).single;
    expect(toast.text, 'Removed from Continue reading.');
    expect(toast.actionLabel, 'Undo');
    expect(toast.hold, const Duration(milliseconds: 8000));
    toast.onAction!();
    await settleTonight(t, by: const Duration(milliseconds: 500));
    expect(find.text('CH 142 · 70%'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('Mark read sends one manual row and toasts "Marked chapter 142 read." with Undo', (t) async {
    final rig = await pumpTonight(t, feed: 'ready', size: _tall, prefs: _stamp);
    await settleTonight(t, by: const Duration(seconds: 3));
    await t.longPress(find.text('CH 142 · 70%'));
    await settleTonight(t, by: const Duration(seconds: 1));
    await t.tap(find.text('Mark read'));
    await settleTonight(t, by: const Duration(seconds: 1));
    final row = rig.rec.pushedRows.single;
    expect((row.chapterKey, row.manual, row.isCompleted, row.timeSpentSeconds), ('c142', true, true, 0));
    final toast = _container(t).read(cineToastsProvider).single;
    expect(toast.text, 'Marked chapter 142 read.');
    toast.onAction!();
    await settleTonight(t, by: const Duration(milliseconds: 300));
    expect(rig.rec.deleted.single.keys, ['c142']);
    // Undo puts the reader's place back: page 28 of 40, not completed.
    final back = rig.rec.pushedRows.last;
    expect((rig.rec.pushedRows.length, back.chapterKey, back.lastPage, back.pageCount, back.isCompleted), (2, 'c142', 28, 40, false));
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('a Continue cutting takes its folio format from its own source, not the cover story', (t) async {
    final j = jsonDecode(File('test/fixtures/home/ready.json').readAsStringSync()) as Map<String, dynamic>..['cover'] = null;
    await pumpTonight(t, view: viewOf(HomeFeed.fromJson(j)), size: _tall, prefs: _stamp, extra: [
      contentModeScopeProvider.overrideWith((ref) => const ContentModeScope(mode: ContentMode.novel, index: {'shelf': ContentMode.novel}, novelsEnabled: true)),
    ]);
    await settleTonight(t, by: const Duration(seconds: 3));
    expect(find.text('70% · CH 142'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('Not for me hides the pick by identity, and restoring it brings the poster back', (t) async {
    await pumpTonight(t, feed: 'ready', size: _tall, prefs: _stamp, extra: [aiRepositoryProvider.overrideWithValue(_OkAi())]);
    await settleTonight(t, by: const Duration(seconds: 3));
    await t.longPress(find.text('Harbor of Small Lights').first);
    await settleTonight(t, by: const Duration(seconds: 1));
    await t.tap(find.text('Not for me'));
    await settleTonight(t, by: const Duration(seconds: 1));
    expect(find.text('Harbor of Small Lights'), findsNothing);
    final dismissed = _container(t).read(dismissedPicksProvider.notifier);
    dismissed.restore(_container(t).read(dismissedPicksProvider).single);
    await settleTonight(t, by: const Duration(seconds: 1));
    expect(find.text('Harbor of Small Lights'), findsWidgets);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('first picks are the reader\'s own follows: Quick look has no Not for me', (t) async {
    await _pump(t, 'onboarded');
    await t.longPress(find.text('NOT STARTED').first);
    await settleTonight(t, by: const Duration(seconds: 1));
    expect(find.text('Not for me'), findsNothing);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('a pick poster: Quick look offers Open and Not for me; information-only adds Search my sources', (t) async {
    await _pump(t, 'ready');
    await t.longPress(find.text('NOT ON YOUR SOURCES'));
    await settleTonight(t, by: const Duration(seconds: 1));
    expect(find.text('Not for me'), findsOneWidget);
    expect(find.text('Search my sources'), findsOneWidget);
    expect(find.text('Open'), findsNothing);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('the numbers teaser: stat blocks, the streak caption by the clock, Open The Numbers', (t) async {
    await _pump(t, 'ready');
    expect(find.text('STREAK'), findsOneWidget);
    expect(find.text('THIS WEEK'), findsOneWidget);
    expect(find.text('TIME READ'), findsOneWidget);
    expect(find.text('3 H 20 M'), findsOneWidget);
    expect(find.text('18'), findsOneWidget);
    expect(find.text('Twelve days and counting. One chapter keeps it alive.'), findsOneWidget);
    expect(find.text('Open The Numbers'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('genres link to Discover with ?genre=, sources tiles render', (t) async {
    final rig = await pumpTonight(t, feed: 'ready', size: _tall, prefs: _stamp);
    await settleTonight(t, by: const Duration(seconds: 3));
    expect(find.text('Shelf Scans'), findsWidgets);
    await t.tap(find.text('FANTASY'));
    await settleTonight(t, by: const Duration(seconds: 1));
    expect(rig.visited.any((l) => l.startsWith('/search') && l.contains('genre=Fantasy')), isTrue);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('stale sections carry SAVED COPY; a picked section older than 24 h says PICKED 3 DAYS AGO', (t) async {
    await _pump(t, 'stale');
    expect(find.text('SAVED COPY · 9 H'), findsOneWidget);
    expect(find.text('PICKED 3 DAYS AGO'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('text scale 2.0 and 1.5 on a phone throw nothing; 2.0 on a tablet either', (t) async {
    await _pump(t, 'ready', textScale: 2.0);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    await _pump(t, 'ready', textScale: 1.5);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    await _pump(t, 'ready', textScale: 2.0, wide: true, size: const Size(834, 4200));
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('every fixture renders on a phone and on a tablet without an exception', (t) async {
    for (final f in ['ready', 'novel', 'new-profile', 'onboarded', 'caught-up', 'at-risk', 'ai-unavailable', 'stale']) {
      await _pump(t, f, size: const Size(390, 3000));
      expect(t.takeException(), isNull, reason: '$f phone');
      await t.pumpWidget(const SizedBox());
      await _pump(t, f, wide: true, size: const Size(834, 3000));
      expect(t.takeException(), isNull, reason: '$f tablet');
      await t.pumpWidget(const SizedBox());
    }
  });
}

class _OkAi implements AiRepository {
  @override
  Future<Result<void>> sendFeedback({required String signal, int? anilistId, String? sourceId, String? seriesKey, String? tag}) async => const Ok(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
