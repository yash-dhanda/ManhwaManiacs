import 'dart:ui' show Size;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/pagination.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_gate_provider.dart';
import 'package:manhwamaniacs/features/library/models/collection.dart';
import 'package:manhwamaniacs/features/library/models/collection_detail.dart';
import 'package:manhwamaniacs/features/library/models/continue_reading_item.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/models/reading_history_item.dart';
import 'package:manhwamaniacs/features/library/models/tag.dart';
import 'package:manhwamaniacs/features/library/repositories/library_repository.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

import '../../../features/library/shelf_fixtures.dart';
import '../shell/shell_rig.dart';

/// A library that answers from memory and records every call (`calls`): the shelf, collections, history and tags of the Glass
/// Library tests. Anything else answers "down".
class FakeLib implements LibraryRepository {
  FakeLib({this.series = const [], this.collections = const [], this.history = const [], this.tags = const [], this.members = const []});
  List<FollowedSeries> series;
  List<Collection> collections;
  List<ReadingHistoryItem> history;
  List<Tag> tags;
  List<CollectionSeriesRef> members;
  final List<String> calls = [];
  bool down = false;

  @override
  Future<Result<PagedResult<FollowedSeries>>> listSeries({int page = 1, int perPage = 40, String? sort, String? search, String? readingStatus, bool? isFavorite, List<int>? tagIds, bool? newOnly}) async {
    calls.add('listSeries:${readingStatus ?? ''}:${tagIds?.join(',') ?? ''}:${isFavorite ?? ''}');
    if (down) return const Err(NetworkError(message: 'down'));
    return Ok(PagedResult(items: series, total: series.length, page: 1, perPage: perPage, hasNext: false));
  }

  @override
  Future<Result<List<ContinueReadingItem>>> continueReading({int limit = 10}) async => const Ok(<ContinueReadingItem>[]);

  @override
  Future<Result<List<Collection>>> listCollections() async => Ok(collections);

  @override
  Future<Result<CollectionDetail>> getCollection(int collectionId) async {
    calls.add('getCollection:$collectionId');
    final c = collections.firstWhere((c) => c.id == collectionId);
    return Ok(CollectionDetail(id: c.id, name: c.name, seriesCount: members.length, sortOrder: 0, series: members));
  }

  @override
  Future<Result<void>> reorderCollectionMembers(int collectionId, List<({String sourceId, String seriesKey})> items) async {
    calls.add('reorder:${items.map((e) => e.seriesKey).join(',')}');
    return const Ok(null);
  }

  @override
  Future<Result<List<ReadingHistoryItem>>> readingHistory({int limit = 50, int offset = 0, bool bySeries = true}) async {
    calls.add('history:$offset:$bySeries');
    return Ok(history.skip(offset).take(limit).toList());
  }

  @override
  Future<Result<List<Tag>>> listTags({String? category}) async => Ok(tags);

  @override
  Future<Result<void>> unfollow(int followedId) async {
    calls.add('unfollow:$followedId');
    series = [for (final s in series) if (s.id != followedId) s];
    return const Ok(null);
  }

  @override
  Future<Result<FollowedSeries>> follow({required String sourceId, required String seriesKey}) async {
    calls.add('follow:$seriesKey');
    return Ok(shelfSeries(99));
  }

  @override
  Future<Result<FollowedSeries>> patchSeries(int followedId, {bool? isFavorite, String? readingStatus, bool? notify, bool? matureOverride, bool clearMatureOverride = false, int? sortOrder}) async {
    calls.add('patch:$followedId:${isFavorite ?? ''}:${readingStatus ?? ''}:${sortOrder ?? ''}');
    return Ok(shelfSeries(followedId));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The overrides a Library test needs on top of the shell's: the fake library and a closed 18+ gate.
List<Override> libraryOverrides(FakeLib lib) => [
      libraryRepositoryProvider.overrideWithValue(lib),
      matureGateOpenProvider.overrideWithValue(false),
    ];

Future<ShellRig> pumpLibrary(WidgetTester t, FakeLib lib, {String start = '/library', Size size = const Size(390, 844), bool android = false, int downloads = 0, List<Override> extra = const []}) async {
  final rig = await pumpGlassShell(t, size: size, start: start, downloads: downloads, platformAndroid: android, settle: false, extra: [...libraryOverrides(lib), ...extra]);
  for (var i = 0; i < 8; i++) {
    await t.pump(const Duration(milliseconds: 300));
  }
  return rig;
}
