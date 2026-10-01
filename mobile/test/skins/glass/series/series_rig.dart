import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/ai/models/similar_result.dart';
import 'package:manhwamaniacs/features/ai/providers/ai_providers.dart';
import 'package:manhwamaniacs/features/ai/providers/suggested_tags_provider.dart';
import 'package:manhwamaniacs/features/ai/repositories/ai_repository.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/models/tag.dart';
import 'package:manhwamaniacs/features/library/providers/tags_controller.dart';
import 'package:manhwamaniacs/features/library/repositories/library_repository.dart';
import 'package:manhwamaniacs/features/novels/models/novel_cast.dart' show NovelAudioJob;
import 'package:manhwamaniacs/features/novels/providers/novel_series_providers.dart';
import 'package:manhwamaniacs/features/novels/providers/series_audio_provider.dart' show novelAudioJobsProvider, seriesAudioProvider;
import 'package:manhwamaniacs/features/ocr/providers/ocr_providers.dart';
import 'package:manhwamaniacs/features/reader/models/reading_progress.dart';
import 'package:manhwamaniacs/features/reader/repositories/reader_repository.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/models/source_chapter_progress.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/providers/discover_providers.dart';
import 'package:manhwamaniacs/features/sources/providers/series_enrichment_provider.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

/// The calls the fakes saw, in order.
final List<String> calls = [];

SourceSeriesDetailData loadSeries({int n = 1000, String sourceId = 'demo', String? sourceUrl}) {
  final j = jsonDecode(File('test/fixtures/series/series_1000.json').readAsStringSync()) as Map<String, dynamic>;
  final s = SourceSeriesSummary.fromJson({...(j['series'] as Map<String, dynamic>), 'source_id': sourceId, 'source_url': sourceUrl}, 'http://127.0.0.1:8000');
  final chapters = [
    for (final c in (j['chapters'] as List).take(n)) SourceChapterSummary.fromJson({...(c as Map<String, dynamic>), 'source_id': sourceId}),
  ];
  return SourceSeriesDetailData(series: s, chapters: chapters);
}

FollowedSeries followRow({int id = 7, String sourceId = 'demo', String seriesKey = 'k1000', String rating = 'safe'}) => FollowedSeries(
      id: id,
      sourceId: sourceId,
      seriesKey: seriesKey,
      title: 'Solo Leveling',
      coverUrl: '',
      isFavorite: false,
      readingStatus: 'reading',
      notify: true,
      sortOrder: 0,
      contentRating: rating,
      rating: rating,
      chapterCount: 1000,
    );

class FakeUpdates extends UpdatesNotifier {
  FakeUpdates(this.followed);
  final List<FollowedSeries> followed;
  @override
  Future<UpdatesState> build() async => UpdatesState(notifications: const [], unreadCount: 0, followed: followed);
}

class Gate extends MatureContentController {
  Gate(this.open);
  final bool open;
  @override
  Future<bool> build() async => open;
}

class FakeReader implements ReaderRepository {
  @override
  Future<Result<({int saved, int advanced})>> saveProgressBatch(List<ProgressPush> pushes) async {
    calls.add('batch:${pushes.length}:manual=${pushes.every((p) => p.manual)}');
    return Ok((saved: pushes.length, advanced: pushes.length));
  }

  @override
  Future<Result<void>> deleteProgress({required String sourceId, required String seriesKey, required List<String> chapterKeys}) async {
    calls.add('delete:${chapterKeys.join(',')}');
    return const Ok(null);
  }

  @override
  dynamic noSuchMethod(Invocation i) {
    calls.add('reader:${i.memberName}');
    return super.noSuchMethod(i);
  }
}

class FakeLibrary implements LibraryRepository {
  @override
  Future<Result<FollowedSeries>> patchSeries(int followedId, {bool? isFavorite, String? readingStatus, bool? notify, bool? matureOverride, bool clearMatureOverride = false, int? sortOrder}) async {
    calls.add('patch:$followedId:${[if (isFavorite != null) 'is_favorite=$isFavorite', if (readingStatus != null) 'reading_status=$readingStatus', if (notify != null) 'notify=$notify'].join(',')}');
    return Ok(followRow(id: followedId));
  }

  @override
  Future<Result<RepointResult>> repoint(int followedId, {required String sourceId, required String seriesKey, required bool keepOld}) async {
    calls.add('repoint:$followedId:$sourceId:$seriesKey:keep_old=$keepOld');
    return Ok((followed: followRow(sourceId: sourceId, seriesKey: seriesKey), mappedChapterKey: null, mappedChapterNumber: null));
  }

  @override
  Future<Result<void>> addTagToSeries({required String sourceId, required String seriesKey, required int tagId}) async {
    calls.add('tag:+$tagId');
    return failTags ? const Err(UnknownError(message: 'boom')) : const Ok(null);
  }

  @override
  Future<Result<void>> removeTagFromSeries({required String sourceId, required String seriesKey, required int tagId}) async {
    calls.add('tag:-$tagId');
    return const Ok(null);
  }

  @override
  Future<Result<List<Tag>>> listTags({String? category}) async => const Ok(tags);

  @override
  dynamic noSuchMethod(Invocation i) {
    calls.add('library:${i.memberName}');
    return super.noSuchMethod(i);
  }
}

bool failTags = false;
const tags = [Tag(id: 1, name: 'Favourite fights', category: 'custom'), Tag(id: 2, name: 'Re-read', category: 'custom')];

class NoAi implements AiRepository {
  @override
  Future<SuggestedTags> suggestedTags(String sourceId, String seriesKey) async => kNoSuggestedTags;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

/// Every override the series tests share. [progress] maps chapter keys to (page, completed).
List<Override> seriesOverrides({
  SourceSeriesDetailData? data,
  List<FollowedSeries> followed = const [],
  bool gateOpen = false,
  bool mature = false,
  bool novel = false,
  Map<String, SourceChapterProgress> progress = const {},
}) {
  calls.clear();
  final d = data ?? loadSeries();
  return [
    sourceSeriesDetailProvider.overrideWith((ref, key) async => d),
    sourcesListProvider.overrideWith((ref) async => [
          SourceSummary(id: d.series.sourceId, name: 'Demo Scans', description: 'd', browsable: true, supportsImport: false, mature: mature, contentKind: novel ? 'novel' : 'manga'),
        ],),
    matureContentProvider.overrideWith(() => Gate(gateOpen)),
    sourceGenresProvider.overrideWith((ref, id) async => const []),
    seriesEnrichmentProvider.overrideWith((ref, k) async => null),
    similarProvider.overrideWith((ref, q) async => const SimilarResult(available: false, reason: 'not_configured')),
    suggestedTagsProvider.overrideWith((ref, k) async => kNoSuggestedTags),
    aiRepositoryProvider.overrideWithValue(NoAi()),
    ocrAvailableProvider.overrideWith((ref) async => false),
    ocrCoverageProvider.overrideWith((ref, s) async => throw StateError('no ocr')),
    novelSeriesWordCountsProvider.overrideWith((ref, s) async => const {}),
    // The Audiobook button's live status: nothing narrating, so no polling timers.
    seriesAudioProvider.overrideWith((ref, k) async => (rendered: <String>{}, narratable: <String>{}, canRender: false)),
    novelAudioJobsProvider.overrideWith((ref, k) => Stream.value(const <NovelAudioJob>[])),
    sourceSeriesProgressProvider.overrideWith((ref, k) => progress),
    updatesProvider.overrideWith(() => FakeUpdates(followed)),
    readerRepositoryProvider.overrideWithValue(FakeReader()),
    libraryRepositoryProvider.overrideWithValue(FakeLibrary()),
    profileTagsProvider.overrideWith((ref) async => tags),
    if (novel)
      contentModeScopeProvider.overrideWith((ref) => ContentModeScope(mode: ContentMode.manga, index: {d.series.sourceId: ContentMode.novel}, novelsEnabled: true)),
  ];
}

/// Counts the chapter row widgets currently built.
int builtRows(WidgetTester t) => find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('chapter-c'), skipOffstage: false).evaluate().length;
