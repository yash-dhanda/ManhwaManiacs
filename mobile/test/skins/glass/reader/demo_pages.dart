import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:manhwamaniacs/features/ocr/models/page_text.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/models/reader_page.dart';

/// The demo pages of `brand/demo/demo.json` (invented art, 2 chapters of 20 pages) as reader chapters, their bytes for the shot
/// server, and their bubbles as an OCR fixture.
class DemoPages {
  DemoPages._(this._pages);

  factory DemoPages.load() {
    final d = jsonDecode(File('../brand/demo/demo.json').readAsStringSync()) as Map<String, dynamic>;
    return DemoPages._([for (final p in d['pages'] as List) Map<String, dynamic>.from(p as Map)]);
  }

  final List<Map<String, dynamic>> _pages;

  List<Map<String, dynamic>> _of(int chapter) => _pages.where((p) => p['chapter'] == chapter).toList();

  /// Chapter [id] drawn from demo chapter [demo] (1 or 2), titled [title].
  /// [onDisk] serves the pages from `brand/demo` files (the saved-chapter path), so no network cache is involved.
  ReaderChapter chapter(String id, {int demo = 1, String? title, String? prev, String? next, int? pages, bool onDisk = true}) {
    final ps = _of(demo).take(pages ?? 20).toList();
    return ReaderChapter(
      id: id,
      seriesId: 'k',
      sourceId: 'demo',
      title: title ?? 'Chapter ${id.replaceAll(RegExp('[^0-9]'), '')}',
      seriesTitle: 'Tower of Dawn',
      pageCount: ps.length,
      previousChapterId: prev,
      nextChapterId: next,
      pages: [
        for (var i = 0; i < ps.length; i++)
          ReaderPage(
            id: '$id-${i + 1}',
            number: i + 1,
            imageUrl: 'http://example.test/reader/page/$id-${i + 1}/image',
            width: ps[i]['width'] as int,
            height: ps[i]['height'] as int,
            localFile: onDisk ? File(File('../brand/demo/${ps[i]['file']}').absolute.path) : null,
          ),
      ],
    );
  }

  /// Request path -> bytes for chapter [id] drawn from demo chapter [demo].
  Map<String, Uint8List> bytes(String id, {int demo = 1}) => {
        for (final (i, p) in _of(demo).indexed) '/reader/page/$id-${i + 1}/image': File('../brand/demo/${p['file']}').readAsBytesSync(),
      };

  /// The bubbles of demo chapter [demo] as recognised pages (fractions of each page).
  List<PageText> ocr({int demo = 1}) => [
        for (final (i, p) in _of(demo).indexed)
          if ((p['bubbles'] as List).isNotEmpty)
            PageText(
              page: i + 1,
              text: [for (final b in p['bubbles'] as List) (b as Map)['text']].join('\n'),
              boxes: [
                for (final b in p['bubbles'] as List)
                  OcrTextBox(
                    text: (b as Map)['text'] as String,
                    x: (b['x'] as num) / (p['width'] as num),
                    y: (b['y'] as num) / (p['height'] as num),
                    width: (b['w'] as num) / (p['width'] as num),
                    height: (b['h'] as num) / (p['height'] as num),
                  ),
              ],
            ),
      ];
}
