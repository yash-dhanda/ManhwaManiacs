// ignore_for_file: directives_ordering
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/settings/models/backup_status.dart';
import 'package:manhwamaniacs/features/settings/repositories/backup_repository.dart';
import 'package:manhwamaniacs/features/settings/services/backup_download.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_switch.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/pages/backup_page.dart';

import '../downloads/downloads_rig.dart' show settle;
import 'settings_rig.dart';

class _Repo implements BackupRepository {
  final log = <String>[];
  @override
  Future<Result<BackupStatus>> getStatus() async => const Ok(BackupStatus(restorePending: false));
  @override
  Future<Result<void>> importBackup(String filePath) async {
    log.add('import $filePath');
    return const Ok(null);
  }

  @override
  Future<Result<void>> cancelPendingRestore() async {
    log.add('cancel');
    return const Ok(null);
  }
}

class _Dio implements Dio {
  _Dio({this.fail = false});
  final bool fail;
  Map<String, dynamic>? query;
  @override
  Future<Response<dynamic>> download(String urlPath, dynamic savePath,
      {ProgressCallback? onReceiveProgress, Map<String, dynamic>? queryParameters, CancelToken? cancelToken, bool deleteOnError = true,
      String lengthHeader = Headers.contentLengthHeader, Object? data, Options? options, FileAccessMode fileAccessMode = FileAccessMode.write,}) async {
    query = queryParameters;
    if (fail) throw DioException(requestOptions: RequestOptions(path: urlPath));
    onReceiveProgress?.call(124 * 1024 * 1024, 412 * 1024 * 1024);
    return Response(requestOptions: RequestOptions(path: urlPath));
  }

  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

Future<void> tapBtn(WidgetTester t, String label) async {
  final b = find.widgetWithText(CineButton, label);
  Scrollable.ensureVisible(t.element(b), alignment: 0.5, duration: Duration.zero);
  await t.pump();
  await t.tap(b);
  await settle(t, ms: 400);
}

void main() {
  test('the nightly line is never healthy while unknown', () {
    expect(nightlyLine(null), 'LAST NIGHTLY · UNKNOWN');
    expect(nightlyLine(NightlyBackup(ok: true, finishedAt: DateTime(2026, 9, 28, 3), bytes: 412 * 1024 * 1024)), 'LAST NIGHTLY · OK · 28 SEP 03:00 · 412.0 MB');
    expect(nightlyLine(NightlyBackup(ok: false, finishedAt: DateTime(2026, 9, 28, 3), phase: 'dump')), 'LAST NIGHTLY · FAILED AT DUMP · 28 SEP 03:00');
  });

  testWidgets('a staged restore shows the NOTE strip and can be cancelled', (t) async {
    final repo = _Repo();
    await pumpPage(t, const BackupPage(), rig: SettingsRig(backup: const BackupStatus(restorePending: true)), more: [backupRepositoryProvider.overrideWithValue(repo)]);
    expect(find.text('A restore is staged. It applies the next time the server starts; the current database is kept.'), findsOneWidget);
    await tapBtn(t, 'Cancel staged restore');
    expect(repo.log, ['cancel']);
  });

  testWidgets('the nightly card: FAILED reads proof, UNKNOWN is shown as such', (t) async {
    await pumpPage(t, const BackupPage(), rig: SettingsRig(backup: BackupStatus(restorePending: false, nightly: NightlyBackup(ok: false, finishedAt: DateTime(2026, 9, 28, 3), phase: 'dump'))));
    expect(find.text('LAST NIGHTLY · FAILED AT DUMP · 28 SEP 03:00'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await pumpPage(t, const BackupPage());
    expect(find.text('LAST NIGHTLY · UNKNOWN'), findsOneWidget);
  });

  testWidgets('export downloads with the client, shows progress, then opens the share sheet', (t) async {
    final dir = Directory.systemTemp.createTempSync('bkp');
    addTearDown(() => dir.deleteSync(recursive: true));
    final shared = <String>[];
    final dio = _Dio();
    await pumpPage(t, const BackupPage(), more: [
      backupDownloaderProvider.overrideWithValue(BackupDownloader(dio, tempDir: () async => dir, clock: () => DateTime(2026, 9, 28, 3), share: (p) async => shared.add(p))),
    ]);
    expect(find.text('The whole database, every account. Keep it private.'), findsOneWidget);
    final sw = find.byType(CineSwitch).first;
    Scrollable.ensureVisible(t.element(sw), alignment: 0.5, duration: Duration.zero);
    await t.pump();
    await t.tap(sw);
    await settle(t, ms: 400);
    await tapBtn(t, 'Export backup');
    expect(dio.query, {'include_cache': true});
    expect(shared, ['${dir.path}/manhwamaniacs-backup-20260928-0300.db']);
  });

  testWidgets('a failed export toasts', (t) async {
    final dir = Directory.systemTemp.createTempSync('bkp');
    addTearDown(() => dir.deleteSync(recursive: true));
    final c = await pumpPage(t, const BackupPage(), more: [
      backupDownloaderProvider.overrideWithValue(BackupDownloader(_Dio(fail: true), tempDir: () async => dir, share: (_) async {})),
    ]);
    await tapBtn(t, 'Export backup');
    expect(c.read(cineToastsProvider).any((x) => x.text == "Couldn't download the backup."), isTrue);
  });

  testWidgets('progress: a determinate rule and the byte line', (t) async {
    final dir = Directory.systemTemp.createTempSync('bkp');
    addTearDown(() => dir.deleteSync(recursive: true));
    await pumpPage(t, const BackupPage(), more: [
      backupDownloaderProvider.overrideWithValue(BackupDownloader(_SlowDio(), tempDir: () async => dir, share: (_) async {})),
    ]);
    final b = find.widgetWithText(CineButton, 'Export backup');
    Scrollable.ensureVisible(t.element(b), alignment: 0.5, duration: Duration.zero);
    await t.pump();
    await t.tap(b);
    await t.pump(const Duration(milliseconds: 50));
    expect(find.text('124 MB OF 412 MB'), findsWidgets);
    expect(find.byType(CineRuleProgress), findsOneWidget);
    await settle(t, ms: 500);
  });

  testWidgets('restore: validation lines, then RESTORE typed and the arm, then Restore staged', (t) async {
    final repo = _Repo();
    ({String path, String name, int size})? picked = (path: '/tmp/x.txt', name: 'notes.txt', size: 10);
    await pumpPage(t, BackupPage(filePicker: () async => picked), more: [backupRepositoryProvider.overrideWithValue(repo)]);
    expect(find.text('No file chosen. Nothing is uploaded until you confirm.'), findsOneWidget);
    await tapBtn(t, 'Choose backup file');
    expect(find.text("That isn't a .db file."), findsOneWidget);
    picked = (path: '/tmp/x.db', name: 'x.db', size: 0);
    await tapBtn(t, 'Choose backup file');
    expect(find.text('That file is empty.'), findsOneWidget);
    picked = (path: '/tmp/x.db', name: 'x.db', size: 412 * 1024 * 1024);
    await tapBtn(t, 'Choose backup file');
    expect(find.text('x.db · 412.0 MB'), findsOneWidget);
    final open = find.widgetWithText(CineButton, 'Restore from this file…');
    Scrollable.ensureVisible(t.element(open), alignment: 0.5, duration: Duration.zero);
    await t.pump();
    await t.tap(open);
    await settle(t, ms: 400);
    expect(find.text('Restore from x.db?'), findsOneWidget);
    await t.enterText(find.byType(EditableText).last, 'restore');
    await t.pump(const Duration(milliseconds: 100));
    await t.tap(find.text('Restore').last, warnIfMissed: false);
    await t.pump(const Duration(milliseconds: 100));
    expect(repo.log, isEmpty, reason: 'armed');
    await settle(t, ms: 1200);
    await t.tap(find.text('Restore').last);
    await settle(t, ms: 800);
    expect(repo.log, ['import /tmp/x.db']);
    expect(find.text('Restore staged.'), findsOneWidget);
    expect(find.text('Restart the server to finish.'), findsOneWidget);
    await t.tap(find.text('Done'));
    await settle(t, ms: 400);
  });
}

class _SlowDio extends _Dio {
  @override
  Future<Response<dynamic>> download(String urlPath, dynamic savePath,
      {ProgressCallback? onReceiveProgress, Map<String, dynamic>? queryParameters, CancelToken? cancelToken, bool deleteOnError = true,
      String lengthHeader = Headers.contentLengthHeader, Object? data, Options? options, FileAccessMode fileAccessMode = FileAccessMode.write,}) async {
    onReceiveProgress?.call(124 * 1024 * 1024, 412 * 1024 * 1024);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return Response(requestOptions: RequestOptions(path: urlPath));
  }
}
