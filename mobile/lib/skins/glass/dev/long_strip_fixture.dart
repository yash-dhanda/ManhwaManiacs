import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/models/reader_feed.dart';
import 'package:manhwamaniacs/features/reader/models/reader_page.dart';
import 'package:path_provider/path_provider.dart';

const int kLongStripPages = 120;
const int kLongStripWidth = 720;
const int kLongStripHeight = 2880;

/// The 120-page, 2,880 px strip of glass 15.4's device check: 120 PNGs of 720 x 2,880 written once to
/// `getTemporaryDirectory()/mm-long-strip/` (a vertical gradient whose hue is `page x 3` degrees, a white
/// 200 x 120 rounded rectangle at y 200 on every third page), served like saved pages: `localFile` set.
/// Debug builds only.
Future<ReaderFeed> buildLongStripFeed() async {
  assert(!kReleaseMode, 'the long-strip fixture is a debug build tool');
  final dir = Directory('${(await getTemporaryDirectory()).path}/mm-long-strip');
  await dir.create(recursive: true);
  final files = [for (var n = 1; n <= kLongStripPages; n++) File('${dir.path}/p$n.png')];
  final missing = [for (var i = 0; i < files.length; i++) if (!files[i].existsSync()) i];
  for (var i = 0; i < missing.length; i += 4) {
    await Future.wait([for (final m in missing.skip(i).take(4)) _writePage(files[m], m + 1)]);
  }
  ReaderChapter chapter(String id, List<File> f, {String? prev, String? next}) => ReaderChapter(
        id: id,
        seriesId: 'long-strip',
        sourceId: 'fixture',
        title: 'Long strip $id',
        pageCount: f.length,
        previousChapterId: prev,
        nextChapterId: next,
        pages: [
          for (var n = 1; n <= f.length; n++)
            ReaderPage(id: '$id-$n', number: n, imageUrl: '', width: kLongStripWidth, height: kLongStripHeight, localFile: f[n - 1]),
        ],
      );
  return ReaderFeed.of([chapter('long', files)]);
}

/// A 3-page neighbour chapter built from the same files.
Future<ReaderChapter> buildLongStripNeighbour(String id) async {
  final feed = await buildLongStripFeed();
  final pages = feed.pages.take(3).toList();
  return ReaderChapter(
    id: id,
    seriesId: 'long-strip',
    sourceId: 'fixture',
    title: 'Long strip $id',
    pageCount: 3,
    pages: [for (var n = 1; n <= 3; n++) ReaderPage(id: '$id-$n', number: n, imageUrl: '', width: kLongStripWidth, height: kLongStripHeight, localFile: pages[n - 1].localFile)],
  );
}

Future<void> _writePage(File file, int page) async {
  final rec = ui.PictureRecorder();
  final canvas = ui.Canvas(rec);
  const rect = ui.Rect.fromLTWH(0, 0, 720, 2880);
  final hue = (page * 3) % 360.0;
  canvas.drawRect(
    rect,
    ui.Paint()
      ..shader = ui.Gradient.linear(ui.Offset.zero, const ui.Offset(0, 2880), [
        HSVColor.fromAHSV(1, hue, 0.55, 0.95).toColor(),
        HSVColor.fromAHSV(1, hue, 0.75, 0.35).toColor(),
      ]),
  );
  if (page % 3 == 0) {
    canvas.drawRRect(ui.RRect.fromRectAndRadius(const ui.Rect.fromLTWH(260, 200, 200, 120), const ui.Radius.circular(40)), ui.Paint()..color = const ui.Color(0xFFFFFFFF));
  }
  final image = await rec.endRecording().toImage(720, 2880);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
}
