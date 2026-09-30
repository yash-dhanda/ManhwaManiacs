import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/circle/circle_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/circle/circle_tabs.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/circle_member/circle_member_screen.dart';

import '../../../features/circle/fakes.dart';
import '../support/cine_harness.dart';

export '../../../features/circle/fakes.dart';
export '../../../screenshots/support/shot_harness.dart' show loadAppFonts;
export '../support/cine_harness.dart';

/// A router with the Circle's routes and stubs for where they lead.
GoRouter circleRouter({String initial = '/circle', Widget? screen}) => GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(path: '/', builder: (_, __) => const Scaffold(body: Text('HOME'))),
        GoRoute(path: '/circle', builder: (_, s) => screen ?? CircleScreen(initialTab: circleTabFromQuery(s.uri.queryParameters['tab']))),
        GoRoute(path: '/circle/:profileId', builder: (_, s) => CircleMemberScreen(profileId: int.parse(s.pathParameters['profileId']!))),
        GoRoute(path: '/sources/:sourceId/series/:seriesKey', builder: (_, s) => Scaffold(body: Text('FEATURE ${s.pathParameters['seriesKey']}'))),
        GoRoute(path: '/settings/:section', builder: (_, s) => Scaffold(body: Text('SETTINGS ${s.pathParameters['section']}'))),
        GoRoute(path: '/library/collections', builder: (_, __) => const Scaffold(body: Text('COLLECTIONS'))),
        GoRoute(path: '/library/collections/:id', builder: (_, s) => Scaffold(body: Text('COLLECTION ${s.pathParameters['id']}'))),
      ],
    );

Future<void> pumpCircle(
  WidgetTester tester,
  FakeCircleRepository repo, {
  CineTestEnv? env,
  String initial = '/circle',
  Size size = const Size(390, 844),
  TargetPlatform platform = TargetPlatform.iOS,
  bool reduced = false,
  double textScale = 1.0,
  List<Override> extra = const [],
}) =>
    pumpCine(
      tester,
      env ?? CineTestEnv(),
      router: circleRouter(initial: initial),
      size: size,
      platform: platform,
      reduced: reduced,
      textScale: textScale,
      extra: [circleRepositoryProvider.overrideWithValue(repo), ...extra],
    );

Future<void> settle(WidgetTester tester, [int ms = 1500]) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  await pumpMs(tester, ms);
}

/// The device's connectivity, fixed.
Override deviceOnlineOverride(bool online) => deviceOnlineProvider.overrideWith((ref) => Stream.value(online));
