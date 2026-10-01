import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/annual.dart';
import 'package:manhwamaniacs/features/library/utils/wrapped_cards.dart';
import 'package:manhwamaniacs/skins/glass/wrapped/share_card.dart';

import '../../../screenshots/support/shot_network.dart';
import '../../../support/numbers_fixtures.dart';
import '../stats/stats_rig.dart';

Map<String, dynamic> _s(String src, String key, String title) => {
      'source_id': src,
      'series_key': key,
      'title': title,
      'cover_url': '/sources/$src/series/$key/cover',
      'seconds_read': 36000,
      'chapters_read': 40,
      'pages_read': 800,
    };

/// A year that is mostly mature: the top series, the top source, the first read, a busiest-day series and the top genre.
Annual _matureYear() {
  final j = annualJson(partial: false, circle: true);
  return Annual.fromJson({
    ...j,
    'top_series': [_s('adultsrc', 'm1', 'Velvet Secret'), ...(j['top_series'] as List)],
    'genres': [{'genre': 'Smut', 'weight': 0.6}, {'genre': 'Fantasy', 'weight': 0.4}],
    'top_sources': [{'source_id': 'adultsrc', 'name': 'AdultSource', 'share': 0.7}, {'source_id': 'shelf', 'name': 'MangaDex', 'share': 0.3}],
    'busiest_day': {'date': '2026-03-14', 'chapters': 42, 'series': [_s('adultsrc', 'm1', 'Velvet Secret'), _s('shelf', 'series-1', 'Tower of God')]},
    'firsts_lasts': {
      'first': {'series': _s('adultsrc', 'm2', 'Crimson Night'), 'read_at': '2026-01-05T10:00:00Z'},
      'last': {'series': _s('shelf', 'series-4', 'Lookism'), 'read_at': '2026-09-20T10:00:00Z'},
    },
    'shareable': {
      // The server already drops mature rows; one leaks through here so the client's own filters are proven too.
      'genre_weights': [{'genre': 'Smut', 'weight': 0.6}, {'genre': 'Fantasy', 'weight': 0.4}],
      'top_series': [_s('adultsrc', 'm1', 'Velvet Secret'), _s('shelf', 'series-0', 'Solo Leveling')],
      'art_series': const <Object?>[],
      'top_sources': const <Object?>[],
    },
  });
}

const _mature = {'adultsrc'};

/// Covers decode from memory here (a 1 x 1 PNG); the share image provider is otherwise the authenticated network one.
final _px = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');
final _memCovers = glassShareImageProvider.overrideWithValue((url) => MemoryImage(_px));
const _bannedText = ['Velvet Secret', 'Crimson Night', 'AdultSource', 'Smut', 'smut'];

/// Drives [renderShareCard] in a widget test: real async for the image work, pumps for the offstage frames.
Future<Uint8List> _render(WidgetTester t, ShareSpec spec, ShareFormat f, {String? name}) async {
  final ctx = t.element(find.byType(Text).first);
  Uint8List? out;
  Object? err;
  unawaited(renderShareCard(ctx, spec, f, profileName: name).then((b) => out = b, onError: (Object e) => err = e));
  for (var i = 0; i < 400 && out == null && err == null; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await t.pump(const Duration(milliseconds: 16));
  }
  if (err != null) throw err!;
  return out!;
}

(int, int) _pngSize(Uint8List b) {
  expect(b.sublist(0, 8), [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  final d = ByteData.sublistView(b);
  return (d.getUint32(16), d.getUint32(20));
}

/// Real async runs here (the image work), so the platform plugins the shell touches get quiet mocks.
void _quietPlugins() {
  final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final name in ['dev.fluttercommunity.plus/connectivity_status', 'dev.fluttercommunity.plus/connectivity']) {
    m.setMockMethodCallHandler(MethodChannel(name), (call) async => call.method == 'check' ? <String>['wifi'] : null);
    addTearDown(() => m.setMockMethodCallHandler(MethodChannel(name), null));
  }
}

void main() {
  setUp(setUpShotCoverCache);
  setUp(_quietPlugins);

  testWidgets('Story and Post PNGs decode to 1080 x 1920 and 1080 x 1350; the name only when on', (t) async {
    await pumpStats(t, FakeNumbers(), extra: [_memCovers]);
    final a = annualFixture(partial: false);
    final spec = ShareSpec.forCard(WrappedCard.time, a)!;
    expect(_pngSize(await _render(t, spec, ShareFormat.story)), (1080, 1920));
    expect(debugGlassShareTexts, isNot(contains('Tester')));
    expect(_pngSize(await _render(t, spec, ShareFormat.post)), (1080, 1350));
    await _render(t, spec, ShareFormat.story, name: shareProfileName(true, 'Tester'));
    expect(debugGlassShareTexts, contains('Tester'));
    expect(shareProfileName(false, 'Tester'), isNull);
    final streak = ShareSpec.stat(id: 'streak', eyebrow: 'Streak', numeral: '12', unit: 'day streak', contextLine: 'Longest: 31 days', flame: true);
    expect(_pngSize(await _render(t, streak, ShareFormat.story)), (1080, 1920));
    await t.pump(const Duration(minutes: 11));
  });

  testWidgets('a mostly mature year: no mature title, cover, source or genre reaches any card', (t) async {
    await pumpStats(t, FakeNumbers(), extra: [_memCovers]);
    final a = _matureYear();
    expect(ShareSpec.forCard(WrappedCard.together, a, matureSources: _mature), isNull, reason: 'card 11 never has a share side');
    for (final card in WrappedCard.values) {
      final spec = ShareSpec.forCard(card, a, matureSources: _mature);
      if (spec == null) continue;
      for (final f in ShareFormat.values) {
        await _render(t, spec, f);
        for (final text in debugGlassShareTexts) {
          for (final banned in _bannedText) {
            expect(text.contains(banned), isFalse, reason: '${card.name} ${f.name} drew "$text"');
          }
        }
        for (final url in debugGlassShareImages) {
          expect(url.contains('adultsrc'), isFalse, reason: '${card.name} ${f.name} drew $url');
        }
      }
    }
    await t.pump(const Duration(minutes: 11));
  });
}
