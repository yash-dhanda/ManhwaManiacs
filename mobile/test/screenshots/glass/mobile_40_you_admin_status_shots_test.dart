@Tags(['screenshots'])
library;

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/admin/providers/status_providers.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/features/library/providers/numbers_providers.dart';
import 'package:manhwamaniacs/features/settings/services/backup_download.dart';
import 'package:manhwamaniacs/features/settings/services/server_switch.dart';
import 'package:manhwamaniacs/features/setup/utils/server_check.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/providers/discover_providers.dart' show sourcesHealthProvider;
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/hold_to_confirm.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/backup_section.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/licenses_sheet.dart';
import 'package:manhwamaniacs/skins/glass/screens/you/you_screen.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart' show glassOfflineProvider;

import '../../skins/glass/you/m40_rig.dart';
import '../glass_shell_shots_support.dart';
import '../support/shot_harness.dart';
import '../support/skin_shots.dart';

/// The mobile/40 proof captures (glass 8.24 to 8.26): You, the admin settings, Server, Diagnostics, the licences sheet and System
/// status. Written only when `MM_PROOF_DIR` is set (never `MM_WRITE_SHOTS`); otherwise rasterised and discarded.
const _phone = SkinShotSize('phone', Size(390, 844), 3.0, EdgeInsets.only(top: 47, bottom: 34));

class _Switch extends ServerSwitch {
  _Switch(super.ref);
  @override
  Future<ServerCheck> check(String input) async => ServerCheck.ok(input);
  @override
  String get current => 'https://mm.example.org';
  @override
  Future<AppError?> confirm(String normalisedUrl) async => null;
}

class _SlowDio implements Dio {
  @override
  Future<Response<dynamic>> download(String urlPath, dynamic savePath, {ProgressCallback? onReceiveProgress, Map<String, dynamic>? queryParameters, CancelToken? cancelToken, bool deleteOnError = true, String lengthHeader = Headers.contentLengthHeader, Object? data, Options? options, FileAccessMode fileAccessMode = FileAccessMode.write}) {
    onReceiveProgress?.call(124 * 1024 * 1024, 412 * 1024 * 1024);
    return Completer<Response<dynamic>>().future;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Future<ShotSession> _open(WidgetTester t, SkinShotSize size, String route, {bool admin = true, List<Override> extra = const [], DateTime? now}) async {
  final s = await openShell(t, size, start: route, settle: false, extra: [
    ...adminOverrides(admin: admin),
    ...youOverrides(admin: admin, withAuth: false),
    youClockProvider.overrideWithValue(() => now ?? m40Now),
    ...extra,
  ],);
  for (var i = 0; i < 4; i++) {
    await s.settle(600);
  }
  return s;
}

Future<void> _end(WidgetTester t) async {
  await t.pumpWidget(const SizedBox.shrink());
  await t.pump(const Duration(minutes: 11));
}

/// A route at phone, tablet and the desktop frame.
Future<void> _all(WidgetTester t, String name, String route, {bool admin = true, List<Override> extra = const []}) async {
  for (final size in [_phone, kSkinShotSizes[1], kSkinShotTabletWide]) {
    final s = await _open(t, size, route, admin: admin, extra: extra);
    await s.snap(name, size);
    await _end(t);
  }
}

Future<void> _scrollTo(WidgetTester t, Finder f) async {
  await t.scrollUntilVisible(f, 240, scrollable: find.byType(Scrollable).first);
  // Clear of the dock.
  await t.drag(find.byType(Scrollable).first, const Offset(0, -300));
  await t.pump(const Duration(milliseconds: 300));
}

void main() {
  setUpAll(loadAppFonts);
  const wide = kSkinShotTabletWide;

  testWidgets('You: every frame, loading, offline, non-admin, the Wrapped card and the Orb lift', (t) async {
    await _all(t, 'you', '/more');
    await _all(t, 'you-nonadmin', '/more', admin: false);
    await _all(t, 'you-wrapped-card', '/more', extra: [youClockProvider.overrideWithValue(() => DateTime(2026, 12, 5))]);
    await _all(t, 'you-loading', '/more', extra: [
      numbersStatisticsProvider.overrideWith((ref, d) => Completer<NumbersLoad<LibraryStatistics>>().future),
    ],);
    await _all(t, 'you-offline', '/more', extra: [glassOfflineProvider.overrideWithValue(true), ...youOverrides(statsOffline: true, withAuth: false)]);
    // The lift 280 ms in: start on Home, then go to /more.
    final s = await openShell(t, _phone, settle: false, extra: [...adminOverrides(), ...youOverrides(withAuth: false)]);
    await s.settle(900);
    s.router.go('/more');
    await t.pump();
    await t.pump(const Duration(milliseconds: 280));
    await s.snap('orb-lift', _phone);
    await _end(t);
  });

  testWidgets('You: solid, contrast, reduced motion, text scale 2', (t) async {
    var s = await _open(t, _phone, '/more');
    s.container.read(glassInAppPrefsProvider.notifier).setSolidGlass(true);
    await s.settle(800);
    await s.snap('you-solid', _phone);
    s.container.read(glassInAppPrefsProvider.notifier)
      ..setSolidGlass(false)
      ..setIncreaseContrast(true);
    await s.settle(800);
    await s.snap('you-contrast', _phone);
    await _end(t);
    s = await _open(t, _phone, '/more');
    s.container.read(glassInAppPrefsProvider.notifier).setReduceMotion(true);
    await s.settle(800);
    await s.snap('you-reduced-motion', _phone);
    await _end(t);
    t.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    s = await _open(t, _phone, '/more');
    await s.snap('you-text-scale-2', _phone);
    await _end(t);
  });

  testWidgets('Notifications, the dirty bar; Security and its states', (t) async {
    await _all(t, 'settings-notifications', '/settings/notifications');
    var s = await _open(t, _phone, '/settings/notifications');
    await t.tap(find.text('Check when the server starts'));
    await s.settle(800);
    await s.snap('settings-notifications-dirty', _phone);
    await _end(t);
    s = await _open(t, wide, '/settings/notifications');
    await t.tap(find.text('Check when the server starts'));
    await s.settle(800);
    await s.snap('settings-notifications-dirty', wide);
    await _end(t);

    await _all(t, 'settings-security', '/settings/security');
    s = await _open(t, _phone, '/settings/security');
    s.container.read(glassInAppPrefsProvider.notifier).setSolidGlass(true);
    await s.settle(800);
    await s.snap('security-solid', _phone);
    await _end(t);
    s = await _open(t, _phone, '/settings/security', extra: adminOverrides(passwordError: const ApiError(statusCode: 429, code: 'rate_limited', message: 'slow', retryAfter: Duration(seconds: 42))));
    final f = find.byType(EditableText);
    await t.enterText(f.at(0), 'old-password');
    await t.enterText(f.at(1), 'new-password-1');
    await t.enterText(f.at(2), 'new-password-1');
    await t.tap(find.text('Change password').last);
    await s.settle(400);
    await s.snap('security-rate-limited', _phone);
    await _end(t);
    s = await _open(t, _phone, '/settings/security');
    await _scrollTo(t, find.byType(HoldToConfirm));
    await t.drag(find.byType(Scrollable).first, const Offset(0, -400));
    await s.settle(400);
    final g = await t.startGesture(t.getCenter(find.byType(HoldToConfirm)));
    await t.pump(const Duration(milliseconds: 50));
    await g.up();
    for (var i = 0; i < 3; i++) {
      await s.settle(300);
    }
    await s.snap('security-sign-out-everywhere-alert', _phone);
    await _end(t);
  });

  testWidgets('Members and the delete alert; Backup, its restore alert and the export progress', (t) async {
    await _all(t, 'settings-members', '/settings/members');
    var s = await _open(t, kSkinShotSizes[1], '/settings/members');
    await t.ensureVisible(find.widgetWithText(GlassButton, 'Delete').first);
    await t.pump();
    await t.tap(find.widgetWithText(GlassButton, 'Delete').first);
    for (var i = 0; i < 3; i++) {
      await s.settle(300);
    }
    await s.snap('members-delete-alert', kSkinShotSizes[1]);
    await _end(t);

    await _all(t, 'settings-backup', '/settings/backup');
    final dir = Directory.systemTemp.createTempSync('m40');
    addTearDown(() => dir.deleteSync(recursive: true));
    s = await _open(t, _phone, '/settings/backup', extra: [
      backupFilePickProvider.overrideWithValue(() async => (path: '${dir.path}/manhwamaniacs-2026-09-28.db', name: 'manhwamaniacs-2026-09-28.db', size: 42 * 1024 * 1024)),
      backupDownloaderProvider.overrideWithValue(BackupDownloader(_SlowDio(), tempDir: () async => dir, share: (_) async {})),
    ],);
    await t.tap(find.text('Export backup'));
    await s.settle(600);
    await s.snap('backup-export-progress', _phone);
    await _scrollTo(t, find.text('Choose backup file'));
    await t.tap(find.text('Choose backup file'));
    await s.settle(400);
    await _scrollTo(t, find.text('Restore from this file…'));
    await t.tap(find.text('Restore from this file…'));
    for (var i = 0; i < 3; i++) {
      await s.settle(300);
    }
    await s.snap('backup-restore-alert', _phone);
    await _end(t);
  });

  testWidgets('Server and its switch alert; Diagnostics; the licences sheet and its text', (t) async {
    await _all(t, 'settings-server', '/settings/server');
    var s = await _open(t, _phone, '/settings/server', extra: [serverSwitchProvider.overrideWith(_Switch.new)]);
    await t.enterText(find.byType(EditableText).first, 'https://reader.example.net');
    await t.pump();
    await t.pump();
    await t.tap(find.text('Save'));
    for (var i = 0; i < 3; i++) {
      await s.settle(300);
    }
    await s.snap('server-switch-alert', _phone);
    await _end(t);

    await _all(t, 'settings-diagnostics', '/settings/diagnostics');
    await _all(t, 'licenses', '/settings/about?sheet=licenses');
    s = await _open(t, _phone, '/settings/about?sheet=licenses');
    await t.tap(find.descendant(of: find.byType(LicenceList), matching: find.text('dio')).last);
    await s.settle(600);
    await s.snap('licenses-text', _phone);
    await _end(t);
  });

  testWidgets('System status: healthy, problems, non-admin, offline, solid and contrast', (t) async {
    await _all(t, 'status', '/admin/status');
    await _all(t, 'status-problems', '/admin/status', extra: adminOverrides(problems: true, backendDown: true));
    await _all(t, 'status-nonadmin', '/admin/status', admin: false);
    await _all(t, 'status-offline', '/admin/status', extra: [
      glassOfflineProvider.overrideWithValue(true),
      backendHealthProvider.overrideWith((ref) => const Stream.empty()),
      sourcesHealthProvider.overrideWith((ref) => Completer<List<SourceSummary>>().future),
    ],);
    final s = await _open(t, wide, '/admin/status', extra: adminOverrides(problems: true));
    s.container.read(glassInAppPrefsProvider.notifier).setSolidGlass(true);
    await s.settle(800);
    await s.snap('status-solid', wide);
    s.container.read(glassInAppPrefsProvider.notifier)
      ..setSolidGlass(false)
      ..setIncreaseContrast(true);
    await s.settle(800);
    await s.snap('status-contrast', wide);
    await _end(t);
  });
}
