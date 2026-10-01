import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/screens/stats/stats_sections.dart';

void main() {
  test('a novel session opens the novel reader, a manga one the reader', () {
    const scope = ContentModeScope(mode: ContentMode.novel, index: {'nv': ContentMode.novel}, novelsEnabled: true);
    expect(sessionRoute(scope, const RecentSession(sourceId: 'nv', seriesKey: 'k', chapterKey: 'c')), Routes.novel('nv', 'k', 'c'));
    expect(sessionRoute(scope, const RecentSession(sourceId: 'mg', seriesKey: 'k', chapterKey: 'c')), Routes.reader('mg', 'k', 'c'));
  });
}
