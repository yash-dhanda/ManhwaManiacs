import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/utils/mark_read.dart';
import 'package:manhwamaniacs/features/sources/models/source_chapter_progress.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/utils/resume_order.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/series_data.dart';

SourceChapterSummary _c(String id, double? n) => SourceChapterSummary(id: id, sourceId: 's', seriesId: 'x', title: id, number: n, pageCount: 20);
SourceChapterProgress _p(DateTime at, {bool done = true, int page = 20}) => SourceChapterProgress(page: page, pageCount: 20, completed: done, updatedAt: at);

void main() {
  final t0 = DateTime.utc(2026, 9, 1);

  test('a manual mark stamped by manualMarkStamp never becomes the Continue chapter', () {
    final order = [for (var i = 1; i <= 80; i++) _c('c$i', i.toDouble())];
    final progress = {'c80': _p(t0, done: false, page: 12)};
    final rows = manualReadRows([(sourceId: 's', seriesKey: 'x', chapterKey: 'c3', chapterNumber: 3, pageCount: 20, completed: false)], at: manualMarkStamp(progress));
    progress['c3'] = _p(rows.single.lastReadAt!);
    final r = seriesResume(order, progress);
    expect(r.chapterKey, 'c80');
    expect(r.page, 12);
  });

  test('one batch of marks shares a stamp; the latest chapter in order wins the tie', () {
    final order = [for (var i = 1; i <= 80; i++) _c('c$i', i.toDouble())];
    final rows = manualReadRows([for (var i = 79; i >= 1; i--) (sourceId: 's', seriesKey: 'x', chapterKey: 'c$i', chapterNumber: i.toDouble(), pageCount: 20, completed: false)]);
    expect(rows.map((r) => r.lastReadAt).toSet(), hasLength(1));
    final progress = {for (final r in rows) r.chapterKey: _p(r.lastReadAt!)};
    expect(seriesResume(order, progress).chapterKey, 'c80');
  });

  test('another upload of the finished number is skipped', () {
    final chapters = [_c('12a', 12), _c('12b', 12), _c('13', 13)];
    final order = readingOrderOf(chapters);
    expect(order.map((c) => c.id), ['12a', '12b', '13']);
    expect(seriesResume(order, {'12b': _p(t0)}).chapterKey, '13');
    expect(seriesResume(order, {'12a': _p(t0)}).chapterKey, '13');
  });

  test('readingOrderOf is stable for equal numbers', () {
    final chapters = [for (var i = 0; i < 50; i++) _c('k$i', (i % 5).toDouble())];
    final order = readingOrderOf(chapters);
    for (var i = 1; i < order.length; i++) {
      if (order[i].number == order[i - 1].number) {
        expect(int.parse(order[i].id.substring(1)) > int.parse(order[i - 1].id.substring(1)), isTrue);
      }
    }
  });
}
