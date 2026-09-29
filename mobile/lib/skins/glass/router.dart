import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/dev/calibration_page.dart';
import 'package:manhwamaniacs/skins/glass/dev/dev_controls.dart';
import 'package:manhwamaniacs/skins/glass/dev/glass_dev_index.dart';
import 'package:manhwamaniacs/skins/glass/dev/glass_gallery.dart';
import 'package:manhwamaniacs/skins/pending_routes.dart';
import 'package:manhwamaniacs/skins/pending_screen.dart';
import 'package:manhwamaniacs/skins/skins.dart';

// Every id is pending; finishing a screen deletes its line. mobile/45 deletes the set.
// ignore: constant_identifier_names
const Set<ScreenId> PENDING = {
  ScreenId.setup,
  ScreenId.login,
  ScreenId.register,
  ScreenId.profiles,
  ScreenId.profileNew,
  ScreenId.profileEdit,
  ScreenId.profilesManage,
  ScreenId.onboarding,
  ScreenId.tonight,
  ScreenId.library,
  ScreenId.updates,
  ScreenId.collections,
  ScreenId.collection,
  ScreenId.history,
  ScreenId.bookmarks,
  ScreenId.picks,
  ScreenId.numbers,
  ScreenId.annual,
  ScreenId.featureByFollow,
  ScreenId.feature,
  ScreenId.recap,
  ScreenId.circle,
  ScreenId.circleMember,
  ScreenId.discover,
  ScreenId.sources,
  ScreenId.source,
  ScreenId.reader,
  ScreenId.readAll,
  ScreenId.novel,
  ScreenId.downloads,
  ScreenId.dialogue,
  ScreenId.indexHub,
  ScreenId.settings,
  ScreenId.status,
  ScreenId.readerLanding,
};

/// The Glass development routes (mobile/25), outside the `ScreenId` map. `mobile/40` moves them into
/// Glass Diagnostics.
const String kGlassDevPath = '/dev/glass';
const String kGlassCalibrationPath = '/dev/glass/calibration';

/// The primitives gallery (`mobile/26`); `?section=buttons|hold|icon-buttons|…` shows one family.
const String kGlassPrimitivesPath = '/dev/glass/primitives';

/// Every pending screen gets a trailing-bottom plain button that opens the development index.
List<GoRoute> _withDevButton(List<GoRoute> routes) => [
      for (final r in routes)
        GoRoute(
          path: r.path,
          name: r.name,
          builder: (context, state) => _PendingWithDev(child: r.builder!(context, state)),
        ),
    ];

class _PendingWithDev extends StatelessWidget {
  const _PendingWithDev({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          child,
          Positioned(
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: DevButton(label: 'Glass development', onTap: () => context.push(kGlassDevPath)),
            ),
          ),
        ],
      );
}

GoRoute _devRoute(String path, Widget Function() page) => GoRoute(
      path: path,
      builder: (context, state) => _DevScaffold(child: page()),
    );

/// The development pages sit on the root's black and its ambient field, so they draw no background.
class _DevScaffold extends StatelessWidget {
  const _DevScaffold({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(type: MaterialType.transparency, child: child);
}

GoRouter buildGlassRouter(Ref ref) => GoRouter(
      initialLocation: ref.read(returnRouteProvider) ?? ScreenId.tonight.path,
      routes: [
        _devRoute(kGlassDevPath, () => const GlassDevIndex()),
        _devRoute(kGlassCalibrationPath, () => const GlassCalibrationPage()),
        GoRoute(
          path: kGlassPrimitivesPath,
          builder: (context, state) => _DevScaffold(child: GlassGallery(section: state.uri.queryParameters['section'])),
        ),
        ..._withDevButton(pendingRoutes(PENDING)),
      ],
      errorBuilder: (context, state) =>
          PendingScreen(screenId: 'not-found', location: state.uri.toString()),
    );
