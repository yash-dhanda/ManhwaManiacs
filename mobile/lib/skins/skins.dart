import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/cinematic/cinematic_skin.dart';
import 'package:manhwamaniacs/skins/glass/glass_skin.dart';
import 'package:manhwamaniacs/skins/legacy/legacy_skin.dart';
import 'package:manhwamaniacs/skins/skin.dart';

export 'package:manhwamaniacs/skins/skin.dart';

const _legacy = LegacySkin();
const _cinematic = CinematicSkin();
const _glass = GlassSkin();

Skin skinFor(SkinId id) => switch (id) {
      SkinId.legacy => _legacy,
      SkinId.cinematic => _cinematic,
      SkinId.glass => _glass,
    };

/// Overridden by `main`; the legacy default keeps every existing test that
/// pumps the app unchanged.
final skinIdProvider = Provider<SkinId>((ref) => SkinId.legacy);

final skinProvider = Provider<Skin>((ref) => skinFor(ref.watch(skinIdProvider)));

final skinRouterProvider =
    Provider<GoRouter>((ref) => ref.watch(skinProvider).buildRouter(ref));

/// The page a restart lands on; null on a cold start.
final returnRouteProvider = Provider<String?>((ref) => null);
