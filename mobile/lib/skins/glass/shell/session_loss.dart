import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/auth/providers/session_end_reason_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/primitives/alert.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/routes/depth_observer.dart';
import 'package:manhwamaniacs/skins/glass/shell/purge.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';
import 'package:manhwamaniacs/skins/glass/shell/stack_overview_host.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// The copy of the signed-out alert (glass 8.0.9): a 401 ends the session; a deactivated account cannot sign back in.
({String title, String body, String button}) signedOutCopy({required bool disabled}) => (
      title: 'You were signed out on this device',
      body: disabled ? 'This account was deactivated. Ask the server\'s owner.' : 'Your session ended on another device or expired.',
      button: disabled ? 'OK' : 'Sign in',
    );

/// The login location that keeps the cached username (never the password).
String signInLocation(String? username) => username == null || username.isEmpty ? '/login' : '/login?user=${Uri.encodeQueryComponent(username)}';

/// Watches the session (glass 8.0.9): signed out elsewhere stops narration, cruise and the soundscape, pauses the download queue,
/// closes any reader without animation and blooms the alert; a profile that disappeared shows a toast and returns to the picker.
/// Placed above the router in the Glass root.
class GlassSessionLoss extends ConsumerStatefulWidget {
  const GlassSessionLoss({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<GlassSessionLoss> createState() => _GlassSessionLossState();
}

class _GlassSessionLossState extends ConsumerState<GlassSessionLoss> {
  bool _hadSession = false;
  String? _username;

  @override
  void initState() {
    super.initState();
    final a = ref.read(authControllerProvider);
    if (a is AuthAuthenticated) {
      _hadSession = true;
      _username = a.user.username;
    }
    ref.listenManual<AuthState>(authControllerProvider, _onAuth);
  }

  void _onAuth(AuthState? was, AuthState now) {
    if (now is AuthAuthenticated) {
      _hadSession = true;
      _username = now.user.username;
      return;
    }
    if (now is! AuthUnauthenticated || !_hadSession) return;
    final reason = ref.read(sessionEndReasonProvider);
    _hadSession = false;
    if (reason == SessionEndReason.signedOut) {
      ref.read(sessionEndReasonProvider.notifier).state = null;
      unawaited(_signedOut());
    }
  }

  Future<void> _signedOut() async {
    GlassStops.stopAllPlayback();
    try {
      ref.read(downloadQueueControllerProvider.notifier).pause();
    } catch (_) {}
    final nav = ref.read(glassNavigatorsProvider);
    final root = nav?.root.currentState;
    // Readers close without animation: pop root routes down to the first.
    root?.popUntil((r) => r.isFirst || glassRouteKeyOf(r) == null);
    ref.read(glassSignedOutPendingProvider.notifier).state = true;
    final ctx = nav?.root.currentContext;
    if (ctx == null || !ctx.mounted) {
      ref.read(glassSignedOutPendingProvider.notifier).state = false;
      return;
    }
    unawaited(ref.read(glassHapticsProvider).fire(HapticEvent.warning));
    final copy = signedOutCopy(disabled: false);
    final signIn = await showGlassAlert<bool>(
      ctx,
      title: copy.title,
      body: copy.body,
      actions: [GlassAlertAction<bool>(copy.button, value: true)],
    );
    ref.read(glassSignedOutPendingProvider.notifier).state = false;
    if (signIn ?? false) ref.read(skinRouterProvider).go(signInLocation(_username));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The profile disappeared (`profile_required`, `profile_not_found`): a toast, playback stops, the app returns to the picker.
/// The dead selection goes (X-Profile-Id with it) and the kept-alive list refetches, so the picker never offers it again.
void handleProfileGone(WidgetRef ref) {
  GlassStops.stopAllPlayback();
  showGlassToast(ref, const GlassToastSpec('That profile is no longer available', kind: GlassToastKind.warning));
  unawaited(ref.read(activeProfileProvider.notifier).clear());
  ref.invalidate(profilesProvider);
  ref.read(skinRouterProvider).go('/profiles');
}
