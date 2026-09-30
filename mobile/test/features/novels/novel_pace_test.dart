import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/novels/utils/novel_pace.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('chapterPaceWpm filters by time and pace', () {
    expect(chapterPaceWpm(3000, 600), 300);
    expect(chapterPaceWpm(3000, 59), isNull);
    expect(chapterPaceWpm(3000, 7201), isNull);
    expect(chapterPaceWpm(100, 3600), isNull); // 1.7 wpm
    expect(chapterPaceWpm(100000, 600), isNull); // 10000 wpm
  });

  test('median of the last 10, 250 until 3 samples', () {
    expect(novelPaceWpm(const []), 250);
    expect(novelPaceWpm(const [NovelPaceSample('a', 400), NovelPaceSample('b', 500)]), 250);
    expect(novelPaceWpm(const [NovelPaceSample('a', 300), NovelPaceSample('b', 312), NovelPaceSample('c', 500)]), 312);
    final many = [for (var i = 0; i < 12; i++) NovelPaceSample('c$i', i < 2 ? 900 : 200)];
    expect(novelPaceWpm(many), 200);
  });

  test('store round trips, caps at 10, replaces a repeated chapter', () async {
    SharedPreferences.setMockInitialValues({});
    final store = NovelPaceStore(await SharedPreferences.getInstance(), NovelPaceStore.keyFor(1, 2));
    expect(store.paceWpm, 250);
    for (var i = 0; i < 12; i++) {
      await store.recordCompletion(chapterKey: 'c$i', wordCount: 3120, timeSpentSeconds: 600);
    }
    expect(store.samples(), hasLength(10));
    expect(store.paceWpm, 312);
    await store.recordCompletion(chapterKey: 'c11', wordCount: 3120, timeSpentSeconds: 600);
    expect(store.samples(), hasLength(10));
    await store.recordCompletion(chapterKey: 'x', wordCount: 5, timeSpentSeconds: 10);
    expect(store.samples(), hasLength(10));
  });

  test('avgWordsPerLine', () => expect(avgWordsPerLine(1000, 100), 10));
}
