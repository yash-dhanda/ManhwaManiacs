import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/paged_rules.dart';

void main() {
  test('zones: 30 / 40 / 30 and mirrored automatic layout for rtl', () {
    expect(zoneIndex(116, 390), 0);
    expect(zoneIndex(118, 390), 1);
    expect(zoneIndex(272, 390), 1);
    expect(zoneIndex(274, 390), 2);
    expect(resolveZones(null, rtl: false), ['previous', 'menu', 'next']);
    expect(resolveZones(null, rtl: true), ['next', 'menu', 'previous']);
    expect(resolveZones(['menu', 'menu', 'next'], rtl: true), ['menu', 'menu', 'next']);
    expect(zoneAction(10, 390, resolveZones(null, rtl: true)), 'next');
    expect(zoneStep('previous'), -1);
    expect(zoneStep('menu'), isNull);
  });
  test('bands show once per layout of zones', () {
    final z = resolveZones(null, rtl: false);
    expect(shouldShowBands([], 'single', z), isTrue);
    final seen = markZonesSeen([], 'single', z);
    expect(seen, ['single:previous,menu,next']);
    expect(shouldShowBands(seen, 'single', z), isFalse);
    expect(shouldShowBands(seen, 'double', z), isTrue);
    expect(shouldShowBands(seen, 'single', resolveZones(null, rtl: true)), isTrue);
    expect(markZonesSeen(seen, 'single', z), seen);
    expect(bandLabels(z), ['BACK', 'MENU', 'NEXT']);
  });
  test('k01 toast only after a sideways migration, once', () {
    expect(shouldShowK01Toast(legacyDirection: 'leftToRight', seen: false), isTrue);
    expect(shouldShowK01Toast(legacyDirection: 'rightToLeft', seen: false), isTrue);
    expect(shouldShowK01Toast(legacyDirection: 'rightToLeft', seen: true), isFalse);
    expect(shouldShowK01Toast(legacyDirection: 'vertical', seen: false), isFalse);
    expect(shouldShowK01Toast(legacyDirection: null, seen: false), isFalse);
  });
  test('layout keys', () {
    expect(layoutForKey('w')!.layout, 'strip');
    expect(layoutForKey('r')!.direction, 'rtl');
    expect(layoutForKey('v')!.direction, 'ltr');
    expect(layoutForKey('x'), isNull);
  });
}
