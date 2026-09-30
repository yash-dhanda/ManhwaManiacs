@Tags(['screenshots'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/global_search_result.dart';
import 'package:manhwamaniacs/features/library/providers/library_list_provider.dart';
import 'package:manhwamaniacs/features/ocr/models/ocr_search_result.dart';
import 'package:manhwamaniacs/features/ocr/providers/ocr_providers.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/models/source_health.dart';
import 'package:manhwamaniacs/features/sources/models/source_pin.dart';
import 'package:manhwamaniacs/features/sources/models/source_search_group.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/providers/discover_providers.dart';
import 'package:manhwamaniacs/features/sources/providers/source_pins_provider.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

import '../support/skin_shots.dart';

/// The mobile/38 proof captures: Glass Search, Sources, the catalogue and Dialogue search on invented data (nothing mature), plus
/// Cinematic's Discover and Sources unchanged. Written only when `MM_PROOF_DIR` is set; otherwise rasterised and discarded.

class _Search extends SearchListNotifier {
  @override
  Future<GroupedSearchResult> build() async => GroupedSearchResult(
        groups: [
          for (var i = 0; i < 3; i++) SourceSearchGroup(source: 's$i', sourceName: 'Source $i', status: SourceGroupStatus.ok, items: [for (var k = 0; k < 4; k++) GlobalSearchItem(kind: 'source', source: 's$i', seriesId: '$i$k', title: 'The Tower $i-$k')]),
          const SourceSearchGroup(source: 'bad', sourceName: 'Bad Source', status: SourceGroupStatus.error),
          const SourceSearchGroup(source: 'quiet', sourceName: 'Quiet Source', status: SourceGroupStatus.empty),
        ],
        sourcesQueried: 7,
        nextTier: 2,
        sourcesDeferred: 3,
      );
}

class _Pins extends SourcePinsNotifier {
  @override
  Future<SourcePinsState> build() async => const SourcePinsState(pins: [SourcePin(sourceId: 'b', sortOrder: 0, name: 'Source b')], synced: true);
}

class _NoMature extends MatureContentController {
  @override
  Future<bool> build() async => false;
}

class _Browse extends SourceBrowseNotifier {
  @override
  Future<SourceBrowseState> build(String sourceId) async => SourceBrowseState(items: [for (var i = 0; i < 12; i++) SourceSeriesSummary(id: 'x$i', sourceId: 'a', title: 'Invented Series $i', chapterCount: 12, genres: const [], coverUrl: '')], total: 412, cache: {'fetched_at': DateTime.now().subtract(const Duration(minutes: 12)).toIso8601String()});
}

SourceSummary _src(String id, [SourceHealthStatus st = SourceHealthStatus.ok]) => SourceSummary(id: id, name: id == 'a' ? 'Alpha Scans' : 'Source $id', description: 'Invented catalogue $id', browsable: true, supportsImport: false, health: SourceHealth(status: st));

final List<Override> _ov = [
  searchListProvider.overrideWith(_Search.new),
  sourcesListProvider.overrideWith((ref) async => [_src('a'), _src('b'), _src('c', SourceHealthStatus.failing)]),
  sourcePinsProvider.overrideWith(_Pins.new),
  sourceHealthSummaryProvider.overrideWith((ref) async => const SourceHealthSummary(total: 3, ok: 2, failing: 1)),
  matureContentProvider.overrideWith(_NoMature.new),
  sourceBrowseProvider.overrideWith(_Browse.new),
  sourceBrowseModesProvider.overrideWith((ref, id) async => const [SourceBrowseMode(id: 'popular', label: 'Popular'), SourceBrowseMode(id: 'latest', label: 'Latest')]),
  sourceGenresProvider.overrideWith((ref, id) async => const []),
  ocrFeatureVisibleProvider.overrideWithValue(true),
  ocrSearchProvider.overrideWith((ref, q) async => const OcrSearchPage(items: [OcrSearchResult(sourceId: 's', seriesKey: 'k', chapterKey: '12', snippet: 'I never said <mark>hello</mark> to the tower', wordCount: 212, engine: 'vision', highlightedTerms: ['hello'], page: 3)], total: 86, offset: 0, limit: 20, hasMore: true)),
];

void main() {
  for (final size in [kSkinShotSizes[0], kSkinShotSizes[1]]) {
    testWidgets('glass search idle ${size.name}', (t) async {
      await captureSkinScreen(t, skin: SkinId.glass, screen: ScreenId.discover, size: size, location: '/search', overrides: _ov);
    });
    testWidgets('glass search results ${size.name}', (t) async {
      await captureSkinScreen(t, skin: SkinId.glass, screen: ScreenId.discover, size: size, location: '/search?q=tower', overrides: _ov);
    });
    testWidgets('glass sources ${size.name}', (t) async {
      await captureSkinScreen(t, skin: SkinId.glass, screen: ScreenId.sources, size: size, overrides: _ov);
    });
    testWidgets('glass catalogue ${size.name}', (t) async {
      await captureSkinScreen(t, skin: SkinId.glass, screen: ScreenId.source, size: size, location: '/sources/a', overrides: _ov);
    });
    testWidgets('glass dialogue ${size.name}', (t) async {
      await captureSkinScreen(t, skin: SkinId.glass, screen: ScreenId.dialogue, size: size, location: '/ocr?q=hello', overrides: _ov);
    });
  }
  testWidgets('cinematic discover and sources are unchanged', (t) async {
    await captureSkinScreen(t, skin: SkinId.cinematic, screen: ScreenId.discover, size: kSkinShotSizes[0], overrides: _ov);
    await captureSkinScreen(t, skin: SkinId.cinematic, screen: ScreenId.sources, size: kSkinShotSizes[0], overrides: _ov);
  });
}
