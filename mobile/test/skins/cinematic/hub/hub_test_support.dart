// ignore_for_file: require_trailing_commas, directives_ordering

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/auth/models/auth_user.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/library/models/collection.dart';
import 'package:manhwamaniacs/features/library/models/collection_detail.dart';
import 'package:manhwamaniacs/features/library/models/reading_history_item.dart';
import 'package:manhwamaniacs/features/library/utils/smart_shelf.dart';
import 'package:manhwamaniacs/features/updates/models/update_notification.dart';
import 'package:manhwamaniacs/features/updates/models/update_settings.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/features/updates/repositories/updates_repository.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

import '../library/library_test_support.dart';

export '../library/library_test_support.dart';

/// The Updates data layer, scripted: notifications that mark themselves read, runs that count up.
class FakeUpdates implements UpdatesRepository {
  FakeUpdates({List<UpdateNotification>? notes, this.settings, this.runs = const [], this.progress = const [], this.queued = true, this.conflict = false, this.failList = false, this.offline = false})
      : notes = notes ?? [];

  List<UpdateNotification> notes;
  UpdateSettings? settings;
  List<UpdateRun> runs;

  /// What `getRun` answers, in turn; the last one repeats.
  List<UpdateRun> progress;
  bool queued, conflict, failList, offline;
  int triggers = 0, getRuns = 0, checkedSeries = 0;
  final List<int> read = [];
  final List<String?> readAll = [];

  UpdateSettings get _settings => settings ?? UpdateSettings(enabled: true, checkIntervalMinutes: 30, notifyEnabled: true, checkOnStartup: false, lastRunAt: kShelfNow.subtract(const Duration(minutes: 12)));

  @override
  Future<Result<UpdateSettings>> getSettings() async => Ok(_settings);

  @override
  Future<Result<List<UpdateNotification>>> listNotifications({bool unreadOnly = false, int limit = 100}) async {
    if (offline) return const Err(NetworkError(message: 'offline in test'));
    if (failList) return const Err(ApiError(statusCode: 500, code: 'boom', message: 'boom'));
    return Ok([for (final n in notes) if (!unreadOnly || !n.isRead) n]);
  }

  @override
  Future<Result<int>> getUnreadCount() async => Ok(notes.where((n) => !n.isRead).length);

  @override
  Future<Result<void>> markRead(int id) async {
    read.add(id);
    notes = [for (final n in notes) n.id == id ? _copy(n, read: true) : n];
    return const Ok(null);
  }

  @override
  Future<Result<void>> markAllRead({String? contentKind}) async {
    readAll.add(contentKind);
    notes = [for (final n in notes) _copy(n, read: true)];
    return const Ok(null);
  }

  @override
  Future<Result<List<UpdateRun>>> listRuns({int limit = 20}) async => Ok(runs);

  @override
  Future<Result<UpdateCheckOutcome>> triggerCheck({List<int>? followedIds}) async {
    triggers++;
    if (conflict) return const Err(ApiError(statusCode: 409, code: 'check_already_running', message: 'An update check is already running.'));
    return Ok(UpdateCheckOutcome(queued: queued));
  }

  @override
  Future<Result<UpdateRun>> checkFollowed(int followedId) async {
    checkedSeries = followedId;
    return const Ok(UpdateRun(id: 1, trigger: 'manual', status: 'finished', seriesChecked: 1, newChaptersFound: 0));
  }

  @override
  Future<Result<UpdateRun>> getRun(int runId) async {
    final i = getRuns < progress.length ? getRuns : progress.length - 1;
    getRuns++;
    return Ok(progress[i]);
  }

  @override
  Future<Result<List<String>>> listUpdateSources() async => const Ok(['shelf', 'other']);

  @override
  Future<Result<UpdateSettings>> updateSettings({bool? enabled, int? checkIntervalMinutes, bool? notifyEnabled, bool? checkOnStartup}) async => Ok(_settings);
}

UpdateNotification _copy(UpdateNotification n, {required bool read}) => UpdateNotification(
      id: n.id,
      followedSeriesId: n.followedSeriesId,
      sourceId: n.sourceId,
      seriesKey: n.seriesKey,
      chapterKey: n.chapterKey,
      chapterTitle: n.chapterTitle,
      chapterNumber: n.chapterNumber,
      isRead: read,
      createdAt: n.createdAt,
    );

/// A notification for `shelfSeries(seriesId)`.
UpdateNotification note(int id, int seriesId, double chapter, {DateTime? at, bool read = false}) => UpdateNotification(
      id: id,
      followedSeriesId: seriesId,
      sourceId: 'shelf',
      seriesKey: 'series-$seriesId',
      chapterKey: 'c${chapter.round()}',
      chapterTitle: 'Chapter ${chapter.round()}',
      chapterNumber: chapter,
      isRead: read,
      createdAt: at ?? kShelfNow.subtract(Duration(minutes: 30 + id)),
    );

class _NonAdmin extends AuthController {
  @override
  AuthState build() => AuthAuthenticated(AuthUser(id: 2, username: 'member', isAdmin: false, createdAt: DateTime.utc(2024)));
}

/// The auth override for a member (the default test user is an admin).
final Override memberAuth = authControllerProvider.overrideWith(_NonAdmin.new);

/// Overrides for the Updates data layer.
List<Override> updatesOverrides(FakeUpdates u, {bool member = false}) => [
      updatesRepositoryProvider.overrideWithValue(u),
      updateCheckPollDelaysProvider.overrideWithValue(const [Duration(milliseconds: 20)]),
      if (member) memberAuth,
    ];

/// Whether [text] is on screen as a plain `Text` (rich text included).
Finder textOf(String s) => find.textContaining(s, findRichText: true);

Future<void> settle(WidgetTester t, [int ms = 1200]) => settleShelf(t, by: Duration(milliseconds: ms));

/// The Library repository with collections, their members and the reading log scripted.
class HubLibrary extends ShelfLibrary {
  HubLibrary({
    required super.all,
    List<Collection>? collections,
    Map<int, List<(String, String)>>? members,
    this.history = const [],
    this.failCollections = false,
    this.offlineCollections = false,
    this.failReorder = false,
    this.failSortWrites = false,
  }) : collections = collections ?? [] {
    this.members = members ?? {};
  }

  List<Collection> collections;
  late Map<int, List<(String, String)>> members;
  List<ReadingHistoryItem> history;
  bool failCollections, offlineCollections, failReorder, failSortWrites;
  final List<Map<String, Object?>> writes = [];
  final List<List<String>> orders = [];
  final List<({int limit, int offset, bool bySeries})> historyCalls = [];
  int deleted = 0;

  Result<T> _gate<T>() => offlineCollections ? Err(const NetworkError(message: 'offline in test')) : Err(const ApiError(statusCode: 500, code: 'boom', message: 'boom'));

  @override
  Future<Result<List<Collection>>> listCollections() async {
    if (offlineCollections || failCollections) return _gate();
    return Ok([
      for (final c in collections)
        Collection(
          id: c.id,
          name: c.name,
          description: c.description,
          seriesCount: members[c.id]?.length ?? c.seriesCount,
          sortOrder: c.sortOrder,
          rules: c.rules,
          previewCovers: c.rules != null ? const [] : [for (final m in (members[c.id] ?? const []).take(4)) '/sources/${m.$1}/series/${m.$2}/cover'],
          createdAt: c.createdAt,
        ),
    ]);
  }

  CollectionDetail _detail(Collection c) => CollectionDetail(
        id: c.id,
        name: c.name,
        description: c.description,
        seriesCount: members[c.id]?.length ?? 0,
        sortOrder: c.sortOrder,
        rules: c.rules,
        createdAt: c.createdAt,
        series: [for (var i = 0; i < (members[c.id] ?? const []).length; i++) CollectionSeriesRef(sourceId: members[c.id]![i].$1, seriesKey: members[c.id]![i].$2, sortOrder: i)],
      );

  @override
  Future<Result<CollectionDetail>> getCollection(int collectionId) async {
    if (offlineCollections || failCollections) return _gate();
    final i = collections.indexWhere((c) => c.id == collectionId);
    if (i < 0) return const Err(ApiError(statusCode: 404, code: 'collection_not_found', message: 'nope'));
    return Ok(_detail(collections[i]));
  }

  @override
  Future<Result<Collection>> createCollection({required String name, String? description, ShelfRules? rules}) async {
    writes.add({'op': 'create', 'name': name, 'description': description, 'rules': rules?.toJson()});
    if (collections.any((c) => c.name == name)) return const Err(ApiError(statusCode: 409, code: 'duplicate', message: 'A shelf with that name already exists.'));
    final c = Collection(id: 100 + collections.length, name: name, description: description, seriesCount: 0, sortOrder: collections.length, rules: rules, createdAt: kShelfNow);
    collections = [...collections, c];
    return Ok(c);
  }

  @override
  Future<Result<Collection>> updateCollection(int collectionId, {String? name, String? description, int? sortOrder, ShelfRules? rules, bool clearRules = false}) async {
    writes.add({'op': 'update', 'id': collectionId, if (name != null) 'name': name, if (sortOrder != null) 'sort_order': sortOrder, if (rules != null) 'rules': rules.toJson(), if (clearRules) 'rules': null});
    if (failSortWrites && sortOrder != null) return const Err(NetworkError(message: 'nope'));
    final i = collections.indexWhere((c) => c.id == collectionId);
    final o = collections[i];
    final n = Collection(id: o.id, name: name ?? o.name, description: description ?? o.description, seriesCount: o.seriesCount, sortOrder: sortOrder ?? o.sortOrder, rules: clearRules ? null : (rules ?? o.rules), createdAt: o.createdAt);
    collections = [...collections]..[i] = n;
    return Ok(n);
  }

  @override
  Future<Result<void>> deleteCollection(int collectionId) async {
    deleted = collectionId;
    collections = [for (final c in collections) if (c.id != collectionId) c];
    return const Ok(null);
  }

  @override
  Future<Result<CollectionDetail>> addSeriesToCollection(int collectionId, {required String sourceId, required String seriesKey}) async {
    members.putIfAbsent(collectionId, () => []).add((sourceId, seriesKey));
    writes.add({'op': 'add', 'id': collectionId, 'key': seriesKey});
    return Ok(_detail(collections.firstWhere((c) => c.id == collectionId)));
  }

  @override
  Future<Result<void>> removeSeriesFromCollection(int collectionId, {required String sourceId, required String seriesKey}) async {
    members[collectionId]?.remove((sourceId, seriesKey));
    writes.add({'op': 'remove', 'id': collectionId, 'key': seriesKey});
    return const Ok(null);
  }

  @override
  Future<Result<void>> reorderCollectionMembers(int collectionId, List<({String sourceId, String seriesKey})> items) async {
    orders.add([for (final i in items) i.seriesKey]);
    if (failReorder) return const Err(NetworkError(message: 'nope'));
    members[collectionId] = [for (final i in items) (i.sourceId, i.seriesKey)];
    return const Ok(null);
  }

  @override
  Future<Result<List<ReadingHistoryItem>>> readingHistory({int limit = 50, int offset = 0, bool bySeries = true}) async {
    historyCalls.add((limit: limit, offset: offset, bySeries: bySeries));
    if (offlineCollections || failCollections) return _gate();
    return Ok(history.skip(offset).take(limit).toList());
  }
}

/// A collection with [count] members recorded in [HubLibrary.members] by the caller.
Collection shelfOf(int id, String name, {int order = 0, ShelfRules? rules, DateTime? at, String? description}) => Collection(id: id, name: name, description: description, seriesCount: 0, sortOrder: order, rules: rules, createdAt: at);
