import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/network/api_image.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/models/source_pin.dart';
import 'package:manhwamaniacs/features/sources/providers/discover_providers.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/features/sources/utils/genre_index.dart';
import 'package:manhwamaniacs/features/sources/utils/source_health.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/duotone.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/cine_glyphs.g.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/phosphor.g.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/typed_text.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_poster.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/genre_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The idle page: RECENT, ASK THE EDITORS, then the numbered sections
/// (genres, sources, dialogue, trending), renumbered with no gaps.
class DiscoverIdle extends ConsumerStatefulWidget {
  const DiscoverIdle({
    super.key,
    required this.recent,
    required this.onRecent,
    required this.onClearRecent,
    required this.aiAvailable,
    required this.dialogueAvailable,
  });

  final List<String> recent;
  final ValueChanged<String> onRecent;
  final VoidCallback onClearRecent;
  final bool aiAvailable;
  final bool dialogueAvailable;

  @override
  ConsumerState<DiscoverIdle> createState() => _DiscoverIdleState();
}

class _DiscoverIdleState extends ConsumerState<DiscoverIdle> {
  bool _allGenres = false;

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    // Only the current content mode's sources (Manga or Novels).
    final scope = ref.watch(contentModeScopeProvider);
    final pins = ref.watch(discoverPinsProvider);
    final genres =
        ref.watch(genreIndexProvider).valueOrNull ?? const <GenreEntry>[];
    final trending = ref.watch(trendingProvider).valueOrNull ?? const [];
    final sources = scope.filter(
      ref.watch(sourcesListProvider).valueOrNull ?? const <SourceSummary>[],
      (s) => s.id,
    );
    final tablet = isTablet(context);
    var n = 0;
    String folio() => (++n).toString().padLeft(2, '0');
    // Rhythm (DESIGN.md 2.2): content, then 40 (phone) / 64 to the next
    // section rule; SectionHead already sets 12 of it above its rule.
    final sectionEnd = SizedBox(
      height: (tablet ? CineSpace.s16 : CineSpace.s10) - CineSpace.s3,
    );

    final shownGenres = _allGenres ? genres : genres.take(12).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.recent.isNotEmpty) ...[
          const SectionHead(null, 'Recent'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: CineSpace.s4),
            child: Wrap(
              spacing: CineSpace.s3,
              children: [
                for (final r in widget.recent)
                  CineButton(
                    label: r,
                    onPressed: () => widget.onRecent(r),
                    variant: CineButtonVariant.quiet,
                  ),
                CineButton(
                  label: 'Clear',
                  onPressed: widget.onClearRecent,
                  variant: CineButtonVariant.quiet,
                ),
              ],
            ),
          ),
          sectionEnd,
        ],
        if (widget.aiAvailable) ...[
          const SectionHead(null, 'Ask the editors'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: CineSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Kicker('Ask the editors'),
                const SizedBox(height: CineSpace.s2),
                TypedText.plain(
                  'A murim regressor who comes back stronger',
                  style: cineText(context, t.typePull),
                ),
                const SizedBox(height: CineSpace.s2),
                Text(
                  'Describe it in your own words; the editors pick from everywhere.',
                  style: cineText(context, t.typeDeck, color: t.colorInk60),
                ),
                CineButton(
                  label: 'Ask',
                  leadingGlyph: PhosphorRegular.sparkle.codePoint,
                  variant: CineButtonVariant.quiet,
                  // Picks focuses its ask field on ?ask=1 (mobile/19).
                  onPressed: () => context.go('${Routes.picks()}?ask=1'),
                ),
              ],
            ),
          ),
          sectionEnd,
        ],
        if (pins.isNotEmpty && genres.isNotEmpty) ...[
          SectionHead(folio(), 'Browse by genre'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: CineSpace.s4),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: tablet ? 3 : 2,
              mainAxisSpacing: CineSpace.s3,
              crossAxisSpacing: CineSpace.s3,
              childAspectRatio: 16 / 9,
              children: [
                for (final g in shownGenres) _GenreTile(genre: g, pinned: pins),
              ],
            ),
          ),
          if (genres.length > 12)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: CineSpace.s4),
              child: CineButton(
                label:
                    _allGenres ? 'Fewer genres' : 'All ${genres.length} genres',
                onPressed: () => setState(() => _allGenres = !_allGenres),
                variant: CineButtonVariant.quiet,
              ),
            ),
          sectionEnd,
        ],
        if (pins.isNotEmpty) ...[
          SectionHead(folio(), 'Sources'),
          for (final p in pins)
            _PinnedCredit(
              pin: p,
              mature: p.mature,
              health: describeHealth(
                sources.where((s) => s.id == p.sourceId).firstOrNull?.health,
                DateTime.now(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: CineSpace.s4),
            child: CineButton(
              label:
                  'All ${sources.isEmpty ? '' : '${sources.length} '}sources',
              onPressed: () => context.push(Routes.sources()),
              variant: CineButtonVariant.quiet,
            ),
          ),
          sectionEnd,
        ],
        if (widget.dialogueAvailable) ...[
          SectionHead(folio(), 'Search what they said'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: CineSpace.s4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    CineGlyphs.bubbleSearchLight,
                    size: 32,
                    color: t.colorInk45,
                  ),
                ),
                const SizedBox(width: CineSpace.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Kicker('Dialogue'),
                      Text(
                        'Find the chapter by a line someone said.',
                        style: cineText(context, t.typeDeck),
                      ),
                      CineButton(
                        label: 'Search dialogue',
                        onPressed: () => context.push(Routes.dialogue()),
                        variant: CineButtonVariant.quiet,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          sectionEnd,
        ],
        if (trending.isNotEmpty) ...[
          SectionHead(folio(), 'Trending on your sources'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: CineSpace.s4),
            child: Wrap(
              spacing: CineSpace.s4,
              children: [
                for (final tt in trending)
                  CineButton(
                    label: tt.title,
                    onPressed: () =>
                        context.push(Routes.feature(tt.sourceId, tt.seriesKey)),
                    variant: CineButtonVariant.quiet,
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: CineSpace.s16),
      ],
    );
  }
}

class _PinnedCredit extends ConsumerWidget {
  const _PinnedCredit({
    required this.pin,
    required this.mature,
    required this.health,
  });

  final SourcePin pin;
  final bool mature;
  final HealthDescription health;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.cine;
    return InkWell(
      onTap: () => context.push(Routes.source(pin.sourceId)),
      child: Semantics(
        button: true,
        label: '${pin.name}, ${health.label}${mature ? ', 18+' : ''}',
        excludeSemantics: true,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: CineSpace.s4),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: pin.iconUrl == null
                      ? ColoredBox(color: t.colorPaper1)
                      : CineCover(
                          url: resolveApiResourceUrl(
                            ref.watch(apiBaseUrlProvider),
                            pin.iconUrl!,
                          ),
                          displayWidth: 24,
                        ),
                ),
                const SizedBox(width: CineSpace.s3),
                Expanded(
                  child: Text(pin.name, style: cineText(context, t.typeTitle)),
                ),
                HealthMark(health.state),
                const SizedBox(width: CineSpace.s2),
                Text(
                  health.label,
                  style: cineText(context, t.typeCaption, color: t.colorInk60),
                ),
                if (mature) ...[
                  const SizedBox(width: CineSpace.s2),
                  Icon(
                    CineGlyphs.certificate18Regular,
                    size: 16,
                    color: t.colorInk100,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GenreTile extends ConsumerWidget {
  const _GenreTile({required this.genre, required this.pinned});

  final GenreEntry genre;
  final List<SourcePin> pinned;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.cine;
    final firstSource = pinned.firstWhere(
      (p) => genre.sourceIds.contains(p.sourceId),
      orElse: () => pinned.first,
    );
    final cover = ref
        .watch(
          genreCoverProvider(
            (
              sourceId: firstSource.sourceId,
              genre: genre.idFor(firstSource.sourceId),
            ),
          ),
        )
        .valueOrNull;
    return Semantics(
      button: true,
      label: genre.label,
      excludeSemantics: true,
      child: PressImpression(
        child: InkWell(
          // The AI genre grid only knows manhwa; a novel genre goes
          // straight to the sources that carry it.
          onTap: () => ref.read(contentModeControllerProvider) ==
                  ContentMode.novel
              ? openGenreOnSources(context, ref, genre, pinned)
              : openGenre(context, ref, genre, pinned),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: t.colorPaper1),
              if (cover != null)
                CineDuotone(
                  duo: t.colorAmbientFallbackDuo,
                  child: CineCover(url: cover.coverUrl, displayWidth: 200),
                ),
              const DecoratedBox(
                decoration: BoxDecoration(gradient: CineScrim.footBlack),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 8,
                child: Text(
                  genre.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: cineText(context, t.typeSubhead),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
