import 'package:manhwamaniacs/skins/skin.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kSkinActiveKey = 'mm.skin.active';
/// Retired: only [SkinBoot.read] touches it, to remove a leftover.
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

  /// The device mirror, else [kDefaultSkin]; a retired `legacy` becomes the default.
  static SkinId resolveSkin(SharedPreferences prefs) {
    final active = skinIdFromName(prefs.getString(kSkinActiveKey));
    if (active == null || active == SkinId.legacy) return kDefaultSkin;
    return active;
  }

  /// Consumes the one-shot return route and session flag (S15).
  static SkinBoot read(SharedPreferences prefs) {
    final route = prefs.getString(kSkinReturnKey);
    final carry = prefs.getString(kSkinSessionKey) == '1';
    prefs.remove(kSkinReturnKey);
    prefs.remove(kSkinSessionKey);
    // The pre-flip debug override is gone (release/01 Decision 3): drop a leftover once, no restart.
    if (prefs.containsKey(kSkinDebugKey)) prefs.remove(kSkinDebugKey);
    return SkinBoot(skin: resolveSkin(prefs), returnRoute: route, carrySession: carry);
  }
}
