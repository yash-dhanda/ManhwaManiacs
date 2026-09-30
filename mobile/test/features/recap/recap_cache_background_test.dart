import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/recap/background_recaps.dart';
import 'package:manhwamaniacs/features/recap/recap_cache.dart';
import 'package:manhwamaniacs/features/recap/recap_deck.dart';
import 'package:manhwamaniacs/features/recap/sse.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_overrides.dart';

class _Profiles extends ActiveProfileNotifier {
  @override
  ActiveProfile? build() => const ActiveProfile(
      id: 1, name: 'One', avatarKey: null, mood: Mood.neutral);
  void to(int id) => state =
      ActiveProfile(id: id, name: 'P$id', avatarKey: null, mood: Mood.neutral);
}

Future<ProviderContainer> _c() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [
    sharedPrefsProvider.overrideWithValue(prefs),
    authenticatedAuthOverride(),
    activeProfileProvider.overrideWith(_Profiles.new)
  ]);
  addTearDown(c.dispose);
  return c;
}

DeckState _deck(String t) => DeckState(
    sections: [const DeckSection(kind: 'left_off', title: 'T').append(t)]);
SseEvent _done() => SseEvent(
    'done',
    jsonEncode({
      'range': [1, 2]
    }));

void main() {
  test('cache: round trip, LRU of 20, profile isolation, clear', () async {
    final c = await _c();
    final cache = c.read(recapCacheProvider);
    await cache.save('a', _deck('hello world'));
    final got = await cache.readCachedRecap('a');
    expect(got!.deck.sections.single.words, ['hello', 'world']);
    for (var i = 0; i < 20; i++) {
      await cache.save('k$i', _deck('x'));
    }
    expect(await cache.readCachedRecap('a'), isNull,
        reason: 'the oldest is evicted at 21');
    expect(await cache.readCachedRecap('k19'), isNotNull);
    (c.read(activeProfileProvider.notifier) as _Profiles).to(2);
    expect(await c.read(recapCacheProvider).readCachedRecap('k19'), isNull);
    (c.read(activeProfileProvider.notifier) as _Profiles).to(1);
    await c.read(recapCacheProvider).clear();
    expect(await c.read(recapCacheProvider).readCachedRecap('k19'), isNull);
  });

  test('keep-alive: ready inside 60 s emits once and saves', () async {
    final c = await _c();
    final bg = c.read(backgroundRecapsProvider);
    // ignore: close_sinks
    final ctl = StreamController<SseEvent>.broadcast();
    final got = <RecapReady>[];
    bg.readyStream.listen(got.add);
    bg.keepAlive('s:k:c:series',
        events: ctl.stream,
        cancel: CancelToken(),
        title: 'Solo',
        sourceId: 's',
        seriesKey: 'k',
        mature: false,
        startedAt: DateTime.now());
    ctl.add(_done());
    await Future<void>.delayed(Duration.zero);
    expect(got.map((e) => e.title), ['Solo']);
    expect(bg.length, 0);
    expect(await c.read(recapCacheProvider).readCachedRecap('s:k:c:series'),
        isNotNull);
  });

  test('keep-alive: cancelled after 60 s; cancelWhere drops mature only', () {
    fakeAsync((async) {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer(overrides: [
        authenticatedAuthOverride(),
        activeProfileProvider.overrideWith(_Profiles.new)
      ]);
      final bg = c.read(backgroundRecapsProvider);
      final t1 = CancelToken(), t2 = CancelToken(), t3 = CancelToken();
      // ignore: close_sinks
      final ctl = StreamController<SseEvent>.broadcast();
      final start = DateTime.now();
      bg.keepAlive('a',
          events: ctl.stream,
          cancel: t1,
          title: 'A',
          sourceId: 's',
          seriesKey: 'a',
          mature: false,
          startedAt: start);
      bg.keepAlive('b',
          events: ctl.stream,
          cancel: t2,
          title: 'B',
          sourceId: 's',
          seriesKey: 'b',
          mature: true,
          startedAt: start);
      bg.keepAlive('c',
          events: ctl.stream,
          cancel: t3,
          title: 'C',
          sourceId: 's',
          seriesKey: 'c',
          mature: false,
          startedAt: start);
      bg.cancelWhere((e) => e.mature);
      expect(t2.isCancelled, isTrue);
      expect(t1.isCancelled, isFalse);
      async.elapse(const Duration(seconds: 59));
      expect(t1.isCancelled, isFalse);
      async.elapse(const Duration(seconds: 2));
      expect(t1.isCancelled, isTrue);
      expect(t3.isCancelled, isTrue);
      expect(bg.length, 0);
      c.dispose();
    });
  });
}
