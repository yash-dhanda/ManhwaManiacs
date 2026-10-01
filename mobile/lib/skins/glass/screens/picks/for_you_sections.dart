import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/ai/providers/ai_providers.dart';
import 'package:manhwamaniacs/features/ai/utils/ai_state.dart' show staleDays;
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/skins/glass/copy/ai.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/parts/ai/not_interested.dart';
import 'package:manhwamaniacs/skins/glass/parts/ai/world_card_for.dart';
import 'package:manhwamaniacs/skins/glass/primitives/ai/machine_badge.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/letter_reveal.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/screens/picks/for_you_states.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

const String kPicksScreenId = 'picks';

/// "For you" and "Because you read {title}" (glass 9.1.2): vertical lists on phones, grids with 300 px minimum columns elsewhere.
class ForYouSections extends ConsumerWidget {
  const ForYouSections(
      {super.key,
      required this.recs,
      required this.genre,
      required this.novels,
      required this.onClearGenre,
      required this.onRetry,});
  final AsyncValue<WorldRecommendations> recs;
  final String? genre;
  final bool novels;
  final VoidCallback onClearGenre;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (novels) {
      return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: GlassText(kNovelsNote,
              role: gt.typeFootnote, color: gt.colorLabel2,),);
    }
    final phone = GlassFrame.of(context) == GlassFrameKind.phone;
    return recs.when(
      loading: () => GlassSkeletonGroup(
        ai: true,
        label: 'Loading picks',
        child: Column(
            children: [for (var s = 0; s < 2; s++) _skeletonSection(phone)],),
      ),
      error: (e, _) => AskFailureNote(
          text: "Couldn't load picks.", action: 'Try again', onAction: onRetry,),
      data: (d) {
        final dismissed = ref.watch(dismissedPicksProvider);
        bool keep(WorldItem w) => !dismissed.contains(pickId(w));
        final forYou = d.forYou.where(keep).toList();
        final sections = [
          for (final s in d.sections)
            (s.becauseTitle, s.items.where(keep).toList()),
        ].where((s) => s.$2.isNotEmpty).toList();
        final stale = staleDays(d.generatedAt, ref.read(clockProvider)());
        final empty = forYou.isEmpty && sections.isEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (d.unavailableReason != null)
              Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassText(kCatalogueSaved,
                      role: gt.typeFootnote, color: gt.colorLabel2,),),
            if (empty && genre != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GlassText(noPicksIn(genre!), role: gt.typeHeadline),
                      GlassButton(
                          label: 'Clear the filter',
                          variant: GlassButtonVariant.plain,
                          onPressed: onClearGenre,),
                    ],),
              ),
            if (forYou.isNotEmpty)
              _Section(
                  title: 'For you',
                  subtitle: null,
                  stale: stale,
                  items: forYou,
                  phone: phone,),
            for (final s in sections)
              _Section(
                  title: 'Because you read ${s.$1}',
                  subtitle: null,
                  stale: stale,
                  items: s.$2,
                  phone: phone,),
          ],
        );
      },
    );
  }

  Widget _skeletonSection(bool phone) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GlassSkeleton(width: 160, height: 22, radius: 8),
            const SizedBox(height: 12),
            Wrap(spacing: 20, runSpacing: 12, children: [
              for (var i = 0; i < 6; i++)
                GlassSkeleton(width: 300, height: 132, radius: 26, index: i),
            ],),
          ],
        ),
      );
}

class _Section extends ConsumerWidget {
  const _Section(
      {required this.title,
      required this.subtitle,
      required this.stale,
      required this.items,
      required this.phone,});
  final String title;
  final String? subtitle;
  final int? stale;
  final List<WorldItem> items;
  final bool phone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget card(WorldItem w) => AiCardActions(
        item: w, swipeRow: phone, child: worldCardFor(context, ref, w),);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const MachineBadge(),
              const SizedBox(width: 8),
              Flexible(
                  child: LetterReveal(title,
                      role: gt.typeTitle2,
                      revealKey: 'picks:$title',
                      screenId: kPicksScreenId,),),
              if (stale != null) ...[
                const SizedBox(width: 8),
                GlassText(glassAiStaleLine(stale!),
                    role: gt.typeCaption1, color: gt.colorLabel3,),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (phone)
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (final w in items)
                Padding(
                    padding: const EdgeInsets.only(bottom: 12), child: card(w),),
            ],)
          else
            Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [for (final w in items) card(w)],),
        ],
      ),
    );
  }
}
