import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/updates/models/update_notification.dart';
import 'package:manhwamaniacs/features/updates/models/update_settings.dart';
import 'package:manhwamaniacs/features/updates/repositories/updates_repository.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

import '../../../screenshots/support/shot_harness.dart';
import '../library/library_rig.dart';

/// Updates from memory: no notifications, and `POST /updates/check` answers [check].
class FakeUpdatesRepo implements UpdatesRepository {
  FakeUpdatesRepo({this.alreadyRunning = false, this.notifications = const []});
  final bool alreadyRunning;
  final List<UpdateNotification> notifications;
  final List<String> calls = [];

  @override
  Future<Result<UpdateCheckOutcome>> triggerCheck({List<int>? followedIds}) async {
    calls.add('check');
    return alreadyRunning ? const Err(ApiError(statusCode: 409, code: 'check_already_running', message: 'running')) : const Ok(UpdateCheckOutcome(queued: false));
  }

  @override
  Future<Result<List<UpdateNotification>>> listNotifications({bool unreadOnly = false, int limit = 100}) async =>
      Ok([for (final n in notifications) if (!unreadOnly || !n.isRead) n]);
  @override
  Future<Result<int>> getUnreadCount() async => Ok(notifications.where((n) => !n.isRead).length);
  @override
  Future<Result<List<UpdateRun>>> listRuns({int limit = 20}) async => const Ok(<UpdateRun>[]);
  @override
  Future<Result<List<String>>> listUpdateSources() async => const Ok(<String>[]);
  @override
  Future<Result<UpdateSettings>> getSettings() async => const Err(NetworkError(message: 'down'));
  @override
  Future<Result<UpdateSettings>> updateSettings({bool? enabled, int? checkIntervalMinutes, bool? notifyEnabled, bool? checkOnStartup}) async => const Err(NetworkError(message: 'down'));
  @override
  Future<Result<void>> markRead(int notificationId) async => const Ok(null);
  @override
  Future<Result<void>> markAllRead({String? contentKind}) async => const Ok(null);
  @override
  Future<Result<UpdateRun>> checkFollowed(int followedId) async => const Err(NetworkError(message: 'down'));
  @override
  Future<Result<UpdateRun>> getRun(int runId) async => const Err(NetworkError(message: 'down'));
}

/// A new-chapter notification of `shelfSeries(series)` (chapter [ch]).
UpdateNotification notification(int id, int series, double ch, {bool read = false}) => UpdateNotification(
      id: id,
      followedSeriesId: series,
      sourceId: 'shelf',
      seriesKey: 'series-$series',
      chapterKey: 'c${ch.toInt()}',
      chapterTitle: 'Chapter ${ch.toInt()}',
      chapterNumber: ch,
      isRead: read,
      createdAt: DateTime.now().subtract(Duration(minutes: id * 7)),
    );

void main() {
  setUpAll(loadAppFonts);

  for (final running in [false, true]) {
    testWidgets('r runs Check now${running ? '; a 409 says a check is already running' : ''}', (t) async {
      final up = FakeUpdatesRepo(alreadyRunning: running);
      await pumpLibrary(t, FakeLib(), start: '/updates', extra: [updatesRepositoryProvider.overrideWithValue(up)]);
      await t.sendKeyEvent(LogicalKeyboardKey.keyR);
      for (var i = 0; i < 6; i++) {
        await t.pump(const Duration(milliseconds: 150));
      }
      expect(up.calls, ['check']);
      expect(find.text('A check is already running'), running ? findsOneWidget : findsNothing);
    });
  }
}
