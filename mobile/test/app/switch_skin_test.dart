import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/app/app_restart.dart';
import 'package:manhwamaniacs/app/skin_boot.dart';
import 'package:manhwamaniacs/app/switch_skin.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/profiles/providers/skin_outbox.dart';
import 'package:manhwamaniacs/features/profiles/repositories/profiles_repository.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Active extends ActiveProfileNotifier {
  @override
  ActiveProfile? build() => const ActiveProfile(
      id: 7, name: 'T', avatarKey: null, mood: Mood.neutral,);
}

Future<(SharedPreferences, VoidCallback, int Function())> _host(
  WidgetTester tester,
  Future<void> Function(BuildContext, WidgetRef) onTap, {
  Map<String, Object> initial = const {},
}) async {
  SharedPreferences.setMockInitialValues({...initial});
  final prefs = await SharedPreferences.getInstance();
  var builds = 0;
  await tester.pumpWidget(
    AppRestart(builder: () {
      builds++;
      return ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          activeProfileProvider.overrideWith(_Active.new),
          // No network: the fake outbox never flushes.
          skinOutboxProvider.overrideWithValue(_NoFlushOutbox(prefs)),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => Consumer(
                builder: (context, ref, _) => TextButton(
                  onPressed: () => onTap(context, ref),
                  child: const Text('go'),
                ),
              ),
            ),
          ],),
        ),
      );
    },),
  );
  return (prefs, () {}, () => builds);
}

class _NoFlushOutbox extends SkinOutbox {
  _NoFlushOutbox(SharedPreferences p) : super(p, _Nope());
  @override
  Future<void> flush() async {}
}

class _Nope implements ProfilesRepository {
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

void main() {
  testWidgets(
      'switchSkin orders t0 and outbox, then outgoing, then mirror and restart',
      (tester) async {
    late SharedPreferences prefs;
    final log = <String>[];
    late int Function() builds;
    (prefs, _, builds) = await _host(tester, (context, ref) async {
      await switchSkin(context, ref, to: SkinId.cinematic, outgoing: () async {
        log.add(
            'outgoing t0=${prefs.containsKey(kSkinT0Key)} outbox=${prefs.getString(kSkinOutboxKey) != null} '
            'mirror=${prefs.containsKey(kSkinActiveKey)} return=${prefs.containsKey(kSkinReturnKey)}');
        await Future<void>.delayed(const Duration(milliseconds: 500));
      },);
    });
    await tester.tap(find.text('go'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(log, ['outgoing t0=true outbox=true mirror=false return=false']);
    expect(prefs.getString(kSkinActiveKey), 'cinematic');
    expect(prefs.getString(kSkinReturnKey), isNotNull);
    expect(builds(), 2);
  });

  testWidgets(
      'debugSwitchSkin writes the override, never the outbox; clear removes it',
      (tester) async {
    late SharedPreferences prefs;
    late int Function() builds;
    (prefs, _, builds) =
        await _host(tester, (c, r) => debugSwitchSkin(c, r, SkinId.cinematic));
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    expect(prefs.getString(kSkinDebugKey), 'cinematic');
    expect(prefs.getString(kSkinReturnKey), '/settings/diagnostics');
    expect(prefs.getString(kSkinOutboxKey), isNull);
    expect(builds(), 2);
  });

  testWidgets('Clear override removes the key', (tester) async {
    late SharedPreferences prefs;
    late int Function() builds;
    (prefs, _, builds) = await _host(
        tester, (c, r) => debugSwitchSkin(c, r, null),
        initial: {kSkinDebugKey: 'cinematic'},);
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    expect(prefs.containsKey(kSkinDebugKey), isFalse);
    expect(builds(), 2);
  });

  testWidgets('the curtain lasts 200 ms and fades linearly', (tester) async {
    var done = false;
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (c) {
      ctx = c;
      return const SizedBox();
    },),),);
    unawaited(showRestartCurtain(ctx).then((_) => done = true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(done, isFalse);
    final o = tester
        .widget<FadeTransition>(find.byType(FadeTransition).last)
        .opacity
        .value;
    expect(o, closeTo(0.5, 0.05));
    await tester.pump(const Duration(milliseconds: 100));
    expect(done, isTrue);
  });

  test('SkinRestartTiming logs 1,212 ms, clears t0 and stores the last',
      () async {
    SharedPreferences.setMockInitialValues({kSkinT0Key: 1000});
    final prefs = await SharedPreferences.getInstance();
    final lines = <String>[];
    final old = debugPrint;
    debugPrint = (m, {wrapWidth}) => lines.add(m ?? '');
    addTearDown(() => debugPrint = old);
    SkinRestartTiming.logFirstFrame(prefs,
        now: () => DateTime.fromMillisecondsSinceEpoch(2212),);
    expect(lines.single, contains('1,212 MS'));
    expect(prefs.containsKey(kSkinT0Key), isFalse);
    expect(prefs.getInt(kSkinRestartLastKey), 1212);
    // Nothing pending: no change.
    SkinRestartTiming.logFirstFrame(prefs,
        now: () => DateTime.fromMillisecondsSinceEpoch(9999),);
    expect(prefs.getInt(kSkinRestartLastKey), 1212);
  });
}
