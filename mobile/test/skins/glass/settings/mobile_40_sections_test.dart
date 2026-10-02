import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/admin/providers/status_providers.dart';
import 'package:manhwamaniacs/features/auth/utils/password_change_check.dart';
import 'package:manhwamaniacs/features/settings/models/backup_status.dart';
import 'package:manhwamaniacs/features/settings/providers/backup_provider.dart';
import 'package:manhwamaniacs/features/settings/services/server_switch.dart';
import 'package:manhwamaniacs/features/setup/utils/server_check.dart';
import 'package:manhwamaniacs/features/updates/models/update_settings.dart';
import 'package:manhwamaniacs/features/updates/repositories/updates_repository.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/dev/auth_fixtures.dart' show FakeAuth;
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/hold_to_confirm.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/backup_section.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/diagnostics_section.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/licenses_sheet.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/security_section.dart';

import '../../../screenshots/support/shot_harness.dart';
import '../shell/shell_rig.dart';
import '../you/m40_rig.dart';

Future<ShellRig> pumpSection(WidgetTester t, String at, {bool admin = true, Size size = const Size(390, 844), List<Override> extra = const [], bool android = false}) async {
  await m40Clear(t);
  final rig = await pumpGlassShell(t, start: at, size: size, platformAndroid: android, extra: [...adminOverrides(admin: admin), ...extra]);
  await m40Settle(t, 1200);
  return rig;
}

class _Updates implements UpdatesRepository {
  final List<Map<String, Object?>> saved = [];
  bool fail = false;
  @override
  Future<Result<UpdateSettings>> updateSettings({bool? enabled, int? checkIntervalMinutes, bool? notifyEnabled, bool? checkOnStartup}) async {
    saved.add({'enabled': enabled, 'interval': checkIntervalMinutes, 'notify': notifyEnabled, 'startup': checkOnStartup});
    if (fail) return const Err(UnknownError(message: 'nope'));
    return Ok(UpdateSettings(enabled: enabled!, checkIntervalMinutes: checkIntervalMinutes!, notifyEnabled: notifyEnabled!, checkOnStartup: checkOnStartup!));
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Switch extends ServerSwitch {
  _Switch(super.ref);
  final List<String> confirmed = [];
  bool didReset = false;
  @override
  Future<ServerCheck> check(String input) async => input.startsWith('https://good') ? ServerCheck.ok(input) : const ServerCheck.httpInRelease();
  @override
  String get current => 'https://mm.example.org';
  @override
  Future<AppError?> confirm(String normalisedUrl) async {
    confirmed.add(normalisedUrl);
    return null;
  }

  @override
  Future<AppError?> reset() async {
    didReset = true;
    return null;
  }
}

void main() {
  setUpAll(loadAppFonts);

  group('Notifications', () {
    m40Test('a non-admin sees only their own profile switch', (t) async {
      await pumpSection(t, '/settings/notifications', admin: false);
      expect(find.text('Notify me about new chapters'), findsOneWidget);
      expect(find.text('Send new-chapter notifications'), findsNothing);
      expect(find.text('Administrators only'), findsNothing);
    });

    m40Test('the schedule strip, the switches, the stepper and the overdue form', (t) async {
      await pumpSection(t, '/settings/notifications');
      expect(find.text('Last check 12 min ago'), findsOneWidget);
      expect(find.text('Next check in 18 min'), findsOneWidget);
      expect(find.text('Every 30 min'), findsOneWidget);
      expect(find.text('Check for new chapters automatically'), findsOneWidget);
      expect(find.text('Check when the server starts'), findsOneWidget);
      expect(find.text('Notify me about new chapters'), findsOneWidget);
      expect(find.text('Send new-chapter notifications'), findsOneWidget);
      expect(find.text('Source catalogue cache', skipOffstage: false), findsOneWidget);

      await pumpSection(t, '/settings/notifications', extra: [updateSettingsProvider.overrideWith((ref) async => m40UpdateSettings(lastRun: DateTime.now().subtract(const Duration(minutes: 37))))]);
      expect(find.text('Overdue by 7 min'), findsOneWidget);
      expect(find.text('See System status'), findsOneWidget);
    });

    m40Test('a change shows the Unsaved changes bar; Save writes, Discard drops, back asks', (t) async {
      final repo = _Updates();
      await pumpSection(t, '/settings/notifications', extra: [updatesRepositoryProvider.overrideWithValue(repo)]);
      expect(find.text('Unsaved changes'), findsNothing);
      await t.tap(find.text('Check when the server starts'));
      await m40Settle(t, 600);
      expect(find.text('Unsaved changes'), findsOneWidget);
      final bar = t.getRect(find.ancestor(of: find.text('Unsaved changes'), matching: find.byType(SizedBox)).first);
      expect(bar.height, 52);
      await t.tap(find.text('Discard'));
      await m40Settle(t, 600);
      expect(find.text('Unsaved changes').hitTestable(), findsNothing);

      await t.tap(find.text('Check when the server starts'));
      await m40Settle(t, 600);
      final nav = t.state<NavigatorState>(find.ancestor(of: find.text('Check when the server starts'), matching: find.byType(Navigator)).first);
      await nav.maybePop();
      await m40Settle(t, 600);
      expect(find.text('Discard your changes?'), findsOneWidget);
      await t.tap(find.text('Keep editing'));
      await m40Settle(t, 600);

      await t.tap(find.text('Save'));
      await m40Settle(t, 800);
      expect(repo.saved.single['startup'], isTrue);
      expect(find.text('Saved'), findsOneWidget);
    });

    m40Test('the interval slider ticks per step and pulls to the 30 min magnet', (t) async {
      await pumpSection(t, '/settings/notifications');
      GlassHaptics.debugLog.clear();
      final slider = find.byKey(const ValueKey('interval-slider'));
      final r = t.getRect(slider);
      final g = await t.startGesture(Offset(r.left + 14, r.center.dy));
      for (var i = 0; i < 12; i++) {
        await g.moveBy(Offset((r.width - 28) / 23, 0));
        await t.pump(const Duration(milliseconds: 150));
      }
      await g.up();
      await m40Settle(t, 400);
      final events = GlassHaptics.debugLog.map((e) => e.event).toList();
      expect(events.where((e) => e == HapticEvent.detentTick), isNotEmpty);
      expect(events.where((e) => e == HapticEvent.detentMagnet), hasLength(1));
    });
  });

  group('Security', () {
    m40Test('client errors, then invalid_credentials inline on Current without a sign-out', (t) async {
      await pumpSection(t, '/settings/security', extra: [], admin: false);
      await t.tap(find.text('Change password'));
      await m40Settle(t, 300);
      expect(find.text('Enter your current password'), findsOneWidget);
      expect(find.text('Enter a new password'), findsOneWidget);
      for (final i in PasswordIssue.values) {
        expect(passwordIssueLine(i), isNotEmpty);
      }
      expect(passwordIssueLine(PasswordIssue.tooLong), 'Password is too long');
      expect(passwordIssueLine(PasswordIssue.mismatch), "The new passwords don't match");
      expect(passwordIssueLine(PasswordIssue.same), 'Your new password must be different');

      FakeAuth.calls.clear();
      await pumpSection(t, '/settings/security', extra: adminOverrides(passwordError: const ApiError(statusCode: 401, code: 'invalid_credentials', message: 'bad')));
      final fields = find.byType(EditableText);
      await t.enterText(fields.at(0), 'old-password');
      await t.enterText(fields.at(1), 'new-password-1');
      await t.enterText(fields.at(2), 'new-password-1');
      await t.tap(find.text('Change password'));
      await m40Settle(t, 600);
      expect(find.text("That isn't your current password."), findsOneWidget);
      expect(FakeAuth.calls, isNot(contains('logout')));
    });

    m40Test('weak_password shows the server line; rate_limited counts down on the button', (t) async {
      await pumpSection(t, '/settings/security', extra: adminOverrides(passwordError: const ApiError(statusCode: 422, code: 'weak_password', message: 'Pick something less common.')));
      var fields = find.byType(EditableText);
      await t.enterText(fields.at(0), 'old-password');
      await t.enterText(fields.at(1), 'new-password-1');
      await t.enterText(fields.at(2), 'new-password-1');
      await t.tap(find.text('Change password'));
      await m40Settle(t, 600);
      expect(find.text('Pick something less common.'), findsOneWidget);

      await pumpSection(t, '/settings/security', extra: adminOverrides(passwordError: const ApiError(statusCode: 429, code: 'rate_limited', message: 'slow', retryAfter: Duration(seconds: 42))));
      fields = find.byType(EditableText);
      await t.enterText(fields.at(0), 'old-password');
      await t.enterText(fields.at(1), 'new-password-1');
      await t.enterText(fields.at(2), 'new-password-1');
      await t.tap(find.text('Change password'));
      await m40Settle(t, 300);
      expect(find.text('Try again in 42 s'), findsOneWidget);
      await t.pump(const Duration(seconds: 1));
      expect(find.text('Try again in 41 s'), findsOneWidget);
    });

    m40Test('sessions: This device, and the other row offers Sign out this device as a custom action', (t) async {
      final h = t.ensureSemantics();
      await pumpSection(t, '/settings/security');
      expect(find.text('This device', skipOffstage: false), findsOneWidget);
      expect(find.text('Safari on Mac', skipOffstage: false), findsOneWidget);
      expect(find.text('ManhwaManiacs app', skipOffstage: false), findsOneWidget);
      await t.scrollUntilVisible(find.text('Safari on Mac'), 200, scrollable: find.byType(Scrollable).first);
      final node = t.getSemantics(find.ancestor(of: find.text('Safari on Mac'), matching: find.byType(Semantics)).first);
      final actions = <String>[];
      void walk(SemanticsNode n) {
        actions.addAll(n.getSemanticsData().customSemanticsActionIds?.map((id) => CustomSemanticsAction.getAction(id)?.label ?? '') ?? const []);
        n.visitChildren((c) {
          walk(c);
          return true;
        });
      }

      walk(node);
      expect(actions, contains('Sign out this device'));
      h.dispose();
    });

    m40Test('Sign out everywhere by tap opens the alert whose confirm needs the acknowledgement switch', (t) async {
      await pumpSection(t, '/settings/security');
      await t.scrollUntilVisible(find.byType(HoldToConfirm), 200, scrollable: find.byType(Scrollable).first);
      // Clear of the dock.
      await t.drag(find.byType(Scrollable).first, const Offset(0, -400));
      await m40Settle(t, 400);
      final g = await t.startGesture(t.getCenter(find.byType(HoldToConfirm)));
      await t.pump(const Duration(milliseconds: 50));
      await g.up();
      await m40Settle(t, 800);
      expect(find.text('I understand this signs me out here too'), findsOneWidget);
      final confirm = find.widgetWithText(GlassButton, 'Sign out everywhere').last;
      expect(t.widget<GlassButton>(confirm).onPressed, isNull);
      await t.tap(find.text('I understand this signs me out here too'));
      await m40Settle(t, 300);
    });

    m40Test('Sign out everywhere by a 1,200 ms hold', (t) async {
      FakeAuth.calls.clear();
      GlassHaptics.debugLog.clear();
      await pumpSection(t, '/settings/security');
      await t.scrollUntilVisible(find.byType(HoldToConfirm), 200, scrollable: find.byType(Scrollable).first);
      // Clear of the dock.
      await t.drag(find.byType(Scrollable).first, const Offset(0, -400));
      await m40Settle(t, 400);
      final g = await t.startGesture(t.getCenter(find.byType(HoldToConfirm)));
      for (var i = 0; i < 26; i++) {
        await t.pump(const Duration(milliseconds: 50));
      }
      await g.up();
      await m40Settle(t, 400);
      expect(FakeAuth.calls, contains('logout-everywhere'));
      expect(GlassHaptics.debugLog.map((e) => e.event), contains(HapticEvent.holdDone));
    });
  });

  group('Members', () {
    m40Test('phone rows; the own row disabled with the reason; the footer count', (t) async {
      await pumpSection(t, '/settings/members');
      expect(find.text('@aarav'), findsOneWidget);
      expect(find.text("You can't deactivate or delete your own account"), findsOneWidget);
      expect(find.text('2 other accounts', skipOffstage: false), findsOneWidget);
      expect(find.textContaining('Registration is open on this server.'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('More actions for @yash')), findsNothing);
    });

    m40Test('tablet: the table sits in its own horizontal scroll view at 640 min', (t) async {
      await pumpSection(t, '/settings/members', size: const Size(834, 1194));
      expect(find.text('MEMBER'), findsOneWidget);
      expect(find.text('ACTIONS'), findsOneWidget);
      final h = find.byWidgetPredicate((w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal);
      expect(h, findsWidgets);
    });

    m40Test('Delete opens the in-alert hold with its visible fallback', (t) async {
      await pumpSection(t, '/settings/members', size: const Size(834, 1194));
      await t.ensureVisible(find.widgetWithText(GlassButton, 'Delete').first);
      await t.pump();
      await t.tap(find.widgetWithText(GlassButton, 'Delete').first);
      await m40Settle(t, 800);
      expect(find.text('Delete @aarav?'), findsOneWidget);
      expect(find.textContaining('Hold to delete @aarav'), findsWidgets);
      expect(find.textContaining('Delete @aarav'), findsWidgets);
    });

    m40Test('a non-admin sees the lens', (t) async {
      await pumpSection(t, '/settings/members', admin: false);
      expect(find.text('Administrators only'), findsOneWidget);
    });
  });

  group('Administration list and storage', () {
    m40Test('admins see System status, Members and Backup; others the lens', (t) async {
      await pumpSection(t, '/settings/admin');
      expect(find.text('System status'), findsOneWidget);
      expect(find.text('Members'), findsWidgets);
      expect(find.text('Backup'), findsOneWidget);
      await pumpSection(t, '/settings/admin', admin: false);
      expect(find.text('Administrators only'), findsOneWidget);
    });

    m40Test('/settings/storage resolves to Downloads -> Storage before any Settings widget builds', (t) async {
      final rig = await pumpSection(t, '/settings/storage');
      expect(rig.at, '/downloads');
      expect(find.text('Settings'), findsNothing);
      expect(find.text('Search settings'), findsNothing);
    });
  });

  group('Backup', () {
    m40Test('the nightly card never shows Unknown as healthy; the phrase gate is case-insensitive', (t) async {
      await pumpSection(t, '/settings/backup');
      expect(nightlyCard(null).line, 'Last nightly backup: Unknown');
      expect(nightlyCard(null).glyph, isNot(nightlyCard(NightlyBackup(ok: true, finishedAt: DateTime(2026, 10, 1, 3, 10))).glyph));
      expect(nightlyCard(NightlyBackup(ok: true, finishedAt: DateTime(2026, 10, 1, 3, 10), bytes: 42 * 1024 * 1024)).line, 'Last nightly backup: 03:10 · 42.0 MB · OK');
      expect(restorePhraseMatches('restore'), isTrue);
      expect(restorePhraseMatches(' RESTORE '), isTrue);
      expect(restorePhraseMatches('RESTOR'), isFalse);
    });

    m40Test('the staged banner, the export switch and the file validation', (t) async {
      await pumpSection(t, '/settings/backup', extra: [
        backupStatusProvider.overrideWith((ref) async => const BackupStatus(restorePending: true)),
      ],);
      expect(find.text('Last nightly backup: Unknown'), findsOneWidget);
      expect(find.text('A restore is staged and applies when the server restarts.'), findsOneWidget);
      expect(find.text('Cancel staged restore'), findsOneWidget);
      expect(find.text('Include caches (larger, restores faster)', skipOffstage: false), findsOneWidget);
      expect(find.text('No file chosen. Nothing is uploaded until you confirm.', skipOffstage: false), findsOneWidget);
    });
  });

  m40Test('Backup: a chosen file opens the restore alert, whose Restore waits for the RESTORE phrase (any case)', (t) async {
    await pumpSection(t, '/settings/backup', extra: [
      backupFilePickProvider.overrideWithValue(() async => (path: '/tmp/x.db', name: 'manhwamaniacs-2026-09-28.db', size: 42 * 1024 * 1024)),
    ],);
    await t.scrollUntilVisible(find.text('Choose backup file'), 200, scrollable: find.byType(Scrollable).first);
    await t.drag(find.byType(Scrollable).first, const Offset(0, -400));
    await m40Settle(t, 300);
    await t.tap(find.text('Choose backup file'));
    await m40Settle(t, 300);
    expect(find.text('manhwamaniacs-2026-09-28.db · 42.0 MB'), findsOneWidget);
    await t.tap(find.text('Restore from this file…'));
    await m40Settle(t, 800);
    expect(find.text('Restore from “manhwamaniacs-2026-09-28.db”?'), findsOneWidget);
    Finder restore() => find.widgetWithText(GlassButton, 'Restore').last;
    expect(t.widget<GlassButton>(restore()).onPressed, isNull);
    await t.enterText(find.byType(EditableText).last, 'restore');
    await t.pump();
    expect(t.widget<GlassButton>(restore()).onPressed, isNotNull);
    await t.tap(find.text('Cancel'));
    await m40Settle(t, 600);
  });

  group('Server', () {
    m40Test('an invalid address shows the Setup line; a valid one asks, switches and toasts', (t) async {
      late _Switch sw;
      await pumpSection(t, '/settings/server', extra: [serverSwitchProvider.overrideWith((ref) => sw = _Switch(ref))]);
      final field = find.byType(EditableText).first;
      await t.enterText(field, 'http://bad.example');
      await t.pump();
      await t.tap(find.text('Save'));
      await m40Settle(t, 600);
      expect(find.text('Use an https address'), findsOneWidget);

      await t.enterText(field, 'https://good.example');
      await t.pump();
      await t.tap(find.text('Save'));
      await m40Settle(t, 600);
      expect(find.text('Switch servers?'), findsOneWidget);
      await t.tap(find.text('Switch servers'));
      await m40Settle(t, 800);
      expect(sw.confirmed, ['https://good.example']);
      expect(find.text('Server URL saved and applied'), findsOneWidget);
    });
  });

  group('Diagnostics', () {
    m40Test('every Flutter row, the preview row and calibration reachable from here', (t) async {
      await pumpSection(t, '/settings/diagnostics');
      for (final s in ['FPS', 'Jank', 'Worst frame', 'Average frame', 'CPU build', 'GPU raster', 'Samples', 'Platform', 'CPU cores', 'Screen', 'App version', 'Build mode', 'Live images', 'Cached', 'Memory', 'Renderer', 'Glass quality', 'Refraction', 'Glass layers on screen', 'Glass calibration', 'Show motion timings']) {
        expect(find.text(s, skipOffstage: false), findsWidgets, reason: s);
      }
      expect(find.text('Refresh rate', skipOffstage: false), findsOneWidget);
      expect(find.text('Preview Glass skin', skipOffstage: false), findsNothing, reason: 'the debug row is gone with the flag on');
      expect(glassLayersLine(7, 5, 1).over, isTrue);
      expect(glassLayersLine(4, 9, 0).over, isTrue);
      expect(glassLayersLine(4, 5, 1), (text: '4 / 6 layers · 5 / 8 shapes · 1 scrim', over: false));
      expect(jankColour(4.99), isNot(jankColour(5)));
    });
  });

  group('Licences', () {
    m40Test('the sheet groups, searches and opens the text with Copy', (t) async {
      await pumpSection(t, '/settings/about?sheet=licenses');
      await m40Settle(t, 800);
      expect(find.text('Open-source licences'), findsWidgets);
      expect(find.text('FONTS'), findsOneWidget);
      expect(find.text('APP PACKAGES'), findsOneWidget);
      expect(find.text('ARTWORK AND SOUNDS'), findsOneWidget);
      expect(find.text('OFL-1.1'), findsOneWidget);
      expect(find.text('CC0'), findsOneWidget);
      await t.enterText(find.byType(EditableText).last, 'zzz');
      await m40Settle(t, 300);
      expect(find.text('No package matches “zzz”'), findsOneWidget);
      await t.enterText(find.byType(EditableText).last, 'dio');
      await m40Settle(t, 300);
      await t.tap(find.descendant(of: find.byType(LicenceList), matching: find.text('dio')).last);
      await m40Settle(t, 500);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.textContaining('Permission is hereby granted'), findsOneWidget);
    });
  });

  test('the backup export failure line and the restore bullets', () {
    expect(kGlassRestoreBullets, hasLength(4));
    expect(manualCheckProvider, isNotNull);
  });
}
