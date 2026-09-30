import 'dart:convert';

/// One Server-Sent Event: [event] (default `message`) and its joined `data:` lines.
class SseEvent {
  const SseEvent(this.event, this.data);
  final String event, data;

  @override
  String toString() => 'SseEvent($event, $data)';
}

/// Parses an SSE byte stream. `utf8.decoder` keeps a multibyte character split across chunks
/// intact and `LineSplitter` handles `\n` and `\r\n`. An event ends at a blank line; comment
/// lines (`:`) are ignored; a trailing event without its blank line is dropped.
Stream<SseEvent> parseSse(Stream<List<int>> bytes) async* {
  var name = 'message';
  final data = <String>[];
  var any = false;
  await for (final line in bytes.map<List<int>>((c) => c).transform(utf8.decoder).transform(const LineSplitter())) {
    if (line.isEmpty) {
      if (any) yield SseEvent(name, data.join('\n'));
      name = 'message';
      data.clear();
      any = false;
    } else if (line.startsWith(':')) {
      continue;
    } else {
      final i = line.indexOf(':');
      final field = i < 0 ? line : line.substring(0, i);
      var value = i < 0 ? '' : line.substring(i + 1);
      if (value.startsWith(' ')) value = value.substring(1);
      if (field == 'event') {
        name = value;
        any = true;
      } else if (field == 'data') {
        data.add(value);
        any = true;
      }
    }
  }
}
