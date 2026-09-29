import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/cine_icon.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/glass/icons/glass_icon.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart';

Widget host(Widget child) => Directionality(textDirection: TextDirection.ltr, child: child);

List<Icon> icons(WidgetTester t) => t.widgetList<Icon>(find.byType(Icon)).toList();

void main() {
  group('CineIcon', () {
    testWidgets('24 is Light, 20 is Regular, selected is Fill', (t) async {
      await t.pumpWidget(host(const CineIcon(CineIconRole.search)));
      expect(icons(t).single.icon!.fontFamily, 'PhosphorLight');
      await t.pumpWidget(host(const CineIcon(CineIconRole.search, size: 20)));
      expect(icons(t).single.icon!.fontFamily, 'PhosphorRegular');
      await t.pumpWidget(host(const CineIcon(CineIconRole.search, selected: true)));
      expect(icons(t).single.icon!.fontFamily, 'PhosphorFill');
    });

    testWidgets('a glyph role draws CineGlyphs', (t) async {
      await t.pumpWidget(host(const CineIcon(CineIconRole.brandMark)));
      expect(icons(t).single.icon!.fontFamily, 'CineGlyphs');
    });

    testWidgets('semantics: no label is excluded, a label is announced', (t) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(host(const CineIcon(CineIconRole.search)));
      expect(find.bySemanticsLabel('Search'), findsNothing);
      await t.pumpWidget(host(const CineIcon(CineIconRole.search, semanticLabel: 'Search')));
      expect(find.bySemanticsLabel('Search'), findsOneWidget);
      h.dispose();
    });

    test('never offers Bold, Thin or Duotone', () {
      expect(CineIconWeight.values.map((w) => w.name), ['light', 'regular', 'fill']);
    });
  });

  group('GlassIcon', () {
    testWidgets('defaults to Regular at 22', (t) async {
      await t.pumpWidget(host(const GlassIcon(GlassIconRole.home)));
      expect(icons(t).single.icon!.fontFamily, 'PhosphorRegular');
      expect(icons(t).single.size, 22);
    });

    testWidgets('selected draws two glyphs, secondary at 0.20', (t) async {
      await t.pumpWidget(host(const GlassIcon(GlassIconRole.home, selected: true)));
      expect(icons(t), hasLength(2));
      expect(icons(t).every((i) => i.icon!.fontFamily == 'PhosphorDuotone'), isTrue);
      final o = t.widget<Opacity>(find.descendant(of: find.byType(PhosphorDuotoneIcon), matching: find.byType(Opacity)));
      expect(o.opacity, 0.20);
    });

    testWidgets('pressed is Fill, 14 is Bold, 56 is Light', (t) async {
      await t.pumpWidget(host(const GlassIcon(GlassIconRole.home, pressed: true)));
      expect(icons(t).single.icon!.fontFamily, 'PhosphorFill');
      await t.pumpWidget(host(const GlassIcon(GlassIconRole.home, size: 14)));
      expect(icons(t).single.icon!.fontFamily, 'PhosphorBold');
      await t.pumpWidget(host(const GlassIcon(GlassIconRole.home, size: 56)));
      expect(icons(t).single.icon!.fontFamily, 'PhosphorLight');
    });

    testWidgets('a glyph role uses GlassGlyphs, never CineGlyphs', (t) async {
      await t.pumpWidget(host(const GlassIcon(GlassIconRole.brandMark)));
      expect(icons(t).single.icon!.fontFamily, 'GlassGlyphs');
    });

    testWidgets('semantics: no label is excluded, a label is announced', (t) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(host(const GlassIcon(GlassIconRole.home)));
      expect(find.bySemanticsLabel('Home'), findsNothing);
      await t.pumpWidget(host(const GlassIcon(GlassIconRole.home, semanticLabel: 'Home')));
      expect(find.bySemanticsLabel('Home'), findsOneWidget);
      h.dispose();
    });
  });
}
