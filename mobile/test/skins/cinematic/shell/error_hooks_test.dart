import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/app/app_restart.dart';
import 'package:manhwamaniacs/core/error/error_log.dart';
import 'package:manhwamaniacs/core/error/fatal_error.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/app_frame.dart';
import 'package:manhwamaniacs/skins/cinematic/cinematic_skin.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/typed_headline.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/system/cine_broken_part.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Boom extends StatelessWidget {
  const _Boom();
  @override
  Widget build(BuildContext context) => throw StateError('boom');
}

var _builds = 0;

Future<void> _pump(WidgetTester t, {required bool release, Widget page = const Scaffold(body: Text('fine'))}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  _builds = 0;
  await t.pumpWidget(AppRestart(builder: () {
    _builds++;
    return ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        skinIdProvider.overrideWithValue(SkinId.cinematic),
        skinRouterProvider.overrideWith((ref) => GoRouter(routes: [GoRoute(path: '/', builder: (c, s) => page)])),
      ],
      child: Consumer(builder: (context, ref, _) => MaterialApp.router(
        theme: CinematicSkin.baseTheme,
        routerConfig: ref.read(skinRouterProvider),
        builder: (context, child) => CineAppFrame(releaseErrorWidget: release, splash: false, child: child!),
      ),),
    );
  },),);
  await t.pump();
}

void main() {
  tearDown(() {
    appFatalError.value = null;
    appErrorLog.clear();
  });

  testWidgets('with releaseErrorWidget a child that throws renders the CORRECTION line', (t) async {
    await _pump(t, release: true, page: const Scaffold(body: Column(children: [Text('above'), _Boom()])));
    expect(t.takeException(), isA<StateError>());
    expect(find.byType(CineBrokenPart), findsOneWidget);
    expect(find.text('CORRECTION · This part of the page broke.'), findsOneWidget);
    expect(find.text('above'), findsOneWidget);
    // A build error is replaced in place: the notice is not raised over the app.
    expect(appFatalError.value, isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('debug keeps Flutter\'s red screen', (t) async {
    await _pump(t, release: false, page: const Scaffold(body: _Boom()));
    expect(t.takeException(), isA<StateError>());
    expect(find.byType(CineBrokenPart), findsNothing);
    expect(find.byType(ErrorWidget), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('the previous ErrorWidget.builder and handlers are restored on dispose', (t) async {
    final beforeBuilder = ErrorWidget.builder;
    final beforeOnError = FlutterError.onError;
    final beforeDispatcher = PlatformDispatcher.instance.onError;
    await _pump(t, release: true);
    expect(ErrorWidget.builder, isNot(same(beforeBuilder)));
    expect(FlutterError.onError, isNot(same(beforeOnError)));
    await t.pumpWidget(const SizedBox());
    expect(ErrorWidget.builder, same(beforeBuilder));
    expect(FlutterError.onError, same(beforeOnError));
    expect(PlatformDispatcher.instance.onError, same(beforeDispatcher));
  });

  testWidgets('appFatalError shows the route-error notice; Try again clears it', (t) async {
    await _pump(t, release: true);
    appFatalError.value = FatalErrorReport(StateError('x'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 2000));
    expect(find.text('CORRECTION'), findsOneWidget);
    expect(find.byType(TypedHeadline), findsOneWidget);
    expect(t.widget<TypedHeadline>(find.byType(TypedHeadline)).text, 'Something broke on this page.');
    expect(find.text('Nothing was lost; trying again usually fixes it.'), findsOneWidget);
    expect(find.textContaining('REF '), findsOneWidget);
    await t.tap(find.text('Try again'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(appFatalError.value, isNull);
    expect(find.text('Try again'), findsNothing);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('Restart the app calls AppRestart', (t) async {
    await _pump(t, release: true);
    expect(_builds, 1);
    appFatalError.value = FatalErrorReport(StateError('y'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 2000));
    await t.tap(find.text('Restart the app'));
    await t.pump();
    expect(_builds, 2);
    expect(appFatalError.value, isNull);
    await t.pumpWidget(const SizedBox());
  });

  group('release policy for what escaped', () {
    FlutterErrorDetails details(Object e, String lib, {bool silent = false}) =>
        FlutterErrorDetails(exception: e, stack: StackTrace.current, library: lib, silent: silent);

    Future<void> report(WidgetTester t, FlutterErrorDetails d) async {
      FlutterError.onError!(d);
      await t.pump();
      // The test binding records what reaches the previous handler; the policy is what is asserted.
      t.takeException();
    }

    testWidgets('a silent image error, a gesture error and an async StateError stay quiet and are recorded', (t) async {
      await _pump(t, release: true);
      await report(t, details(const FormatException('img'), 'image resource service', silent: true));
      expect(appFatalError.value, isNull);
      await report(t, details(StateError('tap'), 'gesture'));
      expect(appFatalError.value, isNull);
      expect(PlatformDispatcher.instance.onError!(StateError('late'), StackTrace.current), isTrue);
      expect(appFatalError.value, isNull);
      final log = appErrorLog.entries;
      expect(log.map((e) => e.type), ['StateError', 'StateError', 'FormatException']);
      expect(log.map((e) => e.source), ['async', 'gesture', 'image resource service']);
      expect(log.first.stackTop, isNotEmpty);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('a silent error of a screen-breaking library, and a dispose that throws, stay quiet', (t) async {
      await _pump(t, release: true);
      await report(t, details(StateError('r'), 'rendering library', silent: true));
      expect(appFatalError.value, isNull);
      await report(
        t,
        FlutterErrorDetails(
          exception: StateError('d'),
          library: 'widgets library',
          context: ErrorDescription('while finalizing the widget tree'),
        ),
      );
      expect(appFatalError.value, isNull);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('a rendering error still raises the notice, with its type beside the REF', (t) async {
      await _pump(t, release: true);
      await report(t, details(StateError('layout'), 'rendering library'));
      expect(appFatalError.value, isNotNull);
      await t.pump(const Duration(milliseconds: 2000));
      expect(find.textContaining('· StateError'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });
  });
}
