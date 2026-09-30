import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/network/interceptors/error_interceptor.dart';
import 'package:manhwamaniacs/features/library/models/suggestion.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/library/providers/intelligence_providers.dart';
import 'package:manhwamaniacs/features/library/repositories/ask_repository.dart';

/// A recorded answer: [status] with a JSON [body] (or never, when [hang] is set).
class Reply {
  const Reply(this.body, {this.status = 200, this.headers = const {}, this.hang = false});
  final Object body;
  final int status;
  final Map<String, String> headers;
  final bool hang;
}

/// A Dio adapter that answers by path and records every request (bodies and queries).
class RoutedAdapter implements HttpClientAdapter {
  RoutedAdapter(this.routes);
  final Map<String, Reply Function(RequestOptions)> routes;
  final calls = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? b, Future<void>? cancel) async {
    calls.add(o);
    final r = routes[o.path]?.call(o) ?? const Reply({}, status: 404);
    if (r.hang) {
      await (cancel ?? Completer<void>().future);
      throw DioException(requestOptions: o, type: DioExceptionType.cancel);
    }
    return ResponseBody.fromString(jsonEncode(r.body), r.status, headers: {'content-type': ['application/json'], for (final e in r.headers.entries) e.key: [e.value]});
  }

  @override
  void close({bool force = false}) {}
}

Dio dioOf(RoutedAdapter a) => Dio(BaseOptions(baseUrl: 'http://x'))
  ..httpClientAdapter = a
  ..interceptors.add(ErrorInterceptor());

Map<String, dynamic> itemJson(String title, {int id = 1, String? why, bool available = true}) => {
      'anilist_id': id,
      'title': title,
      'format': 'Manhwa',
      'status': 'Ongoing',
      'genres': ['Fantasy'],
      'why': why ?? 'Because $title fits.',
      if (available) 'available': [{'source_id': 'src', 'source_name': 'MangaSource', 'series_key': 'k$id'}],
    };

Reply suggestOk(int n, {int remaining = 9}) => Reply({'items': [for (var i = 0; i < n; i++) itemJson('Pick $i', id: i + 1)], 'remaining_today': remaining, 'model': 'm'});

Reply apiError(int status, String code, {Map<String, String> headers = const {}}) => Reply({'code': code, 'message': code}, status: status, headers: headers);

/// Overrides that put [adapter] behind the Ask repository and answer the availability and the recommendations from fixtures.
List<Override> askOverrides(RoutedAdapter adapter, {SuggestionAvailability? availability, WorldRecommendations? recs, void Function(String?)? onGenre}) => [
      askRepositoryProvider.overrideWithValue(AskRepository(dioOf(adapter))),
      suggestAvailabilityProvider.overrideWith((ref) async => availability ?? const SuggestionAvailability(available: true, reason: 'ok', remainingToday: 9)),
      worldRecommendationsProvider.overrideWith((ref, genre) async {
        onGenre?.call(genre);
        return recs ?? WorldRecommendations(forYou: [WorldItem.fromJson(itemJson('Solo Picks', id: 50))], sections: [WorldSection(becauseTitle: 'Solo Leveling', items: [WorldItem.fromJson(itemJson('Tower Climb', id: 51))])]);
      }),
    ];
