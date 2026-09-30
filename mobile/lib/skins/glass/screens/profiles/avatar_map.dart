import 'package:manhwamaniacs/features/profiles/models/profile_avatar.dart';
import 'package:manhwamaniacs/skins/glass/primitives/profile_orb.dart';

/// The Glass preset of an `avatar_key`: the twelve keys of `kAvatarPresets` map to the twelve Glass presets by index (glass 7.26).
GlassAvatarPreset glassPresetFor(String? avatarKey) {
  final i = kAvatarPresets.indexWhere((p) => p.key == avatarKey);
  return GlassAvatarPreset.values[i < 0 ? 0 : i];
}

/// The `avatar_key` of a Glass preset (the inverse of [glassPresetFor]).
String avatarKeyFor(GlassAvatarPreset p) => kAvatarPresets[p.index].key;
