import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/recap/providers/recap_providers.dart';
import 'package:manhwamaniacs/features/recap/repositories/recap_repository.dart';

String sse(String event, Map<String, Object?> data) => 'event: $event\ndata: ${jsonEncode(data)}\n\n';

/// The deck stream of the fixture (real `backend/05` shapes): phase, four sections with deltas, then `done`.
List<String> deckEvents({bool withDone = true}) => [
      sse('phase', {'phase': 'writing'}),
      sse('section', {'kind': 'left_off', 'title': 'Where you left off'}),
      sse('section', {'kind': 'happened', 'title': 'What happened'}),
      sse('section', {'kind': 'cast', 'title': "Who's who"}),
      sse('section', {'kind': 'threads', 'title': 'Open threads'}),
      sse('delta', {'kind': 'left_off', 'text': 'Jinwoo stands at the gate. '}),
      sse('delta', {'kind': 'left_off', 'text': 'Everything is about to change.'}),
      sse('delta', {'kind': 'happened', 'text': 'He cleared the dungeon.\nHe leveled up.'}),
      sse('delta', {'kind': 'threads', 'text': 'Who sent the message?\nWhat is the System?'}),
      if (withDone)
        sse('done', {
          'range': [120, 141],
          'covered_through': 141,
          'cast': [
            {'name': 'Sung Jinwoo', 'note': 'The hunter'},
            {'name': 'Cha Hae-In', 'note': 'An S-rank'},
          ],
          'sourced_from': 'ocr',
          'model': 'test-model',
          'generated_at': '2026-09-30T10:00:00Z',
          'available': true,
        }),
    ];

/// Answers `GET /ai/recap` with [chunks] as an event stream (or JSON [json] when given), recording the calls.
class RecapAdapter implements HttpClientAdapter {
  RecapAdapter({this.chunks, this.json, this.controller});
  final List<String>? chunks;
  final Map<String, Object?>? json;
  final StreamController<List<int>>? controller;
  final calls = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? b, Future<void>? c) async {
    calls.add(o);
    if (json != null) return ResponseBody.fromString(jsonEncode(json), 200, headers: {'content-type': ['application/json']});
    final headers = {'content-type': ['text/event-stream']};
    if (controller != null) return ResponseBody(controller!.stream.map(Uint8List.fromList), 200, headers: headers);
    return ResponseBody(Stream.fromIterable([for (final c in chunks ?? const <String>[]) Uint8List.fromList(utf8.encode(c))]), 200, headers: headers);
  }

  @override
  void close({bool force = false}) {}
}

Override recapOverride(RecapAdapter a) => recapRepositoryProvider.overrideWithValue(RecapRepository(Dio(BaseOptions(baseUrl: 'http://x'))..httpClientAdapter = a));
