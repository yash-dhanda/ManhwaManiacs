import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_icon_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_lightbox.dart';

import 'cine_harness.dart';

final _png = MemoryImage(base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=='));

Future<void> _open(WidgetTester t, {bool reduced = false}) async {
  await pumpCine(
    t,
    Builder(
      builder: (context) => Center(
        child: Hero(
          tag: 'cover',
          child: GestureDetector(
            key: const Key('cover'),
            onTap: () => openCineLightbox(context, heroTag: 'cover', image: _png, title: 'Solo Leveling', folio: 'COVER · 720 × 1080'),
            child: const SizedBox(width: 80, height: 120, child: ColoredBox(color: Colors.red)),
          ),
        ),
      ),
    ),
    reduced: reduced,
  );
  await t.tap(find.byKey(const Key('cover')));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('focus lands on Close and the route is named', (t) async {
    await _open(t);
    expect(find.bySemanticsLabel('Cover of Solo Leveling'), findsWidgets);
    final ctx = FocusManager.instance.primaryFocus!.context!;
    expect(ctx.findAncestorWidgetOfExactType<CineIconButton>()?.label, 'Close');
  });

  testWidgets('double tap zooms to 2.5x and shows the 250% chip; again returns to 1x', (t) async {
    await _open(t);
    final iv = find.byType(InteractiveViewer);
    await t.tapAt(const Offset(120, 300));
    await t.pump(const Duration(milliseconds: 60));
    await t.tapAt(const Offset(120, 300));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    final tc = t.widget<InteractiveViewer>(iv).transformationController!;
    expect(tc.value.getMaxScaleOnAxis(), closeTo(2.5, 0.01));
    expect(find.text('250%'), findsOneWidget);
    await t.pump(const Duration(seconds: 2));
    expect(find.text('250%'), findsNothing);
    await t.tapAt(const Offset(120, 300));
    await t.pump(const Duration(milliseconds: 60));
    await t.tapAt(const Offset(120, 300));
    await t.pumpAndSettle();
    expect(tc.value.getMaxScaleOnAxis(), closeTo(1, 0.01));
  });

  testWidgets('dragging down past 120 px at 1x dismisses', (t) async {
    await _open(t);
    final g = await t.startGesture(const Offset(195, 400));
    for (var i = 0; i < 8; i++) {
      await g.moveBy(const Offset(0, 20));
      await t.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await t.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsNothing);
  });

  testWidgets('a short drag springs back', (t) async {
    await _open(t);
    final g = await t.startGesture(const Offset(195, 400));
    for (var i = 1; i <= 2; i++) {
      await g.moveBy(const Offset(0, 20), timeStamp: Duration(milliseconds: 200 * i));
      await t.pump(const Duration(milliseconds: 200));
    }
    await g.up();
    await t.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });

  testWidgets('Android back closes', (t) async {
    await _open(t);
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsNothing);
  });

  testWidgets('the Close button closes', (t) async {
    await _open(t);
    await t.tap(find.byKey(const Key('lightbox-close')));
    await t.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsNothing);
  });
}
