import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/recap/sse.dart';

Stream<List<int>> chunks(List<List<int>> c) => Stream.fromIterable(c);
List<int> b(String s) => utf8.encode(s);

void main() {
  test('an event split mid-line across chunks', () async {
    final e = await parseSse(chunks([b('event: del'), b('ta\ndata: {"a"'), b(':1}\n\n')])).toList();
    expect(e.single.event, 'delta');
    expect(e.single.data, '{"a":1}');
  });

  test('a UTF-8 character split across chunks stays whole', () async {
    final bytes = b('data: café — done\n\n');
    final cut = bytes.indexOf(0xC3) + 1; // inside the two-byte e-acute
    final e = await parseSse(chunks([bytes.sublist(0, cut), bytes.sublist(cut)])).toList();
    expect(e.single.data, 'café — done');
  });

  test('multi-line data joins with newlines; default event is message', () async {
    final e = await parseSse(chunks([b('data: a\ndata: b\n\n')])).toList();
    expect(e.single.event, 'message');
    expect(e.single.data, 'a\nb');
  });

  test('CRLF, comments and several events', () async {
    final e = await parseSse(chunks([b(': keepalive\r\nevent: meta\r\ndata: 1\r\n\r\nevent: done\r\ndata: 2\r\n\r\n')])).toList();
    expect([for (final x in e) '${x.event}=${x.data}'], ['meta=1', 'done=2']);
  });

  test('a trailing event without its blank line is dropped', () async {
    final e = await parseSse(chunks([b('event: a\ndata: 1\n\nevent: b\ndata: 2\n')])).toList();
    expect(e.map((x) => x.event), ['a']);
  });
}
