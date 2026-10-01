import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/inline_notice.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/lens_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/object_lens.dart';
import 'package:manhwamaniacs/skins/glass/primitives/status_capsule.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_form_route.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart' show GlassTwin;
import 'package:manhwamaniacs/skins/skins.dart';

/// Leaves the series page: pops the sheet, or goes to the source catalogue (or the library) when nothing is beneath.
void seriesBack(WidgetRef ref, {String? sourceId}) {
  final r = ref.read(skinRouterProvider);
  if (r.canPop()) {
    r.pop();
  } else {
    r.go(sourceId == null ? Routes.library() : Routes.source(sourceId));
  }
}

/// The page skeleton (glass 8.12 States, after 180 ms): cover block, three title bars, two button capsules, 8 chapter rows.
class SeriesSkeleton extends StatelessWidget {
  const SeriesSkeleton({super.key, this.book = false});
  final bool book;

  @override
  Widget build(BuildContext context) => GlassSkeletonGroup(
        label: book ? 'Loading this book' : 'Loading this series',
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Column(
            key: const ValueKey('series-skeleton'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassSkeleton(width: book ? 144 : 112, height: book ? 208 : 168, radius: book ? 6 : 14),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GlassSkeleton(height: 24, radius: 8, index: 1),
                        SizedBox(height: 10),
                        GlassSkeleton(width: 160, height: 14, radius: 7, index: 2),
                        SizedBox(height: 10),
                        GlassSkeleton(width: 120, height: 14, radius: 7, index: 3),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const GlassSkeleton(height: 48, radius: 24, index: 4),
              const SizedBox(height: 8),
              const GlassSkeleton(height: 44, radius: 22, index: 5),
              const SizedBox(height: 20),
              for (var i = 0; i < 8; i++) Padding(padding: const EdgeInsets.only(bottom: 8), child: GlassSkeleton(height: 48, radius: 10, index: 6 + i)),
            ],
          ),
        ),
      );
}

/// Chapters loading: 8 row skeletons under the live header.
class ChapterRowsSkeleton extends StatelessWidget {
  const ChapterRowsSkeleton({super.key});
  @override
  Widget build(BuildContext context) => GlassSkeletonGroup(
        label: 'Loading chapters',
        child: Column(children: [for (var i = 0; i < 8; i++) Padding(padding: const EdgeInsets.only(bottom: 8), child: GlassSkeleton(height: 48, radius: 10, index: i))]),
      );
}

enum SeriesLensKind { error, offline, notFound, unavailable, gated, followMissing }

/// The page-level lenses of glass 8.12 States and 8.0.8 (unavailable content).
class SeriesLens extends ConsumerWidget {
  const SeriesLens({super.key, required this.kind, this.sourceId, this.book = false, this.onRetry, this.onMove, this.onRemove, this.message});
  final SeriesLensKind kind;
  final String? sourceId;
  final bool book;
  final VoidCallback? onRetry;

  /// Followed series of an unavailable source: "Move to another source…" and "Remove from library".
  final VoidCallback? onMove;
  final VoidCallback? onRemove;
  final String? message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void back() => seriesBack(ref, sourceId: sourceId);
    void backToSource() {
      final r = ref.read(skinRouterProvider);
      if (sourceId != null) r.go(Routes.source(sourceId!));
    }

    final (situation, tone, title, description, primary, secondary) = switch (kind) {
      SeriesLensKind.error => (
          LensSituation.loadError,
          GlassLensTone.error,
          book ? "Couldn't load this book" : "Couldn't load this series",
          message ?? "The source didn't answer.",
          onRetry == null ? null : LensAction('Try again', onRetry!),
          sourceId == null ? null : LensAction('Back to source', backToSource),
        ),
      SeriesLensKind.offline => (
          LensSituation.offline,
          GlassLensTone.offline,
          book ? 'This book needs a connection to load' : 'This series needs a connection to load',
          null,
          LensAction('Open downloads', () => ref.read(skinRouterProvider).go(Routes.downloads())),
          null,
        ),
      SeriesLensKind.followMissing => (LensSituation.notFound, GlassLensTone.empty, "This isn't here any more", 'It may have been removed on another device.', LensAction('Back', back), null),
      SeriesLensKind.notFound || SeriesLensKind.unavailable => (
          LensSituation.unavailable,
          GlassLensTone.empty,
          message ?? 'This series is no longer available from its source',
          null,
          onMove != null ? LensAction('Move to another source…', onMove!) : LensAction('Back', back),
          onRemove != null ? LensAction('Remove from library', onRemove!) : (onMove != null ? LensAction('Back', back) : null),
        ),
      SeriesLensKind.gated => (LensSituation.unavailable, GlassLensTone.empty, "This isn't available on this profile", null, LensAction('Back home', () => ref.read(skinRouterProvider).go(Routes.tonight())), null),
    };
    final key = ValueKey('series-lens-${kind.name}');
    // Inside a sheet or a window the lens and its actions are content twins (glass 7.10, 7.24): the overlay is the only glass there.
    final route = ModalRoute.of(context);
    if (route is! GlassSheetRoute && route is! GlassFormRoute) {
      return GlassObjectLens(key: key, situation: situation, tone: tone, title: title, description: description, primary: primary, secondary: secondary);
    }
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        GlassObjectLens(placement: GlassLensPlacement.inline, situation: situation, tone: tone, title: title, description: description),
        Wrap(spacing: 8, children: [
          for (final (i, a) in [primary, secondary].nonNulls.indexed)
            GlassButton(label: a.label, twin: GlassTwin.content, variant: i == 0 ? GlassButtonVariant.primary : GlassButtonVariant.secondary, onPressed: a.onPressed),
        ],),
      ],
    );
  }
}

/// The inline chapter-list states of glass 8.12 F7.
enum ChapterListState { offline, error, unavailable, empty, rateLimited }

class ChapterListNotice extends ConsumerWidget {
  const ChapterListNotice({super.key, required this.state, required this.sourceId, this.listed = 0, this.book = false, this.onRetry, this.retryIn = 12});
  final ChapterListState state;
  final String sourceId;
  final int listed;
  final bool book;
  final VoidCallback? onRetry;
  final int retryIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget retry() => onRetry == null ? const SizedBox.shrink() : GlassButton(label: 'Try again', variant: GlassButtonVariant.plain, size: GlassButtonSize.small, onPressed: onRetry);
    Widget block(String title, {String? body, Widget? action}) => Padding(
          key: ValueKey('chapters-${state.name}'),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassLabel(title, role: gt.typeHeadline, maxLines: 2),
              if (body != null) ...[const SizedBox(height: 4), GlassLabel(body, role: gt.typeFootnote, color: gt.colorLabel2, maxLines: 4)],
              if (action != null) ...[const SizedBox(height: 8), action],
            ],
          ),
        );
    return switch (state) {
      ChapterListState.offline => block(book ? 'This book needs a connection to load' : 'The chapter list needs a connection'),
      ChapterListState.error => block(book ? "Contents didn't come through" : "Couldn't load the chapters", action: retry()),
      ChapterListState.unavailable => block(book ? "Contents didn't come through" : "Chapters didn't come through",
          body: 'This source lists $listed chapters but returned none just now; that is usually the source, not you.', action: retry(),),
      ChapterListState.empty => block(book ? 'No chapters yet: this source hasn\'t published any chapters for this book.' : 'No chapters yet',
          action: GlassButton(label: 'Back to source', variant: GlassButtonVariant.plain, size: GlassButtonSize.small, onPressed: () => ref.read(skinRouterProvider).go(Routes.source(sourceId))),),
      ChapterListState.rateLimited => Padding(
          key: const ValueKey('chapters-rateLimited'),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: GlassInlineNotice(variant: GlassNoticeVariant.warning, message: 'This source is busy. Trying again in $retryIn s.'),
        ),
    };
  }
}

/// The "Offline" capsule over a page rendered from cache and downloads.
class SeriesOfflineCapsule extends StatelessWidget {
  const SeriesOfflineCapsule({super.key});
  @override
  Widget build(BuildContext context) => const GlassStatusCapsule(kind: GlassStatusKind.offline);
}
