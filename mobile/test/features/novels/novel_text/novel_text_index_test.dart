import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/downloads/store/downloads_db.dart';
import 'package:manhwamaniacs/features/novels/novel_text/novel_text_index.dart';
import 'package:sqflite/sqflite.dart';

import '../../../support/downloads_test_support.dart';

Future<void> saved(Database db, String scope, String series, String chapter, {int? mature, String? readAt, String kind = 'novel'}) => db.insert('saved_chapters', {
      'scope_id': scope,
      'source_id': 'src',
      'series_key': series,
      'chapter_key': chapter,
      'page_count': 1,
      'bytes': 1,
      'state': 'complete',
      'created_at': '2026-09-01T00:00:00Z',
      'kind': kind,
      'mature': mature,
      'read_at': readAt,
    });

void main() {
  initSqfliteFfiForTests();
  late TestDownloadsHarness h;
  late Database db;
  late NovelTextIndex idx;

  setUp(() async {
    h = await TestDownloadsHarness.create();
    db = await h.openDatabase();
    idx = NovelTextIndex(db);
  });
  tearDown(() => h.dispose());

  Future<void> add(String series, String chapter, List<String> paras, {int? mature, String? readAt, String scope = 'u1p1'}) async {
    await saved(db, scope, series, chapter, mature: mature, readAt: readAt);
    await idx.indexChapter(sourceId: 'src', seriesKey: series, chapterKey: chapter, paragraphs: paras);
  }

  test('AND across two words in any order', () async {
    await add('s', 'c1', ['The rabbit climbed the tower.', 'Only a tower here.', 'Only a rabbit here.']);
    final r = await idx.search('tower rabbit', scopeId: 'u1p1', gateOpen: true);
    expect(r.hits.map((x) => x.para), [0]);
    final r2 = await idx.search('rabbit tower', scopeId: 'u1p1', gateOpen: true);
    expect(r2.hits.map((x) => x.para), [0]);
  });

  test('the gate hides a mature row; an open gate shows it', () async {
    await add('safe', 'c1', ['the moonlit tower']);
    await add('adult', 'c1', ['the forbidden tower'], mature: 1);
    expect((await idx.search('tower', scopeId: 'u1p1', gateOpen: false)).hits.map((x) => x.seriesKey), ['safe']);
    expect((await idx.search('tower', scopeId: 'u1p1', gateOpen: true)).hits, hasLength(2));
  });

  test('other scopes never see a chapter', () async {
    await add('s', 'c1', ['the tower'], scope: 'u1p2');
    expect((await idx.search('tower', scopeId: 'u1p1', gateOpen: true)).hits, isEmpty);
  });

  test('ranking: reading series, then occurrences, then recent read', () async {
    await add('a', 'c1', ['tower tower tower'], readAt: '2026-09-01');
    await add('b', 'c1', ['tower'], readAt: '2026-09-09');
    await add('c', 'c1', ['tower tower'], readAt: '2026-09-05');
    final plain = await idx.search('tower', scopeId: 'u1p1', gateOpen: true);
    expect(plain.hits.map((x) => x.seriesKey), ['a', 'c', 'b']);
    final reading = await idx.search('tower', scopeId: 'u1p1', gateOpen: true, readingSeries: ['src:b']);
    expect(reading.hits.map((x) => x.seriesKey), ['b', 'a', 'c']);
  });

  test('the 50 cap', () async {
    await add('s', 'c1', [for (var i = 0; i < 60; i++) 'tower number $i']);
    final r = await idx.search('tower', scopeId: 'u1p1', gateOpen: true);
    expect(r.hits, hasLength(50));
    expect(r.capped, isTrue);
    final few = await idx.search('number 17', scopeId: 'u1p1', gateOpen: true);
    expect(few.capped, isFalse);
  });

  test('a 50-hit query is fast on the fixture database', () async {
    final fixture = jsonDecode(File('test/fixtures/novel/chapter.json').readAsStringSync()) as Map<String, dynamic>;
    final paras = [for (final p in fixture['paragraphs'] as List) '$p'];
    for (var c = 0; c < 30; c++) {
      await add('s$c', 'c', [...paras, ...paras]);
    }
    final sw = Stopwatch()..start();
    final r = await idx.search('the', scopeId: 'u1p1', gateOpen: true);
    sw.stop();
    // ignore: avoid_print
    print('novel_text: 50-hit query ${sw.elapsedMilliseconds} ms, tokenizer simple=$novelTextSimpleTokenizer, hits ${r.hits.length}');
    expect(r.hits.length, greaterThan(0));
  });

  test('cafe matches café through the tokenizer', () async {
    await add('s', 'c1', ['Un café chaud.']);
    expect((await idx.search('cafe', scopeId: 'u1p1', gateOpen: true)).hits, hasLength(1));
    expect(novelTextSimpleTokenizer, isFalse);
  });

  test('only 1-character words is idle', () async {
    await add('s', 'c1', ['a b c']);
    expect((await idx.search('a b', scopeId: 'u1p1', gateOpen: true)).hits, isEmpty);
  });

  test('snippet: byte offsets with café and Korean text', () async {
    const text = 'Un café très chaud, 그리고 탑 위에서 본 토끼가 tower 를 올랐다.';
    await add('s', 'c1', [text]);
    final hit = (await idx.search('tower', scopeId: 'u1p1', gateOpen: true)).hits.single;
    final s = hit.snippet;
    expect(s.ranges, hasLength(1));
    expect(s.text.substring(s.ranges.single.start, s.ranges.single.end), 'tower');
    final hit2 = (await idx.search('chaud', scopeId: 'u1p1', gateOpen: true)).hits.single;
    final s2 = hit2.snippet;
    expect(s2.text.substring(s2.ranges.single.start, s2.ranges.single.end), 'chaud');
  });

  test('snippet windows at the start, middle and end', () {
    final long = '${'word ' * 40}NEEDLE${' word' * 40}';
    int at(String t) => t.indexOf('NEEDLE');
    String offs(String t) => '4 0 ${t.indexOf('NEEDLE')} 6';
    final mid = novelTextSnippet(long, offs(long));
    expect(mid.text.startsWith('…'), isTrue);
    expect(mid.text.endsWith('…'), isTrue);
    expect(mid.text.substring(mid.ranges.single.start, mid.ranges.single.end), 'NEEDLE');
    expect(mid.text.length, lessThan(160));
    final start = 'NEEDLE${' word' * 40}';
    final s = novelTextSnippet(start, offs(start));
    expect(s.text.startsWith('…'), isFalse);
    expect(s.text.endsWith('…'), isTrue);
    expect(s.ranges.single.start, 0);
    final end = '${'word ' * 40}NEEDLE';
    final e = novelTextSnippet(end, offs(end));
    expect(e.text.startsWith('…'), isTrue);
    expect(e.text.endsWith('…'), isFalse);
    expect(e.text.substring(e.ranges.single.start, e.ranges.single.end), 'NEEDLE');
    expect(at(long), greaterThan(0));
  });

  test('drop only when no scope still references the chapter', () async {
    await saved(db, 'u1p1', 's', 'c1');
    await saved(db, 'u1p2', 's', 'c1');
    await idx.indexChapter(sourceId: 'src', seriesKey: 's', chapterKey: 'c1', paragraphs: ['the tower']);
    await db.delete('saved_chapters', where: 'scope_id = ?', whereArgs: ['u1p1']);
    expect(await idx.dropChapter('src', 's', 'c1'), isFalse);
    expect(await idx.isIndexed('src', 's', 'c1'), isTrue);
    await db.delete('saved_chapters', where: 'scope_id = ?', whereArgs: ['u1p2']);
    expect(await idx.dropChapter('src', 's', 'c1'), isTrue);
    expect(await idx.isIndexed('src', 's', 'c1'), isFalse);
    expect((await db.query('novel_text')).length, 0);
  });

  test('indexing twice keeps one copy', () async {
    await add('s', 'c1', ['the tower']);
    await idx.indexChapter(sourceId: 'src', seriesKey: 's', chapterKey: 'c1', paragraphs: ['the tower']);
    expect((await db.query('novel_text')).length, 1);
  });
}
