import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/network/network_connectivity.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/library/utils/cover_url.dart';
import 'package:manhwamaniacs/features/onboarding/providers/onboarding_providers.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/providers/source_pins_provider.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/inline_notice.dart';
import 'package:manhwamaniacs/skins/glass/primitives/letter_reveal.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster_grid_math.dart';
import 'package:manhwamaniacs/skins/glass/primitives/search_field.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/primitives/spring_value.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/lens_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/object_lens.dart';
import 'package:manhwamaniacs/skins/glass/screens/onboarding/onboarding_flow.dart';
import 'package:manhwamaniacs/skins/glass/screens/onboarding/seed_counter.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// Step 6, Seed titles (glass 8.7): a grid of the catalogue's seeds; a pick follows the first source, keeps a seed no source has,
/// and pulls up to three similar titles in after it; a live counter, a search over the sources and every state.
class GlassSeedsStep extends ConsumerStatefulWidget {
  const GlassSeedsStep({super.key});

  @override
  ConsumerState<GlassSeedsStep> createState() => _GlassSeedsStepState();
}

class _GlassSeedsStepState extends ConsumerState<GlassSeedsStep> {
  final Map<int, List<WorldItem>> _similar = {};
  final Set<int> _arrived = {};
  final TextEditingController _query = TextEditingController();
  Timer? _debounce;
  List<({String sourceId, String seriesKey, String title, String? cover})> _results = const [];
  int _shake = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  Future<void> _pick(WorldItem item) async {
    final flow = ref.read(glassOnboardingFlowProvider.notifier);
    final first = flow.isFirstPick(item.anilistId);
    final pick = await flow.togglePick(item);
    if (!mounted) return;
    if (pick == null) {
      glassFire(ref, HapticEvent.followRemove);
      setState(() {});
      return;
    }
    if (pick.failed) {
      glassFire(ref, HapticEvent.error);
      setState(() => _shake++);
      return;
    }
    glassFire(ref, HapticEvent.followAdd);
    if (first && item.anilistId > 0) {
      try {
        final r = await ref.read(similarSeedsProvider(item.anilistId).future);
        if (!mounted) return;
        if (r.available) {
          final present = {...ref.read(glassOnboardingFlowProvider).picks.map((p) => p.anilistId)};
          setState(() => _similar[item.anilistId] = [for (final s in r.items) if (s.anilistId != 0 && !present.contains(s.anilistId) && s.anilistId != item.anilistId) s].take(3).toList());
        }
      } catch (_) {}
    }
  }

  void _onQuery(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() => _results = const []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final r = await ref.read(globalSearchRepositoryProvider).search(q.trim(), perPage: 12);
      if (!mounted || r.isErr) return;
      final base = ref.read(apiBaseUrlProvider);
      setState(() => _results = [
            for (final i in r.value.items.where((i) => i.isSource && i.source != null).take(12)) (sourceId: i.source!, seriesKey: i.seriesId, title: i.title, cover: searchResultCoverUrl(base, i.coverUrl)),
          ],);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(glassOnboardingFlowProvider);
    final flow = ref.read(glassOnboardingFlowProvider.notifier);
    final online = ref.watch(networkOnlineChangesProvider).valueOrNull ?? true;
    final catalog = ref.watch(onboardingCatalogProvider(flow.catalogKey()));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(alignment: Alignment.centerLeft, child: LetterReveal("Pick a few you've read or want to read", role: gt.typeTitle1, screenId: 'onboarding', revealKey: '6', headingLevel: 1)),
        const SizedBox(height: 8),
        Semantics(liveRegion: true, child: GlassText(seedCounterLine(state.follows, state.kept), role: gt.typeHeadline)),
        const SizedBox(height: 12),
        GlassSearchField(variant: GlassSearchVariant.filter, placeholder: 'Search your sources', onQuery: _onQuery),
        if (_results.isNotEmpty) ...[
          const SizedBox(height: 12),
          _grid([
            for (final r in _results)
              _Tile(
                title: r.title,
                cover: r.cover,
                picked: state.picks.any((p) => p.sourceId == r.sourceId && p.seriesKey == r.seriesKey),
                onTap: () async {
                  final ok = await flow.followSource(sourceId: r.sourceId, seriesKey: r.seriesKey, title: r.title, coverUrl: r.cover);
                  glassFire(ref, ok ? HapticEvent.followAdd : HapticEvent.error);
                  if (!ok && mounted) setState(() => _shake++);
                },
              ),
          ]),
        ],
        const SizedBox(height: 16),
        if (!online && catalog.isLoading)
          GlassObjectLens(situation: LensSituation.offline, title: "You're offline", description: 'Chapters you downloaded still open with no connection.', tone: GlassLensTone.offline, placement: GlassLensPlacement.inline, onRetry: () async {
            ref.invalidate(onboardingCatalogProvider);
            return true;
          },)
        else
          catalog.when(
            loading: () => GlassSkeletonGroup(
              label: 'Loading titles',
              child: _grid([for (var i = 0; i < 12; i++) GlassSkeleton(height: 190, radius: 12, index: i)]),
            ),
            error: (e, _) => _Popular(onTap: (title, sourceId, seriesKey, cover) => flow.followSource(sourceId: sourceId, seriesKey: seriesKey, title: title, coverUrl: cover)),
            data: (c) {
              if (c.unavailableReason != null && c.seeds.isEmpty) {
                return _Popular(onTap: (title, sourceId, seriesKey, cover) => flow.followSource(sourceId: sourceId, seriesKey: seriesKey, title: title, coverUrl: cover));
              }
              final tiles = <Widget>[];
              var idx = 0;
              for (final s in c.seeds) {
                tiles.add(_seedTile(s, state, idx++, false));
                for (final sim in _similar[s.anilistId] ?? const <WorldItem>[]) {
                  tiles.add(_seedTile(sim, state, idx++, true));
                }
              }
              return _grid(tiles);
            },
          ),
      ],
    );
  }

  Widget _seedTile(WorldItem item, GlassOnboardingState state, int index, bool surfaced) {
    final pick = state.picks.where((p) => p.anilistId == item.anilistId).firstOrNull;
    final tile = _Tile(
      title: item.title,
      cover: item.coverUrl,
      picked: pick != null && !pick.failed,
      failed: pick?.failed ?? false,
      caption: pick?.failed ?? false ? "Couldn't add. Tap to retry." : (item.available.isEmpty ? 'Not on your sources yet' : null),
      shake: _shake,
      onTap: () => unawaited(_pick(item)),
    );
    if (!surfaced) return tile;
    return _Surface(key: ValueKey('sim-${item.anilistId}'), index: index % 3, arrived: _arrived, id: item.anilistId, child: tile);
  }

  Widget _grid(List<Widget> tiles) => LayoutBuilder(
        builder: (context, c) {
          const gap = 12.0;
          final cols = posterColumns(c.maxWidth, 104, gap);
          final w = (c.maxWidth - gap * (cols - 1)) / cols;
          return Wrap(spacing: gap, runSpacing: gap, children: [for (final t in tiles) SizedBox(width: w, child: t)]);
        },
      );
}

/// Surface from depth (glass 4.10): scale 0.94 to 1 and brightness 0.4 to 1 on `springSnappy`, 26 ms apart.
class _Surface extends ConsumerStatefulWidget {
  const _Surface({super.key, required this.index, required this.arrived, required this.id, required this.child});
  final int index;
  final Set<int> arrived;
  final int id;
  final Widget child;

  @override
  ConsumerState<_Surface> createState() => _SurfaceState();
}

class _SurfaceState extends ConsumerState<_Surface> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, value: widget.arrived.contains(widget.id) ? 1 : 0);

  @override
  void initState() {
    super.initState();
    if (!widget.arrived.contains(widget.id)) {
      widget.arrived.add(widget.id);
      Future<void>.delayed(Duration(milliseconds: widget.index * 26), () {
        if (mounted) unawaited(GlassMotion.play(MotionName.surfaceFromDepth, controller: _c, target: 1));
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final t = _c.value.clamp(0.0, 1.0);
          final b = 0.4 + 0.6 * t;
          return Transform.scale(
            scale: 0.94 + 0.06 * _c.value,
            child: ColorFiltered(colorFilter: ColorFilter.matrix([b, 0, 0, 0, 0, 0, b, 0, 0, 0, 0, 0, b, 0, 0, 0, 0, 0, 1, 0]), child: child),
          );
        },
        child: widget.child,
      );
}

/// A poster with the pick ring and check orb, and its caption.
class _Tile extends StatelessWidget {
  const _Tile({required this.title, required this.cover, required this.picked, required this.onTap, this.failed = false, this.caption, this.shake = 0});
  final String title;
  final String? cover;
  final bool picked;
  final bool failed;
  final String? caption;
  final int shake;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassShake(
                trigger: failed ? shake : 0,
                child: Stack(
                  children: [
                    GlassPoster(
                      cover: cover == null ? ColoredBox(color: gt.colorSurface2) : GlassCoverImage(url: cover!, width: w),
                      title: title,
                      width: w,
                      onTap: onTap,
                    ),
                    if (picked)
                      Positioned.fill(child: IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: gt.colorIris500, width: 2))))),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: IgnorePointer(
                        child: SpringValue(
                          value: picked ? 1 : 0,
                          spring: gt.springTick,
                          builder: (context, v, _) => Transform.scale(
                            scale: v.clamp(0.0, 1.25),
                            child: Opacity(opacity: v.clamp(0.0, 1.0), child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: gt.colorIris500), child: SizedBox.square(dimension: 24, child: Center(child: GlyphIcon(GlassGlyph.check, size: 14, color: gt.colorOnTint))))),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              GlassText(caption ?? title, role: gt.typeCaption1, color: failed ? gt.colorDanger : (caption != null ? gt.colorLabel2 : gt.colorLabel1), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          );
        },
      );
}

/// The Popular lists of the pinned sources (or the first three), while the catalogue is unavailable.
class _Popular extends ConsumerWidget {
  const _Popular({required this.onTap});
  final Future<bool> Function(String title, String sourceId, String seriesKey, String? cover) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pins = ref.watch(sourcePinsProvider).valueOrNull?.ids ?? const <String>[];
    final sources = ref.watch(sourcesListProvider).valueOrNull ?? const <SourceSummary>[];
    final ids = pins.isNotEmpty ? pins.take(3).toList() : [for (final s in sources.where((s) => s.browsable).take(3)) s.id];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const GlassInlineNotice(message: "Picks come from your sources' popular lists while suggestions are unavailable."),
        const SizedBox(height: 12),
        for (final id in ids) _Rail(sourceId: id, name: sources.where((s) => s.id == id).firstOrNull?.name ?? id, onTap: onTap),
      ],
    );
  }
}

class _Rail extends ConsumerWidget {
  const _Rail({required this.sourceId, required this.name, required this.onTap});
  final String sourceId;
  final String name;
  final Future<bool> Function(String title, String sourceId, String seriesKey, String? cover) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(sourceBrowseProvider(sourceId)).valueOrNull?.items ?? const [];
    if (items.isEmpty) return const SizedBox.shrink();
    final base = ref.watch(apiBaseUrlProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: GlassText(name, role: gt.typeHeadline)),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length.clamp(0, 12),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final s = items[i];
              final cover = searchResultCoverUrl(base, s.coverUrl);
              return SizedBox(width: 104, child: _Tile(title: s.title, cover: cover, picked: false, onTap: () => unawaited(onTap(s.title, sourceId, s.id, cover))));
            },
          ),
        ),
      ],
    );
  }
}
