import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/cinematic/cinematic_skin.dart';
import 'package:manhwamaniacs/skins/glass/glass_skin.dart';
import 'package:manhwamaniacs/skins/skin.dart';

export 'package:manhwamaniacs/skins/skin.dart';

const _cinematic = CinematicSkin();
const _glass = GlassSkin();

Skin skinFor(SkinId id) => switch (id) {
      SkinId.cinematic => _cinematic,
      SkinId.glass => _glass,
    };

/// Overridden by `main` with the booted skin.
final skinIdProvider = Provider<SkinId>((ref) => kDefaultSkin);

final skinProvider = Provider<Skin>((ref) => skinFor(ref.watch(skinIdProvider)));

final skinRouterProvider =
    Provider<GoRouter>((ref) => ref.watch(skinProvider).buildRouter(ref));

/// The page a restart lands on; null on a cold start.
final returnRouteProvider = Provider<String?>((ref) => null);
