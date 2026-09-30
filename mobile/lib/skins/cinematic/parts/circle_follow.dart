import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/library/providers/dashboard_providers.dart';
import 'package:manhwamaniacs/features/library/providers/library_list_provider.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Follows a series from the Circle (`Read it too`, a letter's `Add`): haptic `follow.add`, the toast
/// "Following {title}." with `Read` opening the feature page (8000 ms), the feeds marked followed.
/// Returns whether it worked; a failure toasts "Couldn't follow {title}.".
Future<bool> circleFollow(BuildContext context, WidgetRef ref, {required String sourceId, required String seriesKey, required String title, bool toast = true}) async {
  final r = await ref.read(libraryRepositoryProvider).follow(sourceId: sourceId, seriesKey: seriesKey);
  if (!context.mounted) return r.isOk;
  if (r.isErr) {
    if (toast) ref.read(cineToastsProvider.notifier).error("Couldn't follow $title.");
    return false;
  }
  cineFeedback(context, HapticEvent.followAdd, sound: SoundEvent.followAdd);
  for (final kind in const <String?>[null, 'reading', 'reaction']) {
    ref.read(circleFeedProvider(kind).notifier).markFollowed(sourceId, seriesKey);
  }
  ref
    ..invalidate(libraryListProvider)
    ..invalidate(continueReadingProvider);
  if (toast) {
    final router = GoRouter.of(context);
    ref.read(cineToastsProvider.notifier).action('Following $title.', label: 'Read', onAction: () => unawaited(router.push(Routes.feature(sourceId, seriesKey))));
  }
  return true;
}
