// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_identity.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/features/downloads/services/offline_novel_reader.dart';
import 'package:manhwamaniacs/features/downloads/store/downloads_store.dart';
import 'package:manhwamaniacs/features/library/providers/local_read_marks_provider.dart';
import 'package:manhwamaniacs/features/sources/models/source_chapter_progress.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';

import '../../support/downloads_test_support.dart';
import 'mature_gate_support.dart';

const _hot = (sourceId: 'src', seriesKey: 'hot', chapterKey: 'c1');
const _series = (sourceId: 'src', seriesKey: 'hot');

class _Progress extends SourceProgressNotifier {
  @override
  Map<String, SourceChapterProgress> build() => {
        'src:hot:c1': SourceChapterProgress(page: 3, pageCount: 3, completed: true, updatedAt: DateTime.utc(2026)),
      };
}

Future<void> _save(DownloadsStore s, ChapterIdentity id, {DownloadKind kind = DownloadKind.manga}) async {
  final row = await s.ensureQueued(id: id, kind: kind, seriesTitle: 'Hot');
  await s.updateManifestInfo(rowId: row, pageCount: 1);
  if (kind == DownloadKind.audio) {
    await s.saveAudio(rowId: row, bytes: [1]);
  } else if (kind == DownloadKind.novel) {
    await s.saveNovelText(rowId: row, chapter: {'paragraphs': <String>['x']});
  } else {
    await s.savePage(rowId: row, pageNumber: 1, bytes: [1]);
  }
  await s.markCompleteIfAllPagesPresent(row);
}

void main() {
  initSqfliteFfiForTests();

  test('the series status providers and the read marks hide a gated series and restore it', () async {
    final rig = await gateRig(follows: [follow(1, 'hot', rating: 'mature')]);
    addTearDown(() async {
      rig.container.dispose();
      await rig.harness.dispose();
    });
    final c = rig.container;
    final store = c.read(downloadsStoreProvider)!;
    await _save(store, _hot);
    await _save(store, audioIdentity(_hot), kind: DownloadKind.audio);

    Future<int> chapters() async {
      c.invalidate(seriesChapterDownloadStatusProvider(_series));
      return (await c.read(seriesChapterDownloadStatusProvider(_series).future)).length;
    }

    Future<int> narrations() async {
      c.invalidate(seriesNarrationStatusProvider(_series));
      return (await c.read(seriesNarrationStatusProvider(_series).future)).length;
    }

    expect(await chapters(), 1);
    expect(await narrations(), 1);
    rig.gate(false);
    expect(await chapters(), 0);
    expect(await narrations(), 0);
    rig.gate(true);
    expect(await chapters(), 1);
  });

  test('read marks: a gated series has none while the gate is closed', () async {
    final rig = await gateRig(
      follows: [follow(1, 'hot', rating: 'mature'), follow(2, 'plain', rating: 'safe')],
      extra: [sourceProgressProvider.overrideWith(_Progress.new)],
    );
    final c = rig.container;
    addTearDown(() async {
      rig.container.dispose();
      await rig.harness.dispose();
    });
    final hot = follow(1, 'hot', rating: 'mature');
    expect(c.read(localReadMarksProvider).forFollow(hot), isNotNull);
    rig.gate(false);
    expect(c.read(localReadMarksProvider).forFollow(hot), isNull);
  });

  test('an offline novel chapter of a hidden series opens as not available', () async {
    final rig = await gateRig(follows: [follow(1, 'hot', rating: 'mature')]);
    addTearDown(() async {
      rig.container.dispose();
      await rig.harness.dispose();
    });
    final store = rig.container.read(downloadsStoreProvider)!;
    await _save(store, _hot, kind: DownloadKind.novel);
    expect(await buildOfflineNovelChapter(store, _hot), isNotNull);
    await expectLater(buildOfflineNovelChapter(store, _hot, hideMature: true), throwsA(isA<ApiError>().having((e) => e.code, 'code', 'series_not_found')));
  });
}
