import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show FocusNode;
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/utils/recent_searches.dart';
import 'package:manhwamaniacs/features/settings/models/app_changelog.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/screens/system/route_error.dart';
import 'package:manhwamaniacs/skins/glass/shell/focus_policy.dart';
import 'package:manhwamaniacs/skins/glass/shell/global_keys.dart';
import 'package:manhwamaniacs/skins/glass/shell/insets.dart';
import 'package:manhwamaniacs/skins/glass/shell/overlays.dart';
import 'package:manhwamaniacs/skins/glass/shell/palette_commands.dart';
import 'package:manhwamaniacs/skins/glass/shell/profile_switch.dart';
import 'package:manhwamaniacs/skins/glass/shell/route_focus.dart';
import 'package:manhwamaniacs/skins/glass/shell/session_loss.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell.dart';
import 'package:manhwamaniacs/skins/glass/shell/sidebar_item.dart';
import 'package:manhwamaniacs/skins/glass/shell/skin_switch_flow.dart';
import 'package:manhwamaniacs/skins/glass/shell/whats_new_sheet.dart';
import 'package:manhwamaniacs/skins/glass/transitions/glass_page_transitions.dart';
import 'package:manhwamaniacs/skins/skin.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('insets and bands (glass 2.2)', () {
    const safe = EdgeInsets.only(top: 47, bottom: 34);
    test('phone: top safeTop + 60, bottom safeBottom + 85, + 56 with the accessory', () {
      final a = GlassInsets.compute(frame: GlassFrameKind.phone, safe: safe, keyboard: 0, accessory: false);
      expect((a.top, a.bottom), (107.0, 119.0));
      expect(GlassInsets.compute(frame: GlassFrameKind.phone, safe: safe, keyboard: 0, accessory: true).bottom, 175);
    });
    test('wider frames: 76 and 24; the keyboard leaves safeBottom + 16', () {
      final a = GlassInsets.compute(frame: GlassFrameKind.desktop, safe: safe, keyboard: 0, accessory: false);
      expect((a.top, a.bottom), (76.0, 24.0));
      expect(GlassInsets.compute(frame: GlassFrameKind.phone, safe: safe, keyboard: 300, accessory: true).bottom, 50);
    });
    test('edge plateaus', () {
      expect(GlassInsets.topPlateau(frame: GlassFrameKind.phone, safeTop: 47, toast: false), 99);
      expect(GlassInsets.topPlateau(frame: GlassFrameKind.phone, safeTop: 47, toast: true), 203);
      expect(GlassInsets.topPlateau(frame: GlassFrameKind.tablet, safeTop: 47, toast: true), 60);
      expect(GlassInsets.bottomPlateau(frame: GlassFrameKind.phone, safeBottom: 34, accessory: true), 175);
      expect(GlassInsets.bottomPlateau(frame: GlassFrameKind.desktop, safeBottom: 34, accessory: true), 24);
    });
    test('focus never lands under a bar: the shift is the overlap plus 8', () {
      expect(focusOverlapShift(focused: const Rect.fromLTWH(0, 50, 100, 40), viewportHeight: 800, topBand: 107, bottomBand: 119), 50 - 107 - 8);
      expect(focusOverlapShift(focused: const Rect.fromLTWH(0, 700, 100, 40), viewportHeight: 800, topBand: 107, bottomBand: 119), 740 - (800 - 119) + 8);
      expect(focusOverlapShift(focused: const Rect.fromLTWH(0, 300, 100, 40), viewportHeight: 800, topBand: 107, bottomBand: 119), 0);
    });
  });

  group('sidebar', () {
    test('sidebarPlan follows the frame and the manual choice', () {
      final phone = sidebarPlan(frame: GlassFrameKind.phone, width: 390, choice: true);
      expect(phone.hasSidebar, isFalse);
      final desk = sidebarPlan(frame: GlassFrameKind.desktop, width: 1366, choice: null);
      expect((desk.dockedExpanded, desk.overlayOpen), (true, false));
      expect(sidebarPlan(frame: GlassFrameKind.desktop, width: 1366, choice: false).dockedExpanded, isFalse);
      final narrow = sidebarPlan(frame: GlassFrameKind.desktop, width: 1100, choice: null);
      expect((narrow.dockedExpanded, narrow.overlayOpen), (false, false));
      expect(sidebarPlan(frame: GlassFrameKind.tablet, width: 834, choice: true).overlayOpen, isTrue);
    });
    test('exactly one item is active and activity follows the route', () {
      expect(sidebarActiveId('/'), 'home');
      expect(sidebarActiveId('/library/recommendations'), 'forYou');
      expect(sidebarActiveId('/library'), 'shelf');
      expect(sidebarActiveId('/library/browse?x=1'), 'shelf');
      expect(sidebarActiveId('/library/collections/4'), 'collections');
      expect(sidebarActiveId('/downloads'), 'downloads');
      expect(sidebarActiveId('/sources/mangadex', pinnedSources: ['mangadex']), 'pin:mangadex');
      expect(sidebarActiveId('/sources/other', pinnedSources: ['mangadex']), 'sources');
      expect(sidebarActiveId('/settings/reading'), 'settings');
      expect(sidebarActiveId('/circle/7'), 'circle');
      expect(sidebarActiveId('/library/statistics/annual/2026'), 'stats');
    });
  });

  group('palette', () {
    test('matches a substring, else a subsequence, with the matched indices', () {
      expect(paletteMatch('lib', 'Open library'), [5, 6, 7]);
      expect(paletteMatch('ol', 'Open library'), [0, 5]);
      expect(paletteMatch('zz', 'Open library'), isNull);
      expect(paletteMatch('', 'x'), isEmpty);
    });
    test('prefix beats substring beats subsequence', () {
      expect(paletteScore('lib', 'Library'), 0);
      expect(paletteScore('lib', 'Open library'), 1);
      expect(paletteScore('ol', 'Open library'), 2);
    });
    test('recent searches keep the gate flag per profile', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await writeRecentSearch(prefs, 'a b', profileId: 1, gateOpen: true);
      expect(readRecentSearchEntries(prefs, profileId: 1).single.gateOpen, isTrue);
    });
  });

  group('keys', () {
    GlassKeyBinding b({bool always = false, bool single = false}) => GlassKeyBinding(id: 'x', group: 'g', description: 'd', keys: const ['x'], matches: (e, m, s) => false, action: () {}, alwaysOn: always, singleKey: single);
    test('only mod+K and mod+B fire while typing; single-key bindings obey the switch', () {
      expect(glassKeyMayFire(b(always: true), typing: true, singleKeyOn: true), isTrue);
      expect(glassKeyMayFire(b(), typing: true, singleKeyOn: true), isFalse);
      expect(glassKeyMayFire(b(single: true), typing: false, singleKeyOn: false), isFalse);
      expect(glassKeyMayFire(b(single: true), typing: false, singleKeyOn: true), isTrue);
      expect(glassKeyMayFire(b(), typing: false, singleKeyOn: false), isTrue);
    });
    test('the refresh bus calls the latest subscriber and unsubscribes', () {
      var a = 0, c = 0;
      final da = useGlassRefresh(() => a++);
      final dc = useGlassRefresh(() => c++);
      GlassRefreshBus.fire();
      dc();
      GlassRefreshBus.fire();
      da();
      GlassRefreshBus.fire();
      expect((a, c), (1, 1));
    });
    test('the search focus registry hands the last field the slash key', () {
      final n = FocusNode();
      final d = registerSearchFocus(n);
      d();
      n.dispose();
    });
    test('modifier keys are known', () {
      expect(LogicalKeyboardKey.keyK.keyLabel.toLowerCase(), 'k');
    });
  });

  group('flows', () {
    test('the signed-out copy and sign-in location', () {
      final a = signedOutCopy(disabled: false);
      expect(a.title, 'You were signed out on this device');
      expect(a.button, 'Sign in');
      expect(signedOutCopy(disabled: true).body, contains('deactivated'));
      expect(signedOutCopy(disabled: true).button, 'OK');
      expect(signInLocation('yeahiamyash'), '/login?user=yeahiamyash');
      expect(signInLocation(null), '/login');
    });
    test('the skin switch alert copy adds its notes only when they apply', () {
      final plain = skinSwitchAlertCopy(downloadsQueued: false, offline: false);
      expect(plain.title, 'Restart in Cinematic?');
      expect(plain.notes, isEmpty);
      expect(plain.stay, 'Stay in Glass');
      final both = skinSwitchAlertCopy(downloadsQueued: true, offline: true);
      expect(both.notes, hasLength(2));
      expect(both.notes.first, contains('Downloads pause'));
    });
    test('the profile skin: its own choice, the default, Glass falls back while unavailable', () {
      expect(resolveProfileSkin(profileSkin: 'cinematic', glassAvailable: false), SkinId.cinematic);
      expect(resolveProfileSkin(profileSkin: 'glass', glassAvailable: false), SkinId.cinematic);
      expect(resolveProfileSkin(profileSkin: 'glass', glassAvailable: true), SkinId.glass);
      expect(resolveProfileSkin(profileSkin: null, glassAvailable: true), kDefaultSkin);
    });
    test('route focus moves only on a location change, not a query change', () {
      expect(locationChanged(Uri.parse('/a?x=1'), Uri.parse('/a?x=2')), isFalse);
      expect(locationChanged(Uri.parse('/a'), Uri.parse('/b')), isTrue);
    });
    test('the app-update probe re-runs at most once every 15 minutes', () {
      final now = DateTime(2026, 9, 30, 12);
      expect(shouldRecheckAppUpdate(now: now, last: null), isTrue);
      expect(shouldRecheckAppUpdate(now: now, last: now.subtract(const Duration(minutes: 14))), isFalse);
      expect(shouldRecheckAppUpdate(now: now, last: now.subtract(const Duration(minutes: 15))), isTrue);
    });
    test('the What\'s new folio', () {
      expect(whatsNewFolio(const ChangelogRelease(version: '3.5.0', build: 57, date: '2026-09-28', highlights: [])), '28 Sep · build 57');
      expect(whatsNewFolio(const ChangelogRelease(version: '3.5.0', build: 0, date: '', highlights: [])), '');
    });
    test('an error reference is stable and 8 hex', () {
      final r = errorReference(StateError('boom'));
      expect(r, matches(RegExp(r'^[0-9a-f]{8}$')));
      expect(errorReference(StateError('boom')), r);
      expect(isNetworkFailure('NetworkError: x'), isTrue);
    });
    test('the new-chapters dismissed key is per profile', () {
      expect(newChaptersDismissedKey(3), isNot(newChaptersDismissedKey(4)));
    });
  });

  group('predictive back card (glass 8.0.5)', () {
    test('scale 1 to 0.90, shift toward the swipe edge, radius 0 to 36', () {
      const size = Size(390, 844);
      final g0 = GlassPredictiveGeometry.of(p: 0, size: size, edge: SwipeEdge.left, touchY: 422);
      expect((g0.scale, g0.dx, g0.radius), (1.0, 0.0, 0.0));
      final g1 = GlassPredictiveGeometry.of(p: 1, size: size, edge: SwipeEdge.left, touchY: 422);
      expect(g1.scale, closeTo(0.90, 1e-9));
      expect(g1.dx, closeTo(390 / 20 - 8, 1e-9));
      expect(g1.radius, 36);
      expect(GlassPredictiveGeometry.of(p: 1, size: size, edge: SwipeEdge.right, touchY: 422).dx, lessThan(0));
    });
    test('the y shift follows the finger, clamped to height/20 - 8', () {
      const size = Size(390, 844);
      expect(GlassPredictiveGeometry.of(p: 1, size: size, edge: SwipeEdge.left, touchY: -1000).dy, closeTo(-(844 / 20 - 8), 1e-9));
      expect(GlassPredictiveGeometry.of(p: 1, size: size, edge: SwipeEdge.left, touchY: 622).dy, closeTo(10, 1e-9));
    });
  });
}
