import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/skin.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kSkinActiveKey = 'mm.skin.active';
const kSkinDebugKey = 'mm.skin.debug';
const kSkinReturnKey = 'mm.skin.return';
const kSkinT0Key = 'mm.skin.t0';

/// The edition the user came from, written only by an undoable switch; read once by
/// [takeSkinArrival] to show the arrival toast.
const kSkinFromKey = 'mm.skin.from';
const kSkinSessionKey = 'mm.skin.session';
const kSkinBootRestartKey = 'mm.skin.boot-restart';
const kSkinRestartLastKey = 'mm.skin.restart.last';

class SkinBoot {
  const SkinBoot({required this.skin, required this.returnRoute, required this.carrySession});

  final SkinId skin;
  final String? returnRoute;
  final bool carrySession;

  /// Debug override, else the device mirror, else [kDefaultSkin]; `glass`
  /// from the mirror becomes `cinematic` while it is unavailable (§8.0.7).
  static SkinId resolveSkin(SharedPreferences prefs) {
    final debug = skinIdFromName(prefs.getString(kSkinDebugKey));
    if (debug == SkinId.glass && !Flags.glassAvailable) return SkinId.cinematic;
    return debug ?? resolveSkinWithoutDebug(prefs);
  }

  /// What "Clear override" and "Leave the preview" restart into.
  static SkinId resolveSkinWithoutDebug(SharedPreferences prefs) {
    final active = skinIdFromName(prefs.getString(kSkinActiveKey));
    if (active == null || active == SkinId.legacy) return kDefaultSkin;
    return active == SkinId.glass && !Flags.glassAvailable ? SkinId.cinematic : active;
  }

  /// Consumes the one-shot return route and session flag (S15).
  static SkinBoot read(SharedPreferences prefs) {
    final route = prefs.getString(kSkinReturnKey);
    final carry = prefs.getString(kSkinSessionKey) == '1';
    prefs.remove(kSkinReturnKey);
    prefs.remove(kSkinSessionKey);
    return SkinBoot(skin: resolveSkin(prefs), returnRoute: route, carrySession: carry);
  }
}
