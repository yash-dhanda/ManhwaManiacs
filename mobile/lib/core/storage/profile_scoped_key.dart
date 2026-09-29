import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';

/// `"{prefix}u{userId}p{profileId}"`, or [deviceKey] outside a session: the one per-persona
/// device key convention (the chapter store, the theme, the reader preferences share it).
/// [watch] is true from a `build` (profile and account switches recompute) and false from a
/// write, which must not add dependencies.
String profileScopedKey(
  Ref ref, {
  required String prefix,
  required String deviceKey,
  required bool watch,
}) {
  int? selectUserId(AuthState auth) => auth is AuthAuthenticated ? auth.user.id : null;
  final userId = watch
      ? ref.watch(authControllerProvider.select(selectUserId))
      : selectUserId(ref.read(authControllerProvider));
  final profileId =
      watch ? ref.watch(activeProfileProvider.select((p) => p?.id)) : ref.read(activeProfileProvider)?.id;
  if (userId == null || profileId == null) return deviceKey;
  return '${prefix}u${userId}p$profileId';
}
