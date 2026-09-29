// ignore_for_file: require_trailing_commas, directives_ordering
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/app/skin_app.dart';
import 'package:manhwamaniacs/core/diagnostics/debug_overlays.dart';
import 'package:manhwamaniacs/features/auth/providers/offline_edition_controller.dart';
import 'package:manhwamaniacs/skins/cinematic/cinematic_skin.dart';
import 'package:manhwamaniacs/skins/cinematic/gallery/primitives_gallery.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_route_page.dart';
import 'package:manhwamaniacs/skins/cinematic/splash/cine_splash.dart';
import 'package:manhwamaniacs/skins/skins.dart';

import 'support/shot_harness.dart';
import 'support/skin_shots.dart';

/// Screenshot group `mobile-06`: the shell section of the Cinematic gallery (pure views with
/// fixture props, frozen splash, Column wipe and Iris frames) at phone 390 x 844, tablet
/// 834 x 1194 and landscape phone 844 x 390, grid off and on; `-reduced` variants of the splash and
/// the wipe; and one pending screen inside the real frame for each branch root.
///
/// Files land as `docs/redesign/proof/mobile-06/<name>-<size>.png`.
void mobile06Shots() {
  const sizes = [...kSkinShotSizes, kSkinShotLandscape];
  const heights = {'shell': 6400.0, 'shell-frames': 2600.0};

  for (final size in sizes) {
    for (final section in const ['shell', 'shell-frames']) {
      for (final grid in const [false, true]) {
        final name = '$section${grid ? '-grid' : ''}';
        testWidgets('mobile-06 $name ${size.name}', (t) async {
          final tall = SkinShotSize(size.name, Size(size.logical.width, heights[section]!), size.pixelRatio, size.padding);
          await captureSkinWidget(
            t,
            name: name,
            size: tall,
            overrides: [if (grid) layoutGridOverlayProvider.overrideWith((ref) => true)],
            child: MaterialApp(debugShowCheckedModeBanner: false, home: CinePrimitivesGalleryPage(section: section)),
          );
          await t.pumpWidget(const SizedBox());
          await t.pump(const Duration(seconds: 12));
        });
      }
    }
  }

  // Reduced motion: the splash mid-fade (300 ms fade-in) and the wipe as a cross-fade through black.
  for (final size in kSkinShotSizes) {
    testWidgets('mobile-06 splash-reduced ${size.name}', (t) async {
      await captureSkinWidget(
        t,
        name: 'splash-reduced',
        size: size,
        disableAnimations: true,
        settle: (t) async {
          await t.pump();
          await t.pump(const Duration(milliseconds: 220));
        },
        child: MaterialApp(theme: CinematicSkin.baseTheme, home: const Stack(children: [Positioned.fill(child: CineSplash())])),
      );
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 3));
    });

    testWidgets('mobile-06 wipe-reduced ${size.name}', (t) async {
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (c, s) => const Scaffold(body: Center(child: Text('BEFORE')))),
        GoRoute(path: '/reader/:a', pageBuilder: (c, s) => cineReaderPage(c, s, const Scaffold(body: Center(child: Text('PAGE ONE'))))),
      ],);
      await captureSkinWidget(
        t,
        name: 'wipe-reduced',
        size: size,
        disableAnimations: true,
        settle: (t) async {
          await t.pump();
          unawaited(router.push<void>('/reader/x', extra: <String, String>{'entry': 'wipe'}));
          await t.pump();
          await t.pump(const Duration(milliseconds: 100));
        },
        child: MaterialApp.router(theme: CinematicSkin.baseTheme, routerConfig: router),
      );
      router.dispose();
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 3));
    });
  }

  // A pending screen inside the real frame, one per branch: the thumb index shows on every branch.
  final branches = <(String, String)>[
    ('tonight', '/'),
    ('library', '/library'),
    ('discover', '/search'),
    ('downloads', '/downloads'),
    ('index', '/more'),
  ];
  for (final (name, path) in branches) {
    testWidgets('mobile-06 frame-$name phone', (t) async {
      await captureSkinWidget(
        t,
        name: 'frame-$name',
        size: kSkinShotSizes.first,
        overrides: [
          skinIdProvider.overrideWithValue(SkinId.cinematic),
          returnRouteProvider.overrideWithValue(path),
          // The frame's providers that would call the server.
          outboxSyncProvider.overrideWith((ref) => null),
        ],
        settle: (t) async {
          await settleShot(t);
          await t.pump(const Duration(seconds: 2));
        },
        child: const SkinApp(),
      );
      await drainCacheTimers(t);
    });
  }
}
