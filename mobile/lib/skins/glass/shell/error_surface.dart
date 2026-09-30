import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/skins/glass/copy/errors.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/shell/session_loss.dart';

/// A live rate-limit countdown for the nav row or toolbar ("Slow down a little. Trying again in {n} s").
class GlassRateLimit {
  const GlassRateLimit(this.copy, this.seconds);
  final String copy;
  final int seconds;
}

final glassRateLimitProvider = StateProvider<GlassRateLimit?>((ref) => null);

/// Surfaces an error by the entry of `errorEntry` (glass 8.0.10): a toast with its recovery and haptic; a countdown capsule that
/// retries by itself after `Retry-After` only when the entry's `autoRetry` is true; the sign-in alert is the session watcher's job;
/// lens, inline and form entries are returned for the screen to render.
GlassErrorEntry surfaceError(WidgetRef ref, AppError error, {VoidCallback? retry, String? site, String? name}) {
  final entry = errorEntry(error, site: site, name: name, midSession: true);
  if (entry.haptic != null) unawaited(ref.read(glassHapticsProvider).fire(entry.haptic!));
  switch (entry.surface) {
    case GlassErrorSurface.toast:
      showGlassToast(
        ref,
        GlassToastSpec(entry.copy, kind: GlassToastKind.error, actionLabel: entry.recoveryLabel, onAction: retry),
      );
    case GlassErrorSurface.capsule:
      final n = _seconds(entry.copy) ?? kDefaultRetrySeconds;
      ref.read(glassRateLimitProvider.notifier).state = GlassRateLimit(entry.copy, n);
      if (entry.autoRetry && retry != null) {
        Timer(Duration(seconds: n), () {
          ref.read(glassRateLimitProvider.notifier).state = null;
          retry();
        });
      }
    case GlassErrorSurface.alert:
      // The signed-out alert belongs to GlassSessionLoss, which reacts to the auth state.
      break;
    case GlassErrorSurface.lens:
    case GlassErrorSurface.inline:
    case GlassErrorSurface.form:
      break;
  }
  if (error is ApiError && (error.code == 'profile_required' || error.code == 'profile_not_found')) handleProfileGone(ref);
  return entry;
}

int? _seconds(String copy) {
  final m = RegExp(r'(\d+) s').firstMatch(copy);
  return m == null ? null : int.tryParse(m.group(1)!);
}
