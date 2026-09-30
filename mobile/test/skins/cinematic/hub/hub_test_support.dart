// ignore_for_file: require_trailing_commas, directives_ordering

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/auth/models/auth_user.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/downloads/providers/bookmark_outbox_provider.dart';
import 'package:manhwamaniacs/features/library/models/collection.dart';
import 'package:manhwamaniacs/features/library/providers/bookmarks_provider.dart';
import 'package:manhwamaniacs/features/reader/models/bookmark.dart';
import 'package:manhwamaniacs/features/reader/repositories/reader_repository.dart';
import 'package:manhwamaniacs/features/library/models/collection_detail.dart';
import 'package:manhwamaniacs/features/library/models/reading_history_item.dart';
import 'package:manhwamaniacs/features/library/utils/smart_shelf.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/repositories/sources_repository.dart';
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

/// The chapter list of a series, for Continue on a finished chapter.
class FakeSources implements SourcesRepository {
  FakeSources(this.chapters);
  List<SourceChapterSummary> chapters;
  int calls = 0;

  @override
  Future<Result<List<SourceChapterSummary>>> getChapters(String sourceId, String seriesKey) async {
    calls++;
    return Ok(chapters);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

SourceChapterSummary chapterOf(int n) => SourceChapterSummary(id: 'c$n', sourceId: 'shelf', seriesId: 'k', title: 'Chapter $n', number: n.toDouble(), pageCount: 30);

/// A log row for `shelfSeries(series)`.
ReadingHistoryItem logRow(int id, int series, {double chapter = 142, int page = 12, int pages = 40, bool done = false, DateTime? at, String? title, String? cover}) => ReadingHistoryItem(
      id: id,
      sourceId: 'shelf',
      seriesKey: 'series-$series',
      chapterKey: 'c${chapter.round()}',
      chapterNumber: chapter,
      lastPage: page,
      pageCount: pages,
      isCompleted: done,
      lastReadAt: at ?? kShelfNow.subtract(Duration(minutes: id * 7)),
      seriesTitle: title ?? 'Series $series',
      coverUrl: cover,
    );

/// The location including the query of the topmost route, pushed or not.
String fullLocation(LibRig rig) {
  final m = rig.router.routerDelegate.currentConfiguration.last;
  return m is ImperativeRouteMatch ? m.matches.uri.toString() : m.matchedLocation;
}

class _Reader implements ReaderRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// A bookmark outbox that keeps [items] as its store and records what it was asked.
class FakeOutbox extends BookmarkOutboxController {
  FakeOutbox(this.items) : super(store: null, repository: _Reader(), activeScopeId: _none);

  static String? _none() => null;
  final List<Bookmark> items;
  int pending = 0, flushes = 0;
  bool deletedElsewhere = false;
  final List<(String, String)> notes = [];
  final List<String> removed = [];
  final List<Bookmark> restored = [];

  @override
  Future<int> pendingCount() async => pending;

  @override
  Future<bool> flush() async {
    flushes++;
    pending = 0;
    return false;
  }

  @override
  Future<Bookmark?> setNote(Bookmark bookmark, String note) async {
    if (deletedElsewhere) {
      items.removeWhere((b) => b.clientId == bookmark.clientId);
      throw BookmarkDeletedElsewhere(bookmark.clientId);
    }
    notes.add((bookmark.clientId, note));
    final i = items.indexWhere((b) => b.clientId == bookmark.clientId);
    items[i] = bookmark.copyWith(note: note);
    return items[i];
  }

  @override
  Future<bool> remove(String clientId) async {
    removed.add(clientId);
    items.removeWhere((b) => b.clientId == clientId);
    return true;
  }

  @override
  Future<Bookmark?> restore(Bookmark bookmark) async {
    restored.add(bookmark);
    items.add(bookmark);
    return bookmark;
  }
}

class FakeBookmarks extends BookmarksNotifier {
  FakeBookmarks(this.items, {this.error});
  final List<Bookmark> items;
  final AppError? error;

  @override
  Future<BookmarksState> build() async {
    if (error != null) throw error!;
    return BookmarksState(bookmarks: [...items]);
  }

  @override
  Future<void> refresh() async {}
}

Bookmark mark(String id, {int series = 1, double chapter = 14, int index = 7, double fraction = 0.5, int total = 11, bool novel = false, String? snippet, String? note, bool stale = false, DateTime? at}) => Bookmark(
      clientId: id,
      sourceId: 'shelf',
      seriesKey: 'series-$series',
      chapterKey: 'c${chapter.round()}',
      seriesTitle: 'Series $series',
      chapterNumber: chapter,
      mediaType: novel ? BookmarkMedia.novel : BookmarkMedia.manga,
      anchorIndex: index,
      anchorFraction: fraction,
      anchorTotal: total,
      snippet: snippet,
      note: note,
      anchorStale: stale,
      createdAt: at ?? DateTime.utc(2026, 9, 28, 10),
      updatedAt: at ?? DateTime.utc(2026, 9, 28, 10),
    );

