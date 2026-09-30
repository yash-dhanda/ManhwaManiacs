import 'package:flutter/material.dart' show TextField;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/network/network_connectivity.dart';
import 'package:manhwamaniacs/features/setup/utils/server_check.dart';
import 'package:manhwamaniacs/features/setup/utils/server_check_provider.dart';
import 'package:manhwamaniacs/skins/glass/dev/auth_fixtures.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';

import '../../../screenshots/support/shot_harness.dart';
import 'auth_rig.dart';

Future<void> _enter(WidgetTester t, String url) async {
  await t.enterText(find.byType(TextField), url);
  await t.pump();
}

Future<void> _connect(WidgetTester t) async {
  await t.tap(find.text('Connect'));
  await t.pump();
  await t.pump(const Duration(milliseconds: 50));
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('the URL keyboard, the go action and the exact copy', (t) async {
    await pumpAuth(t, '/setup', const GlassAuthFixture(), setupDone: false);
    final field = t.widget<TextField>(find.byType(TextField));
    expect(field.keyboardType, TextInputType.url);
    expect(field.textInputAction, TextInputAction.go);
    expect(field.autocorrect, isFalse);
    expect(find.text('Server address'), findsOneWidget);
    expect(find.text('https://manhwamaniacs.example'), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget);
    await settleFor(t, 1500);
    expect(find.text('Connect your server'), findsWidgets);
  });

  for (final (check, line) in [
    (const ServerCheck.notManhwaManiacs(), "That address isn't a ManhwaManiacs server"),
    (const ServerCheck.tls(), "The server's certificate isn't trusted. Check the address or the server's HTTPS setup."),
    (const ServerCheck.timeout(), "Couldn't reach that address"),
    (const ServerCheck.httpInRelease(), 'Use an https address'),
  ]) {
    testWidgets('a failed check shows "$line" under the field', (t) async {
      await pumpAuth(t, '/setup', GlassAuthFixture(serverCheck: check), setupDone: false);
      await _enter(t, 'https://nope.example');
      await _connect(t);
      await settleFor(t, 500);
      expect(find.text(line), findsOneWidget);
    });
  }

  testWidgets('offline: the line shows and Connect is disabled', (t) async {
    await pumpAuth(t, '/setup', const GlassAuthFixture(serverCheck: ServerCheck.offline()), setupDone: false);
    await _enter(t, 'https://mm.example');
    await _connect(t);
    await settleFor(t, 500);
    expect(find.text("You're offline. Connect to a network to reach your server."), findsWidgets);
    expect(t.widget<GlassButton>(find.byType(GlassButton).first).onPressed, isNull);
  });

  testWidgets('offline, then the connection returns: the check runs again by itself', (t) async {
    var calls = 0;
    await pumpAuth(
      t,
      '/setup',
      const GlassAuthFixture(),
      setupDone: false,
      extra: [
        networkOnlineChangesProvider.overrideWith((ref) => Stream<bool>.fromIterable([false]).asyncExpand((v) async* {
              yield v;
              await Future<void>.delayed(const Duration(seconds: 4));
              yield true;
            }),),
        serverCheckProvider.overrideWithValue((input) async {
          calls++;
          return const ServerCheck.ok('https://mm.example');
        }),
      ],
    );
    await _enter(t, 'https://mm.example');
    await settleFor(t, 5000);
    await settleFor(t, 500);
    expect(calls, greaterThan(0));
  });

  testWidgets('a good address runs the Address drain and opens onto Login', (t) async {
    final rig = await pumpAuth(t, '/setup', const GlassAuthFixture(), setupDone: false);
    await _enter(t, 'https://mm.example');
    await _connect(t);
    await settleFor(t, 300);
    await settleFor(t, 3000);
    expect(rig.at, '/login');
  });

  testWidgets('reduced motion: a cross-fade to Login', (t) async {
    final rig = await pumpAuth(t, '/setup', const GlassAuthFixture(), setupDone: false, reduced: true);
    await _enter(t, 'https://mm.example');
    await _connect(t);
    await settleFor(t, 600);
    expect(rig.at, '/login');
  });
}
