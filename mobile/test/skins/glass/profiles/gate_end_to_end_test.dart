import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_gate_provider.dart';
import 'package:manhwamaniacs/features/downloads/utils/mature_filter.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/settings/repositories/mature_settings_repository.dart';
import 'package:manhwamaniacs/skins/glass/dev/auth_fixtures.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/switch.dart';
import 'package:manhwamaniacs/skins/glass/routes/nav_extra.dart';
import 'package:manhwamaniacs/skins/glass/shell/purge.dart';

import '../../../screenshots/support/shot_harness.dart';
import '../auth/auth_rig.dart';

class _Repo implements MatureSettingsRepository {
  _Repo(this.read);
  final Future<bool> Function() read;
  @override
  Future<Result<bool>> getMatureEnabled() async => Ok(await read());
  @override
  Future<Result<bool>> setMatureEnabled(bool enabled) async => Ok(enabled);
}

class _Row {
  const _Row(this.title, this.mature);
  final String title;
  final bool mature;
}

const _rows = [_Row('Solo Leveling', false), _Row('Adults only', true)];

/// Scrolls the form's vertical scrollable until [f] is on screen (`ensureVisible` leaves the page variant's far rows below the fold).
Future<void> _reveal(WidgetTester t, Finder f) async {
  await t.scrollUntilVisible(f, 300, scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axis == Axis.vertical).first, maxScrolls: 30);
  await t.pump(const Duration(milliseconds: 100));
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('the active profile turns the gate off: the gate closes, the filtered lists drop the mature rows and the purge runs', (t) async {
    GlassStops.reset();
    var purged = 0;
    registerPurgeHolder('gate-test', (_) => purged++);
    addTearDown(GlassStops.reset);
    late ProviderContainer c;
    final fixture = GlassAuthFixture(
      signedIn: true,
      profiles: [fixtureProfile(1, 'Yash', mature: true), fixtureProfile(2, 'Sunday')],
      active: const ActiveProfile(id: 1, name: 'Yash', avatarKey: 'violet', mood: Mood.neutral),
    );
    final rig = await pumpAuth(t, '/', fixture, extra: [
      matureSettingsRepositoryProvider.overrideWith((ref) => _Repo(() async => (await ref.read(profilesProvider.future)).firstWhere((p) => p.id == 1).matureContentEnabled)),
    ],);
    c = rig.container;
    final keep = c.listen(matureGateOpenProvider, (_, __) {});
    addTearDown(keep.close);
    await settleFor(t, 1200);
    expect(c.read(matureGateOpenProvider), isTrue);
    expect(filterMature(_rows, gateOpen: c.read(matureGateOpenProvider), isMature: (r) => r.mature), hasLength(2));

    unawaited(GoRouter.of(t.element(find.byType(Navigator).first)).push<void>('/profiles/1/edit', extra: const GlassNavExtra()));
    await settleFor(t, 1400);
    await _reveal(t, find.byType(GlassSwitch).last);
    await t.tap(find.byType(GlassSwitch).last);
    await settleFor(t, 700);
    await _reveal(t, find.widgetWithText(GlassButton, 'Save changes'));
    await t.tap(find.widgetWithText(GlassButton, 'Save changes'));
    await settleFor(t, 1500);

    expect(FakeProfiles.calls, contains('edit:1'));
    expect(c.read(matureGateOpenProvider), isFalse);
    expect(filterMature(_rows, gateOpen: c.read(matureGateOpenProvider), isMature: (r) => r.mature).map((r) => r.title), ['Solo Leveling']);
    expect(purged, greaterThan(0), reason: "the shell's purge ran when the gate closed");
  });

  testWidgets('turning it on needs the hold or its visible fallback', (t) async {
    await pumpAuth(t, '/profiles/2/edit', GlassAuthFixture(signedIn: true, profiles: [fixtureProfile(1, 'Yash', mature: true), fixtureProfile(2, 'Sunday')]));
    await settleFor(t, 1500);
    await _reveal(t, find.byType(GlassSwitch).last);
    await t.tap(find.byType(GlassSwitch).last);
    await settleFor(t, 900);
    expect(find.text('I am 18 or older, enable'), findsOneWidget);
    expect(t.widget<GlassSwitch>(find.byType(GlassSwitch).last).value, isFalse, reason: 'the tap alone never flips it');
    await t.tap(find.text('I am 18 or older, enable'));
    await settleFor(t, 900);
    expect(t.widget<GlassSwitch>(find.byType(GlassSwitch).last).value, isTrue);
  });

  testWidgets('picking a profile with a closed gate runs the purge before the hand-off', (t) async {
    GlassStops.reset();
    var purged = 0;
    registerPurgeHolder('pick-test', (_) => purged++);
    addTearDown(GlassStops.reset);
    await pumpAuth(t, '/profiles', GlassAuthFixture(signedIn: true, profiles: [fixtureProfile(1, 'Yash', mature: true), fixtureProfile(2, 'Sunday')]));
    await settleFor(t, 2500);
    await t.tap(find.bySemanticsLabel('Read as Sunday'), warnIfMissed: false);
    await t.pump();
    await t.pump(const Duration(milliseconds: 30));
    expect(purged, greaterThan(0));
    await settleFor(t, 2000);
  });
}
