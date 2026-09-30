import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/lens_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/object_lens.dart';
import 'package:manhwamaniacs/skins/skins.dart';

class DialogueIdleLens extends StatelessWidget {
  const DialogueIdleLens({super.key});
  @override
  Widget build(BuildContext context) => GlassObjectLens(situation: LensSituation.dialogueIdle, title: 'Search the dialogue you remember', description: 'Type at least one word.', placement: GlassLensPlacement.inline);
}

class DialogueEmptyLens extends StatelessWidget {
  const DialogueEmptyLens({super.key, required this.q});
  final String q;
  @override
  Widget build(BuildContext context) => GlassObjectLens(situation: LensSituation.nothingFound, title: 'No dialogue matches', description: 'Nothing found for “$q” in the chapters you follow.', placement: GlassLensPlacement.inline);
}

class DialogueErrorLens extends StatelessWidget {
  const DialogueErrorLens({super.key, required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => GlassObjectLens(situation: LensSituation.loadError, tone: GlassLensTone.error, title: 'Search failed: check your connection', placement: GlassLensPlacement.inline, primary: LensAction('Try again', onRetry));
}

class DialogueOfflineLens extends StatelessWidget {
  const DialogueOfflineLens({super.key});
  @override
  Widget build(BuildContext context) => GlassObjectLens(situation: LensSituation.offline, tone: GlassLensTone.offline, title: 'Dialogue search needs a connection');
}

class DialogueNovelsLens extends ConsumerWidget {
  const DialogueNovelsLens({super.key, required this.q});
  final String q;
  @override
  Widget build(BuildContext context, WidgetRef ref) => GlassObjectLens(
        situation: LensSituation.dialogueIdle,
        title: 'Dialogue search is for manga',
        description: 'Switch to Manga to use it.',
        primary: LensAction('Search novel text instead', () => ref.read(skinRouterProvider).push<void>(Routes.discover({'scope': 'text', if (q.isNotEmpty) 'q': q}))),
      );
}

class DialogueUnavailableLens extends StatelessWidget {
  const DialogueUnavailableLens({super.key});
  @override
  Widget build(BuildContext context) => GlassObjectLens(situation: LensSituation.unavailable, title: "Dialogue search isn't available on this server.");
}

class DialogueSkeleton extends StatelessWidget {
  const DialogueSkeleton({super.key});
  @override
  Widget build(BuildContext context) => GlassSkeletonGroup(child: Column(children: [for (var i = 0; i < 3; i++) Padding(padding: const EdgeInsets.only(bottom: 10), child: GlassSkeleton(height: 96, radius: 20, index: i))]));
}

/// The phone hint row under the field: with `ocrEngineAvailable` a Downloads link, without it the plain note.
class DialogueHint extends ConsumerWidget {
  const DialogueHint({super.key, required this.engineAvailable});
  final bool engineAvailable;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: engineAvailable
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                GlassLabel('Only chapters with extracted text can be searched. Extract text from downloaded chapters in Downloads.', role: gt.typeFootnote, color: gt.colorLabel2, maxLines: 4),
                GlassButton(label: 'Downloads', variant: GlassButtonVariant.plain, size: GlassButtonSize.small, onPressed: () => ref.read(skinRouterProvider).go(Routes.downloads())),
              ])
            : GlassLabel("This phone can't extract text. Chapters extracted on another device still show up here.", role: gt.typeFootnote, color: gt.colorLabel2, maxLines: 4),
      );
}
