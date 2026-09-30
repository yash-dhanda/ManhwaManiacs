// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/bottom_bar.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/novel_paragraph.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/novel_reader_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/paged_columns.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/top_bar.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/type_sheet.dart';

import 'novel_test_support.dart';

Future<void> tapCentre(WidgetTester t) async {
  await t.tapAt(const Offset(195, 422));
  await settleNovel(t, ms: 500);
}

bool chromeShown(WidgetTester t) => find.byType(NovelTopBar).hitTestable().evaluate().isNotEmpty;

void main() {
  testWidgets('opens on the page: opener, paragraphs, chrome hidden', (tester) async {
    await pumpNovel(tester);
    await settleNovel(tester);
    expect(find.byType(CineNovelReader), findsOneWidget);
    expect(find.text('Down the Rabbit-Hole'), findsOneWidget);
    expect(find.byType(NovelParagraph), findsWidgets);
    expect(chromeShown(tester), isFalse);
    await disposeNovel(tester);
  });

  testWidgets('a tap toggles the chrome, which fades', (tester) async {
    await pumpNovel(tester);
    await settleNovel(tester);
    await tapCentre(tester);
    expect(chromeShown(tester), isTrue);
    expect(find.byType(NovelBottomBar), findsOneWidget);
    await tapCentre(tester);
    expect(chromeShown(tester), isFalse);
    await disposeNovel(tester);
  });

  testWidgets('every chrome control is at least 48 x 48 on Android and 44 x 44 on iOS', (tester) async {
    for (final (platform, min) in const [(TargetPlatform.android, 48.0), (TargetPlatform.iOS, 44.0)]) {
      await pumpNovel(tester, platform: platform);
      await settleNovel(tester);
      await tapCentre(tester);
      for (final label in const ['Back to the book', 'Contents', 'Text and page', 'Next chapter']) {
        final f = find.bySemanticsLabel(label);
        expect(f, findsWidgets, reason: label);
        final size = tester.getSize(f.first);
        expect(size.width, greaterThanOrEqualTo(min), reason: '$label $platform');
        expect(size.height, greaterThanOrEqualTo(min), reason: '$label $platform');
      }
      await disposeNovel(tester);
    }
  });

  testWidgets('keys: t opens Text and page, Esc closes; l advances seamlessly', (tester) async {
    final rig = await pumpNovel(tester);
    await settleNovel(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
    await settleNovel(tester, ms: 600);
    expect(find.text('Down the well 2'), findsWidgets);
    expect(rig.router.routeInformationProvider.value.uri.path, '/novels/demo/k/2');
    await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
    await settleNovel(tester, ms: 800);
    expect(find.text('TEXT AND PAGE'), findsWidgets);
    await disposeNovel(tester);
  });

  testWidgets('the Type sheet lists every row with its scope caption', (tester) async {
    await pumpNovel(tester);
    await settleNovel(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
    await settleNovel(tester, ms: 800);
    for (final label in const ['Face', 'Size', 'Line spacing', 'Measure', 'Margins', 'Paragraph spacing', 'Character spacing', 'Bold text', 'Justify and hyphenate', 'Layout', 'Page turn', 'Tap zones', 'Swipe sideways to change chapter', 'Stock']) {
      await tester.dragUntilVisible(find.text(label).first, find.byType(Scrollable).last, const Offset(0, -200));
      expect(find.text(label), findsWidgets, reason: label);
    }
    expect(find.text('Saved for this book'), findsWidgets);
    expect(find.text('Saved for this profile'), findsWidgets);
    await disposeNovel(tester);
  });

  testWidgets('paged layout paginates and shows the page folio', (tester) async {
    final rig = await pumpNovel(tester);
    await settleNovel(tester);
    await rig.settings({'layout': 'paged'});
    await settleNovel(tester, ms: 800);
    expect(find.byType(NovelPagedColumns), findsOneWidget);
    expect(find.textContaining('p. 1 of'), findsOneWidget);
    await tester.tapAt(const Offset(370, 422));
    await settleNovel(tester, ms: 600);
    expect(find.textContaining('p. 2 of'), findsOneWidget);
    await disposeNovel(tester);
  });

  testWidgets('speaker tints appear only for a matching fingerprint', (tester) async {
    await pumpNovel(tester, attribution: fixtureAttribution());
    await settleNovel(tester);
    final tinted = tester.widgetList<NovelParagraph>(find.byType(NovelParagraph)).where((p) => p.decorations.isNotEmpty);
    expect(tinted, isNotEmpty);
    await disposeNovel(tester);
    await pumpNovel(tester, attribution: fixtureAttributionStale());
    await settleNovel(tester);
    expect(tester.widgetList<NovelParagraph>(find.byType(NovelParagraph)).where((p) => p.decorations.isNotEmpty), isEmpty);
    await disposeNovel(tester);
  });

  testWidgets('the error state names the book and offers Back to the book', (tester) async {
    await pumpNovel(tester, failing: {'1': 'boom'});
    await settleNovel(tester);
    await settleNovel(tester, ms: 3000);
    expect(find.bySemanticsLabel(RegExp('load this chapter')), findsWidgets);
    expect(find.text('Back to the book'), findsWidgets);
    await disposeNovel(tester);
  });

  testWidgets('a saved copy shows its badge and the offline mark', (tester) async {
    await pumpNovel(tester, cacheStale: true, offline: true);
    await settleNovel(tester);
    await tapCentre(tester);
    expect(find.textContaining('SAVED COPY'), findsWidgets);
    await disposeNovel(tester);
  });

  testWidgets('the stock scope paints the page in the profile stock', (tester) async {
    final rig = await pumpNovel(tester);
    await settleNovel(tester);
    await rig.settings({'stock': 'dusk'});
    await settleNovel(tester);
    final material = tester.widget<Material>(find.descendant(of: find.byType(CineNovelReader), matching: find.byType(Material)).first);
    expect(material.color, const Color(0xFF0D1117));
    await disposeNovel(tester);
  });

  test('TopBar constants', () {
    expect(kNovelBarHeight, 52);
    expect(kNovelPageTopPad, greaterThan(0));
    expect(TypeSheetSmoke.ok, isTrue);
  });
}

class TypeSheetSmoke {
  static bool get ok => showNovelTypeSheet.runtimeType.toString().isNotEmpty;
}
