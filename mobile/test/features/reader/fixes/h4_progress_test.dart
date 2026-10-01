import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/models/chapter_manifest.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/models/reader_page.dart';
import 'package:manhwamaniacs/features/reader/utils/read_all_feed.dart';

void main() {
  test('a failed read-all placeholder is never saved as progress', () async {
    final saved = <String>[];
    final save = skipFailedChapters((c, p) async => saved.add('${c.id}:$p'));
    await save(failedChapterPlaceholder('c5', seriesKey: 's'), 1);
    await save(
      const ReaderChapter(id: 'c6', seriesId: 's', title: 'Ch 6', pageCount: 1, pages: [ReaderPage(id: 'c6:1', number: 1, imageUrl: 'u')]),
      1,
    );
    expect(saved, ['c6:1']);
  });

  test('a manifest chapter keeps its number for progress and bookmarks', () {
    final m = ChapterManifest.fromJson({
      'source_id': 'src',
      'series_key': 's',
      'chapter_key': 'k7',
      'chapter_number': 7,
      'page_count': 0,
      'pages': <dynamic>[],
    });
    expect(m.toReaderChapter('http://x').chapterNumber, 7);
  });
}
