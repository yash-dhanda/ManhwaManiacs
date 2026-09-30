import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/recap/models/recap_models.dart';
import 'package:manhwamaniacs/features/recap/repositories/recap_repository.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.type, this.body, {this.headers = const {}});
  final String type, body;
  final Map<String, String> headers;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? r, Future<void>? c) async {
    last = o;
    return ResponseBody(
      Stream.value(Uint8List.fromList(utf8.encode(body))),
      200,
      headers: {'content-type': [type], for (final e in headers.entries) e.key: [e.value]},
    );
  }

  @override
  void close({bool force = false}) {}
}

RecapRepository repo(_Adapter a) => RecapRepository(Dio()..httpClientAdapter = a);
const key = RecapKey('s', 'k', 'c2');

void main() {
  test('availability parses the range', () async {
    final a = _Adapter('application/json', '{"available":true,"reason":"ok","range":{"from_key":"c1","to_key":"c2","from_number":131,"to_number":142},"est_seconds":90,"cached":true}');
    final r = await repo(a).availability(key);
    expect(r.available, isTrue);
    expect(r.estSeconds, 90);
    expect(r.cached, isTrue);
    expect(recapRangeLabel(r), '131–142');
    expect(a.last!.queryParameters, {'source': 's', 'series': 'k', 'to': 'c2'});
  });

  test('a stream maps to meta, deltas and done', () async {
    final a = _Adapter('text/event-stream; charset=utf-8',
        'event: meta\ndata: {"range":{"from_number":1,"to_number":3},"cast":[{"name":"Kim","note":"the reader"}],"sourced_from":"text"}\n\n'
        'event: delta\ndata: {"text":"Hello "}\n\nevent: delta\ndata: {"text":"world"}\n\n'
        'event: done\ndata: {"generated_at":"2026-09-01T00:00:00Z"}\n\n');
    final open = await repo(a).open(key);
    expect(open, isA<RecapStream>());
    final ev = await (open as RecapStream).events.toList();
    expect(ev[0], isA<RecapMeta>());
    final meta = ev[0] as RecapMeta;
    expect(meta.cast.single.role, 'the reader');
    expect(meta.sourcedFrom, 'text');
    expect(ev.whereType<RecapDelta>().map((d) => d.text).join(), 'Hello world');
    expect((ev.last as RecapDone).generatedAt, isNotNull);
    expect(a.last!.headers['Accept'], contains('text/event-stream'));
  });

  test('a JSON body maps to a reason and Retry-After', () async {
    final a = _Adapter('application/json', '{"available":false,"reason":"rate_limited"}', headers: {'retry-after': '12'});
    final open = await repo(a).open(key) as RecapNone;
    expect(open.reason, 'rate_limited');
    expect(open.retryAfter, 12);
  });

  test('a mid-stream error event', () async {
    final a = _Adapter('text/event-stream', 'event: delta\ndata: {"text":"x"}\n\nevent: error\ndata: {"code":"rate_limited","message":"m","retry_after":30}\n\n');
    final ev = await ((await repo(a).open(key)) as RecapStream).events.toList();
    final err = ev.last as RecapError;
    expect(err.code, 'rate_limited');
    expect(err.retryAfter, 30);
  });
}
