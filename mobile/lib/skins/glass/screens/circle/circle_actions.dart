import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/library/providers/dashboard_providers.dart' show continueReadingProvider;
import 'package:manhwamaniacs/features/library/providers/library_list_provider.dart' show libraryListProvider;
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/routes/nav_extra.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// Opens a series' detail, zooming from [from] (the `heroine` zoom from the cover).
Future<void> openCircleSeries(WidgetRef ref, String sourceId, String seriesKey, {Rect? from}) =>
    ref.read(skinRouterProvider).push<void>(Routes.feature(sourceId, seriesKey), extra: GlassNavExtra(originRect: from));

/// The global rect of [context]'s render box.
Rect? rectOf(BuildContext context) {
  final ro = context.findRenderObject();
  return ro is RenderBox && ro.attached && ro.hasSize ? ro.localToGlobal(Offset.zero) & ro.size : null;
}

/// Follows a series from the Circle ("Read it too", a letter's "Add to library"): `follow.add`, the feeds mark it followed, and
/// the toast "Following {title}". A failure toasts "Couldn't follow {title}". Returns whether it worked.
/// [actorId] is the dispatch's member: their feed (a friend sheet's Recent) is marked too.
Future<bool> followFromCircle(WidgetRef ref, {required String sourceId, required String seriesKey, required String title, int? actorId}) async {
  final r = await ref.read(libraryRepositoryProvider).follow(sourceId: sourceId, seriesKey: seriesKey);
  final toasts = ref.read(glassToastProvider.notifier);
  if (r.isErr) {
    glassFire(ref, HapticEvent.error);
    toasts.show(GlassToastSpec("Couldn't follow $title", kind: GlassToastKind.error));
    return false;
  }
  glassFire(ref, HapticEvent.followAdd);
  glassSound(ref, SoundEvent.followAdd);
  try {
    ref.read(circleFeedProvider(null).notifier).markFollowed(sourceId, seriesKey);
    if (actorId != null && ref.exists(memberFeedProvider(actorId))) ref.read(memberFeedProvider(actorId).notifier).markFollowed(sourceId, seriesKey);
  } catch (_) {}
  ref
    ..invalidate(libraryListProvider)
    ..invalidate(continueReadingProvider);
  toasts.show(GlassToastSpec('Following $title', kind: GlassToastKind.success));
  return true;
}

/// Opens a letter: sends `read` when it was `new` (Glass never writes `kept`).
void markLetterRead(WidgetRef ref, Letter l) {
  if (l.state == LetterState.newLetter) unawaited(ref.read(lettersProvider.notifier).patch(l.id, LetterState.read));
}
