// ignore_for_file: require_trailing_commas, directives_ordering
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/ai/providers/suggested_tags_provider.dart';
import 'package:manhwamaniacs/features/ai/repositories/ai_repository.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_identity.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/downloads/services/device_storage_info.dart';
import 'package:manhwamaniacs/features/library/models/collection.dart';
import 'package:manhwamaniacs/features/library/models/collection_detail.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/models/tag.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/library/repositories/library_repository.dart';
import 'package:manhwamaniacs/features/library/repositories/progress_deleter.dart';
import 'package:manhwamaniacs/features/novels/providers/series_audio_provider.dart';
import 'package:manhwamaniacs/features/ocr/models/ocr_coverage.dart';
import 'package:manhwamaniacs/features/ocr/providers/ocr_providers.dart';
import 'package:manhwamaniacs/features/reader/models/chapter_manifest.dart';
import 'package:manhwamaniacs/features/reader/models/reading_progress.dart';
import 'package:manhwamaniacs/features/reader/repositories/reader_repository.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/sources/models/series_enrichment.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/models/source_chapter_progress.dart';
import 'package:manhwamaniacs/features/sources/models/source_search_group.dart';
import 'package:manhwamaniacs/features/sources/repositories/sources_repository.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/providers/series_enrichment_provider.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/reader_prefetch.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/skin_haptics.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_data.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../screenshots/support/skin_shots.dart' show kSkinShotKey;
import '../../../support/test_overrides.dart';

/// A fixture from `test/fixtures/series/`: invented series, invented chapters.
({SourceSeriesSummary series, List<SourceChapterSummary> chapters}) loadSeriesFixture(String name) {
  final j = jsonDecode(File('test/fixtures/series/$name.json').readAsStringSync())
      as Map<String, dynamic>;
  return (
    series: SourceSeriesSummary.fromJson(j['series'] as Map<String, dynamic>, 'http://example.test'),
    chapters: [
      for (final c in j['chapters'] as List<dynamic>)
        SourceChapterSummary.fromJson(c as Map<String, dynamic>),
    ],
  );
}

FeatureData fixtureData(String name, {FollowedSeries? followed}) {
  final f = loadSeriesFixture(name);
  return FeatureData(
    sourceId: 'demo',
    seriesKey: 'k',
    series: f.series,
    chapters: f.chapters,
    followed: followed,
  );
}

FollowedSeries followedRow({
  String rating = 'safe',
  bool favorite = false,
  bool notify = false,
  String status = 'reading',
  bool? matureOverride,
  List<Tag> tags = const [],
  String coverUrl = '',
}) =>
    FollowedSeries(
      id: 7,
      sourceId: 'demo',
      seriesKey: 'k',
      title: 'Tower of Dawn',
      coverUrl: coverUrl,
      isFavorite: favorite,
      readingStatus: status,
      notify: notify,
      sortOrder: 0,
      contentRating: rating,
      rating: rating,
      matureOverride: matureOverride,
      chapterCount: 3,
      tags: tags,
    );

/// The boundary the screenshot harness rasterises.
final GlobalKey kShotBoundary = kSkinShotKey;

/// What the page asked the data layer to do.
class Recorder {
  final List<String> haptics = [];
  final List<List<ProgressPush>> pushed = [];
  final List<({String source, String series, List<String> keys})> deleted = [];
  final List<String> manifests = [];
  final List<List<ChapterQueueRequest>> enqueued = [];
  final List<Map<String, Object?>> patches = [];
  final List<String> tagCalls = [];
  final List<String> shelfCalls = [];
  final List<Map<String, Object?>> repoints = [];
  final List<String> bookmarks = [];
  final List<String> following = [];

  List<ProgressPush> get pushedRows => [for (final b in pushed) ...b];
}

class RecordingHaptics extends SkinHaptics {
  RecordingHaptics(this.rec) : super(skin: SkinId.cinematic, map: const {}, enabled: true);
  final Recorder rec;

  @override
  Future<void> fire(HapticEvent event, {double velocity = 0, int depth = 1}) async =>
      rec.haptics.add(event.id);
}

class FakeReader implements ReaderRepository {
  FakeReader(this.rec);
  final Recorder rec;

  @override
  Future<Result<({int saved, int advanced})>> saveProgressBatch(List<ProgressPush> pushes) async {
    rec.pushed.add(pushes);
    return Ok((saved: pushes.length, advanced: pushes.length));
  }

  @override
  Future<Result<ChapterManifest>> manifest({
    required String sourceId,
    required String seriesKey,
    required String chapterKey,
  }) async {
    rec.manifests.add(chapterKey);
    return const Err(NetworkError(message: 'offline in test'));
  }

  @override
  Future<Result<List<ReadingProgress>>> seriesProgress({
    required String sourceId,
    required String seriesKey,
  }) async =>
      const Ok(<ReadingProgress>[]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDeleter extends ProgressDeleter {
  FakeDeleter(this.rec) : super(Dio());
  final Recorder rec;

  @override
  Future<Result<void>> deleteProgress({
    required String sourceId,
    required String seriesKey,
    required List<String> chapterKeys,
  }) async {
    rec.deleted.add((source: sourceId, series: seriesKey, keys: chapterKeys));
    return const Ok(null);
  }
}

class RecordingQueue extends DownloadQueueController {
  RecordingQueue(this.rec);
  final Recorder rec;

  @override
  Future<void> enqueueChapters(Iterable<ChapterQueueRequest> chapters) async {
    rec.enqueued.add(chapters.toList());
  }

  @override
  Future<void> enqueueChapter({
    required ChapterIdentity id,
    double? chapterNumber,
    String? title,
    String? seriesTitle,
    DownloadKind kind = DownloadKind.manga,
  }) async {
    rec.enqueued.add([(id: id, chapterNumber: chapterNumber, title: title, seriesTitle: seriesTitle, kind: kind)]);
  }
}

class _FreeSpace implements DeviceStorageInfo {
  const _FreeSpace(this.bytes);
  final int bytes;
  @override
  Future<int?> freeSpaceBytes() async => bytes;
}

class PausedQueue extends RecordingQueue {
  PausedQueue(super.rec, this.reason);
  final DownloadQueuePauseReason reason;

  @override
  DownloadQueueState build() => DownloadQueueState(pauseReason: reason);
}

class FakeLibrary implements LibraryRepository {
  FakeLibrary(this.rec, {this.followed, this.tags = const [], this.shelves = const []});
  final Recorder rec;
  FollowedSeries? followed;
  List<Tag> tags;
  List<Collection> shelves;

  @override
  Future<Result<FollowedSeries>> patchSeries(
    int followedId, {
    bool? isFavorite,
    String? readingStatus,
    bool? notify,
    bool? matureOverride,
    bool clearMatureOverride = false,
    int? sortOrder,
  }) async {
    rec.patches.add({
      'id': followedId,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (readingStatus != null) 'reading_status': readingStatus,
      if (notify != null) 'notify': notify,
      if (matureOverride != null) 'mature_override': matureOverride,
      if (clearMatureOverride) 'mature_override': null,
    });
    return Ok(followed ?? followedRow());
  }

  @override
  Future<Result<List<Tag>>> listTags({String? category}) async => Ok(tags);

  @override
  Future<Result<Tag>> createTag({required String name, String category = 'custom', String? color}) async {
    rec.tagCalls.add('create:$name');
    final t = Tag(id: 100 + tags.length, name: name, category: category);
    tags = [...tags, t];
    return Ok(t);
  }

  @override
  Future<Result<void>> addTagToSeries({required String sourceId, required String seriesKey, required int tagId}) async {
    rec.tagCalls.add('add:$tagId');
    return const Ok(null);
  }

  @override
  Future<Result<void>> removeTagFromSeries({required String sourceId, required String seriesKey, required int tagId}) async {
    rec.tagCalls.add('remove:$tagId');
    return const Ok(null);
  }

  @override
  Future<Result<List<Collection>>> listCollections() async => Ok(shelves);

  @override
  Future<Result<CollectionDetail>> getCollection(int collectionId) async {
    final c = shelves.firstWhere((s) => s.id == collectionId);
    return Ok(CollectionDetail(
      id: c.id,
      name: c.name,
      seriesCount: c.seriesCount,
      sortOrder: 0,
      series: c.seriesCount > 0
          ? [const CollectionSeriesRef(sourceId: 'demo', seriesKey: 'k', sortOrder: 0)]
          : const [],
    ));
  }

  @override
  Future<Result<CollectionDetail>> addSeriesToCollection(int collectionId, {required String sourceId, required String seriesKey}) async {
    rec.shelfCalls.add('add:$collectionId');
    return getCollection(collectionId);
  }

  @override
  Future<Result<RepointResult>> repoint(int followedId, {required String sourceId, required String seriesKey, required bool keepOld}) async {
    rec.repoints.add({'id': followedId, 'source': sourceId, 'series': seriesKey, 'keep_old': keepOld});
    return Ok((followed: followedRow(), mappedChapterKey: 'c2', mappedChapterNumber: 2.0));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUpdates extends UpdatesNotifier {
  FakeUpdates(this.rec, this.followedRows);
  final Recorder rec;
  final List<FollowedSeries> followedRows;

  @override
  Future<UpdatesState> build() async => UpdatesState(
        notifications: const [],
        unreadCount: 0,
        followed: followedRows,
      );

  @override
  Future<AppError?> followSeries({required String sourceId, required String seriesKey}) async {
    rec.following.add('follow:$sourceId/$seriesKey');
    return null;
  }

  @override
  Future<AppError?> unfollow(int followedId) async {
    rec.following.add('unfollow:$followedId');
    return null;
  }
}

class AiFake extends AiRepository {
  AiFake(this.result, this.rec) : super(Dio());
  final SuggestedTags result;
  final Recorder rec;
  final List<String> rejected = [];

  @override
  Future<SuggestedTags> suggestedTags(String sourceId, String seriesKey) async => result;

  @override
  Future<void> rejectSuggestedTag(String sourceId, String seriesKey, String tag) async {
    rejected.add(tag);
    rec.tagCalls.add('reject:$tag');
  }
}

class FeatureRig {
  FeatureRig({
    this.recorder,
    this.online = true,
    this.statuses = const {},
    this.suggested = kNoSuggestedTags,
    this.tags = const [],
    this.shelves = const [],
    this.followed,
    this.serverProgress = const {},
    this.narrated = const {},
    this.ocrWords = const {},
    this.enrichment,
    this.extra = const [],
    this.pauseReason,
    this.freeBytes,
  });

  Recorder? recorder;
  final bool online;
  final Map<String, ChapterDownloadStatus> statuses;
  final SuggestedTags suggested;
  final List<Tag> tags;
  final List<Collection> shelves;
  final FollowedSeries? followed;
  final Map<String, SourceChapterProgress> serverProgress;
  final Set<String> narrated;
  final Map<String, int> ocrWords;
  final SeriesEnrichment? enrichment;
  final DownloadQueuePauseReason? pauseReason;
  final int? freeBytes;
  final List<Override> extra;

  late final Recorder rec = recorder ?? Recorder();
  late final AiFake ai = AiFake(suggested, rec);
  late final RecordingQueue queue =
      pauseReason == null ? RecordingQueue(rec) : PausedQueue(rec, pauseReason!);
}

List<Override> featureOverrides(FeatureRig r, SharedPreferences prefs, {required bool novel}) => [
      sharedPrefsProvider.overrideWithValue(prefs),
      apiBaseUrlOverride('http://example.test'),
      ...noDownloadsStoreOverrides(),
      ...contentModeOverrides(
          mode: novel ? ContentMode.novel : ContentMode.manga, novelsEnabled: true,),
      activeProfileOverride(),
      sourceModeIndexProvider.overrideWithValue({
        'demo': novel ? ContentMode.novel : ContentMode.manga,
        's': novel ? ContentMode.novel : ContentMode.manga,
      }),
      sourceSeriesServerProgressProvider.overrideWith((ref, p) async => r.serverProgress),
      seriesEnrichmentProvider.overrideWith((ref, k) async => r.enrichment),
      suggestedTagsProvider.overrideWith((ref, k) => r.ai.suggestedTags(k.sourceId, k.seriesKey)),
      aiRepositoryProvider.overrideWithValue(r.ai),
      ocrCoverageProvider.overrideWith((ref, k) async => OcrCoverage(
            sourceId: k.sourceId,
            seriesKey: k.seriesKey,
            wordCountByChapterKey: r.ocrWords,
          ),),
      seriesChapterDownloadStatusProvider.overrideWith((ref, k) async => r.statuses),
      seriesAudioProvider.overrideWith(
        (ref, k) async => (rendered: r.narrated, narratable: r.narrated, canRender: null),
      ),
      deviceOnlineProvider.overrideWith((ref) => Stream.value(r.online)),
      readerRepositoryProvider.overrideWithValue(FakeReader(r.rec)),
      progressDeleterProvider.overrideWithValue(FakeDeleter(r.rec)),
      libraryRepositoryProvider.overrideWithValue(
          FakeLibrary(r.rec, followed: r.followed, tags: r.tags, shelves: r.shelves),),
      downloadQueueControllerProvider.overrideWith(() => r.queue),
      skinHapticsProvider.overrideWithValue(RecordingHaptics(r.rec)),
      if (r.freeBytes != null) deviceStorageInfoProvider.overrideWithValue(_FreeSpace(r.freeBytes!)),
      sourcesListProvider.overrideWith((ref) async => const [
            SourceSummary(
              id: 'demo',
              name: 'Demo Source',
              description: '',
              browsable: true,
              supportsImport: false,
            ),
          ],),
      updatesProvider
          .overrideWith(() => FakeUpdates(r.rec, r.followed == null ? const [] : [r.followed!])),
      matureContentProvider.overrideWith(_MatureOn.new),
      ...r.extra,
    ];

ThemeData featureTheme(TargetPlatform platform) => ThemeData(
      brightness: Brightness.dark,
      platform: platform,
      extensions: const [cinematicTokens],
    );

Widget featureMediaWrap(BuildContext context, Widget? c, {double textScale = 1, bool reduced = false}) =>
    MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: reduced,
      ),
      child: c!,
    );

void sizeView(WidgetTester tester, {bool wide = false, Size? size}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size ?? (wide ? const Size(834, 1194) : const Size(390, 844));
  addTearDown(tester.view.reset);
  addTearDown(() async => tester.pumpWidget(const SizedBox()));
}

/// Pumps [child] (a page widget) inside the app providers the series pages read.
Future<FeatureRig> pumpFeature(
  WidgetTester tester, {
  required Widget child,
  FeatureRig? rig,
  bool wide = false,
  Size? size,
  bool novel = false,
  double textScale = 1,
  bool reducedMotion = false,
  TargetPlatform platform = TargetPlatform.android,
  Widget Function(Widget home)? wrap,
}) async {
  ReaderPrefetch.reset();
  final r = rig ?? FeatureRig();
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  sizeView(tester, wide: wide, size: size);
  final home = Builder(builder: (context) => child);
  await tester.pumpWidget(
    ProviderScope(
      overrides: featureOverrides(r, prefs, novel: novel),
      child: RepaintBoundary(
        key: kShotBoundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
        theme: featureTheme(platform),
          builder: (context, c) =>
              featureMediaWrap(context, c, textScale: textScale, reduced: reducedMotion),
          home: wrap == null ? home : wrap(home),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  return r;
}

class _MatureOn extends MatureContentController {
  @override
  Future<bool> build() async => true;
}

/// Lets timers and entrance animations run out (letters, credits, rating card).
Future<void> settleFeature(WidgetTester tester, {Duration by = const Duration(seconds: 6)}) async {
  final end = by.inMilliseconds;
  for (var t = 0; t < end; t += 100) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Two frames: one to start an animation, one to run it (`pump(duration)` alone
/// starts a route or sheet animation at the end of the duration, not the start).
Future<void> frames(WidgetTester tester, [int ms = 400]) async {
  await tester.pump();
  await tester.pump(Duration(milliseconds: ms));
}

/// Scrolls the page up until the panels under the pinned tabs are on screen.
Future<void> scrollToPanels(WidgetTester tester) async {
  await tester.drag(find.byType(NestedScrollView), const Offset(0, -600));
  await frames(tester);
}

class FakeSources implements SourcesRepository {
  FakeSources({this.groups = const [], this.chapters = const []});
  final List<SourceSearchGroup> groups;
  final List<SourceChapterSummary> chapters;
  final List<String> searched = [];

  @override
  Future<Result<GroupedSearchResult>> searchGrouped(String query, {int page = 1, int perPage = 40}) async {
    searched.add(query);
    return Ok(GroupedSearchResult(groups: groups));
  }

  @override
  Future<Result<List<SourceChapterSummary>>> getChapters(String sourceId, String seriesId) async =>
      Ok(chapters);

  @override
  Future<Result<SeriesEnrichment?>> seriesEnrichment(String sourceId, String seriesKey) async =>
      const Ok(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A router-hosted app for flows that navigate (repoint, back, links).
Future<({FeatureRig rig, GoRouter router})> pumpFeatureRouter(
  WidgetTester tester, {
  required List<RouteBase> routes,
  FeatureRig? rig,
  List<Override> extra = const [],
  bool novel = false,
  TargetPlatform platform = TargetPlatform.android,
  Size? size,
}) async {
  ReaderPrefetch.reset();
  final r = rig ?? FeatureRig();
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  sizeView(tester, size: size);
  final router = GoRouter(routes: routes);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...featureOverrides(r, prefs, novel: novel), ...extra],
      child: RepaintBoundary(
        key: kShotBoundary,
        child: MaterialApp.router(
            debugShowCheckedModeBanner: false, routerConfig: router, theme: featureTheme(platform),),
      ),
    ),
  );
  await tester.pump();
  return (rig: r, router: router);
}
