import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/library/providers/lift_store.dart';
import 'package:manhwamaniacs/skins/glass/parts/recommend/recommend_orbs.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/profile_orb.dart';
import 'package:manhwamaniacs/skins/glass/screens/circle/circle_orb.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';

import '../../../screenshots/support/shot_harness.dart';
import '../home/home_rig.dart';
import 'circle_rig.dart';

class _Sharing extends SharingNotifier {
  @override
  Future<Sharing> build(int arg) async => const Sharing(activity: true);
}

void main() {
  setUpAll(loadAppFonts);

  homeTest('budget: a poster lift with four recommend orbs on a phone Home stays within 6 layers and 8 shapes', (t) async {
    final rig = await pumpHome(t, homeRepoOf('ready'), extra: [
      sharingProvider.overrideWith(_Sharing.new),
      recipientsProvider.overrideWith((ref, key) async => const [
            CircleMember(profileId: 2, name: 'Aarav', avatarKey: 'violet', canReceive: true),
            CircleMember(profileId: 3, name: 'Mira', avatarKey: 'cyan', canReceive: true),
            CircleMember(profileId: 4, name: 'Kai', avatarKey: 'rose', canReceive: true),
            CircleMember(profileId: 5, name: 'Noor', avatarKey: 'amber', canReceive: true),
          ],),
    ],);
    await t.fling(find.byType(Scrollable).first, const Offset(0, -900), 2500);
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }
    rig.container.read(liftProvider.notifier).state = const LiftState(sourceId: 's', seriesKey: 'k', phase: LiftPhase.growing, posterRect: Rect.fromLTWH(20, 400, 124, 186));
    await t.pump(const Duration(milliseconds: 100));
    rig.container.read(liftProvider.notifier).state = const LiftState(sourceId: 's', seriesKey: 'k', phase: LiftPhase.lifted, posterRect: Rect.fromLTWH(20, 400, 124, 186));
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    final r = rig.container.read(glassRegistryProvider);
    final orbs = r.entries.where((e) => e.label == 'GlassRecommendOrbs').toList();
    // ignore: avoid_print
    print('BUDGET circle lift: ${r.layers} layers / ${r.shapes} shapes ${[for (final e in r.entries) '${e.label}:${e.shapes}${e.exempt ? 'x' : ''}${e.scrim ? 's' : ''}']}');
    expect(orbs, hasLength(1), reason: 'the four orbs are one glass group');
    expect(orbs.single.shapes, 4);
    expect(r.layers, lessThanOrEqualTo(6));
    expect(r.shapes, lessThanOrEqualTo(8));
    // Hit targets: each recommend orb is at least 48 x 48 (Android; iOS needs 44).
    final orbWidgets = find.descendant(of: find.byType(RecommendOrbLayer), matching: find.byType(GlassProfileOrb));
    expect(orbWidgets, findsNWidgets(4));
    for (final e in orbWidgets.evaluate()) {
      expect(e.size!.shortestSide, greaterThanOrEqualTo(48));
    }
    rig.container.read(liftProvider.notifier).state = null;
    await t.pump(const Duration(milliseconds: 300));
  });

  testWidgets('reduced motion: rings are static (1 reading, 0.4 today) and nothing breathes', (t) async {
    final rig = await pumpCircle(t, circleFake());
    rig.container.read(glassInAppPrefsProvider.notifier).setReduceMotion(true);
    await settle(t, 300);
    final rings = t.widgetList<PresenceRing>(find.byType(PresenceRing)).toList();
    expect(rings, isNotEmpty);
    // No frame is scheduled by a breathing ring once settled.
    await t.pump(const Duration(milliseconds: 100));
    await t.pump(const Duration(milliseconds: 1200));
    final borders = [
      for (final c in t.widgetList<Container>(find.descendant(of: find.byType(PresenceRing), matching: find.byType(Container))))
        if (c.decoration is BoxDecoration && (c.decoration! as BoxDecoration).border != null) ((c.decoration! as BoxDecoration).border! as Border).top.color.a,
    ];
    // 1 (reading) and 0.4 (today) on the presence rings; 0.6 is each orb's own friend ring.
    expect(borders.map((a) => (a * 100).round()).toSet(), {100, 60, 40});
    await unmount(t);
  });
}
