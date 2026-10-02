// ignore_for_file: directives_ordering, unawaited_futures, avoid_dynamic_calls
import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/models/auth_user.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/auth/providers/sessions_provider.dart';
import 'package:manhwamaniacs/features/settings/models/backup_status.dart';
import 'package:manhwamaniacs/features/settings/services/server_switch.dart';
import 'package:manhwamaniacs/features/setup/utils/server_check.dart';
import 'package:manhwamaniacs/skins/cinematic/overlays/stop_the_press.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_switch.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toast_host.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/edition/edition_picker.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/pages/licenses_page.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/skin_audio.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../skins/cinematic/downloads/downloads_rig.dart' show rigTheme;
import '../../skins/cinematic/settings/settings_rig.dart';
import '../support/shot_harness.dart';
import '../support/skin_shots.dart';

/// mobile/18 proof: Cinematic Settings on phone (390 x 844), tablet (834 x 1194, one pane) and
/// tablet-wide (1024 x 1366, two panes), plus the edition picker, Stop the press frozen in time and
/// the pushed pages. Written to `docs/redesign/proof/mobile-18/{screen}-{state}-{size}.png`:
///
///   MM_PROOF_DIR=../docs/redesign/proof/mobile-18 flutter test \
///     test/screenshots/cinematic/mobile_18_settings_shots_test.dart
///
/// Titles, names and accounts are invented. The test host draws with the bundled brand fonts.
const _phone = SkinShotSize('phone', Size(390, 844), 2.0, EdgeInsets.only(top: 47, bottom: 34));
const _tablet = SkinShotSize('tablet', Size(834, 1194), 1.5, EdgeInsets.only(top: 24, bottom: 20));
const _wide = SkinShotSize('tablet-wide', Size(1024, 1366), 1.5, EdgeInsets.only(top: 24, bottom: 20));
const _sizes = [_phone, _tablet, _wide];

class _Configurator implements SessionConfigurator {
  @override
  Future<void> configure(AudioSessionConfiguration c) async {}
  @override
  Future<void> setActive(bool a) async {}
}

class _Engine implements CueEngine {
  @override
  Future<void> init() async {}
  @override
  Future<dynamic> loadAsset(String path) async => path;
  @override
  Future<dynamic> play(dynamic source, {required double volume}) async => 1;
  @override
  void setRelativePlaySpeed(dynamic handle, double rate) {}
}

class _Auth extends AuthController {
  @override
  AuthState build() => AuthAuthenticated(AuthUser(id: 1, username: 'tester', isAdmin: true, createdAt: DateTime.utc(2024)));

  @override
  Future<AppError?> changePassword({required String currentPassword, required String newPassword}) async =>
      const ApiError(statusCode: 429, code: 'rate_limited', message: 'slow down', retryAfter: Duration(seconds: 14));
}

class _Switch implements ServerSwitch {
  @override
  Future<ServerCheck> check(String input) async => ServerCheck.ok(input.trim());
  @override
  String get current => 'https://manhwamaniacs.xyz';
  @override
  bool isSame(String u) => false;
  @override
  Future<AppError?> confirm(String u) async => null;
  @override
  Future<AppError?> reset() async => null;
}

Future<void> _reveal(WidgetTester t, Finder f) async {
  Scrollable.ensureVisible(t.element(f.first), alignment: 0.4);
  await t.pump();
  await t.pump(const Duration(milliseconds: 60));
}

Future<void> _tap(WidgetTester t, Finder f, {int ms = 600}) async {
  await _reveal(t, f);
  await t.tap(f.first);
  for (var i = 0; i < ms; i += 100) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Widget _app(Widget screen, {bool reduced = false, TargetPlatform platform = TargetPlatform.android, String path = '/'}) => MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: rigTheme(platform),
      routerConfig: GoRouter(routes: [GoRoute(path: path, builder: (c, s) => screen), GoRoute(path: '/:rest(.*)', builder: (c, s) => const SizedBox())]),
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: reduced), child: CineToastHost(child: child!)),
    );

Widget _screen(String? slug, {bool licenses = false}) =>
    SettingsScreen(slug: slug, licenses: licenses, location: slug == null ? '/settings' : '/settings/$slug${licenses ? '?licenses=1' : ''}');

ProviderContainer _container(WidgetTester t) => ProviderScope.containerOf(t.element(find.byType(SettingsScreen).evaluate().isNotEmpty ? find.byType(SettingsScreen) : find.byType(MaterialApp)));

void main() {
  setUpAll(loadAppFonts);

  Future<void> shot(
    WidgetTester tester,
    String name,
    SkinShotSize size,
    Widget child, {
    SettingsRig? rig,
    bool reduced = false,
    TargetPlatform platform = TargetPlatform.android,
    List<Override> more = const [],
    Future<void> Function(WidgetTester)? drive,
    int settleMs = 2200,
  }) async {
    final r = rig ?? SettingsRig();
    const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(pathProvider, (call) async => Directory.systemTemp.path);
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(pathProvider, null));
    SharedPreferences.setMockInitialValues(r.prefs);
    final prefs = await SharedPreferences.getInstance();
    final audio = SkinAudio.forTest(_Configurator(), _Engine())..bind(skin: SkinId.cinematic, userId: 1, profileId: 1, prefs: prefs);
    await captureSkinWidget(
      tester,
      name: name,
      size: size,
      child: child,
      overrides: [...settingsOverrides(r, prefs, audio), ...more],
      disableAnimations: reduced,
      settle: (t) async {
        for (var i = 0; i < settleMs; i += 100) {
          await t.pump(const Duration(milliseconds: 100));
        }
        if (drive != null) await drive(t);
      },
    );
  }

  Future<void> everySize(WidgetTester t, String name, Widget Function() child, {String? tabletName, Future<void> Function(WidgetTester)? drive, SettingsRig? rig, bool reduced = false, List<SkinShotSize> sizes = _sizes}) async {
    for (final s in sizes) {
      await shot(t, name, s, child(), drive: drive, rig: rig, reduced: reduced);
    }
  }

  testWidgets('contents, search and the flashed row', (t) async {
    await everySize(t, 'settings-contents', () => _app(_screen(null)));
    await shot(t, 'settings-contents-reduced', _phone, _app(_screen(null), reduced: true), reduced: true);
    await shot(t, 'settings-search', _phone, _app(_screen(null)), drive: (t) async {
      await _tap(t, find.bySemanticsLabel('Search settings').first, ms: 500);
      await t.enterText(find.byType(EditableText), 'haptic');
      await t.pump(const Duration(milliseconds: 300));
    },);
    await shot(t, 'settings-search-empty', _phone, _app(_screen(null)), drive: (t) async {
      await _tap(t, find.bySemanticsLabel('Search settings').first, ms: 500);
      await t.enterText(find.byType(EditableText), 'zzzz');
      await t.pump(const Duration(milliseconds: 300));
    },);
    await shot(t, 'settings-search-jump', _phone, _app(_screen(null)), drive: (t) async {
      await _tap(t, find.bySemanticsLabel('Search settings').first, ms: 500);
      await t.enterText(find.byType(EditableText), 'haptic');
      await t.pump(const Duration(milliseconds: 300));
      await _tap(t, find.byKey(const Key('settings-result-haptics')), ms: 1200);
    },);
    await shot(t, 'settings-search-dropdown', _wide, _app(_screen(null)), drive: (t) async {
      await t.enterText(find.byType(EditableText), 'read');
      await t.pump(const Duration(milliseconds: 300));
    },);
    await shot(t, 'settings-search-ios', _phone, _app(_screen(null), platform: TargetPlatform.iOS), platform: TargetPlatform.iOS, drive: (t) async {
      await _tap(t, find.bySemanticsLabel('Search settings').first, ms: 500);
    },);
  });

  const slugs = ['profile', 'appearance', 'reading-manga', 'reading-novels', 'listen', 'ambient', 'storage', 'content', 'feedback', 'notifications', 'server', 'admin', 'diagnostics', 'about'];
  for (final slug in slugs) {
    testWidgets('section $slug', (t) async {
      await everySize(t, 'settings-$slug', () => _app(_screen(slug)));
    });
  }

  testWidgets('keyboard, security, members, backup and licences', (t) async {
    await shot(t, 'settings-keyboard', _tablet, _app(_screen('keyboard')));
    await shot(t, 'settings-keyboard', _wide, _app(_screen('keyboard')));
    for (final slug in ['security', 'members', 'backup']) {
      await everySize(t, 'settings-$slug', () => _app(_screen(slug)));
    }
    await shot(t, 'settings-licenses', _phone, _app(_screen('about', licenses: true)));
    await shot(t, 'settings-licenses-page', _phone, _app(const LicensesPage(preview: [
      ('BodoniModa', ['Copyright 2020 The Bodoni Moda Project Authors.', 'This Font Software is licensed under the SIL Open Font License, Version 1.1.']),
      ('phosphor_flutter', ['MIT License', 'Permission is hereby granted, free of charge, to any person obtaining a copy of this software.']),
      ('flutter_riverpod', ['MIT License']),
    ],),),);
  });

  testWidgets('states: no profile, loading, error, offline, reduced motion', (t) async {
    await shot(t, 'settings-no-profile', _phone, _app(_screen('reading-manga')), rig: SettingsRig(profile: false));
    await shot(t, 'settings-loading', _phone, _app(_screen('security')), more: [authSessionsProvider.overrideWith((ref) => Completer<List<Never>>().future.then((_) => throw StateError('never')))], settleMs: 400);
    await shot(t, 'settings-error', _phone, _app(_screen('security')), rig: SettingsRig(sessionsError: true));
    await shot(t, 'settings-offline', _phone, _app(_screen('notifications')), rig: SettingsRig(online: false));
    await shot(t, 'settings-appearance-reduced', _phone, _app(_screen('appearance'), reduced: true), reduced: true);
    await shot(t, 'settings-non-admin', _phone, _app(_screen('backup')), rig: SettingsRig(admin: false));
  });

  testWidgets('the 18+ certificate dialog', (t) async {
    await shot(t, 'settings-certificate', _phone, _app(_screen('content')), drive: (t) async {
      await _tap(t, find.byType(CineSwitch).first, ms: 900);
    },);
  });

  testWidgets('the edition picker: flag off, flag on, the sheet and the dialog', (t) async {
    await shot(t, 'settings-edition-off', _phone, _app(_screen('appearance')));
    Widget picker() => _app(const Scaffold(backgroundColor: Colors.black, body: SafeArea(child: SingleChildScrollView(padding: EdgeInsets.all(16), child: EditionPicker(glassAvailable: true)))));
    await shot(t, 'settings-edition-on', _phone, picker());
    await shot(t, 'settings-edition-on', _tablet, picker());
    await shot(t, 'settings-edition-confirm-sheet', _phone, picker(), drive: (t) async {
      await _tap(t, find.text('Switch to Glass'), ms: 800);
    },);
    await shot(t, 'settings-edition-confirm-dialog', _tablet, picker(), drive: (t) async {
      await _tap(t, find.text('Switch to Glass'), ms: 800);
    },);
  });

  testWidgets('Stop the press frozen at 100, 300 and 470 ms, the reduced fade and the failure toast', (t) async {
    for (final ms in [100.0, 300.0, 470.0]) {
      await shot(t, 'stop-the-press-${ms.round()}ms', _phone, _app(Stack(children: [_screen('appearance'), Positioned.fill(child: StopThePressFrame(ms: ms))])));
    }
    await shot(t, 'stop-the-press-380ms', _tablet, _app(Stack(children: [_screen('appearance'), const Positioned.fill(child: StopThePressFrame(ms: 380))])));
    await shot(t, 'stop-the-press-reduced-170ms', _phone, _app(Stack(children: [_screen('appearance'), const Positioned.fill(child: StopThePressFrame(ms: 170, reduced: true))]), reduced: true), reduced: true);
    await shot(t, 'stop-the-press-failure-toast', _phone, _app(_screen('appearance')), drive: (t) async {
      _container(t).read(cineToastsProvider.notifier).error("Couldn't switch editions. Try again.");
      await t.pump(const Duration(milliseconds: 600));
    },);
    await shot(t, 'settings-arrival-undo-toast', _phone, _app(_screen(null)), drive: (t) async {
      _container(t).read(cineToastsProvider.notifier).undo('Now in the Cinematic edition.', hold: CineDur.holdToastUndo, onUndo: () {});
      await t.pump(const Duration(milliseconds: 600));
    },);
  });

  testWidgets('security with rate_limited, the members delete dialog, the backup dialogs and progress', (t) async {
    await shot(t, 'settings-security-rate-limited', _phone, _app(_screen('security')), more: [authControllerProvider.overrideWith(_Auth.new)], drive: (t) async {
      final fields = find.byType(EditableText);
      await t.enterText(fields.at(0), 'old-password');
      await t.enterText(fields.at(1), 'new-password');
      await t.enterText(fields.at(2), 'new-password');
      await _tap(t, find.widgetWithText(CineButton, 'Change password'), ms: 500);
    },);
    await shot(t, 'settings-members-delete', _phone, _app(_screen('members')), drive: (t) async {
      await _tap(t, find.widgetWithText(CineButton, 'Delete').last, ms: 900);
    },);
    await shot(t, 'settings-backup-staged', _phone, _app(_screen('backup')), rig: SettingsRig(backup: BackupStatus(restorePending: true, nightly: NightlyBackup(ok: true, finishedAt: DateTime(2026, 9, 28, 3), bytes: 412 * 1024 * 1024))));
    await shot(t, 'settings-backup-failed', _phone, _app(_screen('backup')), rig: SettingsRig(backup: BackupStatus(restorePending: false, nightly: NightlyBackup(ok: false, finishedAt: DateTime(2026, 9, 28, 3), phase: 'dump'))));
  });

  testWidgets('server switch dialog, about on both platforms', (t) async {
    await shot(t, 'settings-server-switch', _phone, _app(_screen('server')), more: [serverSwitchProvider.overrideWithValue(_Switch())], drive: (t) async {
      await t.enterText(find.byType(EditableText), 'https://other.example');
      await _tap(t, find.widgetWithText(CineButton, 'Save'), ms: 1000);
    },);
    await shot(t, 'settings-server-error', _phone, _app(_screen('server')), drive: (t) async {
      await t.enterText(find.byType(EditableText), '');
      await _tap(t, find.widgetWithText(CineButton, 'Save'), ms: 400);
    },);
    await shot(t, 'settings-about-android', _phone, _app(_screen('about')));
    await shot(t, 'settings-about-ios', _phone, _app(_screen('about'), platform: TargetPlatform.iOS), platform: TargetPlatform.iOS);
  });
}
