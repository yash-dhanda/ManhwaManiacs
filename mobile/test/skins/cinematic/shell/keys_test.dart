import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/core/utils/pagination.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/repositories/library_repository.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/cinematic_skin.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_search_field.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toast_host.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/command_palette.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/global_keys.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The frame's keys over a tiny router: paths only, no screens.
Future<GoRouter> _app(WidgetTester t, {String start = '/', List<Override> overrides = const []}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  late GoRouter router;
  final container = ProviderContainer(overrides: [
    sharedPrefsProvider.overrideWithValue(prefs),
    skinIdProvider.overrideWithValue(SkinId.cinematic),
    ...overrides,
    skinRouterProvider.overrideWith((ref) {
      router = GoRouter(initialLocation: start, routes: [
        GoRoute(path: '/', builder: (c, s) => _Page(s.uri.toString())),
        GoRoute(path: '/library', builder: (c, s) => _Page(s.uri.toString())),
        GoRoute(path: '/circle', builder: (c, s) => _Page(s.uri.toString())),
        GoRoute(path: '/reader/:a', builder: (c, s) => _Page(s.uri.toString())),
      ],);
      return router;
    }),
  ],);
  addTearDown(container.dispose);
  final key = GlobalKey<CineToastHostState>();
  await t.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      theme: CinematicSkin.baseTheme,
      routerConfig: container.read(skinRouterProvider),
      builder: (context, child) => CineGlobalKeys(toastKey: key, chipBottom: 16, child: child!),
    ),
  ),);
  await t.pumpAndSettle();
  return router;
}

class _Page extends StatelessWidget {
  const _Page(this.loc);
  final String loc;
  @override
  Widget build(BuildContext context) => Scaffold(body: Column(children: [Text('at $loc'), const TextField(key: Key('field'))]));
}

/// The palette's library search: always answers with nothing.
class _EmptyLibrary implements LibraryRepository {
  @override
  Future<Result<PagedResult<FollowedSeries>>> search(String query, {int page = 1, int perPage = 20}) async =>
      Ok(PagedResult(items: const [], total: 0, page: page, perPage: perPage, hasNext: false));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

String _at(GoRouter r) => r.routerDelegate.currentConfiguration.uri.toString();

Future<void> _type(WidgetTester t, List<LogicalKeyboardKey> keys) async {
  for (final k in keys) {
    await t.sendKeyEvent(k);
  }
  await t.pump();
}

void main() {
  testWidgets('g then 2 goes to /library', (t) async {
    final r = await _app(t);
    await _type(t, [LogicalKeyboardKey.keyG, LogicalKeyboardKey.digit2]);
    await t.pumpAndSettle();
    expect(_at(r), '/library');
  });

  testWidgets('g then 1 1 goes to /circle', (t) async {
    final r = await _app(t, start: '/library');
    await _type(t, [LogicalKeyboardKey.keyG, LogicalKeyboardKey.digit1, LogicalKeyboardKey.digit1]);
    await t.pumpAndSettle();
    expect(_at(r), '/circle');
  });

  testWidgets('g then 1 then 700 ms goes to /', (t) async {
    final r = await _app(t, start: '/library');
    await _type(t, [LogicalKeyboardKey.keyG, LogicalKeyboardKey.digit1]);
    await t.pump(const Duration(milliseconds: 700));
    await t.pumpAndSettle();
    expect(_at(r), '/');
  });

  testWidgets('g 1 shows the G 1_ chip and it fades after the sequence', (t) async {
    await _app(t);
    await _type(t, [LogicalKeyboardKey.keyG]);
    expect(find.text('G _'), findsOneWidget);
    await _type(t, [LogicalKeyboardKey.digit1]);
    expect(find.text('G 1_'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 700));
    await t.pump(const Duration(milliseconds: 200));
    expect(find.text('G 1_'), findsNothing);
  });

  testWidgets('the sequence is off inside the readers', (t) async {
    final r = await _app(t, start: '/reader/x');
    await _type(t, [LogicalKeyboardKey.keyG, LogicalKeyboardKey.digit2]);
    await t.pumpAndSettle();
    expect(_at(r), '/reader/x');
  });

  testWidgets('keys typed in a text field trigger nothing', (t) async {
    final r = await _app(t);
    await t.tap(find.byKey(const Key('field')));
    await t.pump();
    await _type(t, [LogicalKeyboardKey.keyG, LogicalKeyboardKey.digit2]);
    await t.pumpAndSettle();
    expect(_at(r), '/');
  });

  testWidgets('mod+k opens the palette with focus in the field; mod+k closes it', (t) async {
    await _app(t);
    await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.keyK);
    await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await t.pumpAndSettle();
    expect(find.byType(CinePalette), findsOneWidget);
    expect(find.byType(CineSearchField), findsOneWidget);
    final editable = t.widget<EditableText>(find.byType(EditableText).last);
    expect(editable.focusNode.hasFocus, isTrue);
    await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.keyK);
    await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await t.pumpAndSettle();
    expect(find.byType(CinePalette), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android),);

  testWidgets('? opens the sheet listing Alt+T', (t) async {
    await _app(t);
    await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.slash);
    await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await t.pumpAndSettle();
    expect(find.text('Keyboard'), findsOneWidget);
    expect(find.textContaining('Alt T'), findsOneWidget);
    expect(find.text('Go to notifications'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android),);

  testWidgets('the palette ranks, wraps with the arrows and opens the active row', (t) async {
    final r = await _app(t);
    await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.keyK);
    await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await t.pumpAndSettle();
    await t.enterText(find.byType(EditableText).last, 'circle');
    await t.pump(const Duration(milliseconds: 300));
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pumpAndSettle();
    expect(_at(r), '/circle');
  }, variant: TargetPlatformVariant.only(TargetPlatform.android),);

  testWidgets('the palette announces "Searching…", then the count or "Nothing matches"', (t) async {
    final said = <String>[];
    t.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (m) async {
      final data = (m as Map?)?['data'] as Map?;
      if (data?['message'] is String) said.add(data!['message'] as String);
      return null;
    });
    addTearDown(() => t.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, null));
    await _app(t, overrides: [libraryRepositoryProvider.overrideWithValue(_EmptyLibrary())]);
    await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.keyK);
    await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await t.pumpAndSettle();
    await t.enterText(find.byType(EditableText).last, 'circle');
    await t.pump(const Duration(milliseconds: 100));
    expect(said, isEmpty);
    await t.pump(const Duration(milliseconds: 200));
    await t.pump();
    expect(said, ['Searching…', matches(RegExp(r'^\d+ results?$'))]);
    said.clear();
    await t.enterText(find.byType(EditableText).last, 'qqzzx');
    await t.pump(const Duration(milliseconds: 300));
    await t.pump();
    expect(said, ['Searching…', 'Nothing matches “qqzzx”.']);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android),);

  test('rankPalette orders groups and truncates at 40', () {
    final items = [
      for (var i = 0; i < 60; i++) PaletteItem(group: 'GO TO', title: 'Item $i', onSelect: () {}),
      PaletteItem(group: 'SOURCES', title: 'Item source', onSelect: () {}),
    ];
    final rows = rankPalette('item', items);
    expect(rows.length, 40);
    expect(rows.first.$1.group, 'SOURCES');
  });

  testWidgets('bindings register while mounted', (t) async {
    await _app(t);
    final c = ProviderScope.containerOf(t.element(find.byType(Scaffold)));
    final groups = c.read(shortcutRegistryProvider.notifier).registeredGroups();
    expect(groups.map((g) => g.name), containsAll(['General', 'Navigation']));
  });
}
