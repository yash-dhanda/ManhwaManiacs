
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/network/network_connectivity.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/models/reader_page.dart';
import 'package:manhwamaniacs/features/reader/repositories/reader_repository.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/ambient_bridge.dart';

import '../feature/feature_test_support.dart' show featureTheme;

class _Repo extends Fake implements ReaderRepository, ReaderAnalysisReports {
  final tints = <List<({int page, String hex})>>[];
  final panels = <List<({int page, List<Rect> panels})>>[];

  @override
  Future<Result<void>> postPageTints({required String sourceId, required String seriesKey, required String chapterKey, required List<({int page, String hex})> tints}) async {
    this.tints.add(tints);
    return const Ok(null);
  }

  @override
  Future<Result<void>> postPanels({required String sourceId, required String seriesKey, required String chapterKey, required List<({int page, List<Rect> panels})> pages}) async {
    panels.add(pages);
    return const Ok(null);
  }
}

class _Net extends Fake implements NetworkConnectivity {
  _Net(this.online);
  final bool online;
  @override
  Future<bool> isOnline() async => online;
}

Future<({CineAmbientBridge bridge, ReaderEngine engine, _Repo repo})> _pump(WidgetTester tester, {required bool online}) async {
  final repo = _Repo();
  late WidgetRef captured;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        readerRepositoryProvider.overrideWithValue(repo),
        networkConnectivityProvider.overrideWithValue(_Net(online)),
        downloadsStoreProvider.overrideWithValue(null),
      ],
      child: MaterialApp(
        theme: featureTheme(TargetPlatform.android),
        home: Consumer(
          builder: (context, ref, _) {
            captured = ref;
            return const SizedBox();
          },
        ),
      ),
    ),
  );
  final engine = ReaderEngine();
  addTearDown(engine.dispose);
  final bridge = CineAmbientBridge(ref: captured, engine: engine, sourceId: 'demo', seriesKey: 'k');
  // The build resolves the handles the exit report uses.
  bridge.sync(tester.element(find.byType(Consumer)), chapters: const [], tintOn: true, paceByDialogue: false, resumeAfterRelease: true, rtl: false, panelsWanted: false);
  return (bridge: bridge, engine: engine, repo: repo);
}

void main() {
  testWidgets('leaving a chapter posts the sampled pages once each; greyscale pages are not in the tints', (tester) async {
    final r = await _pump(tester, online: true);
    r.engine.ambient.debugAddSamples('c1', tints: {1: '#C82828', 4: '#112233'}, panels: {2: const [Rect.fromLTWH(0, 0, 1, 0.5)], 3: const <Rect>[]});
    await r.bridge.flush('c1');
    await tester.pump();
    expect(r.repo.tints, hasLength(1));
    expect(r.repo.tints.single.map((t) => t.page), [1, 4]);
    expect(r.repo.panels, hasLength(1));
    expect(r.repo.panels.single.map((p) => p.page), [2, 3]);
    expect(r.repo.panels.single.last.panels, isEmpty, reason: 'an empty list for a page with none');
    // Nothing new since: nothing is posted again.
    await r.bridge.flush('c1');
    await tester.pump();
    expect(r.repo.tints, hasLength(1));
    expect(r.repo.panels, hasLength(1));
  });

  testWidgets('nothing is posted offline', (tester) async {
    final r = await _pump(tester, online: false);
    r.engine.ambient.debugAddSamples('c1', tints: {1: '#C82828'}, panels: {1: const <Rect>[]});
    await r.bridge.flush('c1');
    await tester.pump();
    expect(r.repo.tints, isEmpty);
    expect(r.repo.panels, isEmpty);
  });

  testWidgets('the manifest tint and panels seed the engine before any sampling', (tester) async {
    final r = await _pump(tester, online: true);
    const chapter = ReaderChapter(
      id: 'c9',
      seriesId: 'k',
      title: 'Chapter 9',
      pageCount: 2,
      pages: [
        ReaderPage(id: 'a', number: 1, imageUrl: 'http://x.test/1', tint: '#C82828', panels: [Rect.fromLTWH(0, 0, 1, 1)]),
        ReaderPage(id: 'b', number: 2, imageUrl: 'http://x.test/2', panels: <Rect>[]),
      ],
    );
    final ctx = tester.element(find.byType(Consumer));
    r.bridge.sync(ctx, chapters: [chapter], tintOn: true, paceByDialogue: false, resumeAfterRelease: true, rtl: false, panelsWanted: false);
    r.engine.ambient.onPage('c9', 1);
    expect(r.engine.pageTint.value, isNotNull, reason: 'tinted from frame 0');
    expect(r.engine.panels.value.keys, containsAll([1, 2]));
    expect(r.engine.ambient.takeReport('c9').isEmpty, isTrue, reason: 'stored values are not new samples');
  });

}
