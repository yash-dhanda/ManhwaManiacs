import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/auth/providers/offline_edition_controller.dart';
import 'package:manhwamaniacs/features/auth/providers/session_offline_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/bookmark_outbox_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/progress_outbox_provider.dart';
import 'package:manhwamaniacs/features/reader/repositories/reader_repository.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_overrides.dart';

class _Progress extends ProgressOutboxController {
  _Progress(super.ref, this.rows);
  int rows;
  @override
  Future<int> pendingCount() async => rows;
  @override
  Future<void> flush() async => rows = 0;
}

class _NoRepo implements ReaderRepository {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Marks extends BookmarkOutboxController {
  _Marks(this.rows) : super(store: null, repository: _NoRepo(), activeScopeId: _none);
  static String? _none() => null;
  int rows;
  @override
  Future<int> pendingCount() async => rows;
  @override
  Future<bool> flush() async {
    rows = 0;
    return false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('polls 15, 30, 60, 60 s, then reconnects, bumps the epoch and reports the flush', (t) async {
    SharedPreferences.setMockInitialValues({});
    final failures = StreamController<AppError>.broadcast(sync: true);
    addTearDown(failures.close);
    final probes = <int>[];
    var up = false;
    final c = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(await SharedPreferences.getInstance()),
      authenticatedAuthOverride(),
      activeProfileOverride(),
      networkFailureStreamProvider.overrideWithValue(failures.stream),
      serverProbeProvider.overrideWithValue(() async {
        probes.add(probes.length);
        return up;
      }),
      progressOutboxControllerProvider.overrideWith((ref) => _Progress(ref, 3)),
      bookmarkOutboxControllerProvider.overrideWith((ref) => _Marks(2)),
    ],);
    addTearDown(c.dispose);
    c.read(offlineEditionControllerProvider);
    expect(c.read(sessionOfflineProvider), isFalse);

    failures.add(const TimeoutError());
    expect(c.read(sessionOfflineProvider), isTrue);
    expect(c.read(offlineEditionControllerProvider).polling, isTrue);

    await t.pump(const Duration(seconds: 14));
    expect(probes, isEmpty);
    await t.pump(const Duration(seconds: 1));
    expect(probes.length, 1);
    await t.pump(const Duration(seconds: 29));
    expect(probes.length, 1);
    await t.pump(const Duration(seconds: 1));
    expect(probes.length, 2);
    await t.pump(const Duration(seconds: 60));
    expect(probes.length, 3);
    await t.pump(const Duration(seconds: 59));
    expect(probes.length, 3);
    up = true;
    await t.pump(const Duration(seconds: 1));
    expect(probes.length, 4);
    await t.pump();

    expect(c.read(sessionOfflineProvider), isFalse);
    expect(c.read(backOnlineEpochProvider), 1);
    final r = c.read(outboxSyncProvider)!;
    expect((r.reads, r.bookmarks), (3, 2));
    expect(c.read(offlineEditionControllerProvider).polling, isFalse);
  });

  test('a failure while signed out does nothing', () async {
    SharedPreferences.setMockInitialValues({});
    final failures = StreamController<AppError>.broadcast(sync: true);
    addTearDown(failures.close);
    final c = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(await SharedPreferences.getInstance()),
      networkFailureStreamProvider.overrideWithValue(failures.stream),
    ],);
    addTearDown(c.dispose);
    c.read(offlineEditionControllerProvider);
    failures.add(const TimeoutError());
    expect(c.read(sessionOfflineProvider), isFalse);
  });

  test('syncedMessage wording', () {
    expect(syncedMessage(3, 2), 'Synced 3 reads and 2 bookmarks.');
    expect(syncedMessage(1, 1), 'Synced 1 read and 1 bookmark.');
    expect(syncedMessage(3, 0), 'Synced 3 reads.');
    expect(syncedMessage(0, 2), 'Synced 2 bookmarks.');
    expect(syncedMessage(0, 0), isNull);
  });
}
