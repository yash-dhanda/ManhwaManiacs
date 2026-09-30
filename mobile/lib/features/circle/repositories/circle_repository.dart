import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';

/// Every Circle endpoint (backend/08 and 09, `backend/docs/circle-api.md`). Failures are
/// `Err(ApiError)` carrying the server `code` (`circle_member_not_sharing`, `recipient_unavailable`
/// with `details.profile_ids`, `member_unavailable`, ...); a network failure is a `NetworkError`.
abstract interface class CircleRepository {
  /// `GET /circle/series` and `GET /circle/reactions` for one series; null when the Circle is not
  /// deployed (404). A failed reactions call leaves the readers.
  Future<Result<CircleSeriesData?>> series({required String sourceId, required String seriesKey});

  /// `GET /circle/members`; with both ids every member carries `canReceive`.
  Future<Result<List<CircleMember>>> members({String? sourceId, String? seriesKey});

  /// `GET /circle/members/{id}`; `404 circle_member_not_sharing` is an `ApiError`.
  Future<Result<MemberPage>> member(int profileId);

  /// `GET /circle/feed`; [kind] is `reading` or `reaction`.
  Future<Result<FeedPage>> feed({String? cursor, int limit = 50, String? kind, int? profileId});

  /// `GET /circle/reactions` (only chapters with a visible reaction).
  Future<Result<List<ChapterReactions>>> reactions({required String sourceId, required String seriesKey});

  /// `POST /circle/reactions`.
  Future<Result<ChapterReactions>> react({required String sourceId, required String seriesKey, required String chapterKey, required ReactionKind kind});

  /// `DELETE /circle/reactions` with the body `{source_id, series_key, chapter_key}`.
  Future<Result<void>> unreact({required String sourceId, required String seriesKey, required String chapterKey});

  /// `GET /circle/letters?box=inbox`.
  Future<Result<List<Letter>>> letters();

  /// `POST /circle/letters`.
  Future<Result<void>> sendLetter({required List<int> toProfileIds, required String sourceId, required String seriesKey, String? note});

  /// `PATCH /circle/letters/{id}`.
  Future<Result<Letter>> patchLetter(int id, LetterState state);

  /// `GET /profiles/{id}/sharing`.
  Future<Result<Sharing>> sharing(int profileId);

  /// `PATCH /profiles/{id}/sharing` with a partial body (snake_case keys).
  Future<Result<Sharing>> patchSharing(int profileId, Map<String, Object?> partial);

  /// `DELETE /circle/activity`.
  Future<Result<void>> clearActivity();

  /// `GET /library/collections?include_shared=true`: own shelves (with `role`/`shared`) and the
  /// shelves shared with the viewer. The legacy list call in `LibraryRepository` is unchanged.
  Future<Result<({List<SharedShelf> collections, List<SharedShelf> sharedWithMe})>> collectionsWithShared();

  /// `GET /library/collections/{id}` with `role`, `shared`, `owner` and per-row adder.
  Future<Result<SharedShelfDetail>> shelfDetail(int id);

  /// `POST /library/collections/{id}/share`; an empty list unshares.
  Future<Result<void>> shareCollection(int id, {required List<int> profileIds, required String mode});

  /// `DELETE /library/collections/{id}/share/{ref}`; [profileRef] is `me` or an id.
  Future<Result<void>> unshareMember(int id, String profileRef);
}
