import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_certificate_dialog.dart';

import 'cine_harness.dart';

bool? _result;

Future<void> _open(WidgetTester t, Future<bool> Function() onConfirm, {String name = 'Ana'}) async {
  _result = null;
  await pumpCine(
    t,
    Builder(
      builder: (context) => Center(
        child: CineButton(key: const Key('t'), label: 'Open', onPressed: () async => _result = await openCineCertificateDialog(context, profileName: name, onConfirm: onConfirm)),
      ),
    ),
  );
  await t.tap(find.byKey(const Key('t')));
  await t.pumpAndSettle();
}

bool _enabled(WidgetTester t) => t.widget<CineButton>(find.byKey(const Key('cert-enable'))).onPressed != null;

void main() {
  testWidgets('Enable 18+ is disabled until the box is checked', (t) async {
    await _open(t, () async => true);
    expect(find.text('Show mature content on Ana?'), findsOneWidget);
    expect(_enabled(t), isFalse);
    await t.tap(find.byKey(const Key('cert-check')));
    await t.pump();
    expect(_enabled(t), isTrue);
  });

  testWidgets('the stamp runs after onConfirm returns true, then the route pops true', (t) async {
    await _open(t, () async => true);
    await t.tap(find.byKey(const Key('cert-check')));
    await t.pump();
    await t.tap(find.byKey(const Key('cert-enable')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 60));
    final fill = t.widget<Container>(find.byKey(const Key('cine-certificate'))).decoration! as BoxDecoration;
    expect(fill.color!.a, greaterThan(0));
    expect(_result, isNull);
    await t.pump(const Duration(milliseconds: 600));
    await t.pumpAndSettle();
    expect(_result, isTrue);
  });

  testWidgets('a false result shows the error state and keeps the dialog', (t) async {
    await _open(t, () async => false, name: '');
    expect(find.text('Show mature content on this profile?'), findsOneWidget);
    await t.tap(find.byKey(const Key('cert-check')));
    await t.pump();
    await t.tap(find.byKey(const Key('cert-enable')));
    await t.pumpAndSettle();
    expect(_result, isNull);
    expect(find.text('That didn’t go through. Try again.'), findsWidgets);
  });
}
