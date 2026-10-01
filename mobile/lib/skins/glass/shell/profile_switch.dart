import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/shell/purge.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// The skin a profile runs in: its own choice, else the default; Glass falls back to Cinematic while it is unavailable (glass 8.2,
/// stack 2.4).
SkinId resolveProfileSkin(
    {required String? profileSkin,
    required bool glassAvailable,}) {
  var s = skinIdFromName(profileSkin) ?? kDefaultSkin;
  if (s == SkinId.glass && !glassAvailable) s = SkinId.cinematic;
  return s;
}

/// Profile switching (glass 8.0.9). `prepare` does everything before the destination is decided; `commit` resets every branch.
class GlassProfileSwitch {
  GlassProfileSwitch(this.ref);
  final Ref ref;

  /// Stops narration, cruise and the soundscape (no Undo), cancels in-flight recaps (they register a canceller with
  /// `registerPlaybackStop`), runs the purge first when the target's 18+ gate is closed, sets the active profile, decides the skin.
  /// The current profile's download queue pauses itself when the scope changes; the new profile's resumes with it.
  Future<({SkinId? restartTo})> prepare(Profile target) async {
    GlassStops.stopAllPlayback();
    if (!target.matureContentEnabled) purgeMatureLocal(ref);
    await ref.read(activeProfileProvider.notifier).select(target);
    final running = ref.read(skinIdProvider);
    final to = resolveProfileSkin(
        profileSkin: target.skin,
        glassAvailable: Flags.glassAvailable,);
    return (restartTo: to == running ? null : to);
  }

  /// Rebuilds the router at [destination] (`Routes.tonight` or the onboarding step): every branch stack, observer and snapshot resets.
  void commit(String destination) {
    final n = ref.read(glassRouterEpochProvider.notifier);
    n.state = GlassRouterEpoch(n.state.epoch + 1, destination);
  }
}

final glassProfileSwitchProvider =
    Provider<GlassProfileSwitch>(GlassProfileSwitch.new);

/// Spec names, for `mobile/30`'s picker.
Future<({SkinId? restartTo})> prepareProfileSwitch(Ref ref, Profile target) =>
    GlassProfileSwitch(ref).prepare(target);

void commitProfileSwitch(Ref ref, String destination) =>
    GlassProfileSwitch(ref).commit(destination);
