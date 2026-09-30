import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/novels/models/novel_audio.dart';
import 'package:manhwamaniacs/features/novels/models/novel_audio_format.dart';
import 'package:manhwamaniacs/features/novels/models/novel_cast.dart';
import 'package:manhwamaniacs/features/novels/models/novel_chapter.dart';
import 'package:manhwamaniacs/features/novels/models/novel_chapter_window.dart';
import 'package:manhwamaniacs/features/novels/repositories/novels_repository.dart';

/// A [NovelsRepository] with every answer scripted and every request
/// recorded, for the narration tests: what the phone asked the server for is
/// usually the thing under test, not just what it did with the answer.
class FakeNovelsRepository implements NovelsRepository {
  /// What `GET /novels/audio` answers, per chapter key.
  Map<String, NovelAudio> audioByChapter = {};

  /// What `GET /novels/audio/file` answers, per chapter key. A key that is
  /// absent answers empty, exactly as the real client maps a 404.
  Map<String, List<int>> audioBytesByChapter = {};

  Result<NovelSeriesAudio> seriesAudioResult = const Ok(
    (rendered: <String>{}, narratable: <String>{}, canRender: true),
  );

  /// Answers for successive `GET /novels/audio/jobs` calls, in order. The
  /// last one repeats once the list runs out.
  List<Result<List<NovelAudioJob>>> audioJobsResults = [
    const Ok(<NovelAudioJob>[]),
  ];

  Result<NovelAudioRequest> requestAudioResult = const Ok(
    NovelAudioRequest(queued: <String>[], skipped: <String, String>{}),
  );

  Result<void> setCastVoiceResult = const Ok(null);

  Result<NovelSeriesAudioDetail> seriesAudioDetailResult = const Ok(
    (renderedAt: <String, DateTime?>{}, narratable: <String>{}, canRender: true, castChangedAt: null),
  );
  Result<List<NovelAudioJob>> activeJobsResult = const Ok(<NovelAudioJob>[]);
  int activeJobsCalls = 0;
  Result<List<NovelVoice>> voicesResult = const Ok(<NovelVoice>[]);
  Result<NovelAttribution> attributionResult = const Ok(NovelAttribution.none);
  Result<void> castGenderResult = const Ok(null);
  Result<void> aliasResult = const Ok(null);
  Result<void> narratorResult = const Ok(null);
  Result<void> cancelJobResult = const Ok(null);
  Result<List<int>> voiceSampleResult = const Ok(<int>[1, 2, 3]);
  Result<void> listenSessionsResult = const Ok(null);

  /// `(keys, priority, force)` for every `POST /novels/audio/render`.
  final List<({List<String> keys, int priority, bool force})> renderCalls = [];
  final List<({String name, String gender})> genderWrites = [];
  final List<({String alias, String canonical})> aliasWrites = [];
  final List<String?> narratorWrites = [];
  final List<String> cancelledJobs = [];
  final List<String> voiceSampleRequests = [];

  /// Every `POST /novels/listen-sessions` body, in order.
  final List<List<Map<String, Object?>>> listenBatches = [];

  /// Errors `GET /novels/audio/file` answers first, one per call (e.g. `503 audio_preparing`).
  final List<AppError> audioBytesFailures = [];

  final List<String> audioRequests = [];
  final List<String> audioBytesRequests = [];

  /// The `format` each `GET /novels/audio/file` asked for, in order.
  final List<NovelAudioFormat> audioBytesFormats = [];
  int seriesAudioCalls = 0;
  int audioJobsCalls = 0;
  final List<List<String>> renderRequests = [];
  final List<({String name, String? voiceId})> castWrites = [];

  @override
  Future<Result<NovelAudio>> audio({
    required String sourceId,
    required String seriesKey,
    required String chapterKey,
  }) async {
    audioRequests.add(chapterKey);
    return Ok(audioByChapter[chapterKey] ?? NovelAudio.none);
  }

  @override
  Future<Result<List<int>>> audioBytes({
    required String sourceId,
    required String seriesKey,
    required String chapterKey,
    required NovelAudioFormat format,
  }) async {
    audioBytesRequests.add(chapterKey);
    audioBytesFormats.add(format);
    if (audioBytesFailures.isNotEmpty) return Err(audioBytesFailures.removeAt(0));
    return Ok(audioBytesByChapter[chapterKey] ?? const <int>[]);
  }

  @override
  Future<Result<NovelSeriesAudio>> seriesAudio({
    required String sourceId,
    required String seriesKey,
  }) async {
    seriesAudioCalls++;
    return seriesAudioResult;
  }

  @override
  Future<Result<NovelAudioRequest>> requestAudio({
    required String sourceId,
    required String seriesKey,
    required List<String> chapterKeys,
    int priority = 0,
    bool force = false,
  }) async {
    renderRequests.add(chapterKeys);
    renderCalls.add((keys: chapterKeys, priority: priority, force: force));
    return requestAudioResult;
  }

  @override
  Future<Result<NovelSeriesAudioDetail>> seriesAudioDetail({
    required String sourceId,
    required String seriesKey,
  }) async =>
      seriesAudioDetailResult;

  @override
  Future<Result<List<NovelAudioJob>>> activeAudioJobs() async {
    activeJobsCalls++;
    return activeJobsResult;
  }

  @override
  Future<Result<void>> setCastGender({
    required String sourceId,
    required String seriesKey,
    required String name,
    required String gender,
  }) async {
    genderWrites.add((name: name, gender: gender));
    return castGenderResult;
  }

  @override
  Future<Result<void>> mergeCastAlias({
    required String sourceId,
    required String seriesKey,
    required String alias,
    required String canonical,
  }) async {
    aliasWrites.add((alias: alias, canonical: canonical));
    return aliasResult;
  }

  @override
  Future<Result<List<int>>> voiceSample(String voiceId) async {
    voiceSampleRequests.add(voiceId);
    return voiceSampleResult;
  }

  @override
  Future<Result<void>> saveListenSessions(List<Map<String, Object?>> sessions) async {
    listenBatches.add(sessions);
    return listenSessionsResult;
  }

  @override
  Future<Result<List<NovelAudioJob>>> audioJobs({
    required String sourceId,
    required String seriesKey,
  }) async {
    final index = audioJobsCalls < audioJobsResults.length
        ? audioJobsCalls
        : audioJobsResults.length - 1;
    audioJobsCalls++;
    return audioJobsResults[index];
  }

  @override
  Future<Result<void>> cancelAudioJob(String jobId) async {
    cancelledJobs.add(jobId);
    return cancelJobResult;
  }

  @override
  Future<Result<NovelAttribution>> attribution({
    required String sourceId,
    required String seriesKey,
    required String chapterKey,
  }) async =>
      attributionResult;

  @override
  Future<Result<List<NovelVoice>>> voices() async => voicesResult;

  @override
  Future<Result<void>> setCastVoice({
    required String sourceId,
    required String seriesKey,
    required String name,
    required String? voiceId,
  }) async {
    castWrites.add((name: name, voiceId: voiceId));
    return setCastVoiceResult;
  }

  @override
  Future<Result<void>> setNarratorVoice({
    required String sourceId,
    required String seriesKey,
    required String? voiceId,
  }) async {
    narratorWrites.add(voiceId);
    return narratorResult;
  }

  @override
  Future<Result<NovelChapter>> chapter({
    required String sourceId,
    required String seriesKey,
    required String chapterKey,
  }) async =>
      const Err(NetworkError(message: 'no chapters in this test'));

  @override
  Future<Result<NovelChapterWindow>> chapterWindow({
    required String sourceId,
    required String seriesKey,
    required List<String> chapterKeys,
  }) async =>
      const Err(NetworkError(message: 'no window in this test'));
}

/// The 403 the server gives a non-admin who tries to change a voice.
const adminRequired = ApiError(
  statusCode: 403,
  code: 'forbidden',
  message: 'Administrator access required.',
);
