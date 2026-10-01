import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/admin/models/account.dart';
import 'package:manhwamaniacs/features/admin/providers/members_provider.dart';
import 'package:manhwamaniacs/features/admin/providers/status_providers.dart';
import 'package:manhwamaniacs/features/admin/utils/status_summary.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/models/auth_user.dart';
import 'package:manhwamaniacs/features/auth/models/user_session.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/auth/providers/sessions_provider.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/features/library/providers/daily_goal_provider.dart';
import 'package:manhwamaniacs/features/library/providers/numbers_providers.dart';
import 'package:manhwamaniacs/features/ocr/providers/ocr_providers.dart';
import 'package:manhwamaniacs/features/settings/models/backup_status.dart';
import 'package:manhwamaniacs/features/settings/providers/backup_provider.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/settings/providers/source_cache_ttl_provider.dart';
import 'package:manhwamaniacs/features/settings/utils/licenses.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/providers/discover_providers.dart' show sourcesHealthProvider;
import 'package:manhwamaniacs/features/updates/models/update_settings.dart';
import 'package:manhwamaniacs/skins/glass/dev/auth_fixtures.dart' show FakeAuth;
import 'package:manhwamaniacs/skins/glass/screens/settings/licenses_sheet.dart';

import '../../../support/numbers_fixtures.dart' show dailyRows;

/// mobile/40's fixtures: the You hub's data, the admin settings and System status, all without a network.

class M40Auth extends FakeAuth {
  M40Auth(bool admin, {this.passwordError}) : super(AuthAuthenticated(AuthUser(id: 1, username: 'yash', isAdmin: admin, createdAt: DateTime.utc(2026))));
  final AppError? passwordError;

  @override
  Future<AppError?> changePassword({required String currentPassword, required String newPassword}) async {
    FakeAuth.calls.add('change-password');
    return passwordError;
  }

  @override
  Future<AppError?> logoutEverywhere() async {
    FakeAuth.calls.add('logout-everywhere');
    state = const AuthUnauthenticated();
    return null;
  }
}

class _Members extends CircleMembersNotifier {
  _Members(this.list);
  final List<CircleMember> list;
  @override
  Future<List<CircleMember>> build() async => list;
}

class _Feed extends CircleFeedNotifier {
  @override
  Future<CircleFeedState> build(String? arg) async => CircleFeedState(items: [
        for (var i = 0; i < 4; i++)
          FeedItem(id: '$i', kind: FeedKind.finishedChapter, actor: ProfileRef(profileId: 10 + i, name: ['Aarav', 'Mira', 'Kenji', 'Noor'][i], avatarKey: 'violet'), sourceId: 'shelf', seriesKey: 's$i', title: ['Solo Leveling', 'Omniscient Reader', 'Blue Hour', 'Frost'][i], chapterNumber: 12.0 + i),
      ],);
}

class _Sharing extends SharingNotifier {
  _Sharing(this.on);
  final bool on;
  @override
  Future<Sharing> build(int arg) async => Sharing(activity: on);
}

class _Ttl extends SourceCacheTtlNotifier {
  @override
  Future<int> build() async => 360;
}

final DateTime m40Now = DateTime(2026, 10, 1, 21);

List<CircleMember> m40Circle() => [
      const CircleMember(profileId: 10, name: 'Aarav', avatarKey: 'violet', now: CircleNow(sourceId: 'shelf', seriesKey: 's0', chapterKey: 'c1', title: 'Solo Leveling')),
      CircleMember(profileId: 11, name: 'Mira', avatarKey: 'cyan', lastActiveAt: DateTime.now()),
      const CircleMember(profileId: 12, name: 'Kenji', avatarKey: 'rose'),
    ];

LibraryStatistics m40Stats({int streak = 12}) => LibraryStatistics.fromJson({
      'daily': dailyRows(DateTime(2026, 10), 7),
      'streak': {'current_days': streak, 'longest_days': 20},
    });

/// The You hub's providers.
List<Override> youOverrides({bool admin = true, bool sharing = true, int streak = 12, bool statsError = false, bool statsOffline = false, bool withAuth = true}) => [
      if (withAuth) authControllerProvider.overrideWith(() => M40Auth(admin)),
      numbersStatisticsProvider.overrideWith((ref, days) async {
        if (statsError) throw StateError('stats');
        return NumbersLoad(m40Stats(streak: streak), offline: statsOffline);
      }),
      activeDailyGoalMinutesProvider.overrideWith((ref) => 20),
      circleMembersProvider.overrideWith(() => _Members(m40Circle())),
      circleFeedProvider.overrideWith(_Feed.new),
      sharingProvider.overrideWith(() => _Sharing(sharing)),
      ocrFeatureVisibleProvider.overrideWithValue(true),
    ];

final List<Account> m40Accounts = [
  Account(id: 1, username: 'yash', isAdmin: true, isActive: true, createdAt: DateTime.utc(2026, 7, 27), lastLoginAt: DateTime.now(), sessionCount: 2),
  Account(id: 2, username: 'aarav', isAdmin: false, isActive: true, createdAt: DateTime.utc(2026, 7, 28), lastLoginAt: DateTime.now().subtract(const Duration(hours: 2)), sessionCount: 2),
  Account(id: 3, username: 'mira', isAdmin: false, isActive: false, createdAt: DateTime.utc(2026, 8, 2), lastLoginAt: null, sessionCount: 0),
];

final List<UserSession> m40Sessions = [
  UserSession(id: 1, createdAt: DateTime.utc(2026, 9, 12), lastUsedAt: DateTime.now(), expiresAt: DateTime.utc(2026, 12, 11), isCurrent: true, userAgent: 'Dart/3.9 (dart:io)', ipAddress: '10.0.0.2'),
  UserSession(id: 2, createdAt: DateTime.utc(2026, 9, 20), lastUsedAt: DateTime.now().subtract(const Duration(hours: 3)), expiresAt: DateTime.utc(2026, 12, 19), isCurrent: false, userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15', ipAddress: '10.0.0.5'),
];

UpdateSettings m40UpdateSettings({DateTime? lastRun, bool enabled = true}) =>
    UpdateSettings(enabled: enabled, checkIntervalMinutes: 30, notifyEnabled: true, checkOnStartup: false, lastRunAt: lastRun ?? DateTime.now().subtract(const Duration(minutes: 12)));

List<UpdateRun> m40Runs() => [
      UpdateRun(id: 3, trigger: 'scheduled', status: 'completed', seriesChecked: 142, newChaptersFound: 5, startedAt: DateTime.now().subtract(const Duration(minutes: 12))),
      UpdateRun(id: 2, trigger: 'manual', status: 'failed', seriesChecked: 40, newChaptersFound: 0, error: 'source timeout: shelf', startedAt: DateTime.now().subtract(const Duration(hours: 1))),
    ];

List<SourceSummary> m40Sources({bool problems = true, DateTime? probed}) => [
      SourceSummary.fromJson({'id': 'shelf', 'name': 'Shelf', 'description': '', 'browsable': true, 'supports_import': false, 'health': {'status': 'ok', 'consecutive_failures': 0, 'last_checked_at': (probed ?? DateTime.now()).toUtc().toIso8601String()}}),
      if (problems) SourceSummary.fromJson({'id': 'lantern', 'name': 'Lantern', 'description': '', 'browsable': true, 'supports_import': false, 'health': {'status': 'failing', 'consecutive_failures': 3, 'demoted': true, 'last_error': 'HTTP 503 from lantern.example', 'last_checked_at': (probed ?? DateTime.now()).toUtc().toIso8601String()}}),
    ];

/// System status and the admin settings sections.
List<Override> adminOverrides({bool admin = true, bool problems = false, bool backendDown = false, AppError? passwordError}) => [
      authControllerProvider.overrideWith(() => M40Auth(admin, passwordError: passwordError)),
      backendHealthProvider.overrideWith((ref) => Stream.value(BackendPoll(
            health: backendDown ? deriveBackendHealth(failed: true, networkFailure: true) : deriveBackendHealth(probe: const BackendProbe(status: 'online', name: 'ManhwaManiacs', version: '3.5.0')),
            nextPollAt: DateTime.now().add(kBackendPollEvery),
          ),),),
      updateSettingsProvider.overrideWith((ref) async => m40UpdateSettings()),
      updateRunsProvider.overrideWith((ref) async => m40Runs()),
      sourcesHealthProvider.overrideWith((ref) async => m40Sources(problems: problems)),
      sourceCacheTtlProvider.overrideWith(_Ttl.new),
      membersProvider.overrideWith((ref) async => m40Accounts),
      authSessionsProvider.overrideWith((ref) async => m40Sessions),
      backupStatusProvider.overrideWith((ref) async => BackupStatus(restorePending: false, nightly: NightlyBackup(ok: true, finishedAt: DateTime(2026, 10, 1, 3, 10), bytes: 42 * 1024 * 1024))),
      settingsApiUrlProvider.overrideWith((ref) async => 'https://mm.example.org'),
      licenceGroupsProvider.overrideWith((ref) async => m40Licences),
    ];

const List<LicenceGroup> m40Licences = [
  LicenceGroup('Fonts', [LicenceItem(name: 'Google Sans Flex', version: null, tag: 'OFL-1.1', text: 'Copyright 2024 Google\n\nSIL OPEN FONT LICENSE Version 1.1')]),
  LicenceGroup('App packages', [
    LicenceItem(name: 'dio', version: '5.8.0', tag: 'MIT', text: 'Permission is hereby granted, free of charge, to any person obtaining a copy'),
    LicenceItem(name: 'go_router', version: '14.8.1', tag: 'BSD-3-Clause', text: 'Redistribution and use in source and binary forms'),
  ]),
  LicenceGroup('Artwork and sounds', [LicenceItem(name: 'Glass UI sounds', version: null, tag: 'CC0', text: 'Synthesized with sox for ManhwaManiacs, CC0')]),
];

/// A widget test that leaves nothing mounted: the shell's autoDispose providers and metrics watcher are released inside the body
/// (the binding checks for pending timers before tear-downs run).
void m40Test(String description, Future<void> Function(WidgetTester t) body) => testWidgets(description, (t) async {
      await body(t);
      await m40Clear(t);
    });

/// Unmounts the current tree and flushes the scheduled provider disposals.
Future<void> m40Clear(WidgetTester t) async {
  await t.pumpWidget(const SizedBox.shrink());
  await t.pump(const Duration(milliseconds: 100));
}

/// Debugging: every visible text.
void m40Dump(String tag) {
  final texts = <String>[
    for (final e in find.byType(RichText, skipOffstage: false).evaluate()) (e.widget as RichText).text.toPlainText(),
  ];
  // ignore: avoid_print
  print('DUMP $tag: ${texts.join(' | ')}');
}

/// Pumps [ms] in 50 ms frames.
Future<void> m40Settle(WidgetTester t, [int ms = 1000]) async {
  for (var e = 0; e < ms; e += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}
