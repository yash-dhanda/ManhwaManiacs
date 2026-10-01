import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/providers/pending_ask_provider.dart';
import 'package:manhwamaniacs/features/library/utils/recent_searches.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs_more.dart';
import 'package:manhwamaniacs/skins/glass/screens/search/search_common.dart';
import 'package:manhwamaniacs/skins/glass/shell/search_orb.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// The idle state (glass 8.9): Recent rows (x removes), Trending choice chips, a "Browse sources" row and, only when AI is available
/// and `picks` is built, the Ask card.
class SearchIdle extends ConsumerWidget {
  const SearchIdle({super.key, required this.recent, required this.onSearch, required this.onRemove, required this.askAvailable, required this.query});
  final List<String> recent;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onRemove;
  final bool askAvailable;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduced = ref.watch(glassReducedProvider);
    var step = 1;
    Widget section(List<Widget> children) => glassSearchStagger(context, step++, Column(crossAxisAlignment: CrossAxisAlignment.start, children: children), reduced: reduced);
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recent.isNotEmpty) section([
            GlassLabel('Recent', role: gt.typeHeadline),
            for (final r in recent)
              Row(
                children: [
                  Expanded(
                    child: GlassTap(
                      label: 'Search $r',
                      onTap: () => onSearch(r),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(GlassGlyph28.clockCounterClockwise.regular, size: 18, color: gt.colorLabel3), const SizedBox(width: 10), GlassLabel(r, role: gt.typeBody)]),
                    ),
                  ),
                  GlassTap(label: 'Remove $r', onTap: () => onRemove(r), child: Center(child: Icon(GlassGlyph28.x.regular, size: 16, color: gt.colorLabel3))),
                ],
              ),
            const SizedBox(height: 12),
          ]),
          section([
            GlassLabel('Trending', role: gt.typeHeadline),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [for (final t in trendingSearchSuggestions) GlassChip(label: t, kind: GlassChipKind.choice, onPressed: () => onSearch(t))]),
            const SizedBox(height: 12),
          ]),
          section([GlassTap(
            label: 'Browse sources',
            onTap: () => ref.read(skinRouterProvider).go(Routes.sources()),
            child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(GlassGlyph.globe.regular, size: 20, color: gt.colorInfo), const SizedBox(width: 10), Flexible(child: GlassLabel('Browse sources', role: gt.typeBody, maxLines: 2))]),
          ),]),
          if (askAvailable) section([
            const SizedBox(height: 12),
            GlassTap(
              label: 'Describe what you want to read',
              onTap: () {
                ref.read(pendingAskProvider.notifier).set(query);
                // `go`, not `push`: Picks lives in a shell branch, and pushing it over the root /search route built a second shell.
                ref.read(skinRouterProvider).go(Routes.picks());
              },
              child: DecoratedBox(
                decoration: BoxDecoration(color: gt.colorSurface1, borderRadius: BorderRadius.circular(26)),
                child: Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(GlassGlyph28.sparkle.regular, size: 20, color: gt.colorMachine), const SizedBox(width: 10), Flexible(child: GlassLabel('Describe what you want to read', role: gt.typeBody, maxLines: 2))])),
              ),
            ),
          ]),
        ],
      );
  }
}
