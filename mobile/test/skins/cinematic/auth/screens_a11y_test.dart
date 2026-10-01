// ignore_for_file: require_trailing_commas, directives_ordering
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';

import 'auth_test_support.dart';

const _yash = ActiveProfile(id: 1, name: 'Yash', avatarKey: 'violet', mood: Mood.neutral);

/// Every screen of mobile/07 by the route that shows it.
const _routes = <(String, String)>[
  ('setup', '/setup'),
  ('login', '/login'),
  ('register', '/register'),
  ('picker', '/profiles'),
  ('form new', '/profiles/new'),
  ('form edit', '/profiles/1/edit'),
  ('manage', '/profiles/manage'),
];

Future<Rig> _open(WidgetTester t, String route, {TargetPlatform platform = TargetPlatform.iOS, double scale = 1, Size size = const Size(390, 844)}) async {
  final signedIn = route.startsWith('/profiles');
  final rig = await pumpAuth(
    t,
    start: signedIn ? '/' : route,
    auth: signedIn ? FakeAuth(initial: AuthAuthenticated(testUser)) : null,
    active: signedIn ? _yash : null,
    setupDone: route != '/setup',
    platform: platform,
    scale: scale,
    size: size,
  );
  if (signedIn) unawaited(rig.router.push<void>(route));
  await settle(t, 1200);
  return rig;
}

void main() {
  for (final (name, route) in _routes) {
    for (final scale in [1.3, 2.0]) {
      testWidgets('$name renders at text scale $scale without overflow', (t) async {
        await _open(t, route, scale: scale);
        expect(t.takeException(), isNull);
      });
    }

    for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
      testWidgets('$name: every control is at least ${platform == TargetPlatform.android ? 48 : 44} and clear of its neighbours ($platform)', (t) async {
        await _open(t, route, platform: platform);
        final min = platform == TargetPlatform.android ? 48.0 : 44.0;
        final rects = <Rect>[];
        final screen = Offset.zero & t.view.physicalSize;
        for (final e in find.byType(CinePressable).evaluate()) {
          final box = e.renderObject! as RenderBox;
          if (!box.attached || !box.hasSize) continue;
          final r = box.localToGlobal(Offset.zero) & box.size;
          if (!r.overlaps(screen)) continue; // below the fold
          expect(r.width, greaterThanOrEqualTo(min - 0.01), reason: '${e.widget} width');
          expect(r.height, greaterThanOrEqualTo(min - 0.01), reason: '${e.widget} height');
          rects.add(r);
        }
        expect(rects, isNotEmpty);
        for (var i = 0; i < rects.length; i++) {
          for (var j = i + 1; j < rects.length; j++) {
            final gapX = rects[i].left >= rects[j].right ? rects[i].left - rects[j].right : rects[j].left >= rects[i].right ? rects[j].left - rects[i].right : -1;
            final gapY = rects[i].top >= rects[j].bottom ? rects[i].top - rects[j].bottom : rects[j].top >= rects[i].bottom ? rects[j].top - rects[i].bottom : -1;
            // Inclusive: a control whose edge lies on its row's edge (a switch on the gutter) is
            // still inside the row. Rect.contains excludes the right and bottom edges.
            final nested = rects[i].expandToInclude(rects[j]) == rects[i] || rects[j].expandToInclude(rects[i]) == rects[j];
            final overlap = gapX < 0 && gapY < 0 && !nested;
            expect(overlap, isFalse, reason: 'controls $i and $j overlap: ${rects[i]} ${rects[j]}');
          }
        }
      });
    }
  }

  testWidgets('tablet widths render without overflow', (t) async {
    for (final (_, route) in _routes) {
      await _open(t, route, size: const Size(834, 1194));
      expect(t.takeException(), isNull, reason: route);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 1));
    }
  });
}
