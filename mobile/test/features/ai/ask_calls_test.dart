import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/ai/models/similar_result.dart';
import 'package:manhwamaniacs/features/ai/repositories/ai_repository.dart';
import 'package:manhwamaniacs/features/library/providers/pending_ask_provider.dart';
import 'package:manhwamaniacs/features/library/repositories/ask_repository.dart';
import 'package:manhwamaniacs/features/recap/models/recap_models.dart';
import 'package:manhwamaniacs/features/recap/repositories/recap_repository.dart';

class _A implements HttpClientAdapter {
  _A(this.json, {this.type = 'application/json'});
  final String json, type;
  final calls = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? b, Future<void>? c) async {
    calls.add(o);
    return ResponseBody.fromString(json, 200, headers: {'content-type': [type]});
  }

  @override
  void close({bool force = false}) {}
}

Dio _d(_A a) => Dio(BaseOptions(baseUrl: 'http://x'))..httpClientAdapter = a;

void main() {
  test('suggest bodies: omitted fields are not sent, Glass fields are', () async {
    final a = _A('{"items":[],"remaining_today":7}');
    final r = AskRepository(_d(a));
    await r.librarySuggest(prompt: 'p', limit: 8, useTaste: true, contentKind: 'novel');
    await r.worldSuggest(prompt: 'p', limit: 12, useTaste: false);
    await r.worldSuggest(prompt: 'p');
    expect(a.calls[0].path, '/library/suggest');
    expect(a.calls[0].data, {'prompt': 'p', 'limit': 8, 'use_taste': true, 'content_kind': 'novel'});
    expect(a.calls[1].path, '/library/world/suggest');
    expect(a.calls[1].data, {'prompt': 'p', 'limit': 12, 'use_taste': false});
    expect(a.calls[2].data, {'prompt': 'p'});
  });

  test('world recommendations sends genre only when given', () async {
    final a = _A('{"for_you":[],"sections":[]}');
    final r = AskRepository(_d(a));
    await r.worldRecommendations(genre: 'Fantasy');
    await r.worldRecommendations();
    expect(a.calls[0].queryParameters, {'genre': 'Fantasy'});
    expect(a.calls[1].queryParameters, isEmpty);
  });

  test('similar sends fallback=genres, feedback sends undo and clear', () async {
    final a = _A('{"items":[],"basis":"genres"}');
    final r = AiRepository(_d(a));
    final s = await r.similar(const SimilarQuery.series('s', 'k', fallbackGenres: true));
    expect(s.isGenres, isTrue);
    expect(a.calls.single.queryParameters, {'source': 's', 'series': 'k', 'fallback': 'genres'});
    await r.sendFeedback(signal: 'undo', anilistId: 4);
    await r.sendFeedback(signal: 'clear');
    expect(a.calls[1].data, {'signal': 'undo', 'anilist_id': 4});
    expect(a.calls[2].data, {'signal': 'clear'});
  });

  test('recap: prose sends no shape, deck sends shape and scope', () async {
    final a = _A('event: done\ndata: {}\n\n', type: 'text/event-stream');
    final r = RecapRepository(_d(a));
    const k = RecapKey('s', 'k', 'c');
    await r.open(k);
    final o = await r.openDeck(k, scope: 'chapter');
    expect(a.calls[0].queryParameters.containsKey('shape'), isFalse);
    expect(a.calls[0].queryParameters.containsKey('scope'), isFalse);
    expect(a.calls[1].queryParameters['shape'], 'deck');
    expect(a.calls[1].queryParameters['scope'], 'chapter');
    expect(o, isA<DeckStream>());
    final j = RecapRepository(_d(_A('{"available":false,"reason":"first_chapter"}')));
    expect((await j.openDeck(k) as RecapNone).reason, 'first_chapter');
  });

  test('pendingAsk is one-shot', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(pendingAskProvider.notifier).set('a revenge story');
    expect(c.read(pendingAskProvider.notifier).take(), 'a revenge story');
    expect(c.read(pendingAskProvider.notifier).take(), isNull);
  });
}
