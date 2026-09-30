import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/logging/app_logger.dart';
import 'package:manhwamaniacs/features/auth/providers/session_offline_provider.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/models/profile_extras.dart';
import 'package:manhwamaniacs/features/profiles/providers/profile_scope.dart';
import 'package:manhwamaniacs/features/profiles/repositories/profiles_repository.dart';
import 'package:manhwamaniacs/features/profiles/repositories/profiles_repository_impl.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';

/// Backend-facing repository for the `/profiles` CRUD surface.
final profilesRepositoryProvider = Provider<ProfilesRepository>(
  (ref) => ProfilesRepositoryImpl(ref.watch(dioProvider)),
  name: 'profilesRepository',
);

/// The signed-in account's profiles, ordered by `sort_order`. Server data —
/// kept alive so the picker, the editor and the app-bar switcher share one
/// cache; mutations refresh it in place.
final profilesProvider =
    AsyncNotifierProvider<ProfilesNotifier, List<Profile>>(
  ProfilesNotifier.new,
  name: 'profiles',
);

class ProfilesNotifier extends AsyncNotifier<List<Profile>> {
  @override
  Future<List<Profile>> build() => _fetch();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<List<Profile>> _fetch() async {
    final result = await ref.read(profilesRepositoryProvider).list();
    if (result.isErr) throw result.error;
    final profiles = [...result.value]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    // Keep the persisted selection honest: if the active profile was deleted
    // elsewhere it must not linger and tint a session for a profile that no
    // longer exists.
    await ref.read(activeProfileProvider.notifier).reconcile(profiles);
    return profiles;
  }

  Future<AppError?> create({
    required String name,
    required String avatarKey,
    required Mood mood,
    bool? matureContentEnabled,
    String? skin,
  }) async {
    final result = await ref.read(profilesRepositoryProvider).create(
          name: name,
          avatarKey: avatarKey,
          mood: mood,
          matureContentEnabled: matureContentEnabled,
          skin: skin,
        );
    if (result.isErr) return result.error;
    await refresh();
    return null;
  }

  Future<AppError?> edit(
    int profileId, {
    String? name,
    String? avatarKey,
    Mood? mood,
    bool? matureContentEnabled,
    String? skin,
    int? sortOrder,
    bool? notifyEnabled,
    ProfileExtras? extras,
  }) async {
    if (extras != null && !extras.isEmpty) {
      // One PATCH carries the fields and the extras (the daily goal has no repository parameter).
      final r = await _patch(profileId, {
        if (name != null) 'name': name,
        if (avatarKey != null) 'avatar_key': avatarKey,
        if (mood != null) 'mood': mood.wire,
        if (matureContentEnabled != null) 'mature_content_enabled': matureContentEnabled,
        if (notifyEnabled != null) 'notify_enabled': notifyEnabled,
        ...extras.toJson(),
      });
      if (r.error != null) return r.error;
      await ref.read(activeProfileProvider.notifier).sync(r.profile!);
      await refresh();
      return null;
    }
    final result = await ref.read(profilesRepositoryProvider).update(
          profileId,
          name: name,
          avatarKey: avatarKey,
          mood: mood,
          matureContentEnabled: matureContentEnabled,
          skin: skin,
          sortOrder: sortOrder,
          notifyEnabled: notifyEnabled,
        );
    if (result.isErr) return result.error;
    // Mirror the edit into the active-selection snapshot so the shell tint and
    // switcher chip update without re-selecting.
    await ref.read(activeProfileProvider.notifier).sync(result.value);
    await refresh();
    return null;
  }

  Future<({AppError? error, Profile? profile})> _patch(int id, Map<String, Object?> body) async {
    try {
      final r = await ref.read(dioProvider).patch<Map<String, dynamic>>('/profiles/$id', data: body);
      return (error: null, profile: Profile.fromJson(r.data!));
    } on DioException catch (e) {
      return (error: e.error is AppError ? e.error! as AppError : UnknownError(message: e.message ?? 'Dio error', cause: e), profile: null);
    } catch (e) {
      return (error: UnknownError(message: e.toString(), cause: e), profile: null);
    }
  }

  /// `POST /profiles` never carries the skin or the daily goal, so [extras] go in one `PATCH` after it succeeds.
  Future<CreateProfileOutcome> createWithExtras({
    required String name,
    required String avatarKey,
    required Mood mood,
    bool? matureContentEnabled,
    ProfileExtras? extras,
  }) async {
    final result = await ref.read(profilesRepositoryProvider).create(name: name, avatarKey: avatarKey, mood: mood, matureContentEnabled: matureContentEnabled);
    if (result.isErr) return CreateProfileOutcome(error: result.error);
    var created = result.value;
    var failed = false;
    if (extras != null && !extras.isEmpty) {
      final r = await _patch(created.id, extras.toJson());
      if (r.error != null) {
        failed = true;
      } else {
        created = r.profile!;
      }
    }
    await refresh();
    return CreateProfileOutcome(created: created, extrasFailed: failed);
  }

  /// Rewrites `sort_order` for the profiles whose index changed, one after another, then refreshes.
  Future<AppError?> reorder(List<int> idsInOrder) async {
    final current = [...(state.valueOrNull ?? const <Profile>[])];
    for (var i = 0; i < idsInOrder.length; i++) {
      final p = current.where((x) => x.id == idsInOrder[i]).firstOrNull;
      if (p == null) continue;
      final index = current.indexOf(p);
      if (index == i) continue;
      final r = await _patch(p.id, {'sort_order': i});
      if (r.error != null) {
        await refresh();
        return r.error;
      }
    }
    await refresh();
    return null;
  }

  Future<AppError?> delete(int id) async {
    final result = await ref.read(profilesRepositoryProvider).remove(id);
    if (result.isErr) return result.error;
    final active = ref.read(activeProfileProvider);
    if (active != null && active.id == id) {
      await ref.read(activeProfileProvider.notifier).clear();
    }
    await refresh();
    return null;
  }
}

/// Whether the user has completed the profile gate for *this app session*.
///
/// Resets to `false` on every cold start (in-memory only). While `false`, the
/// router keeps an authenticated user on the profile picker — Netflix-style —
/// even if a profile was persisted from a previous session. Flips to `true`
/// once a profile is chosen and the entry ceremony finishes.
final profileSessionReadyProvider =
    NotifierProvider<ProfileSessionReadyNotifier, bool>(
  ProfileSessionReadyNotifier.new,
  name: 'profileSessionReady',
);

/// True after a skin restart: the app session (and so the open profile gate)
/// survives it. A cold start still shows the picker.
final skinRestartCarriesSessionProvider = Provider<bool>((ref) => false);

class ProfileSessionReadyNotifier extends Notifier<bool> {
  @override
  bool build() {
    if (ref.read(skinRestartCarriesSessionProvider)) {
      return ref.read(activeProfileProvider) != null;
    }
    // The gate stands on every normal cold start. Offline it cannot: the
    // profile list is server data, so holding an authenticated user on a picker
    // that will never load one parks him on a dead screen with no way forward.
    // The persisted selection is enough to enter as the right persona, and the
    // ceremony returns on the next launch that reaches the server.
    if (!ref.watch(sessionOfflineProvider)) return false;
    // Read, not watch: re-running on every profile switch would slam the gate
    // shut mid-session.
    return ref.read(activeProfileProvider) != null;
  }

  void enter() => state = true;

  void reset() => state = false;
}

/// The profile currently active on this device — a per-device selection, not
/// server data, so it lives in shared preferences rather than being re-fetched.
/// `null` means no profile is selected yet; the router routes an authenticated
/// visitor with no active profile to the picker.
final activeProfileProvider =
    NotifierProvider<ActiveProfileNotifier, ActiveProfile?>(
  ActiveProfileNotifier.new,
  name: 'activeProfile',
);

class ActiveProfileNotifier extends Notifier<ActiveProfile?> {
  static const String _prefsKey = 'mm.active_profile';

  @override
  ActiveProfile? build() {
    final raw = ref.watch(sharedPrefsProvider).getString(_prefsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return ActiveProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (error, stackTrace) {
      appLogger.w('Failed to decode persisted active profile', error, stackTrace);
      return null;
    }
  }

  /// Make [profile] the active reading persona and persist the selection.
  ///
  /// When this is an actual *switch* (a different profile was already active)
  /// every profile-scoped cache is dropped so the incoming persona never shows
  /// the outgoing one's follows/progress/library/collections/mature preference.
  /// This is the single choke point for both the picker ceremony and the
  /// app-bar switcher chip. A first-time selection (no previous profile) needs
  /// no invalidation — nothing stale is cached yet.
  Future<void> select(Profile profile) async {
    final previousId = state?.id;
    await _persist(profile.toSnapshot());
    if (previousId != null && previousId != profile.id) {
      invalidateProfileScopedProviders(ref);
    }
  }

  /// Clear the selection (used on delete-of-active and on account switch).
  ///
  /// Also drops the session gate so the router redirects back to the picker.
  /// Without this, clearing the active profile mid-session (deleting the active
  /// persona, or reconcile() dropping a remotely-deleted one) would strand the
  /// user in the home shell with no profile — every scoped request would 400
  /// `profile_required` and the switcher chip (hidden when active==null) offers
  /// no way back. Harmless in callers that already reset the gate.
  Future<void> clear() async {
    await ref.read(sharedPrefsProvider).remove(_prefsKey);
    state = null;
    ref.read(profileSessionReadyProvider.notifier).reset();
  }

  /// Refresh the stored snapshot when the active profile itself is edited.
  Future<void> sync(Profile profile) async {
    final current = state;
    if (current != null && current.id == profile.id) {
      await _persist(profile.toSnapshot());
    }
  }

  /// Drop the selection if the active profile is absent from [profiles].
  Future<void> reconcile(List<Profile> profiles) async {
    final current = state;
    if (current == null) return;
    if (!profiles.any((p) => p.id == current.id)) {
      await clear();
    }
  }

  Future<void> _persist(ActiveProfile snapshot) async {
    await ref
        .read(sharedPrefsProvider)
        .setString(_prefsKey, jsonEncode(snapshot.toJson()));
    state = snapshot;
  }
}

/// Attaches the active profile as the `X-Profile-Id` request header so the
/// backend scopes reads/writes to the selected persona (household model). Kept
/// alive for the app's lifetime by the router, and re-applied whenever the
/// selection changes or the Dio client is rebuilt (e.g. server-URL change).
///
/// This mutates the shared Dio's default headers rather than adding another
/// interceptor, so it stays entirely within the profiles feature — the network
/// layer needs no knowledge of profiles.
final profileHeaderSyncProvider = Provider<void>(
  (ref) {
    final dio = ref.watch(dioProvider);
    final active = ref.watch(activeProfileProvider);
    if (active != null) {
      dio.options.headers['X-Profile-Id'] = active.id.toString();
    } else {
      dio.options.headers.remove('X-Profile-Id');
    }
  },
  name: 'profileHeaderSync',
);
