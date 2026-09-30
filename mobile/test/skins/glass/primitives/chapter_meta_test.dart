import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/chapter_meta.dart';

void main() {
  final now = DateTime(2026, 9, 30, 10);
  test('date labels are calendar days', () {
    expect(chapterDateLabel(DateTime(2026, 9, 30, 0, 5), now), 'Today');
    expect(chapterDateLabel(DateTime(2026, 9, 29, 23), now), 'Yesterday');
    expect(chapterDateLabel(DateTime(2026, 9, 28), now), '2 d ago');
    expect(chapterDateLabel(DateTime(2026, 9, 24), now), '6 d ago');
    expect(chapterDateLabel(DateTime(2026, 9, 12), now), '12 Sep');
    expect(chapterDateLabel(DateTime(2025, 9, 12), now), '12 Sep 2025');
    expect(chapterDateLabel(DateTime(2026, 10, 2), now), 'Today');
  });

  test('number labels', () {
    expect(chapterNumberLabel(null), '·');
    expect(chapterNumberLabel(12), '12');
    expect(chapterNumberLabel(12.5), '12.5');
  });
}
