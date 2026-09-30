import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/skins/glass/primitives/download_state.dart';

ChapterDownloadKind _k(ChapterDownloadFacts f) => chapterDownloadView(f).kind;

void main() {
  test('eight states from the store row and queue item', () {
    expect(_k(const ChapterDownloadFacts()), ChapterDownloadKind.none);
    expect(_k(const ChapterDownloadFacts(inQueue: true)), ChapterDownloadKind.queued);
    expect(_k(const ChapterDownloadFacts(row: DownloadChapterState.queued)), ChapterDownloadKind.queued);
    expect(_k(const ChapterDownloadFacts(row: DownloadChapterState.downloading, pagesDone: 18, pagesTotal: 40)), ChapterDownloadKind.downloading);
    expect(_k(const ChapterDownloadFacts(row: DownloadChapterState.complete, pagesDone: 40, pagesTotal: 40)), ChapterDownloadKind.saved);
    expect(_k(const ChapterDownloadFacts(row: DownloadChapterState.complete, missingPages: true)), ChapterDownloadKind.incomplete);
    expect(_k(const ChapterDownloadFacts(row: DownloadChapterState.complete, stale: true)), ChapterDownloadKind.stale);
    expect(_k(const ChapterDownloadFacts(row: DownloadChapterState.queued, pauseReason: DownloadPauseReason.cap)), ChapterDownloadKind.paused);
    expect(_k(const ChapterDownloadFacts(row: DownloadChapterState.failed)), ChapterDownloadKind.failed);
  });

  test('a pause reason with nothing active is not paused', () {
    expect(_k(const ChapterDownloadFacts(pauseReason: DownloadPauseReason.userPaused)), ChapterDownloadKind.none);
  });

  test('progress is pages done over total, clamped', () {
    final v = chapterDownloadView(const ChapterDownloadFacts(row: DownloadChapterState.downloading, pagesDone: 18, pagesTotal: 40));
    expect(v.progress, closeTo(0.45, 1e-9));
    expect(chapterDownloadView(const ChapterDownloadFacts(row: DownloadChapterState.downloading, pagesDone: 5)).progress, 0);
  });

  test('semantics labels match the table', () {
    String l(ChapterDownloadView v) => downloadSemanticsLabel(v, 'chapter 12');
    expect(l(const ChapterDownloadView(ChapterDownloadKind.none)), 'Download chapter 12');
    expect(l(const ChapterDownloadView(ChapterDownloadKind.queued)), 'Queued to download');
    expect(l(const ChapterDownloadView(ChapterDownloadKind.downloading, pagesDone: 18, pagesTotal: 40)), 'Downloading, page 18 of 40');
    expect(l(const ChapterDownloadView(ChapterDownloadKind.saved)), 'Downloaded, opens with no connection');
    expect(l(const ChapterDownloadView(ChapterDownloadKind.incomplete)), 'Incomplete, some pages are missing');
    expect(l(const ChapterDownloadView(ChapterDownloadKind.paused, pauseReason: DownloadPauseReason.freeSpaceFloor)), 'Paused, device is full');
    expect(l(const ChapterDownloadView(ChapterDownloadKind.paused, pauseReason: DownloadPauseReason.cap)), 'Paused, storage cap reached');
    expect(l(const ChapterDownloadView(ChapterDownloadKind.paused, pauseReason: DownloadPauseReason.backgrounded)), 'Paused until you reopen the app');
    expect(l(const ChapterDownloadView(ChapterDownloadKind.paused, pauseReason: DownloadPauseReason.userPaused)), 'Paused');
    expect(l(const ChapterDownloadView(ChapterDownloadKind.paused, pauseReason: DownloadPauseReason.noScope)), 'Paused, choose a profile first');
    expect(l(const ChapterDownloadView(ChapterDownloadKind.stale)), 'The source changed these pages, download again');
    expect(l(const ChapterDownloadView(ChapterDownloadKind.failed)), 'Download failed, retry');
  });
}
