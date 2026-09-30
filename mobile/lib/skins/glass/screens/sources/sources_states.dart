import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/lens_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/object_lens.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// Ten row skeletons.
class SourcesSkeleton extends StatelessWidget {
  const SourcesSkeleton({super.key});
  @override
  Widget build(BuildContext context) => GlassSkeletonGroup(child: Column(children: [for (var i = 0; i < 10; i++) Padding(padding: const EdgeInsets.only(bottom: 8), child: GlassSkeleton(height: 64, radius: 20, index: i))]));
}

class SourcesErrorLens extends StatelessWidget {
  const SourcesErrorLens({super.key, required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => GlassObjectLens(situation: LensSituation.loadError, tone: GlassLensTone.error, title: "Couldn't load sources", placement: GlassLensPlacement.inline, primary: LensAction('Retry', onRetry));
}

class SourcesNoneLens extends StatelessWidget {
  const SourcesNoneLens({super.key, required this.novels});
  final bool novels;
  @override
  Widget build(BuildContext context) => GlassObjectLens(situation: LensSituation.unavailable, title: novels ? 'No novel sources installed' : 'No sources installed', placement: GlassLensPlacement.inline);
}

class SourcesNoMatchLens extends StatelessWidget {
  const SourcesNoMatchLens({super.key, this.pinned = false});
  final bool pinned;
  @override
  Widget build(BuildContext context) => GlassObjectLens(
        situation: LensSituation.nothingFound,
        title: pinned ? 'No pinned sources' : 'No sources match',
        description: pinned ? 'Tap the pin on any source to keep it at the top' : 'Try a different name',
        placement: GlassLensPlacement.inline,
      );
}

/// Offline with no cached list.
class SourcesOfflineLens extends ConsumerWidget {
  const SourcesOfflineLens({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => GlassObjectLens(
        situation: LensSituation.offline,
        tone: GlassLensTone.offline,
        title: 'Sources need a connection',
        primary: LensAction('Open downloads', () => ref.read(skinRouterProvider).go(Routes.downloads())),
      );
}
