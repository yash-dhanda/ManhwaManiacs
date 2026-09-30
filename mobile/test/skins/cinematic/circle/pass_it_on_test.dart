import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/pass_it_on_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';

import 'circle_harness.dart';

Future<void> _open(WidgetTester tester, FakeCircleRepository repo, {CineTestEnv? env, int? preselect, List<Override> extra = const [], TargetPlatform platform = TargetPlatform.iOS}) async {
  await pumpCine(
    tester,
    env ?? CineTestEnv(),
    router: circleRouter(
      screen: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showPassItOnSheet(context, sourceId: 's', seriesKey: 'or', title: 'Omniscient Reader', preselectProfileId: preselect),
            child: const Text('OPEN'),
          ),
        ),
      ),
    ),
    platform: platform,
    extra: [circleRepositoryProvider.overrideWithValue(repo), ...extra],
  );
  await tester.tap(find.text('OPEN'));
  await settle(tester, 700);
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('only members who can receive are listed', (tester) async {
    await _open(tester, FakeCircleRepository(membersList: [member(riya, canReceive: true), member(arjun, canReceive: false)]));
    expect(find.text('Riya'), findsOneWidget);
    expect(find.text('Arjun'), findsNothing);
    expect(find.text('Recommend'), findsWidgets);
  });

  testWidgets('the counter reads 12 / 140 and the note stops at 140', (tester) async {
    await _open(tester, FakeCircleRepository(membersList: [member(riya, canReceive: true)]));
    await tester.enterText(find.byType(TextField), 'Twelve chars');
    await tester.pump();
    expect(find.text('12 / 140'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'x' * 200);
    await tester.pump();
    expect(find.text('140 / 140'), findsOneWidget);
  });

  testWidgets('Send needs a recipient, sends the letter with the haptic and the toast', (tester) async {
    final repo = FakeCircleRepository(membersList: [member(riya, canReceive: true), member(arjun, canReceive: true)]);
    final env = CineTestEnv();
    await _open(tester, repo, env: env);
    expect(tester.widget<CineButton>(find.byKey(const Key('pass-send'))).onPressed, isNull);
    await tester.tap(find.byKey(const ValueKey('recipient-2')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('recipient-3')));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'you will love it');
    await tester.tap(find.byKey(const Key('pass-send')));
    await settle(tester, 600);
    expect(repo.sent.single.to, [2, 3]);
    expect(repo.sent.single.note, 'you will love it');
    expect(env.haptics.events.map((e) => e.id), contains('recommend.send'));
    expect(find.text('Sent to Riya and Arjun.'), findsOneWidget);
  });

  testWidgets('a 409 recipient_unavailable deselects that member and keeps the note', (tester) async {
    final repo = FakeCircleRepository(membersList: [member(riya, canReceive: true), member(arjun, canReceive: true)])
      ..failSend = const ApiError(statusCode: 409, code: 'recipient_unavailable', message: 'x', details: {'profile_ids': [2]});
    await _open(tester, repo, preselect: 2);
    await tester.enterText(find.byType(TextField), 'keep me');
    await tester.tap(find.byKey(const Key('pass-send')));
    await settle(tester, 600);
    expect(find.text("Riya isn't taking recommendations any more."), findsOneWidget);
    expect(find.byKey(const ValueKey('recipient-2')), findsNothing);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'keep me');
  });

  testWidgets('nobody eligible: the line, Send disabled', (tester) async {
    await _open(tester, FakeCircleRepository(membersList: [member(riya, canReceive: false)]));
    expect(find.text('Nobody is taking recommendations right now.'), findsOneWidget);
    expect(tester.widget<CineButton>(find.byKey(const Key('pass-send'))).onPressed, isNull);
  });

  testWidgets('offline: Send is disabled with its caption', (tester) async {
    await _open(tester, FakeCircleRepository(membersList: [member(riya, canReceive: true)]), preselect: 2, extra: [deviceOnlineOverride(false)]);
    expect(find.text('Sending needs a connection.'), findsOneWidget);
    expect(tester.widget<CineButton>(find.byKey(const Key('pass-send'))).onPressed, isNull);
  });

  testWidgets('a failure toasts and keeps the sheet open', (tester) async {
    final repo = FakeCircleRepository(membersList: [member(riya, canReceive: true)])..failSend = const NetworkError(message: 'x');
    await _open(tester, repo, preselect: 2);
    await tester.tap(find.byKey(const Key('pass-send')));
    await settle(tester, 600);
    expect(find.text("Couldn't send to Riya. Try again."), findsOneWidget);
    expect(find.byKey(const Key('pass-send')), findsOneWidget);
  });

  testWidgets('hit targets: the toggles and Send are at least 44 on iOS and 48 on Android', (tester) async {
    for (final p in [TargetPlatform.iOS, TargetPlatform.android]) {
      await _open(tester, FakeCircleRepository(membersList: [member(riya, canReceive: true), member(arjun, canReceive: true)]), platform: p);
      final min = p == TargetPlatform.iOS ? 44.0 : 48.0;
      for (final id in [2, 3]) {
        final r = tester.getRect(find.byKey(ValueKey('recipient-$id')));
        expect(r.width, greaterThanOrEqualTo(min));
        expect(r.height, greaterThanOrEqualTo(min));
      }
      expect(tester.getSize(find.byKey(const Key('pass-send'))).height, greaterThanOrEqualTo(min - 0.01));
      await tester.pumpWidget(const SizedBox());
    }
  });
}
