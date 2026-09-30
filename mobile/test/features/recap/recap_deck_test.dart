import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/recap/recap_deck.dart';
import 'package:manhwamaniacs/features/recap/sse.dart';

SseEvent ev(String e, Map<String, Object?> d) => SseEvent(e, jsonEncode(d));

void main() {
  test('sections arrive in order and deltas of two sections interleave', () {
    var s = const DeckState();
    for (final e in [
      ev('phase', {'phase': 'Reading'}),
      ev('section', {'kind': 'left_off', 'title': 'Where you left off'}),
      ev('section', {'kind': 'happened', 'title': 'What happened'}),
      ev('delta', {'kind': 'left_off', 'text': 'He fell '}),
      ev('delta', {'kind': 'happened', 'text': 'A gate opened. '}),
      ev('delta', {'kind': 'left_off', 'text': 'asleep.'}),
    ]) {
      s = deckReducer(s, e);
    }
    expect(s.phase, 'Reading');
    expect(s.sections.map((x) => x.kind), ['left_off', 'happened']);
    expect(s.sections[0].text, 'He fell asleep.');
    expect(s.sections[0].words, ['He', 'fell', 'asleep.']);
    expect(s.sections[1].words, ['A', 'gate', 'opened.']);
    expect(s.finished, isFalse);
  });

  test('done without cast, and error', () {
    final s = deckReducer(const DeckState(), ev('done', {'range': [120, 141], 'covered_through': 141, 'model': 'm', 'generated_at': '2026-09-01T00:00:00Z'}));
    expect(s.done!.cast, isEmpty);
    expect(s.done!.rangeLabel, '120–141');
    expect(s.done!.coveredThrough, 141);
    expect(deckReducer(const DeckState(), ev('error', {'code': 'ai_failed', 'message': 'x'})).error!.code, 'ai_failed');
  });

  test('events split across chunks through the parser', () async {
    const raw = 'event: section\ndata: {"kind":"threads","title":"Open threads"}\n\nevent: delta\ndata: {"kind":"threads","text":"Who? Why?"}\n\n';
    final bytes = utf8.encode(raw);
    final c = StreamController<List<int>>();
    final out = <SseEvent>[];
    final done = parseSse(c.stream).forEach(out.add);
    for (var i = 0; i < bytes.length; i += 7) {
      c.add(bytes.sublist(i, i + 7 > bytes.length ? bytes.length : i + 7));
    }
    await c.close();
    await done;
    final s = out.fold(const DeckState(), deckReducer);
    expect(s.sections.single.text, 'Who? Why?');
  });

  test('json round trip keeps sections and done', () {
    final s = deckReducer(deckReducer(const DeckState(), ev('section', {'kind': 'left_off', 'title': 'T'})), ev('delta', {'kind': 'left_off', 'text': 'Hi there'}));
    final back = DeckState.fromJson(jsonDecode(jsonEncode(deckReducer(s, ev('done', {'range': [1, 2], 'cast': [{'name': 'Jin', 'note': 'lead'}]})).toJson())) as Map<String, dynamic>);
    expect(back.sections.single.words, ['Hi', 'there']);
    expect(back.done!.cast.single.name, 'Jin');
  });

  test('sectionBullets splits on lines, else on sentences', () {
    expect(sectionBullets('One.\n\nTwo!\n'), ['One.', 'Two!']);
    expect(sectionBullets('One. Two? Three.'), ['One.', 'Two?', 'Three.']);
    expect(sectionBullets(''), isEmpty);
  });

  test('lastThirdStart', () {
    expect(lastThirdStart(['a']), 'a');
    expect(lastThirdStart(['a', 'b', 'c']), 'c');
    expect(lastThirdStart([for (var i = 0; i < 22; i++) '$i']), '14');
  });

  test('gapWords boundaries', () {
    expect(gapWords(1), '1 day');
    expect(gapWords(13), '13 days');
    expect(gapWords(14), '2 weeks');
    expect(gapWords(21), '3 weeks');
    expect(gapWords(62), '9 weeks');
    expect(gapWords(63), '2 months');
    expect(gapWords(30 * 13), '13 months');
  });
}
