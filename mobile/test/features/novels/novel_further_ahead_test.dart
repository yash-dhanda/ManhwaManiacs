import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/novels/controllers/novel_reader_controller.dart';

void main() {
  test('the further-ahead percent divides by the row\'s bucket count', () {
    expect(const NovelFurtherAhead(chapterKey: 'k', chapterNumber: 2, bucket: 15, buckets: 30).percent, 50);
    expect(const NovelFurtherAhead(chapterKey: 'k', chapterNumber: 2, bucket: 30, buckets: 30).percent, 100);
  });
}
