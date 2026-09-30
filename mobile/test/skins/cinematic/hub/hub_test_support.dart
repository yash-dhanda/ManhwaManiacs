// ignore_for_file: require_trailing_commas, directives_ordering

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/auth/models/auth_user.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
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
