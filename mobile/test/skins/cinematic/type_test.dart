import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

Widget _host(Widget child, {double scale = 1.0, bool bold = false, bool highContrast = false}) => MaterialApp(
      theme: ThemeData(extensions: const [cinematicTokens]),
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale), boldText: bold, highContrast: highContrast),
        child: app!,
      ),
      home: Scaffold(body: child),
    );

double? _axis(TextStyle s, String axis) => s.fontVariations?.where((v) => v.axis == axis).map((v) => v.value).firstOrNull;

void main() {
  testWidgets('OS Bold Text adds 120 to wght, clamped per face', (t) async {
    late TextStyle normal, bold;
    await t.pumpWidget(_host(Builder(builder: (c) {
      normal = CineType.style(c, c.cine.typeTitle);
      return const SizedBox();
    },),),);
    await t.pumpWidget(_host(Builder(builder: (c) {
      bold = CineType.style(c, c.cine.typeTitle);
      return const SizedBox();
    },), bold: true,),);
    expect(_axis(bold, 'wght'), _axis(normal, 'wght')! + 120);
  });

  testWidgets('caps roles switch to wdth 100 at scale 1.3, except fixed cells', (t) async {
    late TextStyle at1, at13, cell13;
    await t.pumpWidget(_host(Builder(builder: (c) {
      at1 = CineText.style(c, c.cine.typeKicker);
      return const SizedBox();
    },),),);
    await t.pumpWidget(_host(Builder(builder: (c) {
      at13 = CineText.style(c, c.cine.typeKicker);
      cell13 = CineText.style(c, c.cine.typeKicker, fixedCell: true);
      return const SizedBox();
    },), scale: 1.3,),);
    expect(_axis(at13, 'wdth'), 100);
    expect(_axis(at1, 'wdth'), isNot(100));
    expect(_axis(cell13, 'wdth'), _axis(at1, 'wdth'));
    expect(cell13.letterSpacing, closeTo(at1.letterSpacing! + 0.06 * at1.fontSize!, 1e-6));
  });

  testWidgets('literal caps and the reflow steps', (t) async {
    late TextScaler bodoni, newsreader, archivoUpper;
    late CineReflow r;
    await t.pumpWidget(_host(Builder(builder: (c) {
      bodoni = CineText.literalScaler(c, CineFace.bodoni);
      newsreader = CineText.literalScaler(c, CineFace.newsreader);
      archivoUpper = CineText.literalScaler(c, CineFace.archivo, upper: true);
      r = CineReflow.of(c);
      return const SizedBox();
    },), scale: 3.0,),);
    expect(bodoni.scale(10), closeTo(13, 1e-6));
    expect(newsreader.scale(10), closeTo(20, 1e-6));
    expect(archivoUpper.scale(10), closeTo(15, 1e-6));
    expect((r.railCompact, r.stackSplit, r.fullDetent), (true, true, true));
    await t.pumpWidget(_host(Builder(builder: (c) {
      r = CineReflow.of(c);
      return const SizedBox();
    },), scale: 1.3,),);
    expect((r.railCompact, r.stackSplit, r.fullDetent), (true, false, false));
  });

  testWidgets('CineStock scopes remap ink.45, CineContrastScope remaps under high contrast', (t) async {
    Color? raised, wash45, wash60, plain, hc45, hcRule;
    await t.pumpWidget(_host(Column(children: [
      Builder(builder: (c) {
        plain = c.cine.colorInk45;
        return const SizedBox();
      },),
      CineStock.raised(Builder(builder: (c) {
        raised = c.cine.colorInk45;
        return const SizedBox();
      },),),
      CineStock.wash(Builder(builder: (c) {
        wash45 = c.cine.colorInk45;
        wash60 = c.cine.colorInk60;
        return const SizedBox();
      },),),
    ],),),);
    expect(plain, CineColors.ink45);
    expect(raised, CineColors.ink60);
    expect((wash45, wash60), (CineColors.ink80, CineColors.ink80));
    await t.pumpWidget(_host(CineContrastScope(child: Builder(builder: (c) {
      hc45 = c.cine.colorInk45;
      hcRule = c.cine.colorRule1;
      return const SizedBox();
    },),), highContrast: true,),);
    expect((hc45, hcRule), (CineColors.ink80, CineColors.rule2));
  });
}
