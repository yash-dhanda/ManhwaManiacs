import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/annual_entry_points.dart';

import '../../../screenshots/support/shot_harness.dart';
import '../support/cine_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);

  test('the toast shows in December, once per profile per year', () {
    expect(shouldShowAnnualToast(DateTime(2026, 12), null), isTrue);
    expect(shouldShowAnnualToast(DateTime(2026, 12, 20), '2025'), isTrue);
    expect(shouldShowAnnualToast(DateTime(2026, 12, 20), '2026'), isFalse);
    expect(shouldShowAnnualToast(DateTime(2026, 11, 30), null), isFalse);
  });

  testWidgets('December toast: "The Annual 2026 is out." with Open, stored once', (tester) async {
    final env = CineTestEnv(now: DateTime(2026, 12, 2, 9));
    await pumpCine(tester, env, router: cineRouter(initial: '/', home: const AnnualDecemberToastHost(child: Scaffold(body: Text('SHELL')))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('The Annual 2026 is out.'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    expect(env.sp.getString('mm.annual.toast.u1p1'), '2026');
    await tester.tap(find.text('Open'));
    await pumpMs(tester, 800);
    expect(env.repo.annualYears, contains(2026));
    // A second open the same December: nothing.
    final again = CineTestEnv(now: DateTime(2026, 12, 9), prefs: {'mm.annual.toast.u1p1': '2026'});
    await pumpCine(tester, again, router: cineRouter(initial: '/', home: const AnnualDecemberToastHost(child: Scaffold(body: Text('SHELL')))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('The Annual 2026 is out.'), findsNothing);
  });

  testWidgets('the Tonight link exists only in December', (tester) async {
    await pumpCine(tester, CineTestEnv(now: DateTime(2026, 12, 2)), router: cineRouter(initial: '/', home: const Scaffold(body: AnnualOutLink())));
    expect(find.text('The Annual is out →'), findsOneWidget);
    await pumpCine(tester, CineTestEnv(now: DateTime(2026, 9, 2)), router: cineRouter(initial: '/', home: const Scaffold(body: AnnualOutLink())));
    expect(find.text('The Annual is out →'), findsNothing);
  });
}
