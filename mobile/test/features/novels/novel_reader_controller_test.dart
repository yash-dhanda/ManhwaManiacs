
import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/downloads/providers/progress_outbox_provider.dart';
import 'package:manhwamaniacs/features/novels/controllers/novel_reader_controller.dart';
import 'package:manhwamaniacs/features/novels/models/novel_chapter.dart';
import 'package:manhwamaniacs/features/novels/models/novel_typography.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_chapter_provider.dart';
import 'package:manhwamaniacs/features/reader/models/reading_progress.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_overrides.dart';
import 'support/novel_fixtures.dart';

class _Outbox extends ProgressOutboxController {
  _Outbox(super.ref);
  final pushes = <ProgressPush>[];
  @override
  Future<void> save(ProgressPush push) async => pushes.add(push);
}

class _Surface implements NovelReadingSurface {
  int index = 0;
  bool end = false;
  int? landed;
  @override
  bool get atEnd => end;
  @override
  double get maxExtent => 1000;
  @override
  ({int index, double fraction})? anchorAtReadingLine() => (index: index, fraction: 0.5);
  @override
  bool landOn(int i, double fraction, {required bool toReadingLine}) {
    landed = i;
    return true;
  }

  @override
  void jumpEstimate(double fraction) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const args = NovelReaderArgs(sourceId: 'fixture', seriesKey: 'alice', chapterKey: '1');
  final chapter = fixtureChapter();
  final next = NovelChapter.fromJson({
    'source_id': 'fixture',
    'series_key': 'alice',
    'chapter_key': '2',
    'title': 'Two',
    'paragraphs': ['One.', 'Two.'],
    'prev': '1',
    'next': null,
  });

  late _Outbox outbox;
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues(testPrefsDefaults());
    prefs = await SharedPreferences.getInstance();
  });

  ProviderContainer make() {
    final c = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      ...noDownloadsStoreOverrides(),
      resolvedNovelChapterProvider((sourceId: 'fixture', seriesKey: 'alice', chapterKey: '1')).overrideWith((ref) async => chapter),
      resolvedNovelChapterProvider((sourceId: 'fixture', seriesKey: 'alice', chapterKey: '2')).overrideWith((ref) async => next),
      novelChapterNeighboursProvider((sourceId: 'fixture', seriesKey: 'alice', chapterKey: '1')).overrideWith((ref) async => (previousChapterKey: null, nextChapterKey: '2')),
      novelChapterNeighboursProvider((sourceId: 'fixture', seriesKey: 'alice', chapterKey: '2')).overrideWith((ref) async => (previousChapterKey: '1', nextChapterKey: null)),
      progressOutboxControllerProvider.overrideWith((ref) => outbox = _Outbox(ref)),
    ],);
    addTearDown(c.dispose);
    return c;
  }

  Future<NovelReaderController> open(ProviderContainer c) async {
    final sub = c.listen(novelReaderControllerProvider(args), (_, __) {});
    addTearDown(sub.close);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return c.read(novelReaderControllerProvider(args).notifier);
  }

  test('loads the chapter, its neighbours and warms the next chapter', () async {
    final c = make();
    final ctl = await open(c);
    final s = c.read(novelReaderControllerProvider(args));
    expect(s.chapter?.title, 'Down the Rabbit-Hole');
    expect(ctl.nextKey, '2');
    expect(s.nextState, NovelNextState.ready);
  });

  test('scroll position becomes a paragraph bucket, sent once and never backwards', () async {
    final c = make();
    final ctl = await open(c);
    final surface = _Surface()..index = 8;
    ctl.attach(surface);
    ctl.onScrolled();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(outbox.pushes, hasLength(1));
    final first = outbox.pushes.single;
    expect(first.lastPage, greaterThan(1));
    expect(first.isCompleted, isFalse);
    surface.index = 2;
    ctl.onScrolled();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(outbox.pushes, hasLength(1), reason: 'scrolling back never tells the server the reader is earlier');
  });

  test('next() completes the chapter and swaps the next one in with the location replaced', () async {
    final c = make();
    final ctl = await open(c);
    final moved = <String>[];
    ctl
      ..seamless = true
      ..locationReplacer = moved.add
      ..attach(_Surface());
    ctl.next();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(outbox.pushes.any((p) => p.isCompleted && p.chapterKey == '1'), isTrue);
    expect(moved, ['2']);
    final s = c.read(novelReaderControllerProvider(args));
    expect(s.chapter?.chapterKey, '2');
    expect(s.revision, 1);
  });

  test('a restore lands on the requested paragraph and flags a stale anchor', () async {
    final c = make();
    const stale = NovelReaderArgs(sourceId: 'fixture', seriesKey: 'alice', chapterKey: '1', initialParagraph: 999);
    final sub = c.listen(novelReaderControllerProvider(stale), (_, __) {});
    addTearDown(sub.close);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final ctl = c.read(novelReaderControllerProvider(stale).notifier);
    final surface = _Surface();
    ctl.attach(surface);
    ctl.beginRestore();
    expect(surface.landed, chapter.paragraphs.length - 1);
    expect(c.read(novelReaderControllerProvider(stale)).stale, isTrue);
  });

  test('auto next fires 900 ms after the end, unless narration is playing', () async {
    final c = make();
    final ctl = await open(c);
    final moved = <String>[];
    ctl
      ..autoNext = true
      ..locationReplacer = moved.add
      ..attach(_Surface()..end = true);
    ctl.narrationBusy = () => true;
    ctl.onScrolled();
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    expect(moved, isEmpty);
    ctl.narrationBusy = () => false;
    ctl.onScrolled();
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    expect(moved, ['2']);
  });

  test('paginateNovel keeps the reading paragraph across a re-pagination and reports counts', () async {
    final c = make();
    final ctl = await open(c);
    ctl.setViewport(const Size(390, 844), margin: 24);
    final small = ctl.paginateNovel(64, const NovelType());
    expect(c.read(novelReaderControllerProvider(args)).pageCount, small.length);
    ctl.onPaged(2);
    final anchor = small[2].first.paragraphIndex;
    final big = ctl.paginateNovel(64, const NovelType(fontSize: 26));
    final page = c.read(novelReaderControllerProvider(args)).pageIndex;
    expect(big[page].any((s) => s.paragraphIndex == anchor) || big[page].first.paragraphIndex <= anchor, isTrue);
  });
}
