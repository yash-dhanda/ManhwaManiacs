import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';

/// Whether [sourceId] serves prose (the Book page) rather than pages (the
/// Feature page). A property of the SOURCE, not of the reader's current mode.
/// An unknown source reads as manga; a series page asks [sourceKindPending] first.
bool? isNovelSource(ContentModeScope scope, String sourceId) =>
    scope.modeOf(sourceId) == ContentMode.novel;

/// Whether a series page should wait for [sourceId]'s kind: novels are on, neither the listing nor the
/// remembered index knows the source, and `/sources` is still loading. Guessing manga there built the
/// manga page (and its reader links) for a novel.
bool sourceKindPending(WidgetRef ref, String sourceId) {
  final scope = ref.watch(contentModeScopeProvider);
  if (!scope.novelsEnabled || scope.index.containsKey(sourceId)) return false;
  return ref.watch(sourcesListProvider).isLoading;
}
