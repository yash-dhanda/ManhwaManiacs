// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/setup/utils/server_check.dart';
import 'package:manhwamaniacs/features/setup/utils/server_check_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/auth/auth_copy.dart';

import 'auth_test_support.dart';

Override _check(ServerCheck r) => serverCheckProvider.overrideWithValue((_) async => r);

Future<void> _connect(WidgetTester t, {String url = 'https://lib.example'}) async {
  await t.enterText(find.byType(TextField), url);
  await t.tap(find.text('Connect'));
  await t.pump();
}

void main() {
  for (final (platform, action) in [(TargetPlatform.android, TextInputAction.go), (TargetPlatform.iOS, TextInputAction.done)]) {
    testWidgets('the field takes a URL keyboard and the ${action.name} action on $platform', (t) async {
      await pumpAuth(t, start: '/setup', setupDone: false, platform: platform, extra: [_check(const ServerCheck.offline())]);
      final field = t.widget<TextField>(find.byType(TextField));
      expect(field.keyboardType, TextInputType.url);
      expect(field.textInputAction, action);
      expect(field.autocorrect, isFalse);
      expect(field.enableSuggestions, isFalse);
      expect(field.textCapitalization, TextCapitalization.none);
      expect(find.text(kSetupRelease), findsOneWidget, reason: 'the https rule is shown in release builds');
    });
  }

  final failures = <ServerCheck, String>{
    const ServerCheck.offline(): 'This phone is offline. Connect, then try again.',
    const ServerCheck.notManhwaManiacs(): "That address isn't a ManhwaManiacs server.",
    const ServerCheck.tls(): "The server's certificate isn't valid, so the connection was refused.",
    const ServerCheck.httpInRelease(): "Use an https:// address. Plain http isn't allowed in release builds.",
    const ServerCheck.timeout(): 'The server took too long to answer.',
    const ServerCheck.unreachable('x'): 'No ManhwaManiacs server answered at this address.',
  };
  for (final e in failures.entries) {
    testWidgets('a failed check says why: ${e.value}', (t) async {
      await pumpAuth(t, start: '/setup', setupDone: false, extra: [_check(e.key)]);
      await _connect(t);
      await t.pump(const Duration(milliseconds: 50));
      expect(find.text('‸ ${e.value}'), findsOneWidget);
      expect(t.widget<TextField>(find.byType(TextField)).enabled, isTrue, reason: 'the field is live again');
    });
  }

  testWidgets('success: the check holds 400 ms, the rule moves, then setup is completed and Login follows', (t) async {
    final rig = await pumpAuth(
      t,
      start: '/setup',
      setupDone: false,
      gated: true,
      extra: [_check(const ServerCheck.ok('https://lib.example'))],
    );
    expect(rig.at, '/setup');
    await _connect(t);
    await t.pump(const Duration(milliseconds: 200));
    expect(rig.container.read(preferencesProvider).setupCompleted, isFalse, reason: 'still holding the check');
    await t.pump(const Duration(milliseconds: 300));
    await t.pump(const Duration(milliseconds: 300)); // the rule slides
    await t.pump(const Duration(milliseconds: 400));
    await settle(t, 1500);
    expect(rig.container.read(preferencesProvider).setupCompleted, isTrue);
    expect(rig.container.read(apiBaseUrlProvider), 'https://lib.example');
    expect(rig.at, '/login');
  });

  testWidgets('reduced motion: a fade, no rule move, same outcome', (t) async {
    final rig = await pumpAuth(
      t,
      start: '/setup',
      setupDone: false,
      gated: true,
      reduced: true,
      extra: [_check(const ServerCheck.ok('https://lib.example'))],
    );
    await _connect(t);
    await settle(t, 1500);
    expect(rig.at, '/login');
  });
}
