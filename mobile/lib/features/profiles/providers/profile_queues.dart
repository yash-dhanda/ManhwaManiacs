import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/onboarding/providers/onboarding_providers.dart';
import 'package:manhwamaniacs/features/onboarding/store/onboarding_draft.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/profiles/providers/skin_outbox.dart';

/// Sends the profile writes left queued on this device: the skin outbox (a switch made offline or
/// cut short by its restart) and the active profile's pending onboarding `done`. Signed in only (a
/// tokenless request says nothing). When either lands the profile list refreshes, so the picker and
/// the boot check stop reading the old skin or step. True when something was sent.
final profileQueuesFlushProvider = Provider<Future<bool> Function()>(
  (ref) {
    // A skin restart disposes the container while a flush is still awaiting the network.
    var alive = true;
    ref.onDispose(() => alive = false);
    return () async {
      if (ref.read(authControllerProvider) is! AuthAuthenticated) return false;
      var sent = await ref.read(skinOutboxProvider).flush();
      if (!alive) return sent;
      final active = ref.read(activeProfileProvider);
      final store = ref.read(onboardingStoreProvider);
      if (active != null && store.readPending() != null) {
        sent = await store.flushPending(active.id, ref.read(onboardingRepositoryProvider)) || sent;
        if (!alive) return sent;
      }
      if (sent) await ref.read(profilesProvider.notifier).refresh();
      return sent;
    };
  },
  name: 'profileQueuesFlush',
);
