import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/updates/models/update_notification.dart';
import 'package:manhwamaniacs/features/updates/models/update_settings.dart';
import 'package:manhwamaniacs/features/updates/providers/unread_count_provider.dart';
import 'package:manhwamaniacs/features/updates/repositories/updates_repository.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_overrides.dart';

class _Repo implements UpdatesRepository {

  @override
  Future<Result<UpdateRun>> getRun(int runId) => throw UnimplementedError();

  @override
  Future<Result<List<String>>> listUpdateSources() async => const Ok(<String>[]);
  int count = 3;
  int calls = 0;
  List<UpdateNotification> rows = const [];

  @override
  Future<Result<int>> getUnreadCount() async {
    calls++;
    return Ok(count);
  }

  @override
  Future<Result<List<UpdateNotification>>> listNotifications({bool unreadOnly = false, int limit = 100}) async =>
      Ok(rows);

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

UpdateNotification _n(int id, String series) => UpdateNotification(
      id: id,
      followedSeriesId: 1,
      sourceId: 's',
      seriesKey: series,
      chapterKey: 'c$id',
      chapterTitle: 't',
      isRead: false,
    );

class _Switchable extends ActiveProfileNotifier {
  @override
  ActiveProfile? build() => const ActiveProfile(id: 1, name: 'A', avatarKey: null, mood: Mood.neutral);
  void to(int id) => state = ActiveProfile(id: id, name: 'B', avatarKey: null, mood: Mood.neutral);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("a profile switch re-reads the count at once, not on the next poll", (t) async {
    SharedPreferences.setMockInitialValues({});
    final repo = _Repo();
    final c = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(await SharedPreferences.getInstance()),
      updatesRepositoryProvider.overrideWithValue(repo),
      authenticatedAuthOverride(),
      activeProfileProvider.overrideWith(_Switchable.new),
    ],);
    addTearDown(c.dispose);
    c.listen(unreadNotificationCountProvider, (_, __) {});
    await t.pump();
    expect(c.read(unreadNotificationCountProvider), 3);
    repo.count = 0;
    (c.read(activeProfileProvider.notifier) as _Switchable).to(2);
    c.read(unreadNotificationCountProvider);
    await t.pump();
    expect(c.read(unreadNotificationCountProvider), 0);
    expect(repo.calls, 2);
  });

  Future<(ProviderContainer, _Repo)> make({bool signedIn = true}) async {
    SharedPreferences.setMockInitialValues({});
    final repo = _Repo();
    final c = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(await SharedPreferences.getInstance()),
      updatesRepositoryProvider.overrideWithValue(repo),
      if (signedIn) authenticatedAuthOverride(),
      if (signedIn) activeProfileOverride(),
    ],);
    return (c, repo);
  }

  testWidgets('reads at once, then every 60 s', (t) async {
    final (c, repo) = await make();
    c.listen(unreadNotificationCountProvider, (_, __) {});
    await t.pump();
    expect(c.read(unreadNotificationCountProvider), 3);
    expect(repo.calls, 1);
    repo.count = 5;
    await t.pump(const Duration(seconds: 59));
    expect(repo.calls, 1);
    await t.pump(const Duration(seconds: 2));
    expect(repo.calls, 2);
    expect(c.read(unreadNotificationCountProvider), 5);
    c.dispose();
  });

  testWidgets('reads again on resume and stays quiet while paused', (t) async {
    final (c, repo) = await make();
    c.listen(unreadNotificationCountProvider, (_, __) {});
    await t.pump();
    final n = c.read(unreadNotificationCountProvider.notifier);
    n.didChangeAppLifecycleState(AppLifecycleState.paused);
    await t.pump(const Duration(seconds: 61));
    expect(repo.calls, 1);
    n.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await t.pump();
    expect(repo.calls, 2);
    c.dispose();
  });

  testWidgets('no session, no request', (t) async {
    final (c, repo) = await make(signedIn: false);
    c.listen(unreadNotificationCountProvider, (_, __) {});
    await t.pump(const Duration(seconds: 61));
    expect(repo.calls, 0);
    expect(c.read(unreadNotificationCountProvider), 0);
    c.dispose();
  });

  testWidgets('the banner derives chapters, series and max id', (t) async {
    final (c, repo) = await make();
    repo.rows = [_n(4, 'a'), _n(9, 'a'), _n(7, 'b')];
    c.listen(unreadNotificationCountProvider, (_, __) {});
    await t.pump();
    c.listen(newChaptersBannerProvider, (_, __) {});
    await t.pump();
    final b = c.read(newChaptersBannerProvider).value;
    expect(b, (chapters: 3, series: 2, maxId: 9));
    c.dispose();
  });

  testWidgets('no unread, no banner', (t) async {
    final (c, repo) = await make();
    repo.count = 0;
    c.listen(unreadNotificationCountProvider, (_, __) {});
    await t.pump();
    c.listen(newChaptersBannerProvider, (_, __) {});
    await t.pump();
    expect(c.read(newChaptersBannerProvider).value, isNull);
    c.dispose();
  });
}
