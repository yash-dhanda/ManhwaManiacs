import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/chapters_section.dart';

void main() {
  const done = (state: DownloadChapterState.complete, error: null);
  test('a chapter cancelled mid-run (its row gone) still lets the run finish', () {
    final run = {'a', 'b', 'c'};
    final statuses = {'a': done, 'b': done};
    expect(runSummary(run, statuses), isNull);
    expect(runSummary(run, statuses, seen: {'a', 'b', 'c'}), '2 of 3 downloaded');
  });

  test('a key never seen yet is still pending, and an all-cancelled run ends quietly', () {
    expect(runSummary({'a'}, const {}, seen: const {}), isNull);
    expect(runSummary({'a'}, const {}, seen: {'a'}), '');
  });
}
