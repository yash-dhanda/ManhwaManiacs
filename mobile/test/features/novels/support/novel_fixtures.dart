import 'dart:convert';
import 'dart:io';

import 'package:manhwamaniacs/features/novels/models/novel_cast.dart';
import 'package:manhwamaniacs/features/novels/models/novel_chapter.dart';

Map<String, dynamic> _json(String name) => jsonDecode(File('test/fixtures/novel/$name').readAsStringSync()) as Map<String, dynamic>;

/// The fixture chapter (Alice's Adventures in Wonderland, chapter 1, public domain) with a scene
/// break `* * *` after paragraph 12.
NovelChapter fixtureChapter({String? nextKey = '2', String? previousKey}) {
  final j = _json('chapter.json');
  return NovelChapter.fromJson({...j, 'next': nextKey, 'prev': previousKey});
}

List<String> fixtureParagraphs() => fixtureChapter().paragraphs;

/// Alice in slot 1, the White Rabbit in slot 2, fingerprint matching [fixtureParagraphs].
NovelAttribution fixtureAttribution() => NovelAttribution.fromJson(_json('attribution.json'));

/// The same spans with a fingerprint that does not match.
NovelAttribution fixtureAttributionStale() => NovelAttribution.fromJson(_json('attribution-stale.json'));

/// The chapter's paragraphs repeated until they hold at least [words] words.
List<String> longFixtureParagraphs({int words = 12000}) {
  final base = fixtureParagraphs();
  final out = <String>[];
  var count = 0;
  while (count < words) {
    for (final p in base) {
      out.add(p);
      count += p.split(' ').length;
    }
  }
  return out;
}
