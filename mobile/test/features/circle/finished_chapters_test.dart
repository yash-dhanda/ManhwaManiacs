import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/circle/utils/spoiler_guard.dart';
import 'package:manhwamaniacs/features/sources/models/source_chapter_progress.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';

class _Progress extends SourceProgressNotifier {
  @override
  Map<String, SourceChapterProgress> build() => {
        's:k:141': SourceChapterProgress(page: 30, pageCount: 30, completed: true, updatedAt: DateTime.utc(2026)),
        's:k:142': SourceChapterProgress(page: 12, pageCount: 30, completed: false, updatedAt: DateTime.utc(2026)),
        's:other:1': SourceChapterProgress(page: 9, pageCount: 9, completed: true, updatedAt: DateTime.utc(2026)),
      };
}

void main() {
  test('finished chapters come from local progress and this session; the guard follows them', () {
    final c = ProviderContainer(overrides: [sourceProgressProvider.overrideWith(_Progress.new)]);
    addTearDown(c.dispose);
    const key = (sourceId: 's', seriesKey: 'k');
    expect(c.read(finishedChaptersProvider(key)), {'141'});
    c.read(completedThisSessionProvider.notifier).markCompleted('s', 'k', '143');
    final fin = c.read(finishedChaptersProvider(key));
    expect(fin, {'141', '143'});

    expect(guardedFor(fin, chapterKey: '200', isOwn: true, sealed: true), isFalse, reason: 'own');
    expect(guardedFor(fin, chapterKey: '141', isOwn: false, sealed: true), isFalse, reason: 'finished');
    expect(guardedFor(fin, chapterKey: '142', isOwn: false, sealed: true), isTrue, reason: 'half-read');
    expect(guardedFor(fin, chapterKey: '150', isOwn: false, sealed: true), isTrue, reason: 'unread');
    final none = c.read(finishedChaptersProvider((sourceId: 's', seriesKey: 'unfollowed')));
    expect(guardedFor(none, chapterKey: '1', isOwn: false, sealed: null), isTrue, reason: 'unfollowed');
  });
}
